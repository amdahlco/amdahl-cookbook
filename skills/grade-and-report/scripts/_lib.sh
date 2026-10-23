#!/usr/bin/env bash
# Shared helpers for the grade-and-report scripts: auth, transport and the
# grade call. The cards live in _card.sh (sourced at the end of this file), and
# the prompt-run helpers in _prompt.sh (sourced by prompt.sh only).
#
# Every script here calls the Message Optimizer, so the retry/backoff logic
# lives once. A retry policy that only some call sites use is a retry policy
# that does not exist.
#
# The calls:
#   POST messages/optimize            with mode "grade": grades one draft, on the
#                                     same call. Writes nothing.
#   POST messages/optimize_prompt     starts a prompt run (202, a run_id).
#   GET  messages/optimize_prompt/:id reads it; ?wait_ms= holds the read open.
#
# ## Why the transport is this defensive
#
# Each workspace may run 3 optimizes at the same time and start 12 in any 60
# seconds. Every API key, connector session and the console count together. A
# call over a limit waits in line for up to 15 seconds and is then refused with
# HTTP 429 and a `Retry-After`. A naive retry loop cannot tell "refused because
# I am over the limit" from "transient blip", so it keeps sending. Three things
# are in here to stop that:
#
#   1. Honor the server. A 429 carries `Retry-After`, and responses carry
#      `X-RateLimit-Remaining` / `X-RateLimit-Reset`. Waiting the time you were
#      told to wait is better than guessing.
#   2. Back off with FULL jitter. N workers that all sleep exactly 8s are N
#      workers that all wake at the same instant and collide again.
#   3. Circuit-break. Past some count of consecutive failures the honest read is
#      "it is down", and the right move is to stop and say so.
#
# Source it, do not execute it:  . "$(dirname "$0")/_lib.sh"

# ── Config ───────────────────────────────────────────────────────────────────
# The API base. Override for a non-production workspace.
AMDAHL_API_BASE="${AMDAHL_API_BASE:-https://app.amdahl.ai/api/platform/v1}"

# The workspace API key. `AMDAHL_KEY` is the documented name, the one every
# Amdahl doc uses. `AMDAHL_API_KEY` and `AMDAHL_MCP_API_KEY` are accepted as
# fallbacks, because older setups and MCP client configs already set them, and
# making people keep two copies of one secret in sync is how they end up stale.
AMDAHL_KEY="${AMDAHL_KEY:-${AMDAHL_API_KEY:-${AMDAHL_MCP_API_KEY:-}}}"

# What a grade reads as evidence. `workspace` grades the four evidence lines
# against the workspace's synced conversations. `off` grades `cta_clarity`
# alone. A request file that sets `evidence` itself keeps its own value.
AMDAHL_EVIDENCE="${AMDAHL_EVIDENCE:-workspace}"

# How long the server holds a prompt-run read open waiting for the run to
# settle. `GET messages/optimize_prompt/<id>?wait_ms=30000` blocks up to 30s
# (the server's ceiling). Set to 0 to fall back to tight polling on
# AMDAHL_POLL_INTERVAL.
AMDAHL_WAIT_MS="${AMDAHL_WAIT_MS:-30000}"
case "$AMDAHL_WAIT_MS" in ''|*[!0-9]*) AMDAHL_WAIT_MS=30000 ;; esac

# Poll ceiling for a prompt run, counted in blocking reads: 40 x 30s is 20
# minutes. A prompt run writes and grades one email per recipient, and takes
# minutes.
POLL_ATTEMPTS="${AMDAHL_POLL_ATTEMPTS:-40}"
# Only used when AMDAHL_WAIT_MS=0. With a blocking read the server already does
# the waiting, so the client sleeps ~1s between reads as a courtesy gap.
POLL_INTERVAL="${AMDAHL_POLL_INTERVAL:-15}"

# Retry ladder. 6 attempts against a 60s cap is roughly a 2-3 minute ceiling per
# call: long enough to ride out a deploy, short enough that a batch does not
# stall on one item.
MAX_RETRIES="${AMDAHL_MAX_RETRIES:-6}"
BACKOFF_CAP="${AMDAHL_BACKOFF_CAP:-60}"

# Circuit breaker. Consecutive HARD failures (connection error, or a call that
# used all its retries) across every caller sharing the state file. See
# `breaker_trip` for why the count is per CALL and not per attempt.
CIRCUIT_THRESHOLD="${AMDAHL_CIRCUIT_THRESHOLD:-5}"
# Default is keyed to $PPID so concurrent workers under one batch.sh share one
# breaker. A per-worker breaker would need N times the failures to trip. Set it
# explicitly to share across separate invocations.
AMDAHL_BREAKER_FILE="${AMDAHL_BREAKER_FILE:-${TMPDIR:-/tmp}/amdahl_breaker.$PPID}"
# Last seen rate-limit headroom. Same lifecycle as the breaker, so it is derived
# from the one knob rather than being a second one.
AMDAHL_RL_FILE="${AMDAHL_BREAKER_FILE}.rl"

# curl's wall clock. A grade answers on the same call, and the Optimizer's own
# deadline is 300 seconds, so the default sits above it. It must also outlast a
# blocking prompt-run read, so it is never below wait_ms + 30s.
HTTP_TIMEOUT="${AMDAHL_HTTP_TIMEOUT:-330}"
case "$HTTP_TIMEOUT" in ''|*[!0-9]*) HTTP_TIMEOUT=330 ;; esac
if [ "$HTTP_TIMEOUT" -lt $(( AMDAHL_WAIT_MS / 1000 + 30 )) ]; then
  HTTP_TIMEOUT=$(( AMDAHL_WAIT_MS / 1000 + 30 ))
fi

if [ -z "$AMDAHL_KEY" ]; then
  echo "ERROR: set AMDAHL_KEY to your workspace API key." >&2
  echo "  export AMDAHL_KEY='...'   # console: Settings, then Developer, Create key" >&2
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

# _error_field <field> - a field of the refusal envelope in $LAST_BODY. REST
# nests it under `data.error`; some refusals put it at the top level.
_error_field() {
  local v
  v=$(printf '%s' "$LAST_BODY" | jsonpath "data.error.$1")
  if [ -z "$v" ]; then v=$(printf '%s' "$LAST_BODY" | jsonpath "error.$1"); fi
  printf '%s' "$v"
}

# ── Circuit breaker ──────────────────────────────────────────────────────────
#
# State is a single integer in a file rather than a shell variable because the
# workers that need to agree are separate processes. A variable would give each
# worker its own private opinion, and 3 workers each needing 5 failures is 15
# failures before anything stops.

breaker_count() {
  local n=0
  [ -f "$AMDAHL_BREAKER_FILE" ] && n=$(cat "$AMDAHL_BREAKER_FILE" 2>/dev/null || echo 0)
  # A truncated or half-written file reads as 0. Failing open here is the safe
  # direction: worst case we take one more real failure before tripping.
  case "$n" in ''|*[!0-9]*) n=0 ;; esac
  echo "$n"
}

breaker_is_open() {
  [ "$(breaker_count)" -ge "$CIRCUIT_THRESHOLD" ]
}

# breaker_trip - register one hard failure.
#
# Counted per CALL, not per attempt: a call that retried 6 times and lost is one
# piece of evidence that the endpoint is unwell, not six.
#
# The read-modify-write is NOT atomic. Two workers failing in the same
# millisecond can register as one. That only ever UNDERcounts, which delays the
# open by a failure; it cannot open the breaker when nothing failed.
breaker_trip() {
  local n
  n=$(( $(breaker_count) + 1 ))
  printf '%s\n' "$n" > "$AMDAHL_BREAKER_FILE" 2>/dev/null || true
  if [ "$n" -ge "$CIRCUIT_THRESHOLD" ]; then
    echo "  circuit OPEN: $n consecutive failures - further calls will fail fast" >&2
  fi
}

# Any success is proof the endpoint is alive, so the count resets rather than
# decays. "Consecutive" is the whole claim being made.
breaker_reset() {
  [ -f "$AMDAHL_BREAKER_FILE" ] && printf '0\n' > "$AMDAHL_BREAKER_FILE" 2>/dev/null || true
  return 0
}

# ── Transport ────────────────────────────────────────────────────────────────

# _header <header-file> <lowercase-name> - one header value, or nothing.
# Header names are case-insensitive, so fold case; take the LAST match because
# -D leaves one block per response (a redirect or a 100-continue adds another).
_header() {
  tr -d '\r' < "$1" | grep -i "^$2:" | tail -n 1 | cut -d: -f2- \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true
}

# api_request METHOD PATH [json-body] - one authenticated HTTP call, no retries.
#
# Prints the response body on stdout AND leaves it in $LAST_BODY, together with:
#   LAST_STATUS        HTTP status ("000" if curl never got one)
#   LAST_CURL_RC       curl's exit code (0 = the request completed)
#   LAST_RETRY_AFTER   Retry-After, seconds
#   LAST_RL_REMAINING  X-RateLimit-Remaining
#   LAST_RL_RESET      X-RateLimit-Reset, unix seconds
#
# READ THIS BEFORE CALLING IT: `resp=$(api_request ...)` runs the function in a
# SUBSHELL, so every one of those globals is discarded the moment it returns.
# That is why `api_call` invokes it bare and reads $LAST_BODY.
api_request() {
  local method="$1" path="$2" body="${3:-}"
  local hdr bdy rc=0
  hdr="$(mktemp "${TMPDIR:-/tmp}/amdahl_hdr.XXXXXX")"
  bdy="$(mktemp "${TMPDIR:-/tmp}/amdahl_bdy.XXXXXX")"

  LAST_STATUS="000"; LAST_CURL_RC=0; LAST_BODY=""
  LAST_RETRY_AFTER=""; LAST_RL_REMAINING=""; LAST_RL_RESET=""

  # An array, not a string: the JSON body contains spaces, and an unquoted
  # ${body:+-d $body} would word-split it into garbage arguments.
  local -a args=(
    -sS -X "$method"
    -D "$hdr" -o "$bdy" -w '%{http_code}'
    --max-time "$HTTP_TIMEOUT"
    -H "Authorization: Bearer $AMDAHL_KEY"
  )
  if [ -n "$body" ]; then
    args+=( -H "Content-Type: application/json" --data-binary "$body" )
  fi
  args+=( "$AMDAHL_API_BASE/$path" )

  # `|| rc=$?` because a curl failure is DATA here - the caller decides whether
  # it is worth retrying - and an unguarded non-zero would kill the whole script
  # under `set -e`.
  LAST_STATUS=$(curl "${args[@]}") || rc=$?
  LAST_CURL_RC=$rc
  case "$LAST_STATUS" in ''|*[!0-9]*) LAST_STATUS="000" ;; esac

  LAST_RETRY_AFTER=$(_header "$hdr" 'retry-after')
  LAST_RL_REMAINING=$(_header "$hdr" 'x-ratelimit-remaining')
  LAST_RL_RESET=$(_header "$hdr" 'x-ratelimit-reset')
  LAST_BODY=$(cat "$bdy" 2>/dev/null || true)

  # Publish the headroom for _rl_self_throttle, through a FILE: every worker
  # spends from one window, so every worker should see the same reading.
  if [ -n "$LAST_RL_REMAINING" ] && [ -n "$LAST_RL_RESET" ]; then
    printf '%s %s\n' "$LAST_RL_REMAINING" "$LAST_RL_RESET" > "$AMDAHL_RL_FILE" 2>/dev/null || true
  fi

  rm -f "$hdr" "$bdy"
  printf '%s' "$LAST_BODY"
  return "$rc"
}

# _backoff <attempt> - seconds to wait, FULL jitter, capped.
#
# Full jitter (uniform over the whole window) because the failure being guarded
# against is N workers waking together. Floor of 1s: a sub-second retry is the
# same as not backing off at all.
_backoff() {
  local attempt="$1" ceil
  ceil=$(( 1 << ( attempt > 16 ? 16 : attempt ) ))
  if [ "$ceil" -gt "$BACKOFF_CAP" ]; then ceil="$BACKOFF_CAP"; fi
  if [ "$ceil" -lt 1 ]; then ceil=1; fi
  echo $(( 1 + RANDOM % ceil ))
}

# _retry_after_wait - how long a 429 says to wait, or "" if it did not say.
#
# Header first, then `error.details.retry_after_seconds`. The server copies the
# header from that field, so they agree; the header is read first because a
# proxy may answer a 429 with no body.
#
# The server's number is honored even when it exceeds AMDAHL_BACKOFF_CAP: the
# cap governs OUR guesswork. It is still clamped at 300s, because a longer wait
# is a bug or a badly overloaded server, and the caller should find out.
_retry_after_wait() {
  local s="${LAST_RETRY_AFTER:-}"
  if [ -z "$s" ]; then s=$(_error_field details.retry_after_seconds); fi
  # Retry-After may also be an HTTP-date. We do not parse that; falling through
  # to exponential backoff is correct and self-limiting.
  case "$s" in ''|*[!0-9]*) echo ""; return 0 ;; esac
  if [ "$s" -lt 1 ]; then s=1; fi
  if [ "$s" -gt 300 ]; then s=300; fi
  echo "$s"
}

# _rl_self_throttle - wait BEFORE spending the last of the window.
#
# Only 0 and 1 remaining trigger it. The record is NOT cleared after waiting:
# every worker spends from the same window, so every worker honours the same
# reading. It stops firing on its own once `now` passes the reset.
_rl_self_throttle() {
  local remaining reset now delta
  [ -f "$AMDAHL_RL_FILE" ] || return 0
  read -r remaining reset < "$AMDAHL_RL_FILE" 2>/dev/null || return 0

  case "${remaining:-}" in ''|*[!0-9]*) return 0 ;; esac
  [ "$remaining" -le 1 ] || return 0
  case "${reset:-}" in ''|*[!0-9]*) return 0 ;; esac

  now=$(date +%s)
  delta=$(( reset - now ))
  if [ "$delta" -le 0 ]; then return 0; fi
  # Clamp: a skewed clock or a reset stamp in milliseconds would otherwise park
  # a worker for hours.
  if [ "$delta" -gt "$BACKOFF_CAP" ]; then delta="$BACKOFF_CAP"; fi

  echo "  rate-limit headroom $remaining - waiting ${delta}s for the window to roll" >&2
  sleep "$delta"
}

# api_call METHOD PATH [json-body] - a request with backoff, self-throttling and
# the circuit breaker. Prints the body on stdout; non-zero if it gave up.
api_call() {
  local method="$1" path="$2" body="${3:-}" attempt=0 wait ra code

  if breaker_is_open; then
    echo "ERROR: the Amdahl API appears down (circuit open after $(breaker_count) consecutive failures) - stopping instead of retrying" >&2
    return 1
  fi

  while [ "$attempt" -lt "$MAX_RETRIES" ]; do
    attempt=$(( attempt + 1 ))
    _rl_self_throttle
    api_request "$method" "$path" "$body" > /dev/null || true

    if [ "$LAST_CURL_RC" -ne 0 ] || [ "$LAST_STATUS" = "000" ]; then
      # No HTTP status at all: refused, reset, DNS, or timed out. It backs off
      # like any other transient rather than retrying tight.
      wait=$(_backoff "$attempt")
      echo "  connection error on $method $path (curl rc=$LAST_CURL_RC) - retry in ${wait}s [$attempt/$MAX_RETRIES]" >&2

    elif [ "$LAST_STATUS" = "429" ]; then
      code=$(_error_field code)
      if [ "$code" = "quota_exceeded" ]; then
        # The workspace's monthly cap. It resets monthly and states no
        # Retry-After, so no retry inside this run can succeed.
        echo "ERROR: $method $path refused: the workspace's monthly cap is used up (quota_exceeded)." >&2
        echo "  ${LAST_BODY:0:400}" >&2
        return 1
      fi
      ra=$(_retry_after_wait)
      if [ -n "$ra" ]; then
        wait="$ra"
        echo "  429 on $method $path (${code:-no code}) - server said wait ${wait}s [$attempt/$MAX_RETRIES]" >&2
      else
        wait=$(_backoff "$attempt")
        echo "  429 on $method $path with no Retry-After - backing off ${wait}s [$attempt/$MAX_RETRIES]" >&2
      fi

    elif [ "$LAST_STATUS" -ge 500 ]; then
      wait=$(_backoff "$attempt")
      echo "  HTTP $LAST_STATUS on $method $path - retry in ${wait}s [$attempt/$MAX_RETRIES]" >&2

    elif [ "$LAST_STATUS" -ge 400 ]; then
      # A 4xx that is not a 429 is a statement about the REQUEST: wrong key, a
      # key without `messages:execute`, a malformed field. Retrying it gives the
      # same rejection and hides the message. It does not touch the breaker
      # either: a bad request is not evidence the endpoint is down.
      echo "ERROR: $method $path returned HTTP $LAST_STATUS - not retryable." >&2
      echo "  ${LAST_BODY:0:400}" >&2
      return 1

    elif [ -z "$LAST_BODY" ]; then
      # 2xx with nothing in it. Seen when a proxy ends a response early; the
      # caller would read it as "field missing", so treat it as a transport
      # failure.
      wait=$(_backoff "$attempt")
      echo "  empty body on $method $path (HTTP $LAST_STATUS) - retry in ${wait}s [$attempt/$MAX_RETRIES]" >&2

    else
      breaker_reset
      printf '%s' "$LAST_BODY"
      return 0
    fi

    # No sleep after the final attempt - nothing follows it.
    if [ "$attempt" -lt "$MAX_RETRIES" ]; then sleep "$wait"; fi
  done

  breaker_trip
  echo "ERROR: gave up on $method $path after $MAX_RETRIES attempts (last HTTP $LAST_STATUS)." >&2
  return 1
}

# ── Grade one draft ──────────────────────────────────────────────────────────

# grade_request_from_file <draft-or-request> [context.json] - the request body.
#
#   A .json file is a request object (`message`, and optionally `context`,
#   `recipient`, `channel`, ...). Anything else is the draft text, sent as
#   `message`. A context file holds `{"facts": [...], "rules": [...]}` and
#   replaces any `context` the request file carried.
#
# `mode` is always `grade`. `evidence` is AMDAHL_EVIDENCE unless the request
# file sets it. Fails, before any request is sent, on a file it cannot read or
# a request with no draft in `message`.
grade_request_from_file() {
  python3 - "$@" "$AMDAHL_EVIDENCE" <<'PY'
import json, sys
src, ctx_path, evidence = sys.argv[1], sys.argv[2] if len(sys.argv) > 3 else '', sys.argv[-1]
if src.endswith('.json'):
    try: req = json.load(open(src))
    except Exception as e: sys.exit(f'ERROR: {src} is not valid JSON ({e})')
    if not isinstance(req, dict): sys.exit(f'ERROR: {src} must be a JSON object')
else:
    req = {'message': open(src).read()}
if ctx_path:
    try: ctx = json.load(open(ctx_path))
    except Exception as e: sys.exit(f'ERROR: {ctx_path} is not valid JSON ({e})')
    if not isinstance(ctx, dict): sys.exit(f'ERROR: {ctx_path} must be a JSON object')
    req['context'] = ctx
if not isinstance(req.get('message'), str) or not req['message'].strip():
    sys.exit(f'ERROR: {src} has no draft to grade in "message"')
req['mode'] = 'grade'
req.setdefault('evidence', evidence)
print(json.dumps(req))
PY
}

# grade_draft <request-json> - grade one draft; print the response body.
#
# Non-zero when the call gave up, or when the answer is not a grade
# (`ok: false`, with its reason on stderr). The body is still printed in that
# case, so a caller can save it.
#
# There is no `reuse` knob: an identical request returns the same stored
# grading, and a changed draft is a new grading. Retrying this call after a
# dropped connection therefore cannot grade the draft twice.
grade_draft() {
  local resp ok reason detail
  resp=$(api_call POST "messages/optimize" "$1") || return 1
  printf '%s' "$resp"
  ok=$(printf '%s' "$resp" | jsonpath data.ok)
  if [ "$ok" != "True" ] && [ "$ok" != "true" ]; then
    reason=$(printf '%s' "$resp" | jsonpath data.reason)
    detail=$(printf '%s' "$resp" | jsonpath data.detail)
    if [ -z "$reason" ]; then reason=$(printf '%s' "$resp" | jsonpath data.error.code); fi
    echo "ERROR: the draft was not graded (${reason:-unreadable answer}). ${detail:0:300}" >&2
    return 1
  fi
  if [ "$(printf '%s' "$resp" | jsonpath data.outcome)" != "graded" ]; then
    echo "ERROR: the answer is not a grade (outcome=$(printf '%s' "$resp" | jsonpath data.outcome))." >&2
    return 1
  fi
}

# The cards: render_grade_card, render_prompt_card.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_card.sh"
