#!/usr/bin/env bash
# grade.sh - grade one draft and print the card.
#
# Usage: grade.sh <draft.md|request.json> <run-dir> [context.json]
#   draft.md      the draft, sent verbatim as `message`
#   request.json  OR a request object: `message`, and optionally `context`,
#                 `recipient`, `recipient_notes`, `message_type`, `channel`,
#                 `evidence`. The recipient fields are beta, per workspace.
#   run-dir       where grade.json + report.md are written (created if missing)
#   context.json  optional {"facts": [...], "rules": [...]}; replaces any
#                 `context` in request.json
#
# Calls POST messages/optimize with mode "grade". The grade answers on the same
# call; nothing is written. `evidence` defaults to AMDAHL_EVIDENCE (workspace),
# so the four evidence lines are graded against this workspace's conversations.
#
# Writes:
#   <run-dir>/request.json  what was sent
#   <run-dir>/grade.json    the full response (every field, for later analysis)
#   <run-dir>/report.md     the card rendered from grade.json - show this
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

IN="${1:?draft file or request.json required}"
RUNDIR="${2:?run-dir required}"
CONTEXT="${3:-}"

mkdir -p "$RUNDIR"

REQUEST=$(grade_request_from_file "$IN" "$CONTEXT")
printf '%s\n' "$REQUEST" > "$RUNDIR/request.json"

# The response is saved even when it is not a grade, so the reason survives.
if ! grade_draft "$REQUEST" > "$RUNDIR/grade.json"; then
  echo "Not graded - see $RUNDIR/grade.json" >&2
  exit 1
fi

render_grade_card "$RUNDIR/grade.json" > "$RUNDIR/report.md"

echo
cat "$RUNDIR/report.md"
echo
echo "Saved: $RUNDIR/report.md (show this) · $RUNDIR/grade.json (full response)"
