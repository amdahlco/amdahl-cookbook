# Evals — a graded report-card over your answers

**What this does**: Runs a code-defined **eval** — a set of canonical GTM questions plus the graders that score each answer — and hands back a **report card**: an overall score, a `pass` / `partial` / `fail` bucket, and a per-question, per-grader breakdown with rationale and evidence. It is the answer to "how good are our answers *right now*?" as a number you can watch. The shipped default, `gtm-default`, needs no setup.

**When to use it**: You want to *measure* answer quality over time — a nightly regression check, a pre/post gate around a data or prompt change, a confidence signal before you wire Amdahl into an autonomous flow. This is the developer view (REST + MCP payloads) of grading; it grades the same [fast lane](fast-lane-search.md) answers your integrations already consume.

## Why this matters

An eval applies one discipline to a live answer: **validate a figure against an independent source of truth, and abstain rather than guess when there is none.** A run is **read-only by construction** — it only ever dispatches read ops (the question through `search.run`, plus a system-of-record `data.query` for the anchored grader), so firing an eval can never mutate tenant state and is always safe to repeat. And it is **async by design**: grading N questions across three graders takes longer than one HTTP request, so `evals.run` returns a **handle** immediately and you poll the run resource for the verdict — the call never blocks on the grading.

## The operations

| | |
|---|---|
| Run | `evals.run` — `POST /evals/run` — MCP `evals` tool, action `run` — scope `evals:execute` |
| Browse evals | `GET /evals` (`eval://list`), `GET /evals/:slug` (`eval://<slug>`) — scope `evals:read` |
| Poll runs | `GET /eval-runs` (`eval_run://list`), `GET /eval-runs/:id` (`eval_run://<id>`) — scope `evals:read` |
| Grader kinds | `GET /grader-kinds` (`grader_kind://list`) — scope `evals:read` |

> **Prerequisite — Agent Platform v2.** Like the rest of this section, the whole eval surface is gated per workspace by the `agent_v2` flag. On a flag-off workspace the MCP `evals` tool + the `eval://` / `eval_run://` / `grader_kind://` schemes are not registered, and a REST call returns `403` with `error.code: "feature_disabled"`.

## Run it

Every field is optional — an empty body runs `gtm-default`, `reuse: cached`, current data.

| Field | Type | Default | Notes |
|---|---|---|---|
| `eval` | string | `gtm-default` | slug or id of the code-defined eval. Discover options via `eval://list`. |
| `reuse` | `cached` \| `force` | `cached` | `cached` returns the last active run for the same target; `force` always starts fresh. |

**REST:**

```
POST /evals/run
Authorization: Bearer <api-key with evals:execute>
Content-Type: application/json

{ "eval": "gtm-default", "reuse": "cached" }
```

**MCP** (the `evals` coarse tool, `run` action):

```
evals run
  eval  = "gtm-default"
  reuse = "cached"
```

## Response — the handle

`evals.run` returns the run handle immediately, not a verdict:

```json
{
  "success": true,
  "run_id": "b1c2d3e4-...",
  "reused": false,
  "status": "queued",
  "eval_slug": "gtm-default",
  "eval_version": "1.0.0",
  "resource": "eval_run://b1c2d3e4-..."
}
```

- **`run_id`** / **`resource`** — the handle. Poll `resource` (or `GET /eval-runs/<run_id>`) for the verdict.
- **`reused`** — `true` when a still-active run for the same target already existed and was handed back instead of starting a new one (see [Reuse](#reuse)).
- **`status`** — the lifecycle state at hand-off: `queued`, then `running`, then a terminal `complete` / `failed` / `canceled`.

The only `success: false` shape is input validation (`invalid_argument` — an unknown `eval` slug).

## Poll for the verdict

```
GET /eval-runs/b1c2d3e4-...
Authorization: Bearer <api-key with evals:read>
```

Read `status`; when it is `complete`, `verdict` carries the report card. A missing / cross-tenant id returns null.

```json
{
  "eval_slug": "gtm-default",
  "eval_version": "1.0.0",
  "overall_score": 0.79,
  "verdict": "partial",
  "cases": [
    {
      "case_id": "accounts-coverage",
      "label": "Account coverage vs system of record",
      "answered": true, "score": 0.71, "passed": false, "latency_ms": 6880,
      "graders": [
        { "grader_id": "answered", "kind": "deterministic", "score": 1.0, "passed": true, "rationale": "All 2 check(s) passed." },
        { "grader_id": "coverage-matches-sor", "kind": "sor_anchored", "score": 0.42, "passed": false,
          "rationale": "Answer figure 500 diverges 58% from the system-of-record value 1180 (tolerance 50%).",
          "evidence": { "sor_value": 1180, "answer_value": 500, "answer_metric": "internal_row_count", "relative_difference": 0.5763, "tolerance": 0.5 } }
      ]
    }
  ],
  "summary": { "total_cases": 3, "passed_cases": 2, "failed_cases": 1 }
}
```

The load-bearing fields:

- **`verdict`** — the bucket: `pass` = every case passed, `fail` = none passed, `partial` = some. Derived from the per-case pass count, not from `overall_score`.
- **`overall_score`** — the mean case score in `[0, 1]`; each case score is the mean of its graders' scores.
- **`cases[].passed`** — whether *every* grader on the case passed; **`answered`** is whether the target produced a usable answer at all; **`error`** is set only when the target op did not produce an answer (the graders still run over the empty answer).
- **`graders[].evidence`** — the receipt. Store it with the score: a score without its evidence can't be audited later. For `sor_anchored` it is the SoR value vs the answer value; for `judge` it is the per-dimension scores.

## The three grader kinds

Every answer is scored by one or more graders; a case passes only when **all** of its graders pass. Browse them via `grader_kind://list`.

- **`deterministic`** — rule checks over the answer, no LLM: answered, in time, no error, enough rows or citations. The cheapest, most reliable kind.
- **`sor_anchored`** — a system-of-record anchor. Runs a `data.query` for a ground-truth scalar, then compares an answer figure (v1: `internal_row_count`) against it within a relative `tolerance`. This is the "validate a figure against an independent truth" discipline applied to a live answer — it catches **silent under-return**: an answer that looks fine but omits most of the true population.
- **`judge`** — an LLM scores the answer 1–5 on each rubric dimension; the case passes when the mean meets the grader's threshold. If the judge is unavailable it degrades to a neutral, non-passing score rather than failing the run.

## <a id="reuse"></a>Reuse: cached vs force

A run is **content-addressed** by a fingerprint over `(workspace, eval slug, eval version)` — the inputs that fully determine the graded work in v1.

- **`reuse: cached`** (default) — if a run for the same fingerprint is still active (not `failed` / `canceled`), `evals.run` hands it back with `reused: true` instead of starting a duplicate. Two simultaneous cached re-requests for the same target resolve to **one** run (at-most-once dedup).
- **`reuse: force`** — always starts a fresh run.

Caching is **opt-out, not a freshness guarantee**: v1 always grades current data, so a `cached` re-request returns the last run regardless of how much time has passed. When you want to re-grade against the latest data, pass `reuse: force`.

## Paste this into Claude

The MCP-native version — Claude picks the `evals` tool for you:

```
Run the graded report-card over our workspace answers and tell me how we're doing.

Use the default eval (gtm-default), start it, then poll the run resource until it completes.
When it's done, give me: the overall verdict (pass/partial/fail) and score, then per question
which graders passed or failed and why — call out any sor_anchored miss (a silent under-return
where our answer's figure diverged from the system-of-record count) with its evidence.
```

## Tips

- **Poll, don't block.** `evals.run` returns a handle; the grading finishes behind it. Read the verdict from `eval_run://<id>` (or `GET /eval-runs/<id>`) once `status` is `complete`.
- **`sor_anchored` is the one that catches lies.** A `deterministic` pass only says "we answered in time." The anchored grader is what tells you the number was actually *right* — watch its `evidence.relative_difference`.
- **`cached` is a dedup, not a freshness signal.** Re-grade against the latest data with `reuse: force`.
- **Read-only keys** (`evals:read`) can browse evals + poll runs, but cannot fire one — that needs `evals:execute`.

## See also

- [Fast lane — `search.run`](fast-lane-search.md) — the door whose answers `gtm-default` grades.
- [Agentic Chat](agentic-chat.md) — the multi-step lane for the questions the fast lane escalates.
- [Agent platform overview](README.md) — the two doors, the flag prerequisite, the scope table.
