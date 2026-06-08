---
description: Honest closed-lost postmortem for one deal — the timeline, the turning point, verbatim "why we went elsewhere", unresolved objections, competitive context, and 3 do-overs.
argument-hint: <company name or domain> [deal size, segment, stage when lost]
---

Run the Amdahl "why we lost this deal" postmortem for **$ARGUMENTS**. Use the connected **Amdahl** MCP tools. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`. The job is to learn, not to make anyone feel better — be honest.

**Wave 1 — gather in parallel (over `data` query + cluster_search):**
- **Timeline**: every meaningful touch (call, email, internal note) in chronological order, date + 1-line summary.
- **Verbatim buyer signal**: the 5 most important things they said across the deal about priorities, our product, the competition, timeline, budget (speaker role + date).
- **Turning point**: the call or moment where sentiment, urgency, or engagement clearly shifted away — cite the specific signal (a quote, an attendee drop-off, a delayed response, a sudden new requirement).
- **Unresolved objections**: every objection NOT cleanly resolved before the loss (verbatim, dated).
- **Competitive context**: every competitor mention — when they first showed up, in what context, who raised them.
- **CRM reason vs. call reality**: contrast the dropdown reason with what buyers actually said; if they diverge, say so explicitly.

**Wave 2 — postmortem:**
1. Timeline summary (the deal arc in 5–7 sentences).
2. The turning point — when, what happened, the signal (with quote).
3. Verbatim "why they went elsewhere" (role + date).
4. Unresolved objections, ranked by likely impact on the loss.
5. Competitive context — who, when, how late, who let them in.
6. CRM reason vs. call reality — same or divergent?
7. The 3 do-overs — each tied to a specific moment in the timeline.

If a competitor showed up late (after stage 3), chase WHY they got the late look — it's almost always something WE did that opened the door. Full recipe + variations — `prompts/win-loss-deal-postmortem/why-we-lost-this-deal.md`.
