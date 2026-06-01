# Stalled pipeline triage

**What this does**: Takes the pile of deals that have gone quiet for 30 / 60 / 90+ days and triages them into three buckets — chase (real opportunity, needs a re-engagement play), nurture (long-cycle, keep warm, don't push), and close-lost (it's over, stop forecasting it). For chase deals, a specific re-engagement move; for close-lost, the HONEST reason (in quotes) so the loss is educational.

**When to use it**: "End of quarter. The pipeline is bloated with deals nobody's worked in a month or more, and I need to know which ones are actually still alive."

## Why this matters

Stalled deals rot pipeline reviews. A pipeline with 60 deals where 25 haven't been touched in 60 days isn't a 60-deal pipeline — it's a 35-deal pipeline with 25 zombies, and the zombies are quietly distorting every forecast meeting. The triage move is the cleanup: each zombie deal needs a verdict, not a "let's keep watching it."

The interesting move in the triage is the **honest close-lost reason**. Most stalled-out deals get closed-lost with a generic CRM dropdown ("no budget" / "timing"), the rep moves on, and the team learns nothing. But the calls usually contain the actual reason — sometimes a specific objection that was never addressed, sometimes a competitor that quietly won, sometimes a champion who left. Capturing that reason at the moment of triage (before the deal closes-lost in the CRM) is the only time anyone will ever care enough to surface it. Those reasons are the input to [pattern across cohort](../win-loss-deal-postmortem/pattern-across-cohort.md) next quarter.

## Paste this into Claude

```
List every open deal in our pipeline where the last meaningful touch is now {30 / 60 / 90} days old or older.

Wave 1 (run these in parallel):
- The stalled list: for each deal — name, stage, ACV, last touch date, last meaningful conversation summary (what was supposed to happen next), the named contact who went silent.
- Signal scan per deal: pull the verbatim signals from the deal's call history that suggest whether it's truly stalled-but-alive vs. effectively-dead. Look for — last meaningful intent statement, last sentiment read, any competitive mention, any timeline language, any exec sponsorship signal.
- ICP fit check: for each deal, is it in-ICP or out-of-ICP based on our actual win patterns? (Mark each.)

Wave 2 (after wave 1):
Triage each deal into ONE of three buckets:
1. CHASE — real opportunity, alive but stalled. Signals: champion still warm, intent expressed within the last 60 days, in-ICP, no competitive killshot. Action: specific re-engagement move (an email, a Slack DM, a calendar request — name it).
2. NURTURE — long-cycle, keep warm, don't push. Signals: in-ICP but clearly not a near-term buyer (e.g., "we're not looking at this until next FY"), or budget cycle constraints, or champion changed roles. Action: cadence recommendation only (quarterly check-in, etc.).
3. CLOSE-LOST — it's over, stop forecasting it. Signals: champion gone or actively disengaged, competitor won, intent died, out-of-ICP. For each: the HONEST reason (verbatim quote where possible) — not the CRM dropdown reason.

For each CHASE deal, recommend the specific re-engagement play (the exact next-touch and what it should reference).
For each CLOSE-LOST, capture the verbatim "why it died" so we can feed it into win/loss analysis later.

End with:
- Bottom-line counts and dollars: how much pipeline gets reclassified to close-lost (i.e., released from the forecast).
- A "nurture" bucket size check — if nurture is more than 30% of the stalled list, the team is hoarding deals.
```

## What you'll see back

- Three buckets — chase / nurture / close-lost — with named deals in each.
- A specific re-engagement recommendation per chase deal.
- An honest verbatim close-lost reason per close-lost deal.
- A bottom-line forecast-impact number ($ released).
- A nurture-bucket-size check — flags if you're hoarding.

## How to actually use it

1. **Run it at the end of each month at minimum; weekly during forecast crunch.** The cadence prevents zombie buildup.
2. **Treat the close-lost reasons as the highest-value output.** Save the verbatim quotes into a doc; they're the input to [pattern across cohort](../win-loss-deal-postmortem/pattern-across-cohort.md) the next time you run that recipe.
3. **For each chase deal's re-engagement move, send it the same day.** A re-engagement play that sits in a doc for a week is a play you don't make.
4. **Watch the nurture bucket.** A healthy nurture bucket is small (under 20–30% of the stalled list). If yours is bigger, the team is hoarding deals to avoid declaring losses; have the manager conversation.

## Variations

- **Rep-specific**: "Just {rep name}'s pipeline." Useful for manager 1:1s on book hygiene.
- **ICP fit overlay**: "Also tag each deal as in-ICP or out-of-ICP based on how our wins actually look — then tell me what % of the stalled pipeline is out-of-ICP." Often surfaces a top-of-funnel problem.
- **Re-engagement drafts**: "For the top 3 chase deals, draft the exact re-engagement email I'd send."
- **30 / 60 / 90 split**: "Run this for each of 30, 60, and 90+ day buckets separately." The 30-day bucket has different signals than the 90-day bucket — different actions.

## Tips

- **The "honest reason" on close-lost deals is the most valuable output of this recipe.** Don't let it get lost — pipe those quotes into a doc and re-use them.
- **"Nurture" should be a small bucket.** Big nurture bucket = hoarding. Be ruthless.
- **Champion-changed-roles is almost always close-lost, not nurture.** A new champion-equivalent rarely emerges.
- **Run this monthly minimum to keep the pipeline honest.** Quarterly is too slow; the zombies compound.
- **Pair with [why we lost this deal](../win-loss-deal-postmortem/why-we-lost-this-deal.md)** for deep postmortems on the biggest close-lost deals after this recipe re-classifies them.
