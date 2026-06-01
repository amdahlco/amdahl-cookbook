# Weekly recap

**What this does**: A Monday-morning (or Friday-evening) 1-page summary of what moved in the pipeline last week — deals that advanced and why, deals that slipped and why, new deals that entered, deals that went quiet, and sentiment changes on named accounts. Ends with the 3 specific things to watch this week.

**When to use it**: Every Monday before standup. Or every Friday before you log off. The point is the **cadence**, not the one-off — patterns only show up when the recap runs on a regular rhythm.

## Why this matters

Most pipeline reviews fail one of two ways. Either they're a Salesforce report (a list of stages and amounts that doesn't explain anything) or they're a meeting (the same conversation about the same five deals, week after week). What's missing in both is the **delta**: what changed since the last time we looked? A deal that's been in stage 3 for six weeks is a different fact than a deal that moved from stage 2 to stage 3 last week. A deal that's been quiet is a different signal than a deal where sentiment cooled. Without the delta, you're just looking at a snapshot.

This recipe forces the delta into the recap. Movement (what advanced), slippage (what fell behind), new entrants (what's freshly in the funnel), and sentiment shifts (the soft signal that precedes the hard one). The 3-things-to-watch close is the action-forcing function — without it, the recap is information without a decision.

## Paste this into Claude

```
Recap last week's pipeline activity (the 7 days ending today). I want movement, not a static snapshot.

Wave 1 (run these in parallel):
- Moved forward: deals that advanced a stage or had a clear unlock (champion confirmed, EB engaged, proposal sent, contract redlines started). For each: deal name, ACV if known, the specific unlock (verbatim quote where possible).
- Slipped: deals that lost ground — pushed close date, lost a meeting, stage downgrade, key contact going quiet. For each: deal name, ACV, the specific slip signal.
- New entrants: deals that newly hit the pipeline this week. For each: deal name, source, what we know so far.
- Went quiet: deals where the last meaningful touch is now 14+ days old AND was supposed to advance. For each: deal name, last touch date, what was supposed to happen.
- Sentiment shifts: named accounts where sentiment cooled or warmed materially this week, even if the deal didn't move. Verbatim quotes where possible.

Wave 2 (after wave 1):
Synthesize a 1-page recap with this structure:
1. Headline (1 line) — was this a good week or a bad week, and why?
2. Movement table — moved forward / slipped / new entrants / went quiet.
3. Sentiment shifts — named accounts only, with quotes.
4. The 3 things to watch this week — specific deals, specific risks, specific actions. Not "we need to do better on follow-up"; "follow up with {champion} at {account} on the security objection by Wednesday."
5. The 1 question I should ask in the team standup tomorrow.

Keep under 400 words. Cite quote dates. If a section is thin (no movement, no slippage), say so explicitly — silence is data.
```

## What you'll see back

- A 1-line headline: good week or bad week, with the reason.
- A movement table — 4 buckets, each with specific deal names and signals.
- A sentiment-shift section with named accounts and verbatim quotes.
- 3 specific things to watch — named deals, named risks, named actions.
- 1 specific standup question to ask.

## How to actually use it

1. **Pick a day and time, and run it every week without exception.** The recipe is built around cadence; a recap once a month is a different (less useful) artifact.
2. **Read the headline first.** If the week was bad, the recap should change what's on the agenda for tomorrow.
3. **Take the "1 standup question" verbatim into the standup.** That single question — grounded in the specific signals from the week — is usually the single most useful thing in the meeting.
4. **Save each weekly recap to a shared doc.** After 8–12 weeks, you can scroll back and see patterns the individual weeks didn't show (e.g., the same 4 deals keep slipping every other week).

## Variations

- **Team view**: "Group the output by rep." Useful for managers running 1:1s.
- **Big-deals only**: "Only deals over $100K ACV." Tightens the recap to the deals that move the forecast.
- **By segment**: "Cut the movement by ICP segment — are mid-market and enterprise behaving the same?"
- **Cohort focus**: "Only deals expected to close this quarter." Surfaces the in-quarter slip risk fast.
- **Weekly + monthly stack**: run weekly recaps for context, then once a month ask "Across the last 4 weekly recaps, what patterns appeared?" — surfaces the patterns no single week showed.

## Tips

- **Same day, same time, every week.** Patterns only show up when the cadence is regular. A recap on Monday vs. Thursday answers different questions; pick one.
- **The "went quiet" bucket is the most useful one.** Deals that went quiet but were SUPPOSED to advance are the silent slippage that doesn't show up in stage reports.
- **A slip + sentiment shift on the same deal in the same week is the highest-priority signal.** Chase that one first.
- **Pair with [deals at risk](deals-at-risk.md)** for the deeper risk cut, and [stalled pipeline triage](stalled-pipeline-triage.md) for the deals that have gone quiet beyond rescue.
