# How buyers compare us

**What this does**: Pulls the actual trade-offs buyers articulate when they're evaluating you against a specific competitor — in their verbatim language, grouped by theme, with three buckets: where they think we win, where they think the competitor wins, and where they think it's a tie. The tie bucket is usually the most useful.

**When to use it**: "I'm writing a battle card, refreshing positioning, or coaching reps on objection handling for {competitor}, and I want the comparison in buyer words, not marketing words."

## Why this matters

Three reasons most head-to-head competitive content fails:

1. **It's written by your team.** Your team has read every release note, knows every feature; buyers haven't. The way buyers compare two products is at a higher level of abstraction than your team's instinct — and that level is the level that matters.
2. **It treats "we win" and "they win" as the whole picture, and ignores the tie bucket.** The tie bucket is where you discover you've been spending engineering budget on a differentiator buyers don't actually weight. That's a roadmap finding.
3. **It averages across segments.** Enterprise buyers and mid-market buyers compare differently. End users compare differently than economic buyers. Averaging hides the segments where you're losing the comparison.

This recipe enforces all three: buyer voice only, three buckets including the tie, and role-attributed quotes so you can re-slice by who's speaking.

## Paste this into Claude

```
On calls where buyers explicitly compared us to {competitor name or domain}, pull the trade-offs they actually articulated. EXCLUDE rep utterances — buyer voice only. EXCLUDE quotes where the buyer is parroting back a phrase we used in the same call (if it's our pitch echoed, it's not their comparison).

Group quotes into THREE buckets and structure them by theme within each bucket:

1. WHERE BUYERS THINK WE'RE STRONGER — verbatim quotes, grouped by theme (e.g., "implementation speed", "reporting depth", "support quality"). 5+ quotes per theme where the data supports it.
2. WHERE BUYERS THINK THE COMPETITOR IS STRONGER — same structure.
3. WHERE BUYERS THINK IT'S A TIE — same structure. THIS IS USUALLY THE MOST USEFUL BUCKET.

For every quote include: speaker role (champion / economic buyer / end user / technical evaluator), deal stage when it was said, rough date.

After the three buckets, surface:
- Any theme that appears in BOTH "we win" and "they win" — that's a sign of segment differences. Note which segments lean which way.
- A "what to lean into" — the 2 strongest themes from bucket 1.
- A "what to neutralize" — the 2 sharpest themes from bucket 2, with a reframe suggestion for each.
- A "what to stop spending on" — the most surprising theme from bucket 3 (a differentiator we promote that buyers don't weight).
```

## What you'll see back

- Three buckets — we win / they win / tie — with quotes grouped by theme inside each.
- Speaker role on every quote (the role matters more than the company).
- A "split theme" callout — themes that appear on BOTH sides, which always means segment variance.
- Three actionable summaries: lean in, neutralize, stop spending on.

## How to actually use it

1. **Read the tie bucket first.** It's where you'll find the engineering investment buyers don't care about — i.e., the roadmap discussion to have.
2. **Use the "neutralize" reframes verbatim with reps the same week.** Don't wait for a battle card refresh; if buyers are saying X, reps need a response by Monday.
3. **Slice the output by role** if you have time: run it once for economic buyers only, once for end users. The comparisons diverge sharply — and the divergence tells you which buyer to design enablement for.
4. **Take the "split theme" finding to product marketing.** If "support quality" appears in both we-win and they-win, you have a segment-specific story to tell, not a universal one.

## Variations

- **Enterprise vs. mid-market**: run it twice, segmented, and compare. The trade-offs diverge in revealing ways.
- **Late-stage only**: "Only quotes from post-demo / post-pricing conversations." Tightens it to the comparisons that actually decided deals.
- **Loss cohort**: "Only on calls from deals we lost to them." Sharpens the "they win" bucket.
- **Win cohort**: "Only on calls from deals we won." Sharpens the "we win" bucket and shows you the proof points that closed.
- **Add reframes**: append "End with 3 reframes for the themes in bucket 2, each grounded in a quote from bucket 1 or 3."

## Tips

- **The tie bucket is the most useful, full stop.** Most teams skip it — that's a mistake. Read it first.
- **Watch for a theme appearing in both "we win" and "they win" — that means segment differences.** Slice by segment to see which side wins where.
- **Roles matter.** End users say different things than economic buyers; champions say different things than skeptics. Trust the role-attribution; it changes how you weight a quote.
- **Pair with [competitor deep-dive](competitor-deep-dive.md)** for the public-posture side of the story, and [where they show up in our calls](where-they-show-up-in-our-calls.md) for the volume + trend view.
