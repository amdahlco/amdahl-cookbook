# Why we lost this deal

**What this does**: The honest postmortem on one closed-lost deal — a timeline of what actually happened, the turning point where you lost it, verbatim "why we went elsewhere" quotes from the buyer (which are almost always different from the CRM dropdown reason), unresolved objections ranked by likely impact, competitive context, and 3 specific do-overs.

**When to use it**: "We just lost the {company} deal. Before the memory fades and the rationalizations harden, I want the real story of what happened."

## Why this matters

CRM dropdown reasons for closed-lost are almost always wrong. Not because anyone is lying — but because the dropdown forces a single answer to a complicated question, the rep picks the closest option ("Lost to competitor" / "Budget" / "No decision"), and the *actual* reason — usually a specific moment in a specific call where the deal turned — disappears into the calendar. A month later, the "Budget" loss is remembered as a budget loss, and the team learns nothing.

The real postmortem is built around **the turning point**: the moment where the deal shifted from gettable to gone. Sometimes it's a competitor mention in call #3 that you didn't take seriously. Sometimes it's an unresolved objection that piled up across two calls and stopped being recoverable. Sometimes it's a champion change you didn't notice until two weeks later. The turning point is rarely the CRM reason — and finding it is the only thing that makes the loss educational.

## Paste this into Claude

```
We just closed-lost the {company name or domain} deal. {Brief context: deal size, segment, our stage when we lost, if you know — otherwise skip}.

Walk me through what actually happened.

Wave 1 (run these in parallel):
- Timeline: every meaningful touch — call, email, internal note — in chronological order, with date and a 1-line summary of what happened.
- Verbatim buyer signal across the deal: what they said on calls about their priorities, our product, the competition, the timeline, the budget. Pull the 5 most important quotes (speaker role + date).
- Turning point analysis: identify the call or moment where sentiment, urgency, or engagement clearly shifted away from us. Cite the specific signal — a verbatim quote, an attendee drop-off, a delayed response, a sudden new requirement.
- Unresolved objections: every objection raised during the deal that was NOT cleanly resolved before the loss. Verbatim quotes with dates.
- Competitive context: every mention of a competitor on the deal — when they first showed up, in what context, who raised them.
- CRM-stated reason vs. call-reality reason: contrast the dropdown reason with what buyers actually said. If they don't match, say so explicitly.

Wave 2 (after wave 1):
Produce a postmortem with this structure:
1. Timeline summary (the deal arc in 5–7 sentences).
2. The turning point — when, what happened, what the signal was (with quote).
3. Verbatim "why they went elsewhere" — what the buyer actually said about choosing differently. Speaker role + date.
4. Unresolved objections — ranked by likely impact on the loss.
5. Competitive context — who, when, how late, who let them in.
6. CRM reason vs. call reality — same or divergent?
7. The 3 do-overs — if we ran this deal again, what would we do differently? Each tied to a specific moment in the timeline above.

Be honest. The job is to learn, not to make the team feel better.
```

## What you'll see back

- A timeline of the deal in chronological order.
- A named turning point — the specific moment we lost it — with the signal that marked it.
- Verbatim "why we went elsewhere" quotes (almost always different from the CRM reason).
- Unresolved objections ranked by impact.
- Competitive context with timing (when the competitor showed up matters more than who they were).
- A CRM-vs.-reality contrast.
- 3 specific do-overs tied to specific moments.

## How to actually use it

1. **Run it within a week of the loss.** Memory fades fast; rationalizations harden faster. Run it before the team has converged on a narrative.
2. **Send the do-overs to the rep, the manager, and the team channel.** Not as criticism — as the source material for next quarter's enablement.
3. **If a competitor showed up late (after stage 3), that's the question to chase**: WHY did they get a late look? Almost always something WE did opened the door (a pricing email, a timeline slip, a feature gap surfaced). Ask Claude "what did WE do that opened the door for the competitor?" as a follow-up.
4. **Save the postmortem to a doc, not chat history.** It's input for [pattern across cohort](pattern-across-cohort.md) the next time you run that recipe.

## Variations

- **5-minute version**: "Keep it to 5 bullets — I have 5 minutes before a 1:1." Useful for a manager debrief.
- **Coaching frame**: "Frame the do-overs as coaching notes for the specific rep, with the calls they should re-listen to."
- **Multi-deal comparison**: "Compare this to the last 3 deals we lost in the same segment. Same pattern, or a one-off?" Surfaces whether the loss is a systemic issue.
- **Save-play postmortem**: even if the deal isn't formally closed-lost yet, swap "we just lost" with "we're on the verge of losing" — same structure, recommendation flips to a save-play.

## Tips

- **The CRM dropdown reason is almost never the real reason.** Trust the verbatim quotes from the calls.
- **A competitor showing up late is almost always a symptom of something we did.** Don't accept "we lost to {competitor}" as a complete answer — ask why they got the late look.
- **The turning point is the most important finding.** If you know where the deal shifted, you know what to listen for in the next deal.
- **For systemic patterns across deals, use [pattern across cohort](pattern-across-cohort.md).** For the discriminator vs. won deals, use [what separates won from lost](what-separates-won-from-lost.md).
