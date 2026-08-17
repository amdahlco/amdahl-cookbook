# Eval feedback loop — did the recommendation actually land?

**What this does**: Records what happened *after* an eval run — whether its recommendation was applied, where, and why not when it wasn't — and rolls that up across runs. Three calls: `feedback` (write), `feedback_status` (read one run), `adoption` (read the roll-up). Over the REST API and over the MCP `evals` tool.

**When to use it**: You have an agent or a script that reads eval reports and then *does* something with them — rewrites a routine's prompt, files the improved copy, decides against it. Call `feedback` once you have acted. Over time `adoption` answers the question the score never could: is anyone using this?

## Why this matters

An eval run tells you a draft scored 2.6 and a rewrite scored 4.2. It cannot tell you whether anybody used the rewrite. Nothing else in the product can either — the run row knows what was suggested and nothing knows what became of it, so a run that produced a perfect improved prompt and a run whose report nobody opened look identical in every table.

That gap matters more than it sounds. A rising score with no adoption means your team got better on their own; the same score *with* adoption means the eval is doing work. Same number, opposite conclusions.

**The one rule that makes this data worth having: report only what you observed.** You cannot see whether a person pasted an improved message into their mail client after the conversation ended. "Thanks, I'll use that" is not evidence that they did. So every write states **how you know**, and the honest answer is often `inferred` — or no call at all.

## The operations

| Job | Operation | REST | MCP (`evals` tool) | Scope |
|---|---|---|---|---|
| Report what happened | `evals.record_feedback` | `POST /eval-runs/:id/feedback` | `feedback` | `evals:execute` |
| Read one run's feedback | `eval_run.feedback` | `GET /eval-runs/:id/feedback` | `feedback_status` | `evals:read` |
| Roll it up across runs | `eval.adoption` | `GET /evals/:slug/adoption` | `adoption` | `evals:read` |

---

## Step 1 — act on a report, then say so

**REST:**

```
POST /eval-runs/8f3c…/feedback
Authorization: Bearer <api-key with evals:execute>
Content-Type: application/json

{
  "outcome": "used_with_edits",
  "evidence": "did_it_myself",
  "what_happened": "Applied the prompt patch to the outbound routine, kept lines 1-3, dropped the ROI clause because we cannot substantiate it yet.",
  "applied_to": { "kind": "routine", "id": "b41e…" }
}
```

**MCP** (the `evals` tool, `feedback` action):

```
evals feedback
  run_id: 8f3c…
  outcome: used_with_edits
  evidence: did_it_myself
  what_happened: Applied the prompt patch to the outbound routine…
  applied_to: { "kind": "routine", "id": "b41e…" }
```

**Response:**

```json
{
  "success": true,
  "feedback_id": "c19a…",
  "created": true,
  "verified": true,
  "verification_note": "Found: 78% of the recommended wording is present in the routine prompt."
}
```

### `outcome` — four values, and `unsure` is a real one

`used` | `used_with_edits` | `not_used` | `unsure`

`unsure` is not a soft `not_used`. It is you declining to claim, and it is excluded from **both** halves of any adoption rate rather than counted as a failure to adopt. Prefer it to guessing.

### `evidence` — required, and the point of the call

| Value | Means | Counts toward the rate? |
|---|---|---|
| `did_it_myself` | You performed the action in this session | yes — and the only value the server can verify |
| `reported_to_me` | A person told you what they did | yes |
| `inferred` | You concluded it from context | **no** — stored and labelled, never counted |

These are not confidence levels, they are three different observers. An `inferred` row is still worth writing: a labelled inference is honest and useful, while an inference recorded as an observation is the thing this field exists to prevent.

### `what_happened` — free text, and the most valuable field here

Unconstrained on purpose. When the answer is `not_used`, the **reason** is worth more than the verdict: a rate tells you something is wrong, a reason tells you what. "Too long for LinkedIn", "wrong persona", "we're not allowed to claim that number" are each a different fix.

### `applied_to` — a claim the server checks

Open shape. Recognised kinds — `agent`, `routine`, `knowledge_doc` — are dereferenced and matched against what the run recommended. Anything else is stored **unverified rather than rejected**, so you can record a destination we have never heard of.

`verified` is three-state and the states are not interchangeable:

- `true` — the server read the target and found the recommendation
- `false` — it read the target and the recommendation is **absent**
- `null` — nothing was checked (no `applied_to`, an unrecognised kind, an unreadable target, or an overlap too ambiguous to call)

`false` and `null` are different answers. Do not collapse them. A `false` does **not** fail the write — it is recorded, because a stored disagreement is more useful than a rejected one.

## Step 2 — read back before you re-report

```
GET /eval-runs/8f3c…/feedback
```

```json
{
  "status": "complete",
  "run_id": "8f3c…",
  "feedback": [ { "outcome": "used_with_edits", "evidence": "did_it_myself", "verified": true, … } ],
  "summary": {
    "total": 1,
    "by_outcome": { "used_with_edits": 1 },
    "by_evidence": { "did_it_myself": 1 },
    "verified_true": 1, "verified_false": 0, "verified_unchecked": 0
  }
}
```

Read this before reporting a recommendation as unused — someone may have already acted on it. Counts only, never a rate: a ratio over the two or three rows one run collects is arithmetic on a denominator of two.

**Re-submitting is a correction, not a second opinion.** One actor gets one verdict per run; writing again replaces yours (`created: false`). Two *different* actors disagreeing is not a conflict — both rows stand, and the roll-up counts the run as disputed.

## Step 3 — the roll-up

```
GET /evals/prompt-and-message-eval/adoption?window_days=90
```

```json
{
  "adoption": {
    "runs_completed": 214,
    "runs_eligible": 61,
    "runs_with_signal": 12,
    "runs_adopted": 9,
    "runs_disputed": 1,
    "adoption_rate": null,
    "abstain_reason": "unpublished",
    "counted_evidence": ["did_it_myself", "reported_to_me"],
    "verified_true": 6, "verified_false": 1, "verified_unchecked": 5
  }
}
```

The four counts **narrow**, and each one answers a different question:

- `runs_completed` — every graded run in the window
- `runs_eligible` — of those, the ones that actually produced a recommendation. A `gate`-mode run and a refused run recommended nothing, so they are excluded; they are also the majority of most workspaces' volume, and counting them as un-adopted would give you a small number that is arithmetically correct and meaningless.
- `runs_with_signal` — of the eligible, the ones anybody reported on. **This is the rate's denominator.**
- `runs_adopted` — the numerator.

## Traps

- **`adoption_rate: null` is not zero.** Check `abstain_reason`. `unpublished` means the rate is deliberately withheld pending calibration; `thin_window` means too few reports to assert one; `no_signal` means nobody has reported; `no_eligible_runs` means nothing recommended anything. Four different situations, four different things to do.
- **Read `counted_evidence` before quoting the rate.** It names which evidence values the number was computed over. `inferred` is never one of them.
- **Never report on a person's behalf as though you watched it.** If a user says they'll use something and the conversation ends, you have `reported_to_me` at best, and often nothing worth recording. A wrong record here is worse than a missing one, because it gets counted.
- **Don't optimize for adoption.** It is tempting to feed this back into which suggestions you surface. Doing that selects for agreeable, low-effort suggestions that require no work and change nothing. Use it to *cull* — a suggestion kind nobody ever adopts and nobody ever disputes is probably unactionable — not to rank.
- **Scopes:** writing needs `evals:execute` (the same scope as running an eval — anyone who can fire one can report what became of it). Both reads need only `evals:read`.

## See also

- [Evals — grade a message against customer voice](evals.md) — the run this loop closes.
- [Amdahl evals in LangSmith](evals-in-langsmith.md) — the pipeline-gate shape, where `mode: "gate"` runs are the ones deliberately excluded from the adoption denominator.
- [Routines](routines.md) — the usual `applied_to` target when an agent rewrites a scheduled prompt.
