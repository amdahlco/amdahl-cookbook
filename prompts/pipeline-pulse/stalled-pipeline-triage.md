# Stalled pipeline triage

**What this does**: Takes the pile of deals that have gone quiet and tells you which to chase, which to nurture, and which to actually close-lost.

**When to use it**: End of the quarter, or any time the pipeline is bloated with deals nobody's worked in 30+ days.

## Paste this into Claude

```
List every deal in our pipeline that hasn't had a meaningful touch in {30 / 60 / 90} days. For each one, classify it: chase (real opportunity, needs a re-engagement play), nurture (long-cycle, keep warm, don't push), or close-lost (it's over, stop forecasting it). For chase deals, recommend a specific re-engagement move. For close-lost, tell me the honest reason — not the dropdown reason — so we can learn from it.
```

## What you'll see back

- Three buckets: chase / nurture / close-lost.
- Each chase deal gets a specific re-engagement recommendation.
- Each close-lost gets the honest reason (in quotes when possible).
- A bottom-line count: how much $ to release back into the forecast.

## Variations

- Rep-specific: `Just {rep name}'s pipeline.`
- ICP fit: `Also tag each deal as in-ICP or out-of-ICP based on how the wins look.`
- Add: `Draft the re-engagement email for the top 3 chase deals.`

## Tips

- The "honest reason" on close-lost deals is the most valuable output — feed those quotes into a [pattern across cohort](../win-loss-deal-postmortem/pattern-across-cohort.md) run later.
- "Nurture" should be a small bucket. If it's big, you're hoarding deals.
- Run this monthly to keep the pipeline honest.
