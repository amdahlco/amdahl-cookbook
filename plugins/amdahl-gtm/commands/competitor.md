---
description: Competitor deep-dive — their public posture vs. how buyers actually describe them on our calls, with the divergences and the attack angles they imply.
argument-hint: <competitor name or domain>
---

Run the Amdahl "competitor deep-dive" play for **$ARGUMENTS**. Use the connected **Amdahl** MCP tools (CRM + calls fused with the public web), not generic `web_search`. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

**Wave 1 — gather in parallel:**
- Public posture → `agents` { action: start_chat }: their positioning, pricing posture, recent launches, funding, messaging, who they say they're for — and the divergence against what your buyers say about them.
- Call reality → `search` { action: query, mode: "semantic" } and `search` { action: query, mode: "fuzzy" }: every time this competitor comes up on our calls — who raised them, in what context (incumbent, active eval, late entrant), what buyers actually said about them. Pull verbatim quotes with role + date.
- Trend → `search` { action: query } with `group_by` over time: are they showing up earlier / later, more / less, in which segments?

If the synthesis needs real decomposition (many segments, long history), escalate to `agents` { action: start_chat } with the whole ask. *Pre-rollout fallback:* on a legacy session (`data` / `context` / `external_search` tools), use `external_search` { action: enrich_company or search }, `data` cluster_search + query.

**Wave 2 — synthesize:**
1. **Public posture** in 3 lines — how they sell themselves.
2. **Call reality** — how buyers actually describe them (3–5 verbatim quotes, role + date).
3. **The divergences** — where the marketing site and the buyer reality disagree. This is the useful part.
4. **Attack angles** — for each divergence, the specific counter-position it implies, grounded in a customer quote.
5. **Watch-list** — the one trend in how / where they show up that we should track.

Cite every claim. Full recipe + variations — `prompts/competitive-intel/competitor-deep-dive.md` (see also `where-they-show-up-in-our-calls.md` and `how-buyers-compare-us.md`).
