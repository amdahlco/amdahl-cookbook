# Evals — grade a drafted message against customer voice

**What this does**: Takes a prompt and/or a drafted message, retrieves the real customer-voice (VoC) evidence from your workspace, and hands back a **before → after report**. Your prompt and your message are graded **separately**, each on its own rubric with its own score, reasoning, cited quotes and worked examples. It then produces an improved **reusable prompt** plus an illustrative message, and reports the lift. The shipped default, `prompt-and-message-eval`, needs no setup — it is what runs when you pass no `eval`. (It was previously `outreach-eval`; the old slug still resolves — see [Renamed](#renamed).)

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
| Grade a message | `evals.run` — `POST /evals/run` — MCP `evals` action `run` — scope `evals:execute` |
| **Read the report card** | **`GET /eval-runs/:id/report`** (`eval_run://<id>/report`) — scope `evals:read`. Server-rendered markdown to paste, plus the same numbers machine-readable. **Prefer this when a human will read the result** — see [The report card](#report-card) |
| Poll a run | `GET /eval-runs/:id` (`eval_run://<id>`) — MCP `evals` action `status` (pass `wait_ms` up to 30000 to block instead of tight-looping) — scope `evals:read` |
| List runs | `GET /eval-runs` (`eval_run://list`) — MCP `evals` action `list_runs` — scope `evals:read` |
| Browse evals | `GET /evals` (`eval://list`), `GET /evals/:slug` (`eval://<slug>`) — MCP `evals` actions `list` / `get` — scope `evals:read` |
| Grader kinds | `GET /grader-kinds` (`grader_kind://list`) — scope `evals:read` |
| Dry-run a definition | `POST /evals/validate` — MCP `evals` action `validate` — scope `evals:read`, writes nothing |

> **On MCP, the reads are tool ACTIONS, not just resource URIs.** `evals.run` is async-handle, so a run id is useless without a read — and the MCP spec does not require a client to implement `resources/*`, so a tools-only client could once start a graded run and then have no way to reach the verdict. `status` / `list_runs` / `list` / `get` are thin adapters over the same reads the URIs serve, added so that dead end is closed. If your client speaks `resources/*`, either channel works and they cannot disagree. (The tool carries a few more actions than this table — call it with no action, or read its schema, for the current list.)

> **No prerequisite — evals ships to every workspace.** This surface is **not** gated. It grades pasted content against your own customer quotes and reaches only read operations that predate the Agent Platform program, so it was deliberately exempted from that program's flag, and the flag itself is now retired. Earlier versions of this page named an `agent_v2` prerequisite and a `403 feature_disabled`; **neither exists** — if you built a capability check around that error, delete it. Authoring is a separate matter and is still closed (next note).

> **Authoring is closed during the beta.** `evals.create` / `evals.update` / `evals.delete` currently refuse on **every** protocol — REST, MCP and the agent tool surface all dispatch into the same handlers, so one guard covers them all. Running, reading and the write-free `validate` dry-run are unaffected. Contact the Amdahl team if you need a custom eval; [Author your own eval](#author) below describes the shape it will take when the gate opens.

## Grade a message

You pass in the eval's declared inputs under `inputs`. For `prompt-and-message-eval`, `prompt` and `message` are each **optional** — but you must send **at least one**:

| Field | Type | Required | Notes |
|---|---|---|---|
| `eval` | string | no (default `prompt-and-message-eval`) | slug or id of the eval to run. Discover options via `eval://list`. |
| `inputs.prompt` | string | at least one of these two | the prompt / brief / rules document behind the message. Send it **alone** and the grader writes a specimen draft so there is something to grade. Long documents are sectioned, not truncated. |
| `inputs.message` | string | at least one of these two | the drafted message to grade. Send it **alone** and the report also suggests a reusable prompt. |
| `inputs.audience` | string | no | who it's for (e.g. "VP of Sales, mid-market SaaS"). Resolved to a seniority cohort and **checked against your corpus** before the report claims that framing — see [Audience scoping](#audience) |
| `inputs.mode` | `rewrite` \| `advisory` | no (default `rewrite`) | `rewrite` produces a full improved prompt + message. **`advisory`** produces *anchored suggestions against the prompt you already have* and no wholesale rewrite — the mode for a large living rules doc you are not going to replace. |
| `reuse` | `cached` \| `force` | no (default `cached`) | `cached` returns the last run for the **same eval + same inputs**; `force` always re-grades (see [Reuse](#reuse)) |

Sending neither `prompt` nor `message` is the one input error worth planning for: it comes back `invalid_argument` with the failing field named in `details.input_errors`.

<a id="renamed"></a>
> **Renamed.** Write new code against the canonical names on the left; the retired names on the right still resolve, so nothing already integrated breaks.
>
> | canonical (use this) | retired (still accepted) |
> |---|---|
> | slug `prompt-and-message-eval` | `outreach-eval`, `message-grader` |
> | input `message` | `outbound_message` |

**REST:**

```
POST /evals/run
Authorization: Bearer <api-key with evals:execute>
Content-Type: application/json

{
  "eval": "prompt-and-message-eval",
  "inputs": {
    "prompt": "Write a 3-sentence cold email to a VP of Sales at a mid-market SaaS company, open on a pain we hear a lot, end with a soft CTA.",
    "message": "Hi Dana — most VPs of Sales we talk to are drowning in dashboards but still can't tell which deals are quietly dying. Amdahl reads your actual call transcripts and flags the at-risk deals your CRM says are healthy. Worth a 15-min look next week?",
    "audience": "VP of Sales, mid-market SaaS"
  },
  "reuse": "cached"
}
```

**MCP** (the `evals` coarse tool, `run` action):

```
evals run
  eval   = "prompt-and-message-eval"
  inputs = { prompt: "...", message: "Hi Dana — most VPs of Sales ...", audience: "VP of Sales, mid-market SaaS" }
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
  "eval_slug": "prompt-and-message-eval",
  "eval_version": "1.0.0",
  "resource": "eval_run://b1c2d3e4-..."
}
```

- **`run_id`** / **`resource`** — the handle. Poll `resource` (or `GET /eval-runs/<run_id>`) for the scorecard.
- **`reused`** — `true` when a still-active run for the same eval + inputs already existed and was handed back instead of grading again (see [Reuse](#reuse)).
- **`status`** — the lifecycle state at hand-off: `queued`, then `running`, then a terminal `complete` / `failed` / `canceled`.

The only `success: false` shape is input validation (`invalid_argument` — an unknown `eval` slug, or a missing required input field).

## <a id="report-card"></a>The report card — read this first

If a **person** is going to read the result, do not assemble the numbers yourself:

```
GET /eval-runs/b1c2d3e4-.../report
Authorization: Bearer <api-key with evals:read>

->  { "markdown": "...", "headline": { ... }, "run_id": "...", "eval_slug": "...", "status": "complete" }
```

`markdown` is server-rendered and meant to be **pasted as written**; `headline` carries the same numbers machine-readable, so a script and the pasted block cannot disagree.

This is the one read on this API that ships prose, deliberately. The eval grades **two** artifacts — your draft and a rewrite it produced — and `overall_score` mostly follows the rewrite, so an LLM handed a raw verdict narrates its own conclusion and the before/after (the thing the run exists to show) is the first casualty. **An LLM pasting numbers it did not compute cannot reshape them.** The card also applies the rendering rules below for you: it prints a lift only when it is reportable, labels a simulated "before" as simulated, renders an ungraded side as `not graded` rather than a zero, and shows the pass fraction beside the score. It renders on **every** run state, so you never branch on an empty body.

Assemble from the raw verdict when a *program* consumes it — a gate, a dashboard, a store.

## Poll for the scorecard

```
GET /eval-runs/b1c2d3e4-...
Authorization: Bearer <api-key with evals:read>
```

Read `status`; when it is `complete`, the run resource carries the report. A missing / cross-tenant id returns null.

**Don't tight-loop.** On MCP, `evals status` takes a `wait_ms` (capped at 30000) and blocks until the run settles, returning the live status if it hasn't. A budget past the cap is clamped, never rejected, and the wait is an upper bound on added latency rather than that bound plus one poll interval.

The report lives on the `improvement_loop` grader's result, under `verdict.cases[].graders[].improvement`. Trimmed to the load-bearing fields:

```json
{
  "eval_slug": "prompt-and-message-eval",
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
                "before_paired": { "usage": "as_provided", "score_15": 2.6, "text": "Hi Dana — most VPs of Sales ...", "dimensions": [], "quotes": [], "good_examples": [] },
                "after": { "usage": "illustration_only", "score_15": 4.5, "text": "Hi Dana — the VPs of Sales we work with ...", "dimensions": [], "quotes": [], "good_examples": [] },
                "lift": 0.475
              },
              {
                "facet": "prompt",
                "before": { "usage": "as_provided", "score_15": 2.8, "text": "Write a 3-sentence cold email ...", "dimensions": [], "quotes": [], "good_examples": [] },
                "after": { "usage": "reusable_prompt", "score_15": 4.8, "text": "Before drafting, look up what this account said ...", "dimensions": [], "quotes": [], "good_examples": [] },
                "lift": 0.5
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
            "lift_reportable": true,
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
- **`lift` — do NOT recompute it as `after − before`.** The lift is a difference of two blocks from **one** judge call. When a facet carries **`before_paired`**, the absolute score on `before` came from a *separate, unpaired* call, and the lift is `after.score − before_paired.score`. Differencing the two you can see compares two different judge calls and reports cross-call noise as improvement — the exact noise the pairing exists to remove. Render `before` as the level ("your draft scored 3.4") and `lift` as reported; if you must show the arithmetic, show the basis. Anything that walks a facet's quotes must include `before_paired` too, or a quote only that call cited goes missing. Absent on most runs, in which case `before` *is* the paired block and the subtraction is honest.
- **`lift_reportable`** — a boolean gate, and the field that decides whether a lift is a **figure** or a **sentence**. A lift below the instrument's measured run-to-run spread is indistinguishable from noise, so when this is not `true`, render "no measurable change" rather than a small confident number. A UI that prints `lift` unconditionally will report noise as a win on the runs where the copy barely moved.
- **`coverage`** — how much of a long prompt was graded: `{ total_chars, graded_chars, truncated, strategy, sections[] }`. When `truncated` is true, **say so in your UI** — the sections the grader could not see are listed, and nothing in the report makes a claim about them.
- **`audience`** — what cohort the report was graded against, or why it wasn't. A **discriminated union on `status`** (`resolved` | `abstained`), so branch on `status` before reading `dimensions` — it is present on some abstains too. Full contract in [Audience scoping](#audience).
- **`tool_kit`** — `{ callable, out_of_scope }`: how much of the read surface your API key covers. `research_steps` are drawn only from the callable set, so every suggested call runs as written for the key that produced the report.
- **`grader_meta`** — provenance: `blinded` (both candidates scored unlabelled in one pass), `evidence_frozen` (same quote set across every round), `evidence_quotes`, `model_calls`.

> **Read the message facet's numbers above carefully — they are the trap.** `before.score_15` is **3.4** and `after.score_15` is **4.5**, but the reported `lift` is **0.475**, not the `(4.5 − 3.4) / 4 = 0.275` you get by subtracting what you can see. Both are right: `before` is the *absolute* read of your draft, and the lift is measured against `before_paired` (**2.6**), the block the paired judge call produced alongside the improvement. `lift` is on the normalized [0, 1] axis where one rubric line of five is `0.2`; `score_15` is `1 + 4 × score`. Recomputing the lift from the two visible scores would here have produced a number that is both wrong *and* below the reportability floor — a real improvement rendered as "no measurable change".

Every field below `before` / `after` / `lift` / `what_changed` is **optional on the wire**, so a report from an older run still parses — branch on presence rather than assuming.

### <a id="not-applicable"></a>`not_applicable` — never a false fail

If the workspace has no customer-voice evidence yet (a brand-new tenant whose call data hasn't landed), there is nothing to ground the message against — so the grader **abstains** rather than inventing a grade:

```json
{
  "eval_slug": "prompt-and-message-eval",
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

## <a id="audience"></a>Audience scoping — the report says what it was graded against

`inputs.audience` is free text you write, but it does not stay free text. It is resolved to a seniority cohort and then **checked against your own corpus** before the report is allowed to claim that framing.

That check is the point. Without it, a run graded "positioning for VPs of Engineering" on a workspace that has never spoken to one still produced a confident report — the grade was real, the audience printed on top of it was fiction.

The outcome lands on `improvement.audience`, a **discriminated union on `status`**:

```json
"audience": {
  "status": "resolved",
  "dimensions": { "role_level": "executive", "raw": "VPs of Engineering" },
  "evidence": { "distinct_speakers": 7, "utterances": 210, "distinct_companies": 4 },
  "predicate": "role_level = 'executive'"
}
```

```json
"audience": {
  "status": "abstained",
  "reason": "thin_evidence",
  "message": "There are some conversations with that audience, but too few to grade positioning against without over-reading them, so the report was graded against your whole customer corpus.",
  "dimensions": { "role_level": "manager", "raw": "eng managers" },
  "evidence": { "distinct_speakers": 2, "utterances": 9, "distinct_companies": 1 }
}
```

**Branch on `status` before reading `dimensions`.** It is a union rather than a nullable cohort specifically so a renderer cannot show an audience header for a run that was graded unscoped. `dimensions` appears on an abstain too — when we understood you and only the evidence fell short — so its presence is *not* the signal.

**Three floors, all required** to resolve: at least **3 distinct speakers**, **25 utterances**, and **2 distinct companies**. The company floor is the load-bearing one: without it a single talkative account clears the other two by itself, and its vocabulary gets reported back to you as an audience-wide finding.

**Five abstain reasons, and they are not interchangeable** — each asks something different of you:

| `reason` | what it means | what to do |
|---|---|---|
| `not_provided` | you didn't name an audience | nothing — the whole-corpus grade is valid |
| `unresolvable` | the text didn't map to a seniority level | restate naming a level (executive / manager / individual contributor) |
| `no_evidence` | understood, but this workspace has no such conversations | connect more data, or grade a cohort you actually sell to |
| `thin_evidence` | some conversations, too few to read safely | same, or accept the whole-corpus grade |
| `lookup_failed` | **our check broke** | retry. This is **not** a statement about your data |

`lookup_failed` deserves the emphasis: **never render it as "you have no conversations with that audience".** Telling someone their corpus is empty when it isn't is a worse failure than showing nothing. Only `no_evidence` and `thin_evidence` are statements about the workspace.

The report **still grades** on an abstain — it just grades against your whole customer corpus and says so, rather than silently pretending it scoped.

### Suggested calls are bounded by your key

`improvement.tool_kit` is `{ callable, out_of_scope }`: how many public read operations your API key covers, and how many it doesn't. `research_steps` are proposed **only** from the callable set, so a step in the report always runs as written for the key that produced it — a safe-but-uncallable suggestion 403s when you paste it, which discredits every other step alongside it.

Counts only, deliberately: listing the ops would duplicate `research_steps` and turn the report into a permissions catalog. If `out_of_scope` is 0, there is nothing to say and nothing is withheld.

Both `audience` and `tool_kit` are **optional on the wire**. Absent means the run predates audience scoping — which is *not* the same as `not_provided`, so don't collapse them.

## Worked example — grade a cold outbound email

The end-to-end loop, from a drafted email to the thing you actually keep:

1. **You have a draft.** Your outbound tool (or a [Chat](agentic-chat.md)) produced the Dana email above.
2. **Grade it.** `POST /evals/run` with `eval: "prompt-and-message-eval"` and the prompt + message under `inputs`. You get a `run_id` back immediately.
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

`prompt-and-message-eval` is the one code-defined default, but the design target is that you author your own — a subject-line grader, a call-summary checker, a persona-fit scorer — listing alongside the default via `eval://list`. An eval declares three things: its **input schema** (the fields callers pass under `inputs`), its **graders**, and its **outputs**.

The grader kinds you compose from — browse them via `grader_kind://list`:

- **`rule`** — deterministic text checks over the message, no LLM: length bounds, required/forbidden phrases, no ALL-CAPS, must-cite-a-figure. The cheapest, most reliable kind. **Abstains** (rather than failing) on a prompt-only run, since there is no message text to check.
- **`deterministic`** — the same rule checks, applied to a *generated* answer's stats rather than to text you passed in.
- **`sor_anchored`** — a system-of-record anchor: runs a `data.query` for a ground-truth scalar and compares a figure in the message against it within a relative tolerance. Catches a claim that contradicts your own numbers.
- **`judge`** — a plain LLM rubric score 1–5 over an answer, no retrieval.
- **`evidence_judge`** — an LLM scores 1–5 on each rubric dimension **against retrieved VoC evidence** and returns supporting/contradicting quotes. Grade-only: no before/after.
- **`improvement_loop`** — the richest kind, and what `prompt-and-message-eval` is built from: retrieve → grade → improve → **blind-judge both** → report the lift, with per-facet detail and anchored suggestions.

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

Use the prompt-and-message-eval eval, start it, then poll with the status action (pass wait_ms rather
than looping). When it completes, FETCH THE REPORT CARD (eval_run://<id>/report) and paste its markdown
verbatim — do not re-derive the numbers or rewrite the headline. Then add, in this order: (1) the anchored
suggestions, "keep" ones first; (2) the per-facet breakdown for the prompt and the message SEPARATELY,
with the customer quotes it pulled (call out any that CONTRADICT the message).

Do not compute a lift yourself by subtracting the two scores you can see — when the facet carries
before_paired those are different judge calls, and the reported lift is already the right one.

Be explicit about which produced artifact I should keep: the improved PROMPT is the reusable takeaway,
and the improved MESSAGE is an illustration of what that prompt produces — not an email to send as-is.
If coverage says my prompt was truncated, tell me how much was graded. If the verdict is
not_applicable, tell me we don't have customer data to grade against yet — don't treat it as a fail.
```

## Tips

- **Both halves are graded — send both.** The prompt and the message get their own rubric, score and quotes. Sending only one still works (the grader simulates the missing half), but you learn less: a prompt-only run cannot tell you how *your* copy landed, and a message-only run cannot tell you whether the instruction behind it generalizes.
- **Read the transition before the score.** `input_verdict: fail → improved_verdict: pass` is the run succeeding. Rendering one collapsed pass/fail bit is what makes a working run look broken to whoever reads your UI.
- **Never recompute the lift.** `after − before` is the wrong subtraction whenever `before_paired` is present: it differences two separate judge calls and reports their disagreement as improvement. Show `lift` as reported, and gate it on `lift_reportable` — below the measured noise floor, "no measurable change" is the honest render, and a small confident number is not.
- **A person reads the report card; a program reads the verdict.** `GET /eval-runs/:id/report` hands back markdown to paste plus the same numbers machine-readable. Summarising a raw verdict for a human is where the before/after gets lost, because `overall_score` mostly follows the *rewrite*.
- **`reusable_prompt` is the takeaway; `illustration_only` is not.** Branch your UI on `usage`, not on position in the payload. The improved message exists so the lift could be measured — shipping it verbatim as an email is the one misread this field exists to prevent.
- **The `contradicts` quote is the whole point.** A `rule` check only says "well-formed." The cited quotes are what tell you a buyer says the *opposite* of your copy — read those first.
- **Big prompt? Use `advisory` and check `coverage`.** Anchored suggestions apply to a doc nobody is going to replace, and `coverage.truncated` tells you when the grade covers only part of it. Surface that caveat rather than swallowing it.
- **`not_applicable` is not a fail.** It means no customer voice has landed yet — branch on it, don't render it as a zero.
- **Name an audience, then read whether it stuck.** An `audience` you pass is only used as the framing if your corpus clears three evidence floors. Check `audience.status` — a report that says "graded against executives" and one that fell back to the whole corpus look identical if you skip it. And if the reason is `lookup_failed`, that is our check breaking: **never** relay it as "you have no conversations with that audience".
- **`cached` keys on the exact inputs.** A new message always re-grades; an identical message returns the prior run. Re-grade the *same* draft against fresh data with `reuse: force`.
- **Report back what you did with it.** Once you have acted on a report — applied the prompt patch, decided against the rewrite — record it with `evals.record_feedback`, stating **how you know** (`did_it_myself` / `reported_to_me` / `inferred`). It is the only thing that can tell a rising score from a report nobody opened. See [Eval feedback loop](evals-feedback-loop.md).
- **Scopes:** grading needs `evals:execute`; a read-only key (`evals:read`) can browse evals, poll runs and `validate`. Authoring (`evals:write`) is gated off during the beta regardless of scope.

## See also

- [Eval feedback loop](evals-feedback-loop.md) — the other half: report whether a run's recommendation was applied, and roll adoption up across runs.
- [Stress-test a message](../positioning-messaging/stress-test-a-message.md) — the paste-ready prompt version of this grader, for when you're working in chat rather than code.
- [Fast lane](fast-lane-search.md) — the synchronous read lane. (The `sor_anchored` grader's anchor is a `data.query`, not this lane; the previous wording said otherwise.)
- [The answer envelope](answer-envelope.md) — how to render the quotes and rewrite in your own UI.
- [Agent platform overview](README.md) — the two doors, the flag prerequisite, the scope table.
