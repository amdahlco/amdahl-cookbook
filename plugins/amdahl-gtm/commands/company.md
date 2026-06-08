---
description: 1-page account deep-dive — fuse our full internal history (deals, calls, support, contacts) with live public signal, ending on the divergence between the two and a recommended next step.
argument-hint: <company name or domain>
---

You are running the Amdahl "deep-dive on an account" play for **$ARGUMENTS**.

Use the connected **Amdahl** MCP tools — they fuse this tenant's own CRM + call transcripts with the public web. Prefer them over generic `web_search`; `web_search` is only for raw public facts with no tenant angle. If the Amdahl server isn't connected, stop and tell the user to run `/amdahl-gtm:setup` first.

**Disambiguate first.** If "$ARGUMENTS" is a nickname or an ambiguous name, resolve it to a domain (ask the user if unsure). If it's a giant multi-BU company, ask which division to focus on before you spend the calls.

**Wave 1 — gather in parallel:**
- Internal history → `data` query (the interactions corpus) + `context` query_substrate: every deal, call, support ticket, email, CRM note. Surface deal stage, ACV, who we've talked to (with roles), the last 3 meaningful things said on calls (verbatim, speaker + date), open objections, sentiment trajectory.
- Public signal (last 90 days first, last 12 months if thin) → `external_search` { action: enrich_company, domain }: funding, hiring patterns, product launches, leadership changes, M&A, regulatory / earnings news, public commentary from their execs.
- Adjacent mentions → `data` cluster_search / query: any time this company has come up on calls or notes from OTHER accounts — partners, customers, prospects mentioning them.

**Wave 2 — synthesize into ONE page (under 400 words), every section named:**
1. **Snapshot** — what they do, where they are in the buying journey with us, deal stage / status (3 lines).
2. **The 3 things they care about most** — each grounded in a verbatim call quote OR a specific public signal (cite which).
3. **The 2 risks I should know** — internal (champion drift, unresolved objection, sentiment shift) or external (funding pressure, leadership change, roadmap shift).
4. **Where public and internal stories DIVERGE** — the most valuable section. Anything they've told us that contradicts what they're doing publicly, or vice versa.
5. **Recommended next step** — one move, this week, with a reason.

Rules: cite every claim inline (call date + speaker, or news headline + date). No filler. If a section is thin, say so and name the follow-up query that would sharpen it rather than padding.

Full recipe (variations: prospect mode, multi-division, save play, board mention) — `prompts/customer-research/deep-dive-on-account.md`.
