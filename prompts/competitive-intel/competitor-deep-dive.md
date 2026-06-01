# Competitor deep-dive

**What this does**: Builds a two-column picture of a competitor — their public posture on one side, how prospects and customers actually describe them on YOUR calls on the other — and ends with the divergences between the two. The divergence section is where attack angles live.

**When to use it**: "I'm updating the battle card, prepping for a deal where {competitor} is shortlisted, or building positioning to move us out of their shadow. I want to see the gap between their marketing site and what buyers actually say about them."

## Why this matters

Most competitive intel is broken because it picks a side. Either you read the competitor's marketing site (clean, polished, says they win every category) or you read your internal "why we win / why we lose" doc (biased, recency-skewed, written by people incentivized to make the competitor look beatable). Neither alone is the truth.

The truth lives in the **divergence**. When the competitor's public posture is "enterprise-grade security" but your call transcripts show 4 separate buyers describing their security review as a multi-month nightmare — that's not a competitor weakness, that's a positioning lever. When their public ICP is "mid-market" but the buyers who actually chose them in your data are all 5,000+ employees — their real ICP is different from their stated ICP, and your motion is fighting the wrong battle.

This recipe forces both sides into one document and surfaces those gaps explicitly.

## Paste this into Claude

```
Build me a competitor deep-dive on {competitor name or domain}. If they have multiple product lines, focus on: {the specific product line — otherwise the divergences get muddled across SKUs}.

Wave 1 (run these in parallel):
- Public posture: their stated positioning, target ICP, pricing tier / packaging, recent product moves (last 6 months), marketing themes / campaigns, key public hires or leadership changes, recent funding or financial signal. Cite each claim with a source.
- Call reality: every mention of this competitor in our call corpus in the last 12 months. What do buyers say is GOOD about them? What do buyers say is BROKEN? Why do buyers pick them over us, and why do they pick us over them? Verbatim quotes only — attribute each with speaker role + deal stage + date.
- Win/loss split: of deals where this competitor was named, how many did we win vs. lose? In the losses, what was the verbatim "why" from the buyer?

Wave 2 (after wave 1):
Produce a structured deep-dive:
1. Public posture column (4–6 bullets).
2. Call reality column (4–6 bullets, each with a verbatim quote).
3. Win/loss split (the count + 3–5 representative quotes from each side).
4. THE 3 BIGGEST DIVERGENCES between public posture and call reality. (e.g., "claims enterprise-ready, but 4 enterprise buyers on our calls describe their security review as taking 6+ months.")
5. 2–3 specific attack or sidestep angles for our reps, each tied to a specific divergence.
6. A 3-line battle card I can paste into Slack — when we hit them, what's our strongest position?

Cite call dates on all quotes. Cite sources on public claims. No fabrication — if the data is thin in a section, say so.
```

## What you'll see back

- A two-column structure: public posture vs. call reality.
- A win/loss split with the actual numbers from your corpus, plus quotes from each outcome.
- 3 divergences with specifics — usually the most valuable output.
- 2–3 attack angles tied to specific divergences (not generic "we're more reliable").
- A 3-line battle card you can paste into Slack tomorrow.

## How to actually use it

1. **Name the specific product line** if the competitor has more than one (e.g., "their enterprise tier," not just the company name). Different product lines have different divergences.
2. **Read the divergence section first.** Sections 1 and 2 set up section 4; section 4 is the value.
3. **For each divergence, ask "do we have proof?"** A divergence backed by 5+ verbatim quotes is a battle-card line. A divergence backed by 1 quote is a hypothesis worth probing on the next deal where the competitor surfaces.
4. **Send the 3-line battle card to the AEs** the same day. Updated competitive intel only matters if it's in their hands before the next call.

## Variations

- **Loss-only cohort**: "Focus only on deals we lost to them in the last 12 months." Sharpens the attack angles.
- **Segment slice**: "Only on calls in {segment — e.g., mid-market healthcare}." Different segments hear different things.
- **Versus a category, not a product**: replace `{competitor name}` with `{category — e.g., "in-house builds"}` to get the same structure against a non-named competitor.
- **Recent-only**: "Only the last 90 days." Useful right after the competitor ships a major release — surfaces whether the new release has actually changed buyer perception.

## Tips

- **Quotes are gold.** If a section feels generic, ask "pull 5 more verbatim quotes on the {theme} angle" and the section sharpens.
- **The "stated vs. real ICP" divergence is often the biggest lever.** Competitors who chase a stated ICP they don't actually win in are vulnerable in the gap.
- **Re-run quarterly per top competitor.** Their posture shifts; the divergences shift too.
- **Pair with [where they show up in our calls](where-they-show-up-in-our-calls.md)** for the volume / trend view, and [how buyers compare us](how-buyers-compare-us.md) for the head-to-head trade-off language.
