#!/usr/bin/env bash
# batch.sh - grade a manifest of drafts at BOUNDED concurrency, resumably.
#
# Usage: batch.sh <manifest> <run-dir> [concurrency] [eval-slug]
#   manifest     TSV, one item per line (format below)
#   run-dir      parent directory; each item gets <run-dir>/<id>/
#   concurrency  simultaneous runs in flight (default 3 - see below)
#   eval-slug    default: $AMDAHL_EVAL_SLUG, else prompt-and-message-eval
#
# ## Manifest format
#
# Tab-separated, one item per line. Blank lines and lines starting with `#` are
# ignored, so you can comment out an item without deleting it.
#
#   id <TAB> draft-file-or-inputs.json [<TAB> audience] [<TAB> account]
#
#   id        directory name under <run-dir>, and the handle you re-run with.
#             Keep it filesystem-safe; it is used as a path.
#   file      a .json file is sent as the inputs object verbatim; anything else
#             is wrapped as {"message": <contents>}, same rule as grade.sh.
#   audience  optional cohort, e.g. "VP of Marketing"
#   account   optional account name, when it is in your corpus
#
#   # launch-q3.tsv
#   hero-v2	drafts/hero-v2.md	VP of Marketing
#   nurture-1	drafts/nurture-1.md	RevOps	Acme Corp
#   api-brief	inputs/api-brief.json
#
# TSV rather than CSV because audience and account are prose that contains
# commas far more often than it contains tabs.
#
# ## Why concurrency defaults to 3, not 10
#
# The API allows 100 req/min per IP. What blew that budget was 10 workers on a
# tight poll loop: the polling, not the grading, was the traffic. With the
# blocking read in _lib.sh a single run costs roughly 1 submit + ~5 blocking
# reads + 2 report/scorecard fetches over its 2-3 minutes, so 3 workers sit
# around 10 req/min - an order of magnitude under the limit, with room for the
# retries a bad minute needs. Raising this is possible, but the ceiling that
# matters is requests per minute, not workers, and every worker you add also
# adds its share of the retry traffic when things go wrong.
#
# ## Re-running
#
# An item whose report.md already exists is SKIPPED. So the second invocation
# only does the casualties: fix whatever broke, run the exact same command, and
# it picks up where it stopped instead of re-grading (and re-paying for) the
# items that already landed. Delete an item's directory to force a re-grade.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

MANIFEST="${1:?manifest TSV required}"
RUNDIR="${2:?run-dir required}"
CONCURRENCY="${3:-3}"
SLUG="${4:-${AMDAHL_EVAL_SLUG:-prompt-and-message-eval}}"

[ -f "$MANIFEST" ] || { echo "ERROR: no such manifest: $MANIFEST" >&2; exit 1; }
case "$CONCURRENCY" in ''|*[!0-9]*|0) echo "ERROR: concurrency must be a positive integer" >&2; exit 1 ;; esac

mkdir -p "$RUNDIR"
STATUS="$RUNDIR/batch-status.tsv"
: > "$STATUS"

# Workers are subshells of this process, so they already inherit the breaker
# path; exporting it also covers anything that shells out. One breaker for the
# whole batch is the point - a per-worker breaker would need CONCURRENCY times
# the failures to notice the same dead endpoint.
export AMDAHL_BREAKER_FILE
# Start closed. A file left behind by an earlier batch that died mid-flight
# would otherwise open the breaker before the first request.
printf '0\n' > "$AMDAHL_BREAKER_FILE"

# record <id> <outcome> [detail] - one line per item, appended by workers.
#
# Concurrent appends of a short line to the same file are atomic in practice
# (single write, well under PIPE_BUF), which is why this is a bare `>>` and not
# a lock. The summary is computed from this file rather than from variables
# because a background subshell cannot hand a variable back to its parent.
record() {
  printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}" >> "$STATUS"
}

# grade_item <id> <src> <audience> <account> - one item, start to finish.
#
# Always returns 0. The outcome is what goes in the status file; a worker that
# exited non-zero would just be a second, less informative channel for the same
# fact, and under `set -e` it would take the pool down with it.
grade_item() {
  local id="$1" src="$2" audience="$3" account="$4"
  local dir="$RUNDIR/$id" log inputs rid status
  mkdir -p "$dir"
  log="$dir/grade.log"

  # Per-item log: three workers writing to one terminal interleaves into
  # something nobody can debug. The terminal gets one line per item; the detail
  # lands next to the artifacts it describes.
  : > "$log"

  case "$src" in
    *.json)
      if ! inputs=$(cat "$src" 2>>"$log"); then
        record "$id" failed "cannot read inputs file $src"; return 0
      fi
      ;;
    *)
      if ! inputs=$(inputs_from_file "$src" "$audience" "$account" 2>>"$log"); then
        record "$id" failed "cannot read draft file $src"; return 0
      fi
      ;;
  esac

  if ! rid=$(submit_run "$inputs" "$SLUG" 2>>"$log"); then
    record "$id" failed "submit"; return 0
  fi
  printf 'run_id=%s\n' "$rid" >> "$log"

  if ! status=$(poll_run "$rid" 2>>"$log"); then
    record "$id" failed "never settled (run_id=$rid)"; return 0
  fi

  if ! api_get "eval-runs/$rid" > "$dir/scorecard.json" 2>>"$log"; then
    record "$id" failed "scorecard fetch (run_id=$rid)"; return 0
  fi

  # The report endpoint renders every run state, including a failure or an
  # abstain, so a non-`complete` status still has a card worth keeping. It is
  # recorded as done with the status attached rather than as a failure - the run
  # produced a result, and re-running it would produce the same one.
  if ! report_markdown "$rid" > "$dir/report.md.part" 2>>"$log" || [ ! -s "$dir/report.md.part" ]; then
    rm -f "$dir/report.md.part"
    record "$id" failed "report fetch (run_id=$rid)"; return 0
  fi
  # Rename last. report.md's EXISTENCE is the skip signal on the next run, so it
  # must never exist half-written - a truncated card would be silently accepted
  # as a finished item forever.
  mv "$dir/report.md.part" "$dir/report.md"

  record "$id" done "$status (run_id=$rid)"
  echo "  [done] $id - $status"
}

# ── Dispatch ─────────────────────────────────────────────────────────────────

echo "batch: $MANIFEST -> $RUNDIR (concurrency $CONCURRENCY, eval $SLUG)"

BREAKER_STOPPED=0

# Fed by redirection, NOT `cat | while`: a piped loop runs in a subshell, where
# `jobs` reports that subshell's jobs and the pool cap silently stops working.
while IFS=$'\t' read -r id src audience account || [ -n "${id:-}" ]; do
  # Comments and blank lines. Leading `#` only - an id is never a comment.
  case "${id:-}" in ''|'#'*) continue ;; esac
  if [ -z "${src:-}" ]; then
    echo "  [skip] $id - no file column"
    record "$id" failed "manifest line has no file column"
    continue
  fi

  # Idempotent backfill. `-s` not `-f`: a zero-byte report.md is a casualty, not
  # a finished item, and treating it as done would strand it permanently.
  if [ -s "$RUNDIR/$id/report.md" ]; then
    echo "  [skip] $id - report.md already exists"
    record "$id" skipped "report.md already exists"
    continue
  fi

  # Stop LAUNCHING once the endpoint looks dead. In-flight items are left alone:
  # they may well be a poll away from finishing, and killing them would turn
  # completed server-side work into a re-grade.
  if breaker_is_open; then
    BREAKER_STOPPED=1
    echo "  [stop] circuit open - not launching further items" >&2
    break
  fi

  # Block until a slot frees. This is the cap: the pool never exceeds
  # CONCURRENCY, so the request rate has a hard ceiling rather than a hopeful
  # one. Polling `jobs` rather than `wait -n` because macOS ships bash 3.2.
  while [ "$(jobs -pr | wc -l | tr -d ' ')" -ge "$CONCURRENCY" ]; do
    sleep 1
  done

  echo "  [run ] $id"
  grade_item "$id" "$src" "${audience:-}" "${account:-}" &
done < "$MANIFEST"

# Let everything in flight land before reporting. Bare `wait` returns non-zero
# if any child did, and grade_item never does, but `|| true` keeps a surprise
# from killing the summary - which is the part the user actually needs.
wait || true

if breaker_is_open; then BREAKER_STOPPED=1; fi

# ── Summary ──────────────────────────────────────────────────────────────────

# awk rather than `grep -c`, which exits 1 on zero matches and would take the
# summary down with it under `set -e`.
count() { awk -F'\t' -v want="$1" '$2==want {n++} END {print n+0}' "$STATUS"; }
DONE=$(count done)
SKIPPED=$(count skipped)
FAILED=$(count failed)
FAILED_IDS=$(awk -F'\t' '$2=="failed" {printf "%s ", $1}' "$STATUS")

echo
echo "== SUMMARY =="
echo "  done    : ${DONE:-0}"
echo "  skipped : ${SKIPPED:-0}  (report.md already present)"
echo "  failed  : ${FAILED:-0}"
if [ -n "$FAILED_IDS" ]; then
  # A space-separated list, because the next thing you do with it is paste it
  # into a grep to build a smaller manifest.
  echo
  echo "  re-run these ids: $FAILED_IDS"
fi
if [ "$BREAKER_STOPPED" -eq 1 ]; then
  echo
  echo "  CIRCUIT OPEN: the eval endpoint stopped answering, so the batch stopped" >&2
  echo "  launching new items rather than grinding against it. Everything not" >&2
  echo "  listed above is untouched - re-run the same command once it is back." >&2
fi
echo
echo "Saved: $STATUS (one line per item) · $RUNDIR/<id>/{report.md,scorecard.json,grade.log}"

# Non-zero when anything is outstanding, so a wrapper or CI step notices.
if [ "${FAILED:-0}" -gt 0 ] || [ "$BREAKER_STOPPED" -eq 1 ]; then
  exit 1
fi
