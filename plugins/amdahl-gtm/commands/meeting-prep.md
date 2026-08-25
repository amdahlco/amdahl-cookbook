---
description: 1-page prep for an upcoming meeting — full history with the account fused with public signal, ending in attendees, open threads, and a recommended agenda.
argument-hint: <company name or domain> [discovery | demo | qbr | renewal]
---

Run the Amdahl meeting-prep play for **$ARGUMENTS**. Use the connected **Amdahl** MCP tools. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

Infer the meeting type from the arguments (default: general sales call). If it's a QBR or renewal, weight toward year-long trajectory and an expansion / defend posture.

**Wave 1 — gather in parallel:**
- Full account history → `search` { action: query } (mode `fuzzy` to describe the ask, `filter` for an exact slice): who's been on the calls (names + roles), what's been said, what's open, what's stalled, sentiment over time, the last 3 meaningful moments (verbatim, dated).
- Public signal → `agents` { action: start_chat }: anything in their world that's relevant right now. Start it FIRST and poll while you run the corpus gathers — it is the slow leg.
- Open threads → `search` { action: query, semantic }: unresolved objections, promised follow-ups, questions we never answered.

For a high-stakes room (a QBR on a big account), consider escalating the whole prep to `agents` { action: start_chat } instead — one server-side investigation, polled to completion. *Pre-rollout fallback:* on a legacy session, use `data` query + `context` query_substrate and `external_search` { action: enrich_company }.

**Wave 2 — 1-page prep doc (under 400 words):**
1. **Who's in the room** and what each attendee cares about (grounded).
2. **The last 3 things they said that matter** (verbatim, dated).
3. **Open objections / unanswered questions** still on the table.
4. For QBR / renewal: a **FLAT / EXPAND / DEFEND** posture call with the reason. For sales calls: the **one risk** to the deal.
5. **Recommended agenda** — 3–4 bullets, plus the 2–3 verbatim quotes worth referencing in the room.

Cite every claim. Full recipes — `prompts/pre-meeting-prep/sales-call-prep.md`, `qbr-prep.md`, `renewal-prep.md`.

**Offer to automate it:** after delivering the prep, offer to make this happen before *every* meeting — a Subscription (`agents` { action: create_subscription }, kind `calendar.event_upcoming`) fires this same prep a chosen lead time before each event on a connected Google Calendar. Read { action: list_subscription_kinds } for the config fields; the user needs a `google_calendar` connection (Connections → Google Calendar).
