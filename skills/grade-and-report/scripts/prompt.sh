#!/usr/bin/env bash
# prompt.sh - grade or improve a reusable prompt, by the emails it writes.
#
# Usage: prompt.sh <prompt-file> <run-dir> [grade|improve] [extras.json]
#   prompt-file  the reusable prompt: a template, an agent's system prompt, a
#                team's playbook. A prompt that reads as one message is refused
#                (`prompt_is_one_off`); grade that message with grade.sh.
#   mode         `improve` (the default) or `grade`
#   extras.json  optional request fields: `recipients` (1 to 6; `improve` needs
#                at least 2, and 6 gives a reportable held-out lift), `context`,
#                `channel`, `idempotency_key`
#
# Calls POST messages/optimize_prompt (202, a run_id), then reads
# GET messages/optimize_prompt/<id>?wait_ms=30000 until the run settles. A run
# takes minutes.
#
# Writes:
#   <run-dir>/request.json  what was sent
#   <run-dir>/run.json      the settled run (every field, emails included)
#   <run-dir>/report.md     the card rendered from run.json - show this
#   <run-dir>/prompt.md     the revised prompt, only when outcome is `improved`
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_prompt.sh"

SRC="${1:?prompt file required}"
RUNDIR="${2:?run-dir required}"
MODE="${3:-improve}"
EXTRAS="${4:-}"

case "$MODE" in grade|improve) ;; *) echo "ERROR: mode must be grade or improve" >&2; exit 1 ;; esac
mkdir -p "$RUNDIR"

REQUEST=$(prompt_request_from_file "$SRC" "$MODE" "$EXTRAS")
printf '%s\n' "$REQUEST" > "$RUNDIR/request.json"

RID=$(start_prompt_run "$REQUEST")
echo "run_id=$RID"

poll_prompt_run "$RID" > "$RUNDIR/run.json"
render_prompt_card "$RUNDIR/run.json" > "$RUNDIR/report.md"

if [ "$(jsonpath data.outcome < "$RUNDIR/run.json")" = "improved" ]; then
  jsonpath data.prompt < "$RUNDIR/run.json" > "$RUNDIR/prompt.md"
fi

echo
cat "$RUNDIR/report.md"
echo
echo "Saved: $RUNDIR/report.md (show this) · $RUNDIR/run.json (full run)"
if [ -f "$RUNDIR/prompt.md" ]; then echo "Revised prompt: $RUNDIR/prompt.md"; fi

if [ "$(jsonpath data.status < "$RUNDIR/run.json")" != "complete" ]; then exit 1; fi
