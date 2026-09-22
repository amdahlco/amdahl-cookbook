"""Tests for anthropic_review_call.py.

Run: python3 -m unittest discover -s .github/scripts -p 'test_*.py' -v

No network: urlopen, sleep and the clock are fakes passed into main().
"""

import contextlib
import email.message
import io
import json
import os
import socket
import sys
import tempfile
import unittest
import urllib.error

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import anthropic_review_call as helper  # noqa: E402

FAKE_KEY = "test-key-not-a-secret"
STEP = "review batch 1/2"


def message_body(text="[]", stop_reason="end_turn", content=None, **extra):
    if content is None:
        content = [{"type": "text", "text": text}]
    body = {
        "id": "msg_test",
        "type": "message",
        "role": "assistant",
        "model": "claude-sonnet-5",
        "content": content,
        "stop_reason": stop_reason,
        "usage": {"input_tokens": 100, "output_tokens": 20},
    }
    body.update(extra)
    return json.dumps(body)


def error_body(error_type, message, details=None):
    error = {"type": error_type, "message": message}
    if details is not None:
        error["details"] = details
    return json.dumps({"type": "error", "error": error, "request_id": "req_test"})


def http_error(code, body, retry_after=None):
    headers = email.message.Message()
    if retry_after is not None:
        headers["retry-after"] = str(retry_after)
    return urllib.error.HTTPError(
        "https://api.anthropic.com/v1/messages", code, "error", headers, io.BytesIO(body.encode())
    )


class FakeResponse:
    def __init__(self, body, status=200):
        self.status = status
        self._body = body.encode()

    def read(self):
        return self._body

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


class FakeClock:
    def __init__(self):
        self.now = 1000.0
        self.sleeps = []

    def __call__(self):
        return self.now

    def sleep(self, seconds):
        self.sleeps.append(seconds)
        self.now += seconds


class FakeUrlopen:
    """Returns or raises the queued outcomes in order and records each request."""

    def __init__(self, outcomes, clock=None, seconds_per_call=0.0):
        self.outcomes = list(outcomes)
        self.calls = []
        self.clock = clock
        self.seconds_per_call = seconds_per_call

    def __call__(self, request, timeout=None):
        self.calls.append({"request": request, "timeout": timeout})
        if self.clock is not None:
            self.clock.now += self.seconds_per_call
        if not self.outcomes:
            raise AssertionError("urlopen called more times than expected")
        outcome = self.outcomes.pop(0)
        if isinstance(outcome, BaseException):
            raise outcome
        return outcome


class HelperTestCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.prompt_file = os.path.join(self.tmp.name, "prompt.txt")
        self.out = os.path.join(self.tmp.name, "out.txt")
        self.status_file = os.path.join(self.tmp.name, "status.txt")
        with open(self.prompt_file, "w") as handle:
            handle.write("Review this diff.")
        self.env = {"ANTHROPIC_API_KEY": FAKE_KEY, "REVIEW_STATUS_FILE": self.status_file}
        self.clock = FakeClock()
        self.logs = []

    def run_helper(self, outcomes, max_tokens=256, timeout=60, budget=600, env=None, seconds_per_call=0.0):
        self.urlopen = FakeUrlopen(outcomes, clock=self.clock, seconds_per_call=seconds_per_call)
        self.addCleanup(self.close_unused_outcomes, self.urlopen)
        argv = [
            "--step", STEP,
            "--prompt-file", self.prompt_file,
            "--max-tokens", str(max_tokens),
            "--timeout", str(timeout),
            "--budget-seconds", str(budget),
            "--out", self.out,
        ]
        return helper.main(
            argv,
            env=self.env if env is None else env,
            urlopen=self.urlopen,
            sleep=self.clock.sleep,
            clock=self.clock,
            log=self.logs.append,
        )

    @staticmethod
    def close_unused_outcomes(urlopen):
        for outcome in urlopen.outcomes:
            if isinstance(outcome, urllib.error.HTTPError):
                outcome.close()

    def status_lines(self):
        if not os.path.exists(self.status_file):
            return []
        with open(self.status_file) as handle:
            return handle.read().splitlines()

    def assertFailed(self, code, reason, calls):
        self.assertEqual(code, 1)
        self.assertFalse(os.path.exists(self.out), "--out must not be written on failure")
        lines = self.status_lines()
        self.assertEqual(len(lines), 1, lines)
        self.assertTrue(lines[0].startswith("%s: %s (" % (STEP, reason)), lines[0])
        self.assertTrue(lines[0].endswith(")"), lines[0])
        self.assertEqual(len(self.urlopen.calls), calls)
        self.assertNotIn(FAKE_KEY, lines[0])
        self.assertNotIn(FAKE_KEY, "\n".join(self.logs))
        return lines[0]


class SuccessTests(HelperTestCase):
    def test_200_end_turn_with_text_writes_out_and_exits_0(self):
        code = self.run_helper([FakeResponse(message_body(text='[{"path": "a.ts"}]'))])
        self.assertEqual(code, 0)
        with open(self.out) as handle:
            self.assertEqual(handle.read(), '[{"path": "a.ts"}]')
        self.assertEqual(self.status_lines(), [])
        self.assertEqual(len(self.urlopen.calls), 1)
        self.assertTrue(any("Got 18 chars" in line for line in self.logs), self.logs)

    def test_text_blocks_are_joined(self):
        content = [{"type": "text", "text": "KEEP: "}, {"type": "text", "text": "real bug"}]
        code = self.run_helper([FakeResponse(message_body(content=content))])
        self.assertEqual(code, 0)
        with open(self.out) as handle:
            self.assertEqual(handle.read(), "KEEP: real bug")

    def test_stale_out_file_is_removed_before_the_call(self):
        with open(self.out, "w") as handle:
            handle.write("[]")
        code = self.run_helper([http_error(400, error_body("invalid_request_error", "bad"))])
        self.assertFailed(code, "http_400", calls=1)


class RequestTests(HelperTestCase):
    def sent(self):
        request = self.urlopen.calls[0]["request"]
        return request, json.loads(request.data.decode())

    def test_request_body_uses_default_model_and_disables_thinking(self):
        self.run_helper([FakeResponse(message_body())], max_tokens=256)
        request, body = self.sent()
        self.assertEqual(request.full_url, "https://api.anthropic.com/v1/messages")
        self.assertEqual(request.get_method(), "POST")
        self.assertEqual(body["model"], "claude-sonnet-5")
        self.assertEqual(body["thinking"], {"type": "disabled"})
        self.assertEqual(body["max_tokens"], 256)
        self.assertEqual(body["messages"], [{"role": "user", "content": "Review this diff."}])
        for sampling in ("temperature", "top_p", "top_k"):
            self.assertNotIn(sampling, body)
        self.assertEqual(request.get_header("X-api-key"), FAKE_KEY)
        self.assertEqual(request.get_header("Anthropic-version"), "2023-06-01")

    def test_review_model_and_base_url_come_from_the_environment(self):
        env = dict(self.env, REVIEW_MODEL="claude-opus-5", ANTHROPIC_BASE_URL="https://gateway.example/")
        self.run_helper([FakeResponse(message_body())], env=env)
        request, body = self.sent()
        self.assertEqual(body["model"], "claude-opus-5")
        self.assertEqual(request.full_url, "https://gateway.example/v1/messages")

    def test_attempt_timeout_is_cut_to_the_remaining_budget(self):
        self.run_helper([FakeResponse(message_body())], timeout=180, budget=45)
        self.assertEqual(self.urlopen.calls[0]["timeout"], 45)


class NoRetryFailureTests(HelperTestCase):
    def test_credit_balance_400_is_billing_with_one_call(self):
        body = error_body(
            "invalid_request_error",
            "Your credit balance is too low to access the Anthropic API. "
            "Please go to Plans & Billing to upgrade or purchase credits.",
        )
        code = self.run_helper([http_error(400, body)])
        line = self.assertFailed(code, "billing", calls=1)
        self.assertIn("(HTTP 400: ", line)
        self.assertIn("credit balance is too low", line)
        self.assertEqual(self.clock.sleeps, [])

    def test_402_is_billing(self):
        code = self.run_helper([http_error(402, error_body("billing_error", "payment required"))])
        self.assertFailed(code, "billing", calls=1)

    def test_429_enforced_spend_limit_is_spend_limit_with_one_call(self):
        body = error_body(
            "rate_limit_error",
            "You have reached your spend limit.",
            details={"error_code": "enforced_spend_limit_reached"},
        )
        code = self.run_helper([http_error(429, body), FakeResponse(message_body())])
        self.assertFailed(code, "spend_limit", calls=1)
        self.assertEqual(self.clock.sleeps, [])

    def test_400_workspace_usage_limit_is_spend_limit(self):
        body = error_body("invalid_request_error", "You have reached your specified workspace API usage limits.")
        code = self.run_helper([http_error(400, body)])
        self.assertFailed(code, "spend_limit", calls=1)

    def test_401_is_auth(self):
        code = self.run_helper([http_error(401, error_body("authentication_error", "invalid x-api-key"))])
        self.assertFailed(code, "auth", calls=1)

    def test_403_is_auth(self):
        code = self.run_helper([http_error(403, error_body("permission_error", "not allowed"))])
        self.assertFailed(code, "auth", calls=1)

    def test_404_not_found_error_is_model_unavailable(self):
        code = self.run_helper([http_error(404, error_body("not_found_error", "model: claude-sonnet-5"))])
        self.assertFailed(code, "model_unavailable", calls=1)

    def test_other_400_is_http_400_with_one_call(self):
        code = self.run_helper([http_error(400, error_body("invalid_request_error", "max_tokens: too large"))])
        self.assertFailed(code, "http_400", calls=1)

    def test_status_detail_is_one_line_of_at_most_200_body_chars(self):
        body = "x" * 150 + "\n" + "y" * 150
        code = self.run_helper([http_error(418, body)])
        line = self.assertFailed(code, "http_418", calls=1)
        detail = line[len("%s: http_418 (HTTP 418: " % STEP):-1]
        self.assertEqual(len(detail), 200)
        self.assertNotIn("\n", detail)

    def test_failures_append_to_the_status_file(self):
        with open(self.status_file, "w") as handle:
            handle.write("earlier step: auth (HTTP 401: x)\n")
        self.run_helper([http_error(401, error_body("authentication_error", "bad key"))])
        lines = self.status_lines()
        self.assertEqual(len(lines), 2)
        self.assertTrue(lines[1].startswith(STEP + ": auth ("))


class EmptyKeyTests(HelperTestCase):
    def test_empty_key_is_no_key_and_never_calls_urlopen(self):
        env = dict(self.env, ANTHROPIC_API_KEY="")
        code = self.run_helper([FakeResponse(message_body())], env=env)
        self.assertFailed(code, "no_key", calls=0)

    def test_unset_or_blank_key_is_no_key(self):
        for key in (None, "   "):
            with self.subTest(key=key):
                env = dict(self.env)
                if key is None:
                    del env["ANTHROPIC_API_KEY"]
                else:
                    env["ANTHROPIC_API_KEY"] = key
                if os.path.exists(self.status_file):
                    os.remove(self.status_file)
                code = self.run_helper([FakeResponse(message_body())], env=env)
                self.assertFailed(code, "no_key", calls=0)


class ResponseShapeTests(HelperTestCase):
    def test_max_tokens_stop_is_truncated(self):
        code = self.run_helper([FakeResponse(message_body(text="KEEP: the", stop_reason="max_tokens"))])
        self.assertFailed(code, "truncated", calls=1)

    def test_only_a_thinking_block_is_no_text(self):
        content = [{"type": "thinking", "thinking": "", "signature": "sig"}]
        code = self.run_helper([FakeResponse(message_body(content=content))])
        line = self.assertFailed(code, "no_text", calls=1)
        self.assertIn("thinking", line)

    def test_whitespace_only_text_is_no_text(self):
        code = self.run_helper([FakeResponse(message_body(text="  \n"))])
        self.assertFailed(code, "no_text", calls=1)

    def test_refusal_stop_is_refusal(self):
        stop_details = {"type": "refusal", "category": "cyber"}
        body = message_body(text="", stop_reason="refusal", stop_details=stop_details)
        code = self.run_helper([FakeResponse(body)])
        line = self.assertFailed(code, "refusal", calls=1)
        self.assertIn("cyber", line)

    def test_other_stop_reason_is_unexpected_stop(self):
        code = self.run_helper([FakeResponse(message_body(stop_reason="pause_turn"))])
        self.assertFailed(code, "unexpected_stop", calls=1)

    def test_non_json_200_is_bad_response(self):
        code = self.run_helper([FakeResponse("<html>proxy error</html>")])
        self.assertFailed(code, "bad_response", calls=1)

    def test_unreadable_prompt_file_is_internal(self):
        os.remove(self.prompt_file)
        with contextlib.redirect_stderr(io.StringIO()):  # the traceback is expected
            code = self.run_helper([FakeResponse(message_body())])
        self.assertFailed(code, "internal", calls=0)


class RetryTests(HelperTestCase):
    def test_429_with_retry_after_then_200_succeeds_after_two_calls(self):
        code = self.run_helper(
            [http_error(429, error_body("rate_limit_error", "slow down"), retry_after=7), FakeResponse(message_body())]
        )
        self.assertEqual(code, 0)
        self.assertEqual(len(self.urlopen.calls), 2)
        self.assertEqual(self.clock.sleeps, [7.0])
        self.assertEqual(self.status_lines(), [])

    def test_retry_after_is_capped_at_60_seconds(self):
        code = self.run_helper(
            [http_error(429, error_body("rate_limit_error", "slow down"), retry_after=600), FakeResponse(message_body())]
        )
        self.assertEqual(code, 0)
        self.assertEqual(self.clock.sleeps, [60.0])

    def test_5xx_is_retried_and_honors_retry_after(self):
        code = self.run_helper(
            [http_error(503, error_body("api_error", "unavailable"), retry_after=3), FakeResponse(message_body())]
        )
        self.assertEqual(code, 0)
        self.assertEqual(self.clock.sleeps, [3.0])

    def test_529_on_every_attempt_is_http_529_after_4_calls(self):
        overloaded = error_body("overloaded_error", "Overloaded")
        code = self.run_helper([http_error(529, overloaded) for _ in range(4)])
        self.assertFailed(code, "http_529", calls=4)
        self.assertEqual(self.clock.sleeps, [2.0, 4.0, 8.0])

    def test_budget_exhausted_before_the_attempts_is_budget(self):
        overloaded = error_body("overloaded_error", "Overloaded")
        code = self.run_helper([http_error(529, overloaded) for _ in range(4)], budget=5)
        line = self.assertFailed(code, "budget", calls=2)
        self.assertIn("HTTP 529", line)

    def test_retry_after_longer_than_the_budget_is_budget_without_sleeping(self):
        body = error_body("rate_limit_error", "slow down")
        code = self.run_helper([http_error(429, body, retry_after=30)], budget=20)
        self.assertFailed(code, "budget", calls=1)
        self.assertEqual(self.clock.sleeps, [])

    def test_time_spent_in_calls_counts_against_the_budget(self):
        timeouts = [urllib.error.URLError(socket.timeout("timed out")) for _ in range(4)]
        code = self.run_helper(timeouts, timeout=60, budget=100, seconds_per_call=60)
        self.assertFailed(code, "budget", calls=2)
        self.assertEqual(self.urlopen.calls[1]["timeout"], 38)

    def test_network_error_on_every_attempt_is_network_after_4_calls(self):
        errors = [
            urllib.error.URLError("connection refused"),
            urllib.error.URLError(socket.timeout("timed out")),
            TimeoutError("timed out"),
            ConnectionResetError("reset by peer"),
        ]
        code = self.run_helper(errors)
        self.assertFailed(code, "network", calls=4)

    def test_network_error_then_200_succeeds(self):
        code = self.run_helper([urllib.error.URLError("connection refused"), FakeResponse(message_body())])
        self.assertEqual(code, 0)
        self.assertEqual(len(self.urlopen.calls), 2)


if __name__ == "__main__":
    unittest.main()
