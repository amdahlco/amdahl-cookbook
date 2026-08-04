#!/usr/bin/env bash
# Shared helpers for the grade-and-report scripts: auth, submit, poll, report.
#
# Every script here submits a run and waits for it, so the retry/backoff logic
# lives once. The three scripts this was promoted from each carried their own
# copy, and they had already drifted (different retry counts, different terminal
# status lists, one of them reading a field that does not exist).
#
# Source it, do not execute it:  . "$(dirname "$0")/_lib.sh"

# ── Config ───────────────────────────────────────────────────────────────────
# The API base. Override for a non-production workspace.
AMDAHL_API_BASE="${AMDAHL_API_BASE:-https://app.amdahl.ai/api/platform/v1}"

# The workspace API key. `AMDAHL_API_KEY` is the documented name;
# `AMDAHL_MCP_API_KEY` is accepted because that is what an MCP client config
# already sets, and making people keep two copies of one secret in sync is how
# they end up stale.
AMDAHL_KEY="${AMDAHL_API_KEY:-${AMDAHL_MCP_API_KEY:-}}"

# Poll ceiling. A graded run is typically 1-3 minutes; 20 x 15s = 5 minutes.
POLL_ATTEMPTS="${AMDAHL_POLL_ATTEMPTS:-20}"
POLL_INTERVAL="${AMDAHL_POLL_INTERVAL:-15}"

if [ -z "$AMDAHL_KEY" ]; then
  echo "ERROR: set AMDAHL_API_KEY to your workspace API key." >&2
  echo "  export AMDAHL_API_KEY='...'   # Settings -> API keys in the console" >&2
  return 1 2>/dev/null || exit 1
fi

# ── Helpers ──────────────────────────────────────────────────────────────────

# jsonpath <json-on-stdin> <dotted.path> - print a nested field, or nothing.
# Total: a missing path prints an empty string rather than a traceback, because
# every caller here is inside `set -e`.
jsonpath() {
  python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for k in sys.argv[1].split('.'):
    if isinstance(d,list):
        try: d=d[int(k)]
        except Exception: sys.exit(0)
    elif isinstance(d,dict): d=d.get(k)
    else: sys.exit(0)
    if d is None: sys.exit(0)
print(d if not isinstance(d,(dict,list)) else json.dumps(d))
" "$1"
}

# api_get <path> - authenticated GET against the platform API.
api_get() {
  curl -s --max-time 30 -H "Authorization: Bearer $AMDAHL_KEY" "$AMDAHL_API_BASE/$1" || true
}

# submit_run <inputs-json> [eval-slug] [evidence-from-run-id] - start a run,
# print its id on stdout. Retries: the platform returns intermittent 5xx during
# a deploy, and losing a whole batch to one of those is not worth it.
#
# ALWAYS submits reuse=force. The `cached` default is content-addressed on the
# inputs with a 15-minute window, so an iteration loop silently replays the
# previous verdict and the score cannot move - which reads exactly like "my edit
# did nothing".
submit_run() {
  local inputs="$1" slug="${2:-prompt-and-message-eval}" pin="${3:-}"
  local body resp rid reused
  body=$(python3 -c "
import json,sys
b={'eval':sys.argv[1],'reuse':'force','inputs':json.loads(sys.argv[2])}
if sys.argv[3]: b['evidence_from_run']=sys.argv[3]
print(json.dumps(b))
" "$slug" "$inputs" "$pin")

  for attempt in 1 2 3 4; do
    resp=$(curl -s --max-time 40 -X POST "$AMDAHL_API_BASE/evals/run" \
      -H "Authorization: Bearer $AMDAHL_KEY" -H "Content-Type: application/json" \
      -d "$body" || true)
    rid=$(printf '%s' "$resp" | jsonpath data.run_id)
    [ -n "$rid" ] && break
    echo "  submit attempt $attempt failed, retrying..." >&2
    sleep $((attempt * 3))
  done

  if [ -z "${rid:-}" ]; then
    echo "ERROR: could not submit an eval run. Last response: $resp" >&2
    return 1
  fi

  # `reused` is the one field that catches a silent no-op. A replay returns a
  # verdict that looks completely normal, so without this check an iteration
  # loop can run all afternoon grading nothing.
  reused=$(printf '%s' "$resp" | jsonpath data.reused)
  if [ "$reused" = "True" ] || [ "$reused" = "true" ]; then
    echo "WARN: reused=true - this run is a REPLAY, not a fresh grade." >&2
  fi
  echo "$rid"
}

# poll_run <run-id> - block until the run reaches a terminal status; print it.
poll_run() {
  local rid="$1" status
  for attempt in $(seq 1 "$POLL_ATTEMPTS"); do
    status=$(api_get "eval-runs/$rid" | jsonpath data.run.status)
    case "$status" in
      complete|failed|canceled)
        echo "$status"
        return 0
        ;;
    esac
    echo "  poll $attempt/$POLL_ATTEMPTS: ${status:-unreachable}" >&2
    sleep "$POLL_INTERVAL"
  done
  echo "ERROR: run $rid did not reach a terminal status in time." >&2
  return 1
}

# report_markdown <run-id> - the server-authored report card.
#
# This is the block to show a person, PASTED AS WRITTEN. The numbers on it were
# computed by Amdahl; restating them in your own words is how a score that
# describes the rewrite gets reported as a score for the draft.
report_markdown() {
  api_get "eval-runs/$1/report" | jsonpath data.report.markdown
}

# report_field <run-id> <dotted-path-under-headline> - one machine-readable
# number off the same derivation the card renders, e.g. `submitted.score_15`.
report_field() {
  api_get "eval-runs/$1/report" | jsonpath "data.report.headline.$2"
}

# inputs_from_file <draft-file> [audience] [account] - build the inputs JSON.
inputs_from_file() {
  python3 -c "
import json,sys
i={'message':open(sys.argv[1]).read()}
if len(sys.argv)>2 and sys.argv[2]: i['audience']=sys.argv[2]
if len(sys.argv)>3 and sys.argv[3]: i['account']=sys.argv[3]
print(json.dumps(i))
" "$@"
}
