# What separates won from lost

**What this does**: A diff, not two profiles. Compares closed-won deals against closed-lost deals in the same segment and window, and surfaces the specific things that were different between them — stakeholders engaged, objections raised and resolved, language used, competitive context, time-to-value mentioned, exec sponsorship. Ends with the 3 sharpest discriminators most likely to predict win vs. lose.

**When to use it**: "I want to know what good actually looks like — not 'what did we do in the wins' or 'what did we do in the losses,' but what did we do in the wins that we didn't do in the losses."

## Why this matters

Most win/loss work falls into a trap: it describes each side instead of comparing them. A "what we did right in the wins" doc is fine. A "what we did wrong in the losses" doc is fine. Neither is actionable on its own, because the actions you'd take from each are different — and most of what's in each is also present in the other. The interesting output is the **diff**: what's actually different between the cohorts? Not "wins had more stakeholders" — every deal has multiple stakeholders. But "wins had an economic buyer on the third call, losses had an economic buyer on the seventh call or never" — that's a discriminator, and that's enablement-actionable.

Discriminators have a specific shape: a thing that's TRUE in the wins and FALSE (or much weaker) in the losses, with enough cohort volume to suggest it's not a coincidence. This recipe enforces that shape — and ranks the discriminators by how cleanly they separate the two outcomes.

## Paste this into Claude

```
Compare our closed-won deals against our closed-lost deals in {segment + time window — e.g. "the last 12 months among enterprise prospects" or "mid-market healthcare in the last 2 years"}.

Wave 1 (run these in parallel):
- Stakeholder profile: for each deal in each cohort, identify the named stakeholders engaged, their roles, and when (by stage) each role joined the conversation. Compare aggregate profiles across the two cohorts.
- Meetings and engagement: average / median number of meetings, attendees per meeting, multi-thread vs. single-thread, exec-to-exec touches. Compare across cohorts.
- Objections raised AND resolved: not just objections raised. Track for each deal — what was raised, and was it clearly resolved before the next stage? Compare resolution rate across cohorts.
- Language patterns: pull the verbatim buyer language across each cohort. Are there phrases that show up frequently in wins but not in losses (or vice versa)?
- Competitive presence: when (by stage) did a competitor first surface in the deal? Compare across cohorts.
- Time-to-value mentions: did the buyer ever articulate a specific time-to-value or business deadline? When? Compare frequency and specificity across cohorts.
- Exec sponsorship: was there an executive sponsor named on the buyer side, and when did they engage?

Wave 2 (after wave 1):
Produce a DIFF — not two separate profiles. For each dimension above:
- State the win cohort behavior + the lost cohort behavior, with numbers / counts.
- Quantify the delta. ("Wins had economic buyer engaged by stage 3 in 17/20 deals; losses had economic buyer engaged by stage 3 in 4/22 deals.")
- Mark whether the delta is sharp, moderate, or noise.

End with:
1. The 3 SHARPEST DISCRIMINATORS — the dimensions where the delta is biggest. Phrase each as a testable predictor. ("Economic buyer engaged by stage 3" is a predictor; "more stakeholders" is not.)
2. 1–2 surprising findings worth pulling into a sales team meeting.
3. 2 recommended changes to the discovery checklist or sales motion grounded in the discriminators.

Cite cohort sizes. If a discriminator is based on under 10 deals per side, flag it as suggestive.
```

## What you'll see back

- A dimension-by-dimension diff with counts on each side.
- Delta sharpness markers (sharp / moderate / noise) per dimension.
- 3 ranked discriminators phrased as testable predictors.
- 1–2 surprising findings.
- 2 specific motion or discovery-checklist changes.

## How to actually use it

1. **Translate the top discriminator into a single discovery-checklist line.** If "economic buyer engaged by stage 3" is the #1 discriminator, the rule for the team is "no deal advances past stage 3 without an EB conversation."
2. **Run it before any sales-motion or ICP rework.** This recipe is the empirical input for those decisions.
3. **Run it per segment, not just overall.** What separates won from lost in mid-market is often different from what separates won from lost in enterprise.
4. **Re-run quarterly.** Discriminators shift as the product and the market shift; what was a moat last year may be table stakes this year.

## Variations

- **Sharper output**: "Just the top 3 discriminators, with the delta on each, and the 1 discovery checklist change."
- **By rep**: "Compare wins and losses within a single rep's book — what's HIS/HER winning pattern vs. losing pattern?" Useful for individual coaching.
- **ICP refinement**: "Translate the discriminators into ICP criteria — what should our outbound filter look like?"
- **Stage focus**: "Limit to deals that reached at least stage 3 — exclude top-of-funnel noise." Sharper discriminators for late-stage motion.

## Tips

- **Time-to-value language is almost always a discriminator.** Wins consistently have a specific timeline ("we need this live by Q1 because…"); losses are vague. If yours doesn't, dig deeper.
- **"Stakeholders engaged" is the single most common discriminator across B2B SaaS.** Don't skip it.
- **A discriminator with under 10 deals on either side is suggestive, not conclusive.** Treat it as a hypothesis worth testing, not a rule.
- **Pair with [pattern across cohort](pattern-across-cohort.md)** for deep single-cohort patterns, or [why we lost this deal](why-we-lost-this-deal.md) for single-deal depth.
