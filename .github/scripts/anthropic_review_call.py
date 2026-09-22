#!/usr/bin/env python3
"""Make one Anthropic Messages API call for an automated review step.

This is the only code in the review workflow that calls Anthropic. It either
writes the model's text to --out and exits 0, or appends one line to the
status file and exits 1. It never writes a stand-in answer on failure, so a
failed call cannot be read downstream as "no findings" or as a verdict.

Success means all three of: HTTP 200, stop_reason "end_turn", and a non-empty
text block. Every other outcome is a failure with one of these reasons:

  no_key             ANTHROPIC_API_KEY is empty or unset; no request is sent
  billing            credit balance too low (HTTP 400), billing_error, HTTP 402
  spend_limit        HTTP 429 with error_code enforced_spend_limit_reached, or
                     HTTP 400 "reached your specified ... API usage limits"
  auth               HTTP 401 or 403
  model_unavailable  HTTP 404 not_found_error (unknown model, or not enabled
                     for this key)
  truncated          stop_reason max_tokens or model_context_window_exceeded
  refusal            stop_reason refusal
  unexpected_stop    any other stop_reason
  no_text            no non-empty text block (for example only a thinking block)
  bad_response       HTTP 200 whose body is not a JSON object
  budget             --budget-seconds ran out before the next attempt could start
  http_<n>           any other HTTP status, including 429 and 5xx after the
                     last attempt
  network            connection error or timeout on the last attempt
  internal           an unexpected error in this script (for example an
                     unreadable prompt file)

The status line is "<step>: <reason> (<detail>)". For HTTP errors the detail
is "HTTP <n>: <first 200 chars of the response body>".

Retries: 429 (except the spend cap), 5xx including 529, and network errors,
at most 4 attempts. A retry-after header is honored and capped at 60 seconds;
without one the wait is 2, 4, then 8 seconds. All attempts and waits share
one --budget-seconds wall clock, and each attempt's timeout is cut to the
time that is left.

Environment:
  ANTHROPIC_API_KEY    required, sent only in the x-api-key header
  ANTHROPIC_BASE_URL   default https://api.anthropic.com
  REVIEW_MODEL         default claude-sonnet-5
  REVIEW_STATUS_FILE   default /tmp/review_status.txt

Thinking is disabled on every request: Sonnet 5 thinks by default, and on a
small max_tokens (a 256-token verdict) thinking can use the whole budget and
leave no text. No temperature is sent; Sonnet 5 rejects sampling parameters.

Standard library only, so it runs on any runner with python3 (3.8 or later).
"""

import argparse
import http.client
import json
import math
import os
import sys
import time
import traceback
import urllib.error
import urllib.request

API_VERSION = "2023-06-01"
DEFAULT_BASE_URL = "https://api.anthropic.com"
DEFAULT_MODEL = "claude-sonnet-5"
DEFAULT_STATUS_FILE = "/tmp/review_status.txt"

MAX_ATTEMPTS = 4
RETRY_AFTER_CAP_SECONDS = 60.0
BACKOFF_BASE_SECONDS = 2.0
SNIPPET_CHARS = 200

TRUNCATED_STOP_REASONS = ("max_tokens", "model_context_window_exceeded")


class CallFailed(Exception):
    """A call outcome that is not a usable answer."""

    def __init__(self, reason, detail):
        super().__init__("%s (%s)" % (reason, detail))
        self.reason = reason
        self.detail = detail


def snippet(value):
    """First SNIPPET_CHARS characters of value, whitespace collapsed to one line."""
    return " ".join(str(value).split())[:SNIPPET_CHARS]


def error_fields(body):
    """Return (error_type, message, error_code) from an Anthropic error body."""
    try:
        data = json.loads(body)
    except ValueError:
        return "", "", ""
    error = data.get("error") if isinstance(data, dict) else None
    if not isinstance(error, dict):
        return "", "", ""
    details = error.get("details")
    code = details.get("error_code") if isinstance(details, dict) else None
    return str(error.get("type") or ""), str(error.get("message") or ""), str(code or "")


def classify_http_error(status, body):
    """Map a non-200 HTTP response to (reason, retryable)."""
    error_type, message, error_code = error_fields(body)
    lowered = message.lower()
    if error_code == "enforced_spend_limit_reached":
        return "spend_limit", False
    if status == 402 or error_type == "billing_error" or "credit balance is too low" in lowered:
        return "billing", False
    if status == 400 and "api usage limits" in lowered:
        return "spend_limit", False
    if status in (401, 403):
        return "auth", False
    if status == 404 and error_type == "not_found_error":
        return "model_unavailable", False
    if status == 429 or status >= 500:
        return "http_%d" % status, True
    return "http_%d" % status, False


def retry_after_seconds(headers):
    """Seconds from a retry-after header, or None when absent or not a number."""
    if headers is None:
        return None
    value = headers.get("retry-after")
    if value is None:
        return None
    try:
        seconds = float(str(value).strip())
    except ValueError:
        return None
    if not math.isfinite(seconds):
        return None
    return max(seconds, 0.0)


def read_error_body(error):
    try:
        return error.read().decode("utf-8", "replace")
    except Exception:  # the body is only used for the status detail
        return ""
    finally:
        error.close()


def parse_success(body, max_tokens):
    """Return (text, message) from an HTTP 200 body, or raise CallFailed."""
    try:
        message = json.loads(body)
    except ValueError:
        message = None
    if not isinstance(message, dict):
        raise CallFailed("bad_response", "HTTP 200: " + snippet(body))

    stop_reason = message.get("stop_reason")
    if stop_reason in TRUNCATED_STOP_REASONS:
        usage = message.get("usage") if isinstance(message.get("usage"), dict) else {}
        raise CallFailed(
            "truncated",
            "HTTP 200: stop_reason %s, output_tokens %s, max_tokens %d"
            % (stop_reason, usage.get("output_tokens"), max_tokens),
        )
    if stop_reason == "refusal":
        details = message.get("stop_details")
        category = details.get("category") if isinstance(details, dict) else None
        raise CallFailed("refusal", "HTTP 200: stop_reason refusal, category %s" % category)
    if stop_reason != "end_turn":
        raise CallFailed("unexpected_stop", "HTTP 200: stop_reason %s" % stop_reason)

    content = message.get("content")
    blocks = [b for b in content if isinstance(b, dict)] if isinstance(content, list) else []
    text = "".join(
        b["text"] for b in blocks if b.get("type") == "text" and isinstance(b.get("text"), str)
    )
    if not text.strip():
        types = [str(b.get("type")) for b in blocks]
        raise CallFailed("no_text", "HTTP 200: content block types [%s]" % ", ".join(types))
    return text, message


def call_messages(prompt, *, step, max_tokens, timeout, budget_seconds, env, urlopen, sleep, clock, log):
    """POST one message and return (text, message, attempts), or raise CallFailed."""
    api_key = (env.get("ANTHROPIC_API_KEY") or "").strip()
    if not api_key:
        raise CallFailed("no_key", "ANTHROPIC_API_KEY is empty or unset")

    url = (env.get("ANTHROPIC_BASE_URL") or DEFAULT_BASE_URL).rstrip("/") + "/v1/messages"
    payload = json.dumps(
        {
            "model": env.get("REVIEW_MODEL") or DEFAULT_MODEL,
            "max_tokens": max_tokens,
            "thinking": {"type": "disabled"},
            "messages": [{"role": "user", "content": prompt}],
        }
    ).encode("utf-8")
    headers = {
        "x-api-key": api_key,
        "anthropic-version": API_VERSION,
        "content-type": "application/json",
    }

    deadline = clock() + budget_seconds
    last = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        remaining = deadline - clock()
        if remaining <= 0:
            raise CallFailed("budget", last.detail if last else "no time left for attempt %d" % attempt)

        request = urllib.request.Request(url, data=payload, headers=headers, method="POST")
        retry_after = None
        try:
            with urlopen(request, timeout=min(timeout, remaining)) as response:
                status = response.status
                body = response.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as error:
            body = read_error_body(error)
            reason, retryable = classify_http_error(error.code, body)
            last = CallFailed(reason, "HTTP %d: %s" % (error.code, snippet(body)))
            retry_after = retry_after_seconds(error.headers)
        except (urllib.error.URLError, http.client.HTTPException, OSError) as error:
            cause = getattr(error, "reason", None) or error
            last = CallFailed("network", "%s: %s" % (type(error).__name__, snippet(cause)))
            retryable = True
        else:
            if status != 200:
                raise CallFailed("http_%d" % status, "HTTP %d: %s" % (status, snippet(body)))
            text, message = parse_success(body, max_tokens)
            return text, message, attempt

        if not retryable or attempt == MAX_ATTEMPTS:
            raise last
        wait = retry_after if retry_after is not None else BACKOFF_BASE_SECONDS * 2 ** (attempt - 1)
        wait = min(wait, RETRY_AFTER_CAP_SECONDS)
        if clock() + wait >= deadline:
            raise CallFailed("budget", last.detail)
        log(
            "%s: %s on attempt %d/%d, retrying in %.0fs"
            % (step, last.reason, attempt, MAX_ATTEMPTS, wait)
        )
        sleep(wait)
    raise last  # not reached: the last attempt always returns or raises above


def record_failure(status_file, step, reason, detail, log):
    line = "%s: %s (%s)" % (step, reason, detail)
    with open(status_file, "a", encoding="utf-8") as handle:
        handle.write(line + "\n")
    # A GitHub Actions error annotation; plain text anywhere else.
    escaped = line.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    log("::error title=Anthropic call failed::" + escaped)


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Make one Anthropic Messages API call for a review step.")
    parser.add_argument("--step", required=True, help='label for the status line, e.g. "review batch 1/3"')
    parser.add_argument("--prompt-file", required=True, help="file holding the user message")
    parser.add_argument("--max-tokens", type=int, required=True)
    parser.add_argument("--timeout", type=float, required=True, help="seconds allowed for one HTTP attempt")
    parser.add_argument(
        "--budget-seconds", type=float, required=True, help="wall-clock seconds for all attempts and waits"
    )
    parser.add_argument("--out", required=True, help="file that receives the text on success")
    return parser.parse_args(argv)


def main(argv=None, *, env=None, urlopen=None, sleep=None, clock=None, log=None):
    args = parse_args(argv)
    env = os.environ if env is None else env
    urlopen = urllib.request.urlopen if urlopen is None else urlopen
    sleep = time.sleep if sleep is None else sleep
    clock = time.monotonic if clock is None else clock
    log = (lambda text: print(text, flush=True)) if log is None else log
    status_file = env.get("REVIEW_STATUS_FILE") or DEFAULT_STATUS_FILE

    # A file left by an earlier call must never be read as this call's answer.
    try:
        os.remove(args.out)
    except FileNotFoundError:
        pass

    try:
        with open(args.prompt_file, encoding="utf-8") as handle:
            prompt = handle.read()
        text, message, attempts = call_messages(
            prompt,
            step=args.step,
            max_tokens=args.max_tokens,
            timeout=args.timeout,
            budget_seconds=args.budget_seconds,
            env=env,
            urlopen=urlopen,
            sleep=sleep,
            clock=clock,
            log=log,
        )
    except CallFailed as failure:
        record_failure(status_file, args.step, failure.reason, failure.detail, log)
        return 1
    except Exception as error:  # record a reason for anything unforeseen, then fail
        traceback.print_exc()
        record_failure(status_file, args.step, "internal", "%s: %s" % (type(error).__name__, snippet(error)), log)
        return 1

    with open(args.out, "w", encoding="utf-8") as handle:
        handle.write(text)
    usage = message.get("usage") if isinstance(message.get("usage"), dict) else {}
    log(
        "%s: Got %d chars, %d lines (model %s, input_tokens %s, output_tokens %s, attempt %d)"
        % (
            args.step,
            len(text),
            len(text.splitlines()),
            message.get("model"),
            usage.get("input_tokens"),
            usage.get("output_tokens"),
            attempts,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
