# Evals — grade a drafted message against customer voice

**What this does**: Takes a drafted outbound message and the prompt that produced it, retrieves the real customer-voice (VoC) evidence from your workspace, and hands back a **scorecard**: an overall grade with reasoning, a per-dimension breakdown (grounding / specificity / differentiation / cta_clarity / tone_fit), the **verbatim customer quotes** that support or contradict the message, and a **grounded rewrite**. The shipped default, `message-grader`, needs no setup — you pass it a message and it grades it.

**When to use it**: You have a drafted message — a cold email, a LinkedIn opener, a nurture line — and you want a grounded second opinion *before it goes out*: is this claim something your buyers actually say, or something the rep wishes they'd say? It's the developer view (REST + MCP payloads) of the [stress-test a message](../positioning-messaging/stress-test-a-message.md) prompt, wired so you can drop it into an outbound flow and gate a send on the verdict.

## Why this matters

The grader applies one discipline to a drafted message: **score it against what your customers actually said, and quote the receipts — never invent them.** Every quote in the scorecard is a real utterance pulled from your corpus, tagged `supports` or `contradicts`; a `contradicts` quote is the highest-signal thing the grader can hand you, because it's a buyer saying the opposite of your copy in their own words. A run is **read-only by construction** — it only ever dispatches read ops (the VoC retrieval, plus a system-of-record `data.query` for the anchored graders) — so grading a message can never mutate tenant state and is always safe to repeat. And it is **async by design**: retrieval + LLM judging takes longer than one HTTP request, so `evals.run` returns a **handle** immediately and you poll the run resource for the scorecard.

## The operations

| | |
|---|---|
| Grade a message | `evals.run` — `POST /evals/run` — MCP `evals` tool, action `grade` — scope `evals:execute` |
| Author an eval | `POST /evals` (create), `PATCH /evals/:slug` (update), `POST /evals/validate` (dry-run) — MCP `evals` author actions — scope `evals:write` |
| Browse evals | `GET /evals` (`eval://list`), `GET /evals/:slug` (`eval://<slug>`) — scope `evals:read` |
| Poll runs | `GET /eval-runs` (`eval_run://list`), `GET /eval-runs/:id` (`eval_run://<id>`) — scope `evals:read` |
| Grader kinds | `GET /grader-kinds` (`grader_kind://list`) — scope `evals:read` |

> **Prerequisite — Agent Platform v2.** Like the rest of this section, the whole eval surface is gated per workspace by the `agent_v2` flag. On a flag-off workspace the MCP `evals` tool + the `eval://` / `eval_run://` / `grader_kind://` schemes are not registered, and a REST call returns `403` with `error.code: "feature_disabled"`.

## Grade a message

You pass in the eval's declared inputs under `inputs`. For `message-grader` those are the drafted message and the prompt behind it:

| Field | Type | Required | Notes |
|---|---|---|---|
| `eval` | string | no (default `message-grader`) | slug or id of the eval to run. Discover options via `eval://list`. |
| `inputs.prompt` | string | yes | the prompt / brief that produced the message |
| `inputs.outbound_message` | string | yes | the drafted message to grade |
| `inputs.audience` | string | no | who it's for (e.g. "VP of Sales, mid-market SaaS") — sharpens the VoC retrieval |
| `reuse` | `cached` \| `force` | no (default `cached`) | `cached` returns the last run for the **same eval + same inputs**; `force` always re-grades (see [Reuse](#reuse)) |

**REST:**

```
POST /evals/run
Authorization: Bearer <api-key with evals:execute>
Content-Type: application/json

{
  "eval": "message-grader",
  "inputs": {
    "prompt": "Write a 3-sentence cold email to a VP of Sales at a mid-market SaaS company, open on a pain we hear a lot, end with a soft CTA.",
    "outbound_message": "Hi Dana — most VPs of Sales we talk to are drowning in dashboards but still can't tell which deals are quietly dying. Amdahl reads your actual call transcripts and flags the at-risk deals your CRM says are healthy. Worth a 15-min look next week?",
    "audience": "VP of Sales, mid-market SaaS"
  },
  "reuse": "cached"
}
```

**MCP** (the `evals` coarse tool, `grade` action):

```
evals grade
  eval   = "message-grader"
  inputs = { prompt: "...", outbound_message: "Hi Dana — most VPs of Sales ...", audience: "VP of Sales, mid-market SaaS" }
  reuse  = "cached"
```

## Response — the handle

`evals.run` returns the run handle immediately, not the scorecard:

```json
{
  "success": true,
  "run_id": "b1c2d3e4-...",
  "reused": false,
  "status": "queued",
  "eval_slug": "message-grader",
  "eval_version": "1.0.0",
  "resource": "eval_run://b1c2d3e4-..."
}
```

- **`run_id`** / **`resource`** — the handle. Poll `resource` (or `GET /eval-runs/<run_id>`) for the scorecard.
- **`reused`** — `true` when a still-active run for the same eval + inputs already existed and was handed back instead of grading again (see [Reuse](#reuse)).
- **`status`** — the lifecycle state at hand-off: `queued`, then `running`, then a terminal `complete` / `failed` / `canceled`.

The only `success: false` shape is input validation (`invalid_argument` — an unknown `eval` slug, or a missing required input field).

## Poll for the scorecard

```
GET /eval-runs/b1c2d3e4-...
Authorization: Bearer <api-key with evals:read>
```

Read `status`; when it is `complete`, the run resource carries the scorecard. A missing / cross-tenant id returns null.

```json
{
  "eval_slug": "message-grader",
  "eval_version": "1.0.0",
  "status": "complete",
  "verdict": "partial",
  "overall_score": 3.4,
  "overall_reasoning": "Grounded opening and a clear CTA, but the core claim ('flags deals your CRM says are healthy') leans on a benefit no buyer named in this voice, and one customer said the opposite about dashboards.",
  "dimensions": [
    { "name": "grounding", "score": 4, "reasoning": "The 'drowning in dashboards' pain matches how buyers describe their tooling; the at-risk-deal framing is close but slightly overstated vs. the evidence." },
    { "name": "specificity", "score": 3, "reasoning": "Concrete enough to feel real, but 'quietly dying' is generic — no role- or segment-specific detail a VP would recognize as theirs." },
    { "name": "differentiation", "score": 2, "reasoning": "The 'reads your call transcripts' wedge is the real one, but it's buried; the message reads like several call-intelligence tools." },
    { "name": "cta_clarity", "score": 4, "reasoning": "A single, low-friction ask with a time box. Clear." },
    { "name": "tone_fit", "score": 4, "reasoning": "Peer-to-peer, no hype — fits a VP-of-Sales register." }
  ],
  "quotes": [
    { "text": "our CRM said the deal was on track right up until they ghosted us", "source": "call · Acme Corp · VP Sales · 2026-04-18", "stance": "supports" },
    { "text": "honestly the dashboards are fine, it's that nobody reads the calls", "source": "call · Northwind · RevOps lead · 2026-05-02", "stance": "contradicts" }
  ],
  "rewrite": "Hi Dana — the VPs of Sales we work with tell us the same thing: the CRM says a deal's on track right up until the buyer ghosts. Amdahl reads the actual call transcripts your reps are already recording and flags the deals going quiet before the stage does. Worth 15 minutes next week to see it on your pipeline?"
}
```

The load-bearing fields:

- **`verdict`** — the bucket: `pass` = strong, grounded message; `partial` = usable but with gaps worth fixing; `fail` = poorly grounded or off-voice; `not_applicable` = the workspace has no customer data to grade against yet (see below). Derived from the overall grade, with `not_applicable` as the special no-evidence case.
- **`overall_score`** — the grade in `[1, 5]`, the mean of the dimension scores. `null` when the verdict is `not_applicable`.
- **`overall_reasoning`** — one paragraph on why it landed where it did — usually the single decision that would move it up a bucket.
- **`dimensions[]`** — the five axes, each `{ name, score (1–5), reasoning }`: **grounding** (does the message match real buyer language?), **specificity** (is it concrete enough to feel like theirs?), **differentiation** (does it say something only you can?), **cta_clarity**, **tone_fit**.
- **`quotes[]`** — the receipts: real customer utterances `{ text, source, stance }`, `stance` ∈ `supports` | `contradicts`. **Never fabricated** — a quote is a verbatim line from your corpus with its source attribution. A `contradicts` quote is a buyer saying the opposite of your copy; treat it as the sharpest edit note in the card.
- **`rewrite`** — a better, grounded version of the message, written to fix the weakest dimensions and lean on the `supports` quotes. When the verdict is `partial`, this is usually what you send instead of the original.

### <a id="not-applicable"></a>`not_applicable` — never a false fail

If the workspace has no customer-voice evidence yet (a brand-new tenant whose call data hasn't landed), there is nothing to ground the message against — so the grader **abstains** rather than inventing a grade:

```json
{
  "eval_slug": "message-grader",
  "status": "complete",
  "verdict": "not_applicable",
  "overall_score": null,
  "overall_reasoning": "No customer-voice evidence has landed for this workspace yet, so there is nothing to ground the message against. This is not a failing grade — connect your call data and re-run.",
  "dimensions": [],
  "quotes": [],
  "rewrite": null
}
```

`not_applicable` is the abstain-rather-than-guess discipline: a message is never marked `fail` just because the workspace is empty. Branch on it — don't render it as a zero.

## Worked example — grade a cold outbound email

The end-to-end loop, from a drafted email to the line you actually send:

1. **You have a draft.** Your outbound tool (or a [Chat](agentic-chat.md)) produced the Dana email above.
2. **Grade it.** `POST /evals/run` with `eval: "message-grader"` and the prompt + message under `inputs`. You get a `run_id` back immediately.
3. **Poll the run.** `GET /eval-runs/<run_id>` until `status` is `complete`.
4. **Read the scorecard.** Verdict `partial`, overall `3.4`. Grounding and tone are strong (4s), but **differentiation is a 2** — and the `quotes` tell you why: a RevOps lead literally said *"the dashboards are fine, it's that nobody reads the calls"* (`contradicts`). Your opener led with the dashboards pain the buyer just waved off.
5. **Use the quote + rewrite.** The `supports` quote (*"on track right up until they ghosted us"*) is the language that lands, and the `rewrite` already leans into it and pulls the transcript wedge to the front. Send the rewrite — or hand the `contradicts` quote back to the rep as the reason.

The scorecard didn't just score the message; it handed you the customer's own words for the fix.

## <a id="reuse"></a>Reuse: cached vs force

A run is **content-addressed** by a fingerprint over `(workspace, eval slug, eval version, inputs)` — the inputs are part of the key, so grading a *different* message is always a fresh run.

- **`reuse: cached`** (default) — if a run for the same fingerprint (same eval, same message + prompt + audience) is still active, `evals.run` hands it back with `reused: true` instead of grading again. Two simultaneous cached re-requests for the same message resolve to **one** run (at-most-once dedup).
- **`reuse: force`** — always re-grades, even for an identical message. Use it to re-grade the same draft against fresher customer data after new calls have landed.

## Author your own eval

`message-grader` and `gtm-default` are the code-defined defaults, but you can author your own eval — a subject-line grader, a call-summary checker, a persona-fit scorer — and it lists alongside the defaults via `eval://list`. An eval declares three things: its **input schema** (the fields callers pass under `inputs`), its **graders**, and its **outputs**.

The three grader kinds you compose from — browse them via `grader_kind://list`:

- **`rule`** — deterministic text checks over the message, no LLM: length bounds, required/forbidden phrases, no ALL-CAPS, must-cite-a-figure. The cheapest, most reliable kind.
- **`sor_anchored`** — a system-of-record anchor: runs a `data.query` for a ground-truth scalar and compares a figure in the message against it within a relative tolerance. Catches a claim that contradicts your own numbers.
- **`evidence_judge`** — an LLM scores the message 1–5 on each rubric dimension **against retrieved VoC evidence**, and returns supporting/contradicting quotes. This is the grader `message-grader` is built from.

**Create** (`POST /evals`), **update** (`PATCH /evals/:slug`), and dry-run **validate** (`POST /evals/validate`) — the same author actions are on the MCP `evals` tool:

```
POST /evals
Authorization: Bearer <api-key with evals:write>

{
  "slug": "sdr-subject-line",
  "name": "SDR subject-line grader",
  "input_schema": {
    "subject_line": { "type": "string", "required": true },
    "audience":     { "type": "string", "required": false }
  },
  "graders": [
    { "kind": "rule", "config": { "max_chars": 60, "no_all_caps": true } },
    { "kind": "evidence_judge",
      "config": { "dimensions": ["curiosity", "specificity", "grounding"], "threshold": 3.5 } }
  ]
}
```

**Validate first** — `POST /evals/validate` with the same body runs the full author-time check and **persists nothing**, so it's the safe dry-run for a build loop:

```
POST /evals/validate  { ...same body... }
->  { "valid": true, "issues": [] }
```

A bad definition (an unknown grader kind, a grader config that references a field the input schema doesn't declare) comes back `valid: false` with a structured `issues` list — fix and re-validate before you `POST /evals`.

## Paste this into Claude

The MCP-native version — Claude picks the `evals` tool for you:

```
Grade this outbound email against how our customers actually talk before I send it.

Prompt I used: {the brief that produced the draft}
Draft message:
"""
{paste the draft}
"""
Audience: {e.g. "VP of Sales, mid-market SaaS"}

Use the message-grader eval, start it, then poll the run resource until it completes. When it's done,
give me: the verdict (pass/partial/fail) and overall grade, the per-dimension breakdown, the customer
quotes it pulled (call out any that CONTRADICT the message), and the grounded rewrite. If the verdict
is not_applicable, tell me we don't have customer data to grade against yet — don't treat it as a fail.
```

## Tips

- **Grade the message, not the prompt.** `outbound_message` is what gets scored; `prompt` and `audience` sharpen the retrieval and the tone check. Pass the real draft, not a paraphrase.
- **The `contradicts` quote is the whole point.** A `rule` check only says "well-formed." The `evidence_judge` quotes are what tell you a buyer says the *opposite* of your copy — read those first.
- **Ship the rewrite on a `partial`.** The scorecard hands you a grounded version built from the supporting quotes; on a `partial` verdict that's usually the line to send instead of the original.
- **`not_applicable` is not a fail.** It means no customer voice has landed yet — branch on it, don't render it as a zero.
- **`cached` keys on the exact inputs.** A new message always re-grades; an identical message returns the prior run. Re-grade the *same* draft against fresh data with `reuse: force`.
- **Scopes:** grading needs `evals:execute`, authoring needs `evals:write`, and a read-only key (`evals:read`) can browse evals + poll runs but can't do either.

## See also

- [Stress-test a message](../positioning-messaging/stress-test-a-message.md) — the paste-ready prompt version of this grader, for when you're working in chat rather than code.
- [Fast lane — `search.run`](fast-lane-search.md) — the synchronous door the `sor_anchored` grader's anchor query runs through.
- [The answer envelope](answer-envelope.md) — how to render the quotes and rewrite in your own UI.
- [Agent platform overview](README.md) — the two doors, the flag prerequisite, the scope table.
