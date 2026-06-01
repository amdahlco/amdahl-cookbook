# Renewal prep

**What this does**: A renewal prep doc grounded in the actual year — what they used, the value moments and friction moments (with quotes), the sentiment trajectory across the contract, champion changes, competitive mentions — ending with a recommended posture (flat / expand / defend) and the 3 strongest proof-of-value points you can put on the table.

**When to use it**: "The {customer} renewal is 30–60 days out. I need to walk in with a clear posture — am I defending, going flat, or asking for an expansion — and the evidence to support whichever it is."

## Why this matters

Renewal conversations fail when they're prepared from a position of optimism or anxiety, both of which are guesses. The honest renewal prep is built around **trajectory**, not snapshot. What's changed across the year? Did the champion change roles? Did the sentiment cool around month 7 and never come back? Did a competitor surface for the first time in month 9? Did they expand usage in some areas and abandon others?

A renewal posture (flat / expand / defend) only makes sense in the context of trajectory. A customer whose sentiment is climbing, whose champion is solid, who has been name-checking your product to peers — that's an expand conversation. A customer whose sentiment cooled in Q3, whose champion changed roles in Q4, who has been quiet for two months — that's a defend conversation, and asking for expansion will lose you the renewal. The recipe forces the trajectory into the prep so the posture choice is grounded.

## Paste this into Claude

```
The renewal with {company name or domain} is coming up on {renewal date}. Current contract value: {ACV, if known}. Specific business unit or product line: {if applicable; otherwise "all"}.

Build me a renewal prep doc.

Wave 1 (run these in parallel):
- Year of usage: what they actually used across the contract year — products, features, volume / scale, adoption pattern (growing, flat, declining), launches and rollouts on their side that affected usage.
- Value moments: 3–5 verbatim quotes from calls during the year where the customer described value they got. Speaker role + date on every quote.
- Friction moments: 3–5 verbatim quotes where the customer described frustration, an unmet need, a complaint, a support issue. Speaker role + date on every quote.
- Sentiment trajectory: month-by-month sentiment read across the contract year. Note any inflection points (e.g., "warmer through month 5, cooled sharply in month 7 after the pricing email"). Tie inflections to specific events where possible.
- Stakeholder map changes: champions gained, lost, gone quiet. Role changes on their side. New economic buyer.
- Competitive context: any competitor mentioned on calls during the year, when, by whom, and the verbatim quote.

Wave 2 (after wave 1):
Produce a renewal prep doc with this structure:
1. Renewal snapshot (3 lines) — overall trajectory, biggest tailwind, biggest headwind.
2. Year of usage — adoption pattern + 1 value moment quote + 1 friction moment quote.
3. Sentiment trajectory — month-by-month read, with inflection points called out.
4. Stakeholder changes — champion / economic buyer / detractor changes across the year.
5. Competitive context — any competitor named this year, in what context.
6. Recommended renewal posture — FLAT, EXPAND, or DEFEND — with a 2-sentence justification grounded in the data above.
7. The 3 strongest proof-of-value points I can put on the table — each tied to a verbatim quote or a measurable outcome.

If posture is EXPAND: also surface the 1 specific expansion angle, grounded in a customer quote.
If posture is DEFEND: also surface the 1 specific commercial concession likely to be required, grounded in a friction signal.
Cite dates on every quote.
```

## What you'll see back

- A year-long trajectory view, not a snapshot.
- A sentiment trajectory with inflection points tied to specific events.
- A stakeholder-change section (this is often the deciding factor).
- A clear posture recommendation — flat / expand / defend — justified in 2 sentences.
- 3 proof-of-value points, each tied to a quote or outcome.
- A specific expand angle OR a specific defend concession, depending on posture.

## How to actually use it

1. **Run it 45 days out, not 7.** The recipe surfaces signals that take time to act on — champion re-engagement, exec-to-exec calls, support escalations to clean up before the conversation.
2. **Trust the posture recommendation, but pressure-test it.** If the recipe says DEFEND and your gut says EXPAND, ask Claude "what would have to be true for an EXPAND posture to be safe here?" — that surfaces the exact gaps.
3. **The stakeholder-changes section is the single biggest signal.** A champion who changed roles or went quiet is the most reliable predictor of a hard renewal.
4. **Take the 3 proof points into the renewal call as your back-pocket evidence.** If the customer pushes back on price, those proof points are the answer.

## Variations

- **Multi-year customer**: "Compare year 1 to year 2 — what changed in adoption, sentiment, stakeholders, competitive context?"
- **Multi-product**: "Break the recap and posture out by product line they have with us."
- **Draft the renewal email**: append "Draft the renewal email I'd send their economic buyer next week, grounded in the proof points and the posture above."
- **Procurement-led renewal**: "Add a section on what their procurement / legal team has said this year and any commercial pushback already on record."

## Tips

- **Champion changes are the single biggest renewal signal.** A defensible position with a strong champion beats a perfect-usage account with a champion who left.
- **If the sentiment trajectory is flat (not negative, but flat), ask "what would have to be true for them to upgrade?"** That sets the year-2 plan even if you don't get expansion this renewal.
- **A DEFEND posture isn't a failure — it's a strategy.** Defending a renewal cleanly is worth more than asking for expansion you can't get and losing trust.
- **For mid-year health, use [QBR prep](qbr-prep.md)** instead — same mechanic, different scope.
