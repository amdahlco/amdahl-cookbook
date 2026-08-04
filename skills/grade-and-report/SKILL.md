---
name: grade-and-report
description: Submit a draft (and optionally the prompt behind it) to Amdahl Eval, poll the queued run to a verdict, and report the result using Amdahl's own report card. Use after ground-and-draft, before anything publishes. Also covers A/B-ing two drafts on frozen evidence and taking a median of N to see past the noise.
---

# grade-and-report

The second half of the loop: (ground-and-draft) → **Grade → Fix**.

Submits to Eval, waits, and shows the **server-authored report card**.

## The one rule

**Paste the report card. Do not restate the numbers in your own words.**

`GET /eval-runs/{id}/report` returns finished markdown: the draft's score, the
rewrite's score, the bar, the transition, the customer quotes, and any caveat.
Show that block as written.

This is not a style preference. The eval reports two different artifacts — your
draft and a rewrite Amdahl generated — and the headline `overall_score` mostly
follows the _rewrite_. Summarising a run in your own words is precisely where
those get merged, and the result is a confident sentence about the user's copy
built on a number that was never about their copy. Live example: run
`783c94c1` carries `overall_score: 1.0` for a draft that passed **2 of 5**
checks. The card says 2.6/5, 2 of 5. Your summary would have said "scored
perfectly".

If you need a number in your own prose — to compare runs, to decide whether to
iterate — read `report.headline.*`, which is the same derivation the card
renders, so the two cannot disagree.

## Steps

1. **Build the inputs.** Message-only grades the copy. Add `prompt` to grade the
   instruction that produced it too — that is the half you can actually reuse.
   Add `audience` (e.g. `"VP of Marketing"`) and, when the account is in your
   corpus, `account`, to scope the evidence. Homepage/hero copy runs unscoped.

2. **Grade.**

   ```bash
   export AMDAHL_API_KEY='...'          # Settings → API keys
   bash scripts/grade.sh draft.md runs/2026-08-03-launch "" "VP of Marketing"
   ```

   Submits (with retries), polls to terminal, writes `scorecard.json` +
   `report.md`, and prints the card.

3. **Show the card.** `report.md`, verbatim, in the section order below.

4. **Read the two things worth reading — and skip the three that look
   readable.**
   - **The fraction, not the score.** `submitted.checks` — "2 of 5" — is the
     measurement; `score_15` is `1 + 4·(passed/total)`, a rendering of it. With
     five binary checks the dial has six positions, so an edit that does not
     flip a whole check is invisible in the number. If you iterate and the score
     does not move, you have learned you have not yet flipped a check.
   - **The quotes, especially a `contradicts`.** A customer arguing against a
     claim you hold is the highest-value output of the whole run. Escalate it;
     do not average it away.
   - **Not the Improved row, not `lift`, not `transition`.** The improved side
     is a rewrite the eval writes for itself, and its own field says so:
     `improved.usage` is `illustration_only`. Read it for the _wording_ it
     reaches for; do not read its number. Measured at eval_version 2.9.0 (n =
     89 runs / 40 distinct messages, one tenant): the improved side clears the
     4.2 bar on **92%** of them, so it is close to a constant — and because
     `lift` is `improved − submitted`, that makes `lift` **−0.90 correlated
     with your own draft's score** on that same run set. A big lift means your
     draft scored low, not that the rewrite added much. The noise-floor filter
     does not fix this: restricted to the runs where `lift_reportable` is
     `true`, the correlation is still **−0.88**. `transition` inherits the
     same problem — its first half is the submitted verdict by definition,
     and its second half is a 92% constant. **Use the submitted fraction. It
     is the only number on the card that is about your writing.**

     Bounds on the 92%: the same statistic read 71.0% at eval_version 2.7.0,
     on a message population that overlaps with but is not identical to the
     89-run 2.9.0 population above. The two readings are separate
     measurements taken at different versions on partly different message
     populations — not a controlled before/after of the same experiment — so
     do not read the difference between them as caused by the version bump.
     Live is now eval_version 2.12.0; neither reading has been re-taken
     there.

5. **Fix.** Apply the suggestions to the draft _and_ to the prompt, then re-run
   as a **new** run folder. Runs are immutable.

## Output contract

Fixed section order. Nothing between §1 and §2.

1. **The card** — `report.md` pasted verbatim. No preamble, no "here's how it
   did", no reformatting the table.
2. **What you changed, or would change** — your own words, about the _edits_,
   never restating a score.
3. **Anything a `contradicts` quote surfaced** — the belief, and the quote.
4. **What you ran** — run id, whether the evidence was pinned, and `reused`.

When a run comes back `not_applicable`, the card says so and says why; report
that. It is not a failing grade and must not be presented as one.

## A/B-ing two drafts

```bash
bash scripts/ab.sh v1.md v2.md runs/ab-hook "VP of Marketing"
```

Grades v1 fresh, grades v2 **pinned to v1's evidence**, and reports the delta
between the two **submitted** drafts.

> **Do not A/B on `compare.score_delta` or on `overall_score`.** Those are
> rewrite-versus-rewrite. On a live pinned pair whose true draft delta was
> **−0.8** (2.6 → 1.8), `score_delta` reported **−0.167**. `ab.sh` reads
> `report.headline.submitted.score_15` on each side instead. `evidence_overlap`
> from the compare endpoint _is_ correct and worth reading — it tells you the
> pin held.

Pinning matters because a second search returns different quotes, so an
unpinned difference could be your edit or could be retrieval.

## One run is not a measurement

```bash
bash scripts/repeat.sh draft.md runs/noise-check 5
```

Grades the same draft N times, drops degenerate runs, reports the **median** and
the range plus a pass **rate**.

A single fingerprinted draft graded 15 times on byte-identical input spanned
`overall_score` 0.0 → 1.0 (sd 0.244) and produced all four transitions. Across
18 repeat groups the submitted pass/fail flipped 22% of the time and the
transition changed 33%. The cause is quantization — five binary lines, six
possible scores, the bar at 4.2, so one dimension flipping flips the verdict —
and it does not go away at temperature 0 (measured: identical noise floor across
a 600-call two-arm test).

Vintage: these figures were measured on the superseded 4.x-series judge and
before #2291 made evidence draws deterministic, so they describe the historical
instrument, not the current one.

Take the median before you act on a change, and before you tell anyone a draft
got better. Take it on the **submitted fraction** — medianing `transition` buys
you a stable reading of a number that read 92% at eval_version 2.9.0 anyway
(see step 4 for the bounds on that figure, including the 71.0% reading at
2.7.0 and why the two are not a before/after).

## Gotchas

- **A run is queued.** Budget 1–3 minutes; the scripts poll for you.
- **`reuse` defaults to `cached`** (15 min, content-addressed on the inputs), so
  an iteration loop silently replays and the score cannot move. The scripts
  always send `force` and warn loudly if `reused=true` comes back anyway.
- **`dimension.pass` is the boolean; `facet.passed` is a count.** Reading
  `dimension['passed']` yields nothing and prints every dimension as a failure.
- **Not every run has a before/after.** A `not_applicable` run, a failure, or an
  eval whose graders produce no improvement report all return a card with no
  scorecard table and a null `headline`. Do not fabricate one.
- **`audience` can abstain** (`not_provided` / `unresolvable` / `no_evidence` /
  `thin_evidence` / `lookup_failed`). An abstained run was graded against the
  whole corpus, so it is not comparable to a scoped one.
