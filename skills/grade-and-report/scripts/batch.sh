#!/usr/bin/env bash
# batch.sh - grade a manifest of drafts at BOUNDED concurrency, resumably.
#
# Usage: batch.sh <manifest> <run-dir> [concurrency]
#   manifest     TSV, one item per line (format below)
#   run-dir      parent directory; each item gets <run-dir>/<id>/
#   concurrency  grades in flight at once (default 3 - see below)
#
# Each item is one POST messages/optimize with mode "grade", the same call
# grade.sh makes. The batch lane (`messages.optimize_batch`) does not take
# `mode`, so a batch of grades is many single grades.
#
# ## Manifest format
#
# Tab-separated, one item per line. Blank lines and lines starting with `#` are
# ignored, so you can comment out an item without deleting it.
#
#   id <TAB> draft-file-or-request.json [<TAB> context.json]
#
#   id            directory name under <run-dir>, and the handle you re-run with.
#                 Keep it filesystem-safe; it is used as a path.
#   file          a .json file is sent as the request object; anything else is
#                 sent as `message`. Same rule as grade.sh.
#   context.json  optional {"facts": [...], "rules": [...]} for this item
#
#   # launch-q3.tsv
#   hero-v2	drafts/hero-v2.md	context/launch.json
#   nurture-1	drafts/nurture-1.md
#   api-brief	requests/api-brief.json
#
# ## Why concurrency defaults to 3
#
# A workspace may run 3 optimizes at the same time and start 12 in any 60
# seconds, counted over every key, connector session and the console together.
# A grade holds its call open while it is graded, so 3 workers fill the
# in-flight limit on their own. A call over a limit waits in line for up to 15
# seconds and is then refused with HTTP 429 and a `Retry-After`, which the
# transport honours. Raising this past 3 only adds refusals and waiting, and
# leaves no room for anyone else in the workspace.
#
# ## Re-running
#
# An item whose report.md already exists is SKIPPED. So the second invocation
# only does the casualties: fix whatever broke, run the exact same command, and
# it picks up where it stopped. An identical request returns the same stored
# grading anyway, so a re-grade of an unchanged item would measure nothing new.
# Delete an item's directory to send it again.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

MANIFEST="${1:?manifest TSV required}"
RUNDIR="${2:?run-dir required}"
CONCURRENCY="${3:-3}"

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

# grade_item <id> <src> <context> - one item, start to finish.
#
# Always returns 0. The outcome is what goes in the status file; a worker that
# exited non-zero would just be a second, less informative channel for the same
# fact, and under `set -e` it would take the pool down with it.
grade_item() {
  local id="$1" src="$2" context="$3"
  local dir="$RUNDIR/$id" log request
  mkdir -p "$dir"
  log="$dir/grade.log"

  # Per-item log: three workers writing to one terminal interleaves into
  # something nobody can debug. The terminal gets one line per item; the detail
  # lands next to the artifacts it describes.
  : > "$log"

  if ! request=$(grade_request_from_file "$src" "$context" 2>>"$log"); then
    record "$id" failed "cannot build the request from $src"; return 0
  fi
  printf '%s\n' "$request" > "$dir/request.json"

  if ! grade_draft "$request" > "$dir/grade.json" 2>>"$log"; then
    record "$id" failed "not graded (see $dir/grade.log)"; return 0
  fi

  if ! render_grade_card "$dir/grade.json" > "$dir/report.md.part" 2>>"$log" \
      || [ ! -s "$dir/report.md.part" ]; then
    rm -f "$dir/report.md.part"
    record "$id" failed "card render"; return 0
  fi
  # Rename last. report.md's EXISTENCE is the skip signal on the next run, so it
  # must never exist half-written - a truncated card would be silently accepted
  # as a finished item forever.
  mv "$dir/report.md.part" "$dir/report.md"

  record "$id" done "$(jsonpath data.grade.passed < "$dir/grade.json") of $(jsonpath data.grade.total < "$dir/grade.json") lines (optimize_id=$(jsonpath data.optimize_id < "$dir/grade.json"))"
  echo "  [done] $id"
}

# ── Dispatch ─────────────────────────────────────────────────────────────────

echo "batch: $MANIFEST -> $RUNDIR (concurrency $CONCURRENCY, evidence $AMDAHL_EVIDENCE)"

BREAKER_STOPPED=0

# Fed by redirection, NOT `cat | while`: a piped loop runs in a subshell, where
# `jobs` reports that subshell's jobs and the pool cap silently stops working.
while IFS=$'\t' read -r id src context || [ -n "${id:-}" ]; do
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
  # a grade in flight may be close to an answer, and stopping it would throw
  # that work away.
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
  grade_item "$id" "$src" "${context:-}" &
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
  echo "  CIRCUIT OPEN: the Amdahl API stopped answering, so the batch stopped" >&2
  echo "  launching new items rather than grinding against it. Everything not" >&2
  echo "  listed above is untouched - re-run the same command once it is back." >&2
fi
echo
echo "Saved: $STATUS (one line per item) · $RUNDIR/<id>/{report.md,grade.json,grade.log}"

# Non-zero when anything is outstanding, so a wrapper or CI step notices.
if [ "${FAILED:-0}" -gt 0 ] || [ "$BREAKER_STOPPED" -eq 1 ]; then
  exit 1
fi
