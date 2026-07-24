# Evals — grade a drafted message against customer voice

**What this does**: Takes a prompt and/or a drafted outbound message, retrieves the real customer-voice (VoC) evidence from your workspace, and hands back a **before → after report**. Your prompt and your message are graded **separately**, each on its own rubric with its own score, reasoning, cited quotes and worked examples. It then produces an improved **reusable prompt** plus an illustrative message, and reports the lift. The shipped default, `outreach-eval`, needs no setup — it is what runs when you pass no `eval`.

**When to use it**: You have a drafted message — a cold email, a LinkedIn opener, a nurture line — and you want a grounded second opinion *before it goes out*: is this claim something your buyers actually say, or something the rep wishes they'd say? It's the developer view (REST + MCP payloads) of the [stress-test a message](../positioning-messaging/stress-test-a-message.md) prompt, wired so you can drop it into an outbound flow and gate a send on the verdict.

## Why this matters

The grader applies one discipline: **score it against what your customers actually said, and quote the receipts — never invent them.** Every quote is a real utterance pulled from your corpus, tagged `supports` or `contradicts`; a `contradicts` quote is the highest-signal thing the report can hand you, because it's a buyer saying the opposite of your copy in their own words.

Three properties make the number trustworthy rather than flattering:

- **Blinded, paired scoring.** One model writes the improvement; a *separate* judge call scores both candidates in one pass, **unlabelled**, with the order derived from a content hash. A grader that writes and scores its own draft cannot produce an unflattering lift — so those steps are split.
- **Frozen evidence.** The VoC quotes are retrieved once and reused across every revision round, so the reported lift measures *the draft improving* and never *the evidence moving under it*.
- **Coverage is reported, never silent.** A long prompt is **sectioned, not truncated**, and the report always states how much of it was graded. A grade over part of a document never presents as a grade of the whole one.

A run is **read-only by construction** — it only ever dispatches read ops (the VoC retrieval, plus a system-of-record `data.query` for the anchored graders) — so grading can never mutate tenant state and is always safe to repeat. And it is **async by design**: retrieval + LLM judging takes longer than one HTTP request, so `evals.run` returns a **handle** immediately and you poll the run resource for the report.

## The operations

| | |
|---|---|
| Grade a message | `evals.run` — `POST /evals/run` — MCP `evals` tool, action `run` — scope `evals:execute` |
| Browse evals | `GET /evals` (`eval://list`), `GET /evals/:slug` (`eval://<slug>`) — scope `evals:read` |
| Poll runs | `GET /eval-runs` (`eval_run://list`), `GET /eval-runs/:id` (`eval_run://<id>`) — scope `evals:read` |
| Grader kinds | `GET /grader-kinds` (`grader_kind://list`) — scope `evals:read` |
| Dry-run a definition | `POST /evals/validate` — MCP `evals` action `validate` — scope `evals:read`, writes nothing |

> **Prerequisite — Agent Platform v2.** Like the rest of this section, the whole eval surface is gated per workspace by the `agent_v2` flag. On a flag-off workspace the MCP `evals` tool + the `eval://` / `eval_run://` / `grader_kind://` schemes are not registered, and a REST call returns `403` with `error.code: "feature_disabled"`.

> **Authoring is closed during the beta.** `evals.create` / `evals.update` / `evals.delete` currently refuse on **every** protocol — REST, MCP and the agent tool surface all dispatch into the same handlers, so one guard covers them all. Running, reading and the write-free `validate` dry-run are unaffected. Contact the Amdahl team if you need a custom eval; [Author your own eval](#author) below describes the shape it will take when the gate opens.

## Grade a message

You pass in the eval's declared inputs under `inputs`. For `outreach-eval`, `prompt` and `outbound_message` are each **optional** — but you must send **at least one**:

| Field | Type | Required | Notes |
|---|---|---|---|
| `eval` | string | no (default `outreach-eval`) | slug or id of the eval to run. Discover options via `eval://list`. |
| `inputs.prompt` | string | at least one of these two | the prompt / brief / rules document behind the message. Send it **alone** and the grader writes a specimen draft so there is something to grade. Long documents are sectioned, not truncated. |
| `inputs.outbound_message` | string | at least one of these two | the drafted message to grade. Send it **alone** and the report also suggests a reusable prompt. |
| `inputs.audience` | string | no | who it's for (e.g. "VP of Sales, mid-market SaaS") — sharpens the VoC retrieval |
| `inputs.mode` | `rewrite` \| `advisory` | no (default `rewrite`) | `rewrite` produces a full improved prompt + message. **`advisory`** produces *anchored suggestions against the prompt you already have* and no wholesale rewrite — the mode for a large living rules doc you are not going to replace. |
| `reuse` | `cached` \| `force` | no (default `cached`) | `cached` returns the last run for the **same eval + same inputs**; `force` always re-grades (see [Reuse](#reuse)) |

Sending neither `prompt` nor `outbound_message` is the one input error worth planning for: it comes back `invalid_argument` with the failing field named in `details.input_errors`.

**REST:**

```
POST /evals/run
Authorization: Bearer <api-key with evals:execute>
Content-Type: application/json

{
  "eval": "outreach-eval",
  "inputs": {
    "prompt": "Write a 3-sentence cold email to a VP of Sales at a mid-market SaaS company, open on a pain we hear a lot, end with a soft CTA.",
    "outbound_message": "Hi Dana — most VPs of Sales we talk to are drowning in dashboards but still can't tell which deals are quietly dying. Amdahl reads your actual call transcripts and flags the at-risk deals your CRM says are healthy. Worth a 15-min look next week?",
    "audience": "VP of Sales, mid-market SaaS"
  },
  "reuse": "cached"
}
```

**MCP** (the `evals` coarse tool, `run` action):

```
evals run
  eval   = "outreach-eval"
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
  "eval_slug": "outreach-eval",
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

Read `status`; when it is `complete`, the run resource carries the report. A missing / cross-tenant id returns null.

The report lives on the `improvement_loop` grader's result, under `verdict.cases[].graders[].improvement`. Trimmed to the load-bearing fields:

```json
{
  "eval_slug": "outreach-eval",
  "eval_version": "2.0.0",
  "status": "complete",
  "verdict": "pass",
  "cases": [
    {
      "case_id": "grade-outreach",
      "input_passed": false,
      "improved_passed": true,
      "transition": "fail_to_pass",
      "graders": [
        {
          "kind": "improvement_loop",
          "improvement": {
            "mode": "rewrite",
            "what_changed": "Led with the ghosting language buyers actually use and pulled the transcript wedge to the first line.",
            "transition": {
              "input_verdict": "fail", "improved_verdict": "pass",
              "transition": "fail_to_pass", "threshold": 4.2, "iterations": 2
            },
            "facets": [
              {
                "facet": "message",
                "before": {
                  "usage": "as_provided", "score_15": 3.4, "text": "Hi Dana — most VPs of Sales ...",
                  "dimensions": [
                    { "name": "relevant_positioning", "score": 2, "reasoning": "Opens on the dashboards pain a RevOps lead explicitly waved off." },
                    { "name": "grounding", "score": 4, "reasoning": "The ghosting framing matches how buyers describe it." }
                  ],
                  "quotes": [
                    { "text": "our CRM said the deal was on track right up until they ghosted us", "source": "call · Acme Corp · VP Sales · 2026-04-18", "stance": "supports" },
                    { "text": "honestly the dashboards are fine, it's that nobody reads the calls", "source": "call · Northwind · RevOps lead · 2026-05-02", "stance": "contradicts" }
                  ],
                  "good_examples": []
                },
                "after": { "usage": "illustration_only", "score_15": 4.5, "text": "Hi Dana — the VPs of Sales we work with ...", "dimensions": [], "quotes": [], "good_examples": [] },
                "lift": 0.22
              },
              {
                "facet": "prompt",
                "before": { "usage": "as_provided", "score_15": 2.8, "text": "Write a 3-sentence cold email ...", "dimensions": [], "quotes": [], "good_examples": [] },
                "after": { "usage": "reusable_prompt", "score_15": 4.4, "text": "Before drafting, look up what this account said ...", "dimensions": [], "quotes": [], "good_examples": [] },
                "lift": 0.32
              }
            ],
            "suggestions": [
              { "kind": "keep", "facet": "message", "title": "Keep the time-boxed ask",
                "anchor_quote": "Worth a 15-min look next week?", "anchor_offset": 231,
                "detail": "Leave this line as-is.", "why": "A single low-friction ask; nothing in the evidence argues against it.", "quotes": [] },
              { "kind": "remove", "facet": "message", "title": "Drop the dashboards opener",
                "anchor_quote": "drowning in dashboards", "anchor_offset": 41,
                "detail": "Replace with the CRM-says-on-track framing.", "why": "A RevOps lead said the dashboards are fine.",
                "quotes": [{ "text": "honestly the dashboards are fine, it's that nobody reads the calls", "stance": "contradicts" }] }
            ],
            "coverage": { "total_chars": 148, "graded_chars": 148, "truncated": false, "strategy": "verbatim", "sections": [] },
            "grader_meta": { "blinded": true, "evidence_frozen": true, "evidence_quotes": 14, "model_calls": 4 }
          }
        }
      ]
    }
  ]
}
```

The load-bearing fields:

- **`transition`** — **the headline, and the reason the verdict is split.** `input_verdict` is how *your* draft scored; `improved_verdict` is how the improvement scored; `transition` ∈ `fail_to_pass` | `pass_to_pass` | `fail_to_fail` | `pass_to_fail`. Your draft failing is the **finding you ran the eval to get** — collapsing it into one bit makes a working run look like a failure. Branch on the pair, not on a single boolean. When the improved side still misses, `explanation` says why, honestly.
- **`facets[]`** — one entry per graded half, `facet` ∈ `prompt` | `message`, each with its own `before` / optional `after` / `lift`. **They are graded on different rubrics**: a prompt is judged on whether it reliably produces good outreach for *any* account; a message on whether *this* one lands with *these* buyers. Don't average them.
- **`usage`** — what each artifact **is**, and the field to render your framing from: `as_provided` (what you sent), `simulated_specimen` (written so a prompt-only run had something to grade — nobody sent it), `reusable_prompt` (**the takeaway** — keep and re-run it), `illustration_only` (an example produced so the score difference could be measured — *evidence the prompt is better, not a message to send*). Treat an unknown value as `as_provided`.
- **`quotes[]`** — the receipts, per facet: real customer utterances `{ text, source, stance }`, `stance` ∈ `supports` | `contradicts`. **Never fabricated** — the model may only cite ids from the retrieved set and the server hydrates them back to verbatim text. A `contradicts` quote is the sharpest edit note in the report.
- **`suggestions[]`** — surgical, anchored edits: `kind` ∈ `keep` | `add` | `strengthen` | `remove` | `reorder`. `anchor_quote` is **verified server-side to be a literal substring** of your text before it ships, so a suggestion can never quote back something you did not write; `anchor_offset` is that verified position (which is what makes it usable inside a 50k-char document where a phrase repeats). Always present in `advisory` mode. **`keep` matters** — a report that is only criticism tells you nothing about what to protect on the next edit.
- **`coverage`** — how much of a long prompt was graded: `{ total_chars, graded_chars, truncated, strategy, sections[] }`. When `truncated` is true, **say so in your UI** — the sections the grader could not see are listed, and nothing in the report makes a claim about them.
- **`grader_meta`** — provenance: `blinded` (both candidates scored unlabelled in one pass), `evidence_frozen` (same quote set across every round), `evidence_quotes`, `model_calls`.

Every field below `before` / `after` / `lift` / `what_changed` is **optional on the wire**, so a report from an older run still parses — branch on presence rather than assuming.

### <a id="not-applicable"></a>`not_applicable` — never a false fail

If the workspace has no customer-voice evidence yet (a brand-new tenant whose call data hasn't landed), there is nothing to ground the message against — so the grader **abstains** rather than inventing a grade:

```json
{
  "eval_slug": "outreach-eval",
  "status": "complete",
  "verdict": "not_applicable",
  "overall_score": null,
  "overall_reasoning": "No customer-voice evidence has landed for this workspace yet, so there is nothing to ground the message against. This is not a failing grade — connect your call data and re-run.",
  "cases": [
    {
      "case_id": "grade-outreach",
      "applicable": false,
      "not_applicable_reason": "empty_corpus",
      "graders": [
        { "kind": "improvement_loop", "applicable": false, "evidence": { "not_applicable_reason": "empty_corpus" } }
      ]
    }
  ],
  "summary": { "total_cases": 1, "passed_cases": 0, "failed_cases": 0, "not_applicable_cases": 1 }
}
```

`not_applicable` is the abstain-rather-than-guess discipline: a message is never marked `fail` just because the workspace is empty. It is first-class at **two** levels — a whole case, and a single grader — and both use the same rule: **`applicable` is absent or `true` when it counts; only an explicit `false` excludes it.** Never treat a missing `applicable` as not-applicable. A grader abstaining on its own (the `rule` grader on a prompt-only run, which has no message text to check) drops just that grader, not the case.

## Worked example — grade a cold outbound email

The end-to-end loop, from a drafted email to the thing you actually keep:

1. **You have a draft.** Your outbound tool (or a [Chat](agentic-chat.md)) produced the Dana email above.
2. **Grade it.** `POST /evals/run` with `eval: "outreach-eval"` and the prompt + message under `inputs`. You get a `run_id` back immediately.
3. **Poll the run.** `GET /eval-runs/<run_id>` until `status` is `complete`.
4. **Read the transition first.** `input_verdict: "fail"` → `improved_verdict: "pass"`. That is the run working, not failing: your draft missed the 4.2 bar and the improvement clears it.
5. **Read the message facet.** `relevant_positioning` is a 2 — and the `quotes` say why: a RevOps lead literally said *"the dashboards are fine, it's that nobody reads the calls"* (`contradicts`). Your opener led with the pain the buyer waved off.
6. **Act on the two artifacts, differently.** The **prompt** facet's `after` is `reusable_prompt` — *that* is the takeaway: save it, re-run it for the next account, hand it to the team. The **message** facet's `after` is `illustration_only` — it exists so the score difference could be measured; it is evidence the prompt improved, not an email to paste into your sequence. Use the anchored `suggestions` to edit the draft you already have.

The report didn't just score the message; it handed you the customer's own words for the fix, and a template that gets it right next time without you.

**A large living prompt?** Send `mode: "advisory"`. You get the same graded facets and the same evidence, but instead of a rewrite you get anchored `suggestions` pointing at verbatim lines of your own document — the shape a team can actually apply to a rules doc they are not going to replace.

## <a id="reuse"></a>Reuse: cached vs force

A run is **content-addressed** by a fingerprint over `(workspace, eval slug, eval version, inputs)` — the inputs are part of the key, so grading a *different* message is always a fresh run.

- **`reuse: cached`** (default) — if a run for the same fingerprint (same eval, same message + prompt + audience) is still active, `evals.run` hands it back with `reused: true` instead of grading again. Two simultaneous cached re-requests for the same message resolve to **one** run (at-most-once dedup).
- **`reuse: force`** — always re-grades, even for an identical message. Use it to re-grade the same draft against fresher customer data after new calls have landed.

## <a id="author"></a>Author your own eval

> **Closed during the beta.** `create` / `update` / `delete` refuse on every protocol today (see the note under [The operations](#the-operations)); `validate` still works and writes nothing. This section documents the shape so you can design against it — and dry-run it — before the gate opens.

`outreach-eval` is the one code-defined default, but the design target is that you author your own — a subject-line grader, a call-summary checker, a persona-fit scorer — listing alongside the default via `eval://list`. An eval declares three things: its **input schema** (the fields callers pass under `inputs`), its **graders**, and its **outputs**.

The grader kinds you compose from — browse them via `grader_kind://list`:

- **`rule`** — deterministic text checks over the message, no LLM: length bounds, required/forbidden phrases, no ALL-CAPS, must-cite-a-figure. The cheapest, most reliable kind. **Abstains** (rather than failing) on a prompt-only run, since there is no message text to check.
- **`deterministic`** — the same rule checks, applied to a *generated* answer's stats rather than to text you passed in.
- **`sor_anchored`** — a system-of-record anchor: runs a `data.query` for a ground-truth scalar and compares a figure in the message against it within a relative tolerance. Catches a claim that contradicts your own numbers.
- **`judge`** — a plain LLM rubric score 1–5 over an answer, no retrieval.
- **`evidence_judge`** — an LLM scores 1–5 on each rubric dimension **against retrieved VoC evidence** and returns supporting/contradicting quotes. Grade-only: no before/after.
- **`improvement_loop`** — the richest kind, and what `outreach-eval` is built from: retrieve → grade → improve → **blind-judge both** → report the lift, with per-facet detail and anchored suggestions.

**Create** (`POST /evals`), **update** (`PATCH /evals/:slug`), and dry-run **validate** (`POST /evals/validate`) — the same actions are on the MCP `evals` tool:

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

Use the outreach-eval eval, start it, then poll the run resource until it completes. When it's done,
give me, in this order: (1) the TRANSITION — what my draft scored vs what the improved version scored,
and whether that moved it past the bar; (2) the anchored suggestions, "keep" ones first; (3) the
per-facet breakdown for the prompt and the message SEPARATELY, with the customer quotes it pulled
(call out any that CONTRADICT the message).

Be explicit about which produced artifact I should keep: the improved PROMPT is the reusable takeaway,
and the improved MESSAGE is an illustration of what that prompt produces — not an email to send as-is.
If coverage says my prompt was truncated, tell me how much was graded. If the verdict is
not_applicable, tell me we don't have customer data to grade against yet — don't treat it as a fail.
```

## Tips

- **Both halves are graded — send both.** The prompt and the message get their own rubric, score and quotes. Sending only one still works (the grader simulates the missing half), but you learn less: a prompt-only run cannot tell you how *your* copy landed, and a message-only run cannot tell you whether the instruction behind it generalizes.
- **Read the transition before the score.** `input_verdict: fail → improved_verdict: pass` is the run succeeding. Rendering one collapsed pass/fail bit is what makes a working run look broken to whoever reads your UI.
- **`reusable_prompt` is the takeaway; `illustration_only` is not.** Branch your UI on `usage`, not on position in the payload. The improved message exists so the lift could be measured — shipping it verbatim as an email is the one misread this field exists to prevent.
- **The `contradicts` quote is the whole point.** A `rule` check only says "well-formed." The cited quotes are what tell you a buyer says the *opposite* of your copy — read those first.
- **Big prompt? Use `advisory` and check `coverage`.** Anchored suggestions apply to a doc nobody is going to replace, and `coverage.truncated` tells you when the grade covers only part of it. Surface that caveat rather than swallowing it.
- **`not_applicable` is not a fail.** It means no customer voice has landed yet — branch on it, don't render it as a zero.
- **`cached` keys on the exact inputs.** A new message always re-grades; an identical message returns the prior run. Re-grade the *same* draft against fresh data with `reuse: force`.
- **Scopes:** grading needs `evals:execute`; a read-only key (`evals:read`) can browse evals, poll runs and `validate`. Authoring (`evals:write`) is gated off during the beta regardless of scope.

## See also

- [Stress-test a message](../positioning-messaging/stress-test-a-message.md) — the paste-ready prompt version of this grader, for when you're working in chat rather than code.
- [Fast lane — `search.run`](fast-lane-search.md) — the synchronous door the `sor_anchored` grader's anchor query runs through.
- [The answer envelope](answer-envelope.md) — how to render the quotes and rewrite in your own UI.
- [Agent platform overview](README.md) — the two doors, the flag prerequisite, the scope table.
