# Amdahl evals in LangSmith - wire the eval as a pipeline gate

**What this does**: Wires Amdahl's message eval into LangSmith as a custom evaluator, so every email your pipeline generates is graded against your workspace's real customer conversations before it ships. One `evals.run` call in gate mode, one gate read, one pass/fail that is actually about your copy.

**When to use it**: You generate outbound copy in a LangChain / LangSmith pipeline and want an automated quality gate grounded in what your buyers actually said, not a generic LLM judge.

This recipe exists because the first integrator had to reverse-engineer all of it live. Follow the order below and read the [trap list](#traps) before you wire anything into CI. If you want the full eval (the rewrite, the report card, the suggestions), that is the [Evals recipe](evals.md); this one is the narrow pipeline slice.

## 1. Connect Amdahl MCP in LangSmith

1. In LangSmith, open **Settings -> MCP servers** and add a server with URL `https://app.amdahl.ai/mcp`.
2. Auth: **OAuth 2.1 (Auto)**. Click connect and sign in to Amdahl when prompted.
3. On the authorize screen, pick your workspace.

**The workspace you pick on the authorize screen is the data boundary.** The eval grades against that workspace's customer conversations - its calls, its CRM, its quotes. Pick a sandbox workspace and every grade will be grounded in the sandbox's (probably empty) corpus. Pick production and the grades mean something.

Once connected, four tools appear: `agents` / `connections` / `evals` / `search`.

The MCP connection is what LangSmith agents and the playground use. The evaluator wrapper in step 4 runs your own Python, so it uses the REST equivalents with an API key (**Settings -> API keys** in the Amdahl console; grading needs `evals:execute`, the gate read needs `evals:read`).

## 2. The one-call pipeline gate

Fire `evals.run`: the `evals` MCP tool, `run` action. REST equivalent:

```
POST https://app.amdahl.ai/api/platform/v1/evals/run
Authorization: Bearer <api-key with evals:execute>
Content-Type: application/json

{
  "inputs": {
    "message": "<the generated email>",
    "mode": "gate",
    "audience": "VP of Sales, mid-market SaaS",
    "account": "Acme Corp"
  }
}
```

- `message` - the generated email to grade. Required for a gate.
- `mode: "gate"` - grades the submitted copy against retrieved customer quotes and **stops**. No rewrite is generated. That makes it faster (roughly the evidence retrieval plus one judge call, about 60-90 seconds, vs 1-3 minutes for a full run) and it removes the number that misleads pipelines (trap 1 below).
- `audience` - optional. Scopes the evidence to a seniority cohort, checked against your corpus before it is claimed.
- `account` - optional. Scopes to a named account when it exists in your corpus.

The call returns a run handle immediately, not the verdict:

```json
{ "success": true, "run_id": "...", "status": "queued", "resource": "eval_run://..." }
```

## 3. Read the verdict with the gate read

Poll the gate read: `GET /eval-runs/{id}/gate` (MCP: `evals` tool, `gate` action). It supports `wait_ms` up to `30000`, so block on the server instead of tight-looping:

```
GET https://app.amdahl.ai/api/platform/v1/eval-runs/{run_id}/gate?wait_ms=30000
Authorization: Bearer <api-key with evals:read>
```

Response shape:

```json
{
  "run_id": "...",
  "eval_slug": "prompt-and-message-eval",
  "status": "complete",
  "gate": {
    "passed": false,
    "checks_passed": 2,
    "checks_total": 5,
    "score_15": 2.6,
    "threshold": 3.5,
    "basis": "message",
    "simulated": false,
    "dimensions_failed": ["Grounding: ...", "Verified specifics: ..."]
  }
}
```

- `gate.passed` - the pipeline boolean. This is the field to gate on.
- `checks_passed` / `checks_total` - the measurement. `score_15` is a rendering of the same fraction on a 1-5 dial; `threshold` is the bar it is judged against.
- `basis` - what was graded (`message`). `simulated` is `false` when you sent real copy; `true` means the run had to write a specimen to grade (a prompt-only run), which is not your copy's grade.
- `dimensions_failed` - the failed rubric lines, human-readable. Use them as the feedback comment.

Two null cases, and they are different:

- `gate` is `null` while the run is still `queued` or `running`. Keep polling.
- `gate` is `null` on a terminal run that **refused**, and the response then carries a `not_applicable_reason` (for example `empty_corpus` - no customer voice has landed for the workspace yet - or `not_outreach` - the submitted text is not a sales message). **A refusal is NOT a fail. Do not gate on it as one.** Record it as ungraded and move on.

## 4. The LangSmith evaluator

Latency expectation up front: **expect roughly 1-2 minutes per run** (submit, evidence retrieval, one judge call, poll). That is fine for LangSmith **dataset experiments** run offline; it is not suitable for interactive playground grading.

```python
import os
import time

import requests

AMDAHL_API = "https://app.amdahl.ai/api/platform/v1"
HEADERS = {
    "Authorization": f"Bearer {os.environ['AMDAHL_API_KEY']}",
    "Content-Type": "application/json",
}
TERMINAL = {"complete", "failed", "canceled"}


def amdahl_gate(run, example):
    """LangSmith evaluator: gate a generated email on Amdahl's customer-voice eval."""
    message = run.outputs["output"]  # adjust to where your chain puts the email

    started = requests.post(
        f"{AMDAHL_API}/evals/run",
        headers=HEADERS,
        json={"inputs": {"message": message, "mode": "gate"}},
        timeout=30,
    ).json()
    if not started.get("success"):
        return {"key": "amdahl_gate", "comment": f"submit failed: {started}"}
    run_id = started["run_id"]

    deadline = time.time() + 300  # gate runs land in ~60-90s; leave headroom
    verdict = None
    while time.time() < deadline:
        verdict = requests.get(
            f"{AMDAHL_API}/eval-runs/{run_id}/gate",
            headers=HEADERS,
            params={"wait_ms": 30000},  # server-side block, no tight loop
            timeout=45,
        ).json()
        if verdict.get("status") in TERMINAL:
            break
    else:
        return {"key": "amdahl_gate", "comment": f"timed out waiting on run {run_id}"}

    gate = verdict.get("gate")
    if gate is None:
        # Terminal but refused (empty corpus, not outreach, ...). Not a fail:
        # return no score, carry the reason as the comment.
        reason = verdict.get("not_applicable_reason") or verdict.get("status")
        return {"key": "amdahl_gate", "comment": f"not graded: {reason}"}

    return {
        "key": "amdahl_gate",
        "score": gate["checks_passed"] / gate["checks_total"],
        "value": "pass" if gate["passed"] else "fail",
        "comment": "; ".join(gate.get("dimensions_failed", [])) or None,
    }
```

Use it in a dataset experiment like any custom evaluator:

```python
from langsmith import evaluate

evaluate(
    generate_email,          # your chain / target function
    data="cold-email-drafts",
    evaluators=[amdahl_gate],
)
```

The feedback contract: `score` is `checks_passed / checks_total` (a real fraction of rubric checks, not a vibe), `value` is `"pass"` or `"fail"` straight from `gate.passed`, and a refused run returns **no score** with the reason in the comment, so a `not_applicable` never averages into your experiment as a zero.

<a id="traps"></a>
## 5. Traps

Each of these was hit for real. Read them before you trust a number.

- **Never wire `overall_score` or `lift` into a pipeline.** On a full (non-gate) run they mostly follow the REWRITE the eval wrote for itself, and the rewrite clears the bar about 92% of the time - so you would score every run near 5/5 no matter what your pipeline produced. The `gate` block is the pipeline number; it only ever describes the copy you submitted.
- **One run is not a measurement.** The judge has run-to-run noise. For any comparison ("did prompt v2 beat v1?") use a median of N runs, or a pinned A/B - never a single pair of scores.
- **Draft and grade on the same evidence.** Each run retrieves its own quote pool. If your pipeline grounds the draft in its own separate Amdahl search, the specifics it used can read as fabricated to the grader, because the grader's pool did not happen to contain them. To iterate on copy, pin the evidence with `inputs.evidence_from_run: "<prior run id>"` so both versions grade against one frozen pool.
- **A cold prospect has no account-tier evidence by definition.** Passing `account` for a company you have never spoken to cannot conjure quotes from them; prospect-specific claims can only be graded against what the workspace corpus holds today. Expect those checks to lean on segment and corpus evidence, not on the account.

## See also

- [Evals - grade a message against customer voice](evals.md) - the full eval surface: the report card, the rewrite, anchored suggestions, audience scoping, and authoring your own eval.
- [`grade-and-report` skill](../../skills/grade-and-report/SKILL.md) - the same grading loop as a Claude Code skill, including the A/B and median-of-N scripts the traps above point at.
- [Stress-test a message](../positioning-messaging/stress-test-a-message.md) - the paste-ready chat version of the same grader.
