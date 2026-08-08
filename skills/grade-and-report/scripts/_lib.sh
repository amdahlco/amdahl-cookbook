#!/usr/bin/env bash
# Shared helpers for the grade-and-report scripts: auth, submit, poll, report.
#
# Every script here submits a run and waits for it, so the retry/backoff logic
# lives once. The three scripts this was promoted from each carried their own
# copy, and they had already drifted (different retry counts, different terminal
# status lists, one of them reading a field that does not exist).
#
# ## Why the transport is this defensive
#
# The API rate-limits at 100 req/min per IP. A batch run with 10 workers on a
# tight 15s poll loop blows through that in well under a minute, and the failure
# is not a clean error: the server starts dropping connections, and a naive
# retry loop cannot tell "dropped because I am hammering" from "transient blip",
# so it keeps hammering. One user ground against a dead endpoint for 30-60
# minutes that way. Three things are in here to make that impossible:
#
#   1. Honor the server. A 429 carries `Retry-After`, and EVERY response carries
#      `X-RateLimit-Remaining` / `X-RateLimit-Reset`. Waiting the time you were
#      told to wait is strictly better than guessing, and reading the headroom
#      lets us stop BEFORE the 429 rather than after it.
#   2. Back off with FULL jitter. N workers that all sleep exactly 8s are N
#      workers that all wake at the same instant and re-collide.
#   3. Circuit-break. Retrying is only correct while the endpoint might come
#      back. Past some count of consecutive failures the honest read is "it is
#      down", and the right move is to stop and say so.
#
# Plus the poll loop now BLOCKS server-side (`?wait_ms=`), which is the change
# that actually drops the request count: a 2-3 minute run costs ~5 requests
# instead of ~12.
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

# How long the server holds a read open waiting for the run to settle.
# `GET /eval-runs/<id>?wait_ms=30000` blocks up to 30s, so a 2-3 minute run is
# ~5 requests instead of ~12. Set to 0 to fall back to tight polling on
# AMDAHL_POLL_INTERVAL (only useful against a server that does not support it).
AMDAHL_WAIT_MS="${AMDAHL_WAIT_MS:-30000}"
case "$AMDAHL_WAIT_MS" in ''|*[!0-9]*) AMDAHL_WAIT_MS=30000 ;; esac

# Poll ceiling. Now counted in BLOCKING reads, not tight polls: 12 x 30s ≈ 6
# minutes, which is a wide margin over a typical 1-3 minute run. The env var
# keeps its old name so an existing override still means "the ceiling".
POLL_ATTEMPTS="${AMDAHL_POLL_ATTEMPTS:-12}"
# Only used when AMDAHL_WAIT_MS=0. With a blocking read the server already does
# the waiting, so the client sleeps ~1s between reads as a courtesy gap.
POLL_INTERVAL="${AMDAHL_POLL_INTERVAL:-15}"

# Retry ladder. 6 attempts against a 60s cap is roughly a 2-3 minute ceiling per
# call - long enough to ride out a deploy, short enough that a batch does not
# silently stall on one item.
MAX_RETRIES="${AMDAHL_MAX_RETRIES:-6}"
BACKOFF_CAP="${AMDAHL_BACKOFF_CAP:-60}"

# Circuit breaker. Consecutive HARD failures (connection error, or a call that
# exhausted its retries) across every caller sharing the state file. See
# `breaker_trip` for why the count is per-CALL and not per-attempt.
CIRCUIT_THRESHOLD="${AMDAHL_CIRCUIT_THRESHOLD:-5}"
# Default is keyed to $PPID so concurrent workers under one batch.sh share one
# breaker - that sharing is the point, a per-worker breaker would need N times
# the failures to trip. Set it explicitly to share across separate invocations.
AMDAHL_BREAKER_FILE="${AMDAHL_BREAKER_FILE:-${TMPDIR:-/tmp}/amdahl_breaker.$PPID}"
# Last seen rate-limit headroom, same lifecycle as the breaker so it rides along
# on the one knob. Derived rather than its own env var - two paths that have to
# be set together is one more thing to get half-right.
AMDAHL_RL_FILE="${AMDAHL_BREAKER_FILE}.rl"

# curl's wall clock has to outlast the server's blocking read, or --max-time
# guillotines the very request we asked to be held open. Derived, not a knob, so
# it cannot drift out of sync with AMDAHL_WAIT_MS.
HTTP_TIMEOUT=$(( AMDAHL_WAIT_MS / 1000 + 30 ))

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

# ── Circuit breaker ──────────────────────────────────────────────────────────
#
# State is a single integer in a file rather than a shell variable because the
# workers that need to agree are separate processes. A variable would give each
# worker its own private opinion, and 3 workers each needing 5 failures is 15
# failures before anything stops - which is the grind this exists to prevent.

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
# piece of evidence that the endpoint is unwell, not six. With the default
# ladder that puts the worst case at roughly CIRCUIT_THRESHOLD x 2-3 minutes
# before the breaker opens - minutes, against the 30-60 the naive loop burned.
#
# The read-modify-write is NOT atomic. Two workers failing in the same
# millisecond can register as one. That only ever UNDERcounts, which delays the
# open by a failure; it cannot open the breaker spuriously, which is the
# direction that would matter.
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
# Header names are case-insensitive and the gateway has changed casing before,
# so fold case; take the LAST match because -D leaves one block per response
# (a redirect or a 100-continue adds another).
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
# That is why `api_call` invokes it bare and reads $LAST_BODY. The stdout print
# is kept for the one-shot case where you only want the body and nothing else.
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

  # Publish the headroom for _rl_self_throttle. Via a FILE, not just the global:
  # the limit is per-IP, so every worker is spending from one window and every
  # worker should see the same reading - and the globals do not survive the
  # command substitution most callers wrap this in anyway.
  if [ -n "$LAST_RL_REMAINING" ] && [ -n "$LAST_RL_RESET" ]; then
    printf '%s %s\n' "$LAST_RL_REMAINING" "$LAST_RL_RESET" > "$AMDAHL_RL_FILE" 2>/dev/null || true
  fi

  rm -f "$hdr" "$bdy"
  printf '%s' "$LAST_BODY"
  return "$rc"
}

# _backoff <attempt> - seconds to wait, FULL jitter, capped.
#
# Full jitter (uniform over the whole window) rather than the textbook
# "cap/2 + rand" because the failure mode being defended against is N workers
# waking together. Half-jitter still clusters them in the back half of the
# window; full jitter spreads them across all of it. Floor of 1s: a sub-second
# retry is indistinguishable from not backing off at all.
_backoff() {
  local attempt="$1" ceil
  ceil=$(( 1 << ( attempt > 16 ? 16 : attempt ) ))
  if [ "$ceil" -gt "$BACKOFF_CAP" ]; then ceil="$BACKOFF_CAP"; fi
  if [ "$ceil" -lt 1 ]; then ceil=1; fi
  echo $(( 1 + RANDOM % ceil ))
}

# _retry_after_wait - how long a 429 says to wait, or "" if it did not say.
#
# Header first, then `error.details.retry_after_seconds` - the server sends
# both, and they have been observed to disagree by a second on a window edge,
# where the header is the one the limiter actually enforces.
#
# The server's number is honored even when it exceeds AMDAHL_BACKOFF_CAP: the
# cap governs OUR guesswork, and second-guessing an explicit "come back in 90s"
# just buys another 429. It is still clamped at 300s, because a wait longer than
# that is a bug or a wildly overloaded server, and either way the caller should
# find out rather than sit in a sleep.
_retry_after_wait() {
  local s="${LAST_RETRY_AFTER:-}"
  if [ -z "$s" ]; then
    s=$(printf '%s' "$LAST_BODY" | jsonpath error.details.retry_after_seconds)
  fi
  # Retry-After may also be an HTTP-date. We do not parse that; falling through
  # to exponential backoff is correct and self-limiting.
  case "$s" in ''|*[!0-9]*) echo ""; return 0 ;; esac
  if [ "$s" -lt 1 ]; then s=1; fi
  if [ "$s" -gt 300 ]; then s=300; fi
  echo "$s"
}

# _rl_self_throttle - park BEFORE spending the last of the window.
#
# The last response already told us the headroom. Burning the final token and
# then eating the 429 costs a whole retry ladder for information we were handed
# for free. Only 0 and 1 trigger it - throttling at, say, 10 remaining would just
# make us slower than the limit actually requires.
#
# The record is deliberately NOT cleared after waiting. Every worker is spending
# from the same per-IP window, so every worker should honour the same exhausted
# reading; it stops firing on its own once `now` passes the reset, and the next
# response overwrites it with fresh headroom.
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
  # a worker for hours on what looks like a routine wait.
  if [ "$delta" -gt "$BACKOFF_CAP" ]; then delta="$BACKOFF_CAP"; fi

  echo "  rate-limit headroom $remaining - waiting ${delta}s for the window to roll" >&2
  sleep "$delta"
}

# api_call METHOD PATH [json-body] - a request with backoff, self-throttling and
# the circuit breaker. Prints the body on stdout; non-zero if it gave up.
#
# Every call in this file goes through here. A retry policy that only some call
# sites use is a retry policy that does not exist.
api_call() {
  local method="$1" path="$2" body="${3:-}" attempt=0 wait ra

  if breaker_is_open; then
    echo "ERROR: eval endpoint appears down (circuit open after $(breaker_count) consecutive failures) - stopping instead of hammering" >&2
    return 1
  fi

  while [ "$attempt" -lt "$MAX_RETRIES" ]; do
    attempt=$(( attempt + 1 ))
    _rl_self_throttle
    api_request "$method" "$path" "$body" > /dev/null || true

    if [ "$LAST_CURL_RC" -ne 0 ] || [ "$LAST_STATUS" = "000" ]; then
      # No HTTP status at all: refused, reset, DNS, or timed out. This is the
      # shape a rate-limited server takes once it starts dropping connections,
      # which is exactly when hammering is worst, so it backs off like any other
      # transient rather than retrying tight.
      wait=$(_backoff "$attempt")
      echo "  connection error on $method $path (curl rc=$LAST_CURL_RC) - retry in ${wait}s [$attempt/$MAX_RETRIES]" >&2

    elif [ "$LAST_STATUS" = "429" ]; then
      ra=$(_retry_after_wait)
      if [ -n "$ra" ]; then
        wait="$ra"
        echo "  429 on $method $path - server said wait ${wait}s [$attempt/$MAX_RETRIES]" >&2
      else
        wait=$(_backoff "$attempt")
        echo "  429 on $method $path with no Retry-After - backing off ${wait}s [$attempt/$MAX_RETRIES]" >&2
      fi

    elif [ "$LAST_STATUS" -ge 500 ]; then
      wait=$(_backoff "$attempt")
      echo "  HTTP $LAST_STATUS on $method $path - retry in ${wait}s [$attempt/$MAX_RETRIES]" >&2

    elif [ "$LAST_STATUS" -ge 400 ]; then
      # A 4xx that is not a 429 is a statement about the REQUEST - wrong key,
      # unknown eval slug, malformed inputs. Retrying it six times produces six
      # identical rejections and hides the message. It also does not touch the
      # breaker: a bad slug is not evidence the endpoint is down.
      echo "ERROR: $method $path returned HTTP $LAST_STATUS - not retryable." >&2
      echo "  ${LAST_BODY:0:400}" >&2
      return 1

    elif [ -z "$LAST_BODY" ]; then
      # 2xx with nothing in it. Seen when a proxy terminates a response early;
      # the caller would read it as "field missing" and report a run that never
      # happened, so treat it as a transport failure.
      wait=$(_backoff "$attempt")
      echo "  empty body on $method $path (HTTP $LAST_STATUS) - retry in ${wait}s [$attempt/$MAX_RETRIES]" >&2

    else
      breaker_reset
      printf '%s' "$LAST_BODY"
      return 0
    fi

    # No sleep after the final attempt - nothing follows it to be polite to.
    if [ "$attempt" -lt "$MAX_RETRIES" ]; then sleep "$wait"; fi
  done

  breaker_trip
  echo "ERROR: gave up on $method $path after $MAX_RETRIES attempts (last HTTP $LAST_STATUS)." >&2
  return 1
}

# api_get <path> - authenticated GET against the platform API.
#
# This used to swallow every failure with `|| true`, which meant a caller
# redirecting it to a file wrote an empty scorecard and carried on. It now
# returns non-zero, so under `set -e` a dead endpoint stops the script instead
# of producing plausible-looking empty artifacts.
api_get() {
  api_call GET "$1"
}

# submit_run <inputs-json> [eval-slug] [evidence-from-run-id] - start a run,
# print its id on stdout. Retries live in api_call now: the platform returns
# intermittent 5xx during a deploy, and losing a whole batch to one of those is
# not worth it.
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

  resp=$(api_call POST "evals/run" "$body") || return 1

  rid=$(printf '%s' "$resp" | jsonpath data.run_id)
  if [ -z "$rid" ]; then
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
#
# The read is BLOCKING server-side (`?wait_ms=`), so the client is not the thing
# deciding how often to ask. That is the single biggest reduction in request
# count here: a 2-3 minute run costs ~5 reads instead of ~12, which is the
# difference between 10 workers fitting inside 100 req/min and not.
poll_run() {
  local rid="$1" status resp path gap
  if [ "$AMDAHL_WAIT_MS" -gt 0 ]; then
    path="eval-runs/$rid?wait_ms=$AMDAHL_WAIT_MS"
    gap=1   # the server did the waiting; this is just a courtesy gap
  else
    path="eval-runs/$rid"
    gap="$POLL_INTERVAL"
  fi

  for attempt in $(seq 1 "$POLL_ATTEMPTS"); do
    # api_call failing here means retries were exhausted or the breaker opened.
    # Neither gets better by polling again, so it propagates.
    resp=$(api_call GET "$path") || return 1
    status=$(printf '%s' "$resp" | jsonpath data.run.status)
    case "$status" in
      complete|failed|canceled)
        echo "$status"
        return 0
        ;;
    esac
    echo "  read $attempt/$POLL_ATTEMPTS: ${status:-unreachable}" >&2
    sleep "$gap"
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
