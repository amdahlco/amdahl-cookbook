#!/usr/bin/env bash
# grade.sh - grade one draft and print the canonical report card.
#
# Usage: grade.sh <inputs.json|draft.md> <run-dir> [eval-slug] [audience] [account]
#   inputs.json   a JSON object of eval inputs, OR a plain draft file (any
#                 non-.json path is wrapped as {"message": <contents>})
#   run-dir       where scorecard.json + report.md are written (created if missing)
#   eval-slug     default: prompt-and-message-eval
#   audience      optional cohort, e.g. "VP of Marketing"
#   account       optional account name, when it is in your corpus
#
# Writes:
#   <run-dir>/scorecard.json  the full run row (every field, for later analysis)
#   <run-dir>/report.md       the server-authored card - THIS is what you show
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

IN="${1:?inputs.json or draft file required}"
RUNDIR="${2:?run-dir required}"
SLUG="${3:-prompt-and-message-eval}"
AUDIENCE="${4:-}"
ACCOUNT="${5:-}"

mkdir -p "$RUNDIR"

case "$IN" in
  *.json) INPUTS=$(cat "$IN") ;;
  *)      INPUTS=$(inputs_from_file "$IN" "$AUDIENCE" "$ACCOUNT") ;;
esac

RID=$(submit_run "$INPUTS" "$SLUG")
echo "run_id=$RID"

STATUS=$(poll_run "$RID")
api_get "eval-runs/$RID" > "$RUNDIR/scorecard.json"

if [ "$STATUS" != "complete" ]; then
  echo "Run finished as '$STATUS' - see $RUNDIR/scorecard.json" >&2
fi

# The report endpoint renders every run state, including a failure or an
# abstain, so there is always a block to show.
report_markdown "$RID" > "$RUNDIR/report.md"

echo
cat "$RUNDIR/report.md"
echo
echo "Saved: $RUNDIR/report.md (show this) · $RUNDIR/scorecard.json (full run)"
