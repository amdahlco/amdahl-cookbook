# Where they show up in our calls

**What this does**: Lists every call this competitor was mentioned on — date, deal, deal stage at the time, who raised them, and verbatim quotes — then summarizes whether they're showing up earlier, later, more, less, and in which segments. The volume + trend view.

**When to use it**: "Has {competitor} been gaining ground? Are they suddenly showing up in stage-2 calls when they used to only appear in late-stage? Did their last launch change buyer perception?"

## Why this matters

A competitor isn't a fixed thing — they're a moving signal. The interesting questions are not "do buyers know about them" but "are they showing up *earlier* than they used to?" and "are they showing up in segments where they didn't before?" Both are early indicators that the competitor has shipped something, hired someone, or run a campaign that changed their gravitational pull. A jump in early-stage mentions usually means a new top-of-funnel push; a jump in late-stage mentions usually means a new sales motion or a new pricing play. They look identical in aggregate ("more mentions") but they mean different things.

The other reason to run this: the absence of mentions in a segment is also data. If a competitor isn't showing up at all in your enterprise segment but is everywhere in your mid-market segment, that's a useful tell about where they actually compete.

## Paste this into Claude

```
List every call in the last {6 / 12} months where {competitor name or domain} was mentioned. Be liberal — include passing mentions, not just head-to-head comparisons.

Wave 1 (run these in parallel):
- The mention table: for each call, surface — deal name, date, deal stage at the time of the call, who on the BUYER side raised the competitor (role), and 1–2 verbatim quotes of what was said.
- The trend cuts: bucket the mentions by (a) month, (b) deal stage, (c) segment (ICP slice), (d) outcome of the deal (won, lost, open). For each cut, count how mentions are distributed.

Wave 2 (after wave 1):
Synthesize a summary:
1. Volume trend — month over month, are mentions going up, down, or flat? Note any sharp inflections (a 2x jump in a month is interesting).
2. Stage shift — are they showing up EARLIER (stage 1–2) or LATER (stage 4+) than they used to? Compare the most recent 90 days to the prior 90 days.
3. Segment shift — which ICP segments are seeing more / less of them? Any segments where they've gone from zero to consistent presence?
4. Outcome correlation — when this competitor is named, what's our win rate vs. when they're not named?
5. Two hypotheses for WHY the pattern looks the way it does. Tie each hypothesis to a specific public signal if you can find one (a launch, a hire, a campaign).

End with: the 3 single quotes from the data that are most worth pulling into a sales team Slack today.
```

## What you'll see back

- A chronological table of mentions (deal, date, stage, speaker, quote).
- 4 trend cuts — by month, by deal stage, by segment, by outcome.
- A volume + stage + segment summary with explicit deltas vs. the prior period.
- 2 hypotheses for WHY the pattern is what it is, tied to public signals.
- 3 pull-quotes worth posting to the sales channel.

## How to actually use it

1. **Run it monthly per top-3 competitor.** Drift is the signal. A one-off run is a snapshot; the trend only shows in cadence.
2. **Watch the stage-shift section.** A sudden jump in stage 1–2 mentions means buyers are hearing about them before our first call — that's a marketing-side problem, not a sales problem.
3. **Compare segments.** If they're surging in mid-market but flat in enterprise, that's where to deploy enablement first.
4. **The win-rate correlation is sobering.** If the win rate when they're named is much lower than when they're not, you have a head-to-head problem worth investigating with [competitor deep-dive](competitor-deep-dive.md).

## Variations

- **Big-deal cohort**: "Only deals over $100K ACV." The competitor pattern in your top deals is the one that matters for the forecast.
- **Loss-only**: "Only on calls that resulted in closed-lost." Sharpens the why-we-lose narrative.
- **Group by stage**: "Group the output by deal stage instead of by date." Useful if you suspect they're a late-stage problem.
- **Group by rep**: "Group by rep — are some reps seeing this competitor more than others?" Catches rep-specific deal patterns (territory, ICP focus, etc.).

## Tips

- **If the competitor's name is a common word** (a verb, a person's name, a generic noun), specify the domain or a disambiguator — otherwise you'll get noise.
- **A sudden inflection always has a cause.** When you see a 2x jump month-over-month, the second hypothesis ("WHY?") is the one to chase — usually a launch or a campaign.
- **Pair with [competitor deep-dive](competitor-deep-dive.md)** when the pattern shifts — the deep-dive will tell you what changed.
- **A competitor showing up earlier in deals is more dangerous than one showing up more often.** Earlier means buyers are reaching for them before they reach for you. Fix early-stage positioning first.
