---
description: 1-page prep for an upcoming meeting — full history with the account fused with public signal, ending in attendees, open threads, and a recommended agenda.
argument-hint: <company name or domain> [discovery | demo | qbr | renewal]
---

Run the Amdahl meeting-prep play for **$ARGUMENTS**. Use the connected **Amdahl** MCP tools. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

Infer the meeting type from the arguments (default: general sales call). If it's a QBR or renewal, weight toward year-long trajectory and an expansion / defend posture.

**Wave 1 — gather in parallel:**
- Full account history → `search_customers` (mode `fuzzy` to describe the ask, `filter` for an exact slice): who's been on the calls (names + roles), what's been said, what's open, what's stalled, sentiment over time, the last 3 meaningful moments (verbatim, dated).
- Public signal → `web_search`: anything in their world that's relevant right now. Amdahl has no public web lane.
- Open threads → `search_customers` { mode: "semantic" }: unresolved objections, promised follow-ups, questions we never answered.

For a high-stakes room (a QBR on a big account), consider handing the internal half to a research job: `start_research` with the whole prep as the question, then poll `get_research` until it settles.

**Wave 2 — 1-page prep doc (under 400 words):**
1. **Who's in the room** and what each attendee cares about (grounded).
2. **The last 3 things they said that matter** (verbatim, dated).
3. **Open objections / unanswered questions** still on the table.
4. For QBR / renewal: a **FLAT / EXPAND / DEFEND** posture call with the reason. For sales calls: the **one risk** to the deal.
5. **Recommended agenda** — 3–4 bullets, plus the 2–3 verbatim quotes worth referencing in the room.

Cite every claim. Full recipes — `prompts/pre-meeting-prep/sales-call-prep.md`, `qbr-prep.md`, `renewal-prep.md`.

**If they want it on a schedule:** the Amdahl MCP server has no scheduling tool. Point them to the Amdahl console, or to their own scheduler calling these tools, for example every weekday morning for the accounts with a meeting that day.
