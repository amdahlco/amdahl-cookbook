# Deals at risk

**What this does**: Surfaces deals that look healthy on paper — right stage, recent activity, no CRM flag — but are actually at risk based on what's being said (or not said) on calls. For each: the "looks healthy because…" + "but actually…" framing, the specific risk signal, and a recommended action this week. Sorted so the biggest at-risk dollars surface first.

**When to use it**: "It's forecast week (or any time the pipeline looks too clean to be true). I want the deals where the CRM is lying — where the stage and the activity look fine but the calls are telling a different story."

## Why this matters

Pipeline reviews work backwards from CRM signal: stage, activity count, days since last touch. Those signals are easy to game and easy to read. The deals that surprise you in a bad way usually look perfectly healthy on those metrics right up until the moment they don't — because the real risk signal is in the **call content**, not the call count.

The risks worth surfacing are the ones that the CRM can't see by structure: a champion who's still on the meetings but has gone quiet in their participation; an objection that was raised three calls ago, never resolved, never raised again; a competitor that surfaced briefly and was waved off but is still in the picture; an exec sponsor who joined once and never came back. None of those show up in a stage report. All of them are visible in the transcripts. This recipe goes after that gap explicitly — and forces every flagged deal to be paired with a specific action, not a generic "the rep should follow up."

## Paste this into Claude

```
Surface the deals in our pipeline that look healthy on paper but are actually at risk based on call activity, sentiment, unanswered objections, champion behavior, or competitive context.

Wave 1 (run these in parallel):
- The healthy-looking universe: every open deal that on paper looks fine — recent activity, no overdue stage, no CRM red flag. List the deals (name, stage, ACV, days in stage, last touch date).
- Risk signals across the corpus: for each deal in the above universe, scan the call content for any of these:
  - Champion gone quiet (still attending, but contributing less, or stopped responding outside meetings)
  - Unresolved objection (raised in a prior call, never cleanly addressed)
  - Competitor surfaced but waved off (mentioned, dismissed, but never confirmed dead)
  - Exec sponsor disengaged (joined a call, never returned)
  - Sentiment cooled (specific verbatim shift in tone, not just fewer words)
  - New stakeholder with unknown posture (someone appeared late in the deal with no read on their stance)
  - Timeline ambiguity (initial timeline was clear, now vague)
- ACV × risk weighting: combine the ACV of each at-risk deal with the severity of the risk signal (high / med / low). Sort by ACV × risk.

Wave 2 (after wave 1):
Produce a structured at-risk list — usually 3–8 deals — each with:
1. Deal name + stage + ACV
2. "Looks healthy because…" (the surface signal that the CRM shows)
3. "But actually…" (the call-content risk signal, with a verbatim quote where possible)
4. Severity: HIGH / MED / LOW
5. Recommended action this week — specific, not generic. ("Get {EB name} on a call by Thursday; if they don't take it, flag the deal at risk in forecast" beats "follow up.")

Sort by ACV × severity. If a deal looks risky but the signal is thin, flag it as a watch-item, not an at-risk deal.
```

## What you'll see back

- A list of 3–8 deals (usually) that pass the "looks healthy / actually risky" test.
- For each: the surface-vs.-real-signal framing, a verbatim quote where possible, a severity grade, and a specific action.
- Sorted by ACV × severity, so the biggest at-risk dollars are at the top.
- A watch-list of weaker signals worth tracking but not chasing this week.

## How to actually use it

1. **Run it on forecast day, before submitting numbers.** The point is to flag risks before the forecast hardens, not to second-guess it after.
2. **Take the top 3 actions to the reps the same day.** A recommended action that sits in a doc for a week is the same as no action.
3. **Distinguish "at risk" from "watch."** The 3–8 at-risk deals need action this week. The watch-list deals need monitoring; if a watch-item produces a new signal next week, it graduates.
4. **Re-run weekly.** A deal that's at-risk one week and resolves the next is a save story; a deal that stays at-risk for three weeks running needs a manager conversation, not just a rep nudge.

## Variations

- **In-quarter cohort**: "Only deals expected to close this quarter." Sharpens the forecast review.
- **Late-stage cohort**: "Only deals in stage 4+ (post-demo or further)." Late-stage at-risk is the highest forecast impact.
- **Rep-level**: "Just {rep name}'s book." Useful for manager 1:1s.
- **Draft the save move**: append "For each at-risk deal, draft the Slack message OR email the rep should send today to begin the save."
- **Champion-specific filter**: "Only deals where the champion has gone quiet in the last 14 days." Sharp filter for the highest-precision risk signal.

## Tips

- **Champion-gone-quiet is the single highest-precision risk signal.** A champion who's contributed less for two calls running is more predictive than any structured field.
- **"No bad signals" is itself a signal in late-stage deals.** Silence isn't peace; in a deal you should be hearing from weekly, silence is the precursor to "we've gone in a different direction."
- **If the same risk type shows up across 3+ deals (e.g., security objection unresolved, repeatedly), that's a [pattern across cohort](../win-loss-deal-postmortem/pattern-across-cohort.md) question, not a per-deal one.** Escalate appropriately.
- **The action recommendation matters more than the risk grade.** A HIGH severity with a vague action is less useful than a MED severity with a specific one-this-week move.
- **Pair with [weekly recap](weekly-recap.md)** for the broader pulse and [stalled pipeline triage](stalled-pipeline-triage.md) for the deals that have already gone past at-risk into quiet.
