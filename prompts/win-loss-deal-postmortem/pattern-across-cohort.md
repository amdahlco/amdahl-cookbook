# Pattern across cohort

**What this does**: Finds the common threads across a cohort of deals — all the losses last quarter, all the wins in a segment, all the no-decisions in a window — grouped by theme with counts, verbatim quotes per theme, the deal stage where things broke, and the buyer role that pushed back. Ends with the single biggest pattern and what it suggests changing.

**When to use it**: "I sense a pattern across the last quarter's losses (or wins, or no-decisions), but I don't have time to read 30 deal notes by hand. I want the systematic view, not anecdotes."

## Why this matters

Single-deal postmortems teach you about the deal. Cohort analysis teaches you about your **motion** — the systematic things that go right or wrong across many deals that no single deal would surface. A common objection that came up in 12 of 18 losses isn't a quirk of one buyer; it's a positioning problem. A common deal stage where things break (e.g., always between demo and pricing) isn't a rep problem; it's a process problem. A common buyer role that pushes back (e.g., security every time, even in mid-market) isn't a deal-specific objection; it's an enablement problem.

The other thing cohort analysis surfaces: the **delta vs. the wins**. A pattern that shows up in 50% of losses but also 50% of wins isn't a pattern — it's just background noise. The patterns that matter are the ones that distinguish outcomes. (For that specific cut, see [what separates won from lost](what-separates-won-from-lost.md); this recipe stays focused on a single cohort.)

## Paste this into Claude

```
Look at every {closed-lost / closed-won / no-decision} deal in {segment + time window — e.g. "Q3 mid-market," "the last 6 months in fintech," "all losses over $50K ACV in the last year"}.

Wave 1 (run these in parallel):
- Common objections: cluster every objection raised across the cohort by theme (pricing, security, integration, timing, etc.). For each theme: count of deals it appeared in, 2–3 verbatim quotes (speaker role + deal name + date).
- Common competitive presence: which competitors showed up across the cohort, and at what frequency. For each: count of deals + 2–3 quotes about how the buyer compared.
- Stage where things broke: bucket each deal by the stage where it stalled or shifted. Count of deals per stage.
- Buyer role that pushed back: which roles (champion, economic buyer, end user, technical evaluator, procurement, legal) raised the decisive objection. Count per role.
- Language patterns: are there phrases that show up across multiple deals? (e.g., "we'd rather wait" / "we'll build it ourselves" / "your pricing is steeper than expected"). Pull the recurring phrases with counts.

Wave 2 (after wave 1):
Synthesize:
1. The 4–6 dominant themes across the cohort, ranked by frequency. For each: count, 2–3 quotes, and a 1-line "what this is."
2. The stage where things consistently broke (single most common stage + count).
3. The buyer role that consistently pushed back (single most common role + count).
4. The 2–3 recurring phrases worth treating as signals.
5. The SINGLE BIGGEST PATTERN — the one thing that, if true, would shift our motion the most. Be specific. ("18 of 24 losses had no security review scheduled before the pricing conversation" is a pattern; "we need to handle security objections" is not.)
6. One recommended change to our motion, grounded in #5.

Cite call dates and speaker roles on every quote. If a cohort is thin (under 10 deals), say so and treat the patterns as suggestive, not conclusive.
```

## What you'll see back

- 4–6 themes ranked by frequency, each with counts and verbatim quotes.
- A stage-where-things-broke single most-common answer.
- A buyer-role-that-pushed-back single most-common answer.
- 2–3 recurring phrases worth treating as signals.
- The single biggest pattern — phrased specifically enough to act on.
- One recommended motion change tied to that pattern.

## How to actually use it

1. **Pick the cohort tightly.** "All losses last year" is too broad to surface a pattern; "all mid-market losses where security was raised last year" is sharp. Narrow first, then widen if the patterns are thin.
2. **Run it once on losses, once on wins, then compare.** A pattern that's 50/50 between cohorts isn't a pattern; one that's 80/20 is. (For the formal version, see [what separates won from lost](what-separates-won-from-lost.md).)
3. **Take the single-biggest-pattern to a sales meeting and pressure-test it.** If 18 of 24 losses share a stage where they broke, that's the topic for the next motion review.
4. **Don't try to fix every pattern.** Pick the top 1 by frequency × impact, change one thing in the motion, and re-run the cohort analysis next quarter.

## Variations

- **Sharper output**: "Just the top 3 patterns, with 1 quote each, and the single motion change." Useful for an exec readout.
- **By rep**: "Group the patterns by which rep owned each deal. Are we seeing rep-specific patterns vs. systemic patterns?" Surfaces whether it's a coaching or motion problem.
- **By segment**: "Cut the patterns by ICP segment — are the losses in mid-market and enterprise telling the same story?"
- **No-decision cohort**: this recipe works especially well on the "no decision" bucket, which is usually under-analyzed because reps move on. Surfacing the patterns there often unlocks pipeline.

## Tips

- **Bigger cohorts surface stronger patterns.** Aim for 10+ deals minimum; 20+ if you can.
- **A pattern phrased generically is useless.** "We have a security problem" is not a pattern; "12 of 18 losses had no security review scheduled before the pricing call" is.
- **Watch the recurring-phrases section.** If 3 different buyers in 3 different deals used the same specific phrase, that's a positioning signal, not a coincidence.
- **For single-deal depth, use [why we lost this deal](why-we-lost-this-deal.md).** For the won-vs-lost diff, use [what separates won from lost](what-separates-won-from-lost.md).
