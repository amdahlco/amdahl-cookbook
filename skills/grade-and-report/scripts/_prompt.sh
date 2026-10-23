#!/usr/bin/env bash
# Prompt-run helpers: start a run of messages.optimize_prompt and read it until
# it settles. Sourced by prompt.sh, after _lib.sh (it uses api_call and
# jsonpath).

# prompt_request_from_file <prompt-file> <mode> [extras.json] - the request.
# `extras.json` is an object merged in as is: `recipients`, `context`,
# `channel`, `idempotency_key`.
prompt_request_from_file() {
  python3 - "$@" <<'PY'
import json, sys
src, mode = sys.argv[1], sys.argv[2]
extras_path = sys.argv[3] if len(sys.argv) > 3 else ''
req = {}
if extras_path:
    try: req = json.load(open(extras_path))
    except Exception as e: sys.exit(f'ERROR: {extras_path} is not valid JSON ({e})')
    if not isinstance(req, dict): sys.exit(f'ERROR: {extras_path} must be a JSON object')
req['prompt'] = open(src).read()
if not req['prompt'].strip(): sys.exit(f'ERROR: {src} is empty')
req['mode'] = mode
print(json.dumps(req))
PY
}

# start_prompt_run <request-json> - start a prompt run; print its run_id.
#
# An identical request names the run an earlier identical request started, so
# a retry after a dropped connection starts no second run. `replayed: true`
# says the answer is such an earlier run.
start_prompt_run() {
  local resp rid replayed
  resp=$(api_call POST "messages/optimize_prompt" "$1") || return 1
  rid=$(printf '%s' "$resp" | jsonpath data.run_id)
  if [ -z "$rid" ]; then
    echo "ERROR: could not start a prompt run. Last response: ${resp:0:400}" >&2
    return 1
  fi
  replayed=$(printf '%s' "$resp" | jsonpath data.replayed)
  if [ "$replayed" = "True" ] || [ "$replayed" = "true" ]; then
    echo "NOTE: replayed=true - this is the run an earlier identical request started." >&2
  fi
  echo "$rid"
}

# poll_prompt_run <run-id> - block until the run settles; print the final body.
#
# The read BLOCKS server-side (`?wait_ms=`), so a run of several minutes costs
# a read every 30 seconds rather than a tight loop.
poll_prompt_run() {
  local rid="$1" status resp path gap attempt
  if [ "$AMDAHL_WAIT_MS" -gt 0 ]; then
    path="messages/optimize_prompt/$rid?wait_ms=$AMDAHL_WAIT_MS"
    gap=1   # the server did the waiting; this is a courtesy gap
  else
    path="messages/optimize_prompt/$rid"
    gap="$POLL_INTERVAL"
  fi

  for attempt in $(seq 1 "$POLL_ATTEMPTS"); do
    # A failure here means retries ran out or the breaker opened. Polling again
    # does not help, so it propagates.
    resp=$(api_call GET "$path") || return 1
    status=$(printf '%s' "$resp" | jsonpath data.status)
    case "$status" in
      complete|failed)
        printf '%s' "$resp"
        return 0
        ;;
    esac
    if [ -n "$(printf '%s' "$resp" | jsonpath data.error.code)" ]; then
      # A run whose result could not be read answers an error, not a status.
      printf '%s' "$resp"
      return 0
    fi
    echo "  read $attempt/$POLL_ATTEMPTS: ${status:-unreadable} $(printf '%s' "$resp" | jsonpath data.phase)" >&2
    sleep "$gap"
  done
  echo "ERROR: prompt run $rid did not settle in time. Read it later: GET messages/optimize_prompt/$rid" >&2
  return 1
}
