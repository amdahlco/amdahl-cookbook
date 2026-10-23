---
name: grade-and-report
description: Grade a draft with the Amdahl Message Optimizer against your workspace's customer conversations, and report the result as a card built from the grade's own fields. Use after ground-and-draft, before anything publishes. Also covers comparing two drafts, grading a batch, and grading or improving the reusable prompt behind your drafts.
---

# grade-and-report

The second half of the loop: (ground-and-draft) → **Grade → Fix**.

Grades a draft with `POST /messages/optimize` and `mode: "grade"`, and shows a
card that `scripts/_lib.sh` builds from the response. The grade answers on the
same call, and nothing is written.

## The one rule

**Show the card. Do not restate the numbers in your own words.**

The card prints the score with the fraction it comes from beside it (`passed` of
`total` lines), the verdict and reason for each of the five lines, the claims
nothing in your conversations backs, the notes meant for the sender, and what
one grade can and cannot tell you. A summary in your own words is where those
qualifiers drop out. Every card ends with the same sentence, and it stays:

> The grade measures the message against your evidence and this rubric; it does
> not predict replies.

Never say a grade makes a reply more likely.

## What the grade is

The grade comes from the Optimizer's **final judge**, on five pass or fail lines:
`relevant_positioning`, `grounding`, `verified_specifics`, `differentiation` and
`cta_clarity`. The score is `1 + 4 × passed / total`, so on five lines it takes
six values: 1, 1.8, 2.6, 3.4, 4.2 and 5. The bar is 4.2. The response names the
judge in `grade.judge`.

The first four lines read your customers' own words. They are graded only when
the call sends `evidence: "workspace"` (the scripts' default) and the workspace
has synced conversations. Otherwise they abstain, and only `cta_clarity` is
graded. A line that abstains has `pass: null` and `applicable: false`, and it is
out of both `passed` and `total`: not graded is not a fail. When no line could
be graded, `score` is `null`, never 0.

This is a different instrument from the retired evals (`evals.run`), which
graded on another scale with another judge. A grade from before 22 October 2026
does not compare with a grade from this call.

## Steps

1. **Build the request.** A plain draft file is sent as `message`. Add a
   context file to send what you know first-hand that no conversation holds:

   ```json
   { "facts": ["Helix cut provisioning tickets by 70% with us."], "rules": ["Under 90 words."] }
   ```

   A fact backs only the claim it states, and it is never counted as a customer
   quote. To say who the draft is for, use a request file (`request.json`) with
   `message` and `recipient`; the recipient fields are beta, per workspace, and
   a workspace without them ignores them and names them in `ignored_params`.

2. **Grade.**

   ```bash
   export AMDAHL_KEY='...'              # Settings, then Developer, Create key
   bash scripts/grade.sh draft.md runs/2026-10-22-launch context.json
   ```

   Writes `request.json`, `grade.json` (the full response) and `report.md` (the
   card), and prints the card.

3. **Show the card.** `report.md`, verbatim, in the section order below.

4. **Read two things.**
   - **The fraction, not the score.** "3 of 5 lines passed" is the measurement;
     the score is a rendering of it. An edit that does not flip a whole line does
     not move the score. If you edit and the score stays, no line changed.
   - **The reasons and the unsupported claims.** Each failed line has one
     sentence of `reason`. `unsupported_claims` lists the spans in your draft
     that nothing in your conversations backs. A claim you believed that the
     evidence does not hold is the most useful thing a grade finds. Report it;
     do not average it away.

5. **Fix.** Edit the draft from the reasons, then grade it again into a **new**
   run folder. A changed draft is a new grading.

## Output contract

Fixed section order. Nothing between §1 and §2.

1. **The card**: `report.md` pasted verbatim. No preamble, no "here's how it
   did", no changes to the table.
2. **What you changed, or would change**: your own words, about the _edits_,
   never restating a score.
3. **Anything an unsupported claim surfaced**: the belief, and the span.
4. **What you ran**: `optimize_id`, and whether the evidence was read (the
   card's Evidence line).

When lines abstain, the card says so and says why. Report that. It is not a
failing grade and must not be presented as one.

## Comparing two drafts

```bash
bash scripts/ab.sh v1.md v2.md runs/ab-hook context.json
```

Grades both drafts with the same context and prints the two fractions and the
lines that changed their verdict.

These are **two independent grades**. Each call reads its own evidence from the
workspace's conversations, and nothing pins the second grade to the first one's
quotes. A difference can come from your edit, from different evidence, or from
the judge. Read the lines that changed, and their reasons, before you decide
the edit did it.

## No repeat script

An identical grade request returns the same stored grading, so grading one draft
N times measures nothing. How much this judge's score moves on a repeat is
stated on every grade in `disclosures.repeat_spread`, and the card prints it.

## Grading a batch

```bash
bash scripts/batch.sh launch-q3.tsv runs/q3 3
```

Grades a manifest of drafts at bounded concurrency, writing each item to
`runs/q3/<id>/{report.md,grade.json,request.json,grade.log}`. Each item is one
grade call. The batch lane (`messages.optimize_batch`) does not take `mode`.

**The manifest is TSV**: one item per line, blank lines and lines starting with
`#` ignored, so you can comment an item out without deleting it:

```
id <TAB> file [<TAB> context.json]
```

`id` is the directory name under the run-dir and the handle you re-run with, so
keep it filesystem-safe. A `.json` file is sent as the request object; anything
else is sent as `message`, the same rule `grade.sh` uses.

**Concurrency defaults to 3.** A workspace may run 3 optimizes at the same time
and start 12 in any 60 seconds, counted over every key, connector session and
the console together. A grade holds its call open while it is graded, so 3
workers fill the in-flight limit. A call over a limit waits up to 15 seconds and
is then refused with HTTP 429 and `Retry-After`. The transport waits that long
and tries again. It circuit-breaks a dead endpoint: once the breaker opens, the
batch stops **launching** new items and says so, and it leaves items in flight
alone.

**Re-running only does the casualties.** An item whose `report.md` already
exists is skipped. After a partial batch, fix whatever broke and run the same
command. Failed ids are printed at the end as a space-separated list. Delete an
item's directory to send it again.

## Grading or improving the prompt

```bash
bash scripts/prompt.sh prompt.md runs/prompt-v3 improve extras.json
```

`POST /messages/optimize_prompt` grades a reusable prompt by the emails it
writes for sample recipients (up to 6, in `extras.json` as `recipients`; with
none, Amdahl picks accounts from your workspace). `grade` mode grades those
emails. `improve` mode (the default) also tries revisions of the prompt and
returns one only when it wrote better email on recipients held out from the
revision. A run takes minutes: the script reads
`GET /messages/optimize_prompt/{id}?wait_ms=30000` until it settles, then writes
`run.json`, `report.md` and, when `outcome` is `improved`, `prompt.md`.

The card prints `lift` only when `lift_reportable` is `true`; otherwise it
prints the reason (`held_out_under_3`, `no_revision` or `a_side_not_graded`).
Send 6 recipients for a reportable lift. The train scores are the in-loop
judge's, never lift. A prompt that reads as one message is refused with
`prompt_is_one_off`: grade that message with `grade.sh`.

## Config

| Env var | Default | What it does |
| --- | --- | --- |
| `AMDAHL_KEY` | - | Workspace API key. `AMDAHL_API_KEY` and `AMDAHL_MCP_API_KEY` are accepted too. |
| `AMDAHL_API_BASE` | production | Point at a non-production workspace. |
| `AMDAHL_EVIDENCE` | `workspace` | What a grade reads. `off` grades `cta_clarity` alone. A request file that sets `evidence` keeps its own value. |
| `AMDAHL_HTTP_TIMEOUT` | `330` | curl's wall clock per call, in seconds. A grade answers on the call, and the Optimizer's own deadline is 300 seconds. |
| `AMDAHL_WAIT_MS` | `30000` | How long the server holds each prompt-run read open (`?wait_ms=`). `0` falls back to tight polling. |
| `AMDAHL_POLL_ATTEMPTS` | `40` | Prompt-run read ceiling, counted in blocking reads: 40 x 30s is 20 minutes. |
| `AMDAHL_POLL_INTERVAL` | `15` | Gap between reads, only used when `AMDAHL_WAIT_MS=0`. |
| `AMDAHL_MAX_RETRIES` | `6` | Attempts per call before it gives up. |
| `AMDAHL_BACKOFF_CAP` | `60` | Ceiling on our own backoff, in seconds. A server-sent `Retry-After` is honored past it. |
| `AMDAHL_CIRCUIT_THRESHOLD` | `5` | Consecutive hard failures (per call, not per attempt) before the breaker opens. |
| `AMDAHL_BREAKER_FILE` | keyed to `$PPID` | Breaker state file. Workers under one `batch.sh` share one by default; set it explicitly to share across separate invocations. |

## Gotchas

- **The key needs `messages:execute`,** and its member needs the editor role or
  above. A Customer agent key has the scope; a Read only key does not, and is
  refused.
- **A grade has no `message` key.** The draft is yours, and nothing was written.
  `outcome` is `graded`; anything else is not a grade.
- **A failure is `ok: false`** with a `reason` and `detail`, on HTTP 200. The
  script saves the response and exits non-zero. A failed grade is not billed.
- **`include_tries` and `on_missing_input: "ask"` are refused** with
  `400 invalid_input` in grade mode: a grade writes no versions and asks no
  questions.
- **`quota_exceeded`** is a 429 too, but it resets monthly, so the transport
  stops instead of retrying.
- **The evidence line on the card matters.** A grade with the evidence read and
  a grade without it are different readings. Record which one each grade was,
  and never pool them.
