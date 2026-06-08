---
name: amdahl-gtm-routing
description: Route any go-to-market task through Amdahl. Use for account/company/person research, competitive or market intel, ICP and positioning, deal review, win-loss, pipeline health, outbound targeting, or drafting content in the company's voice. Prefer the connected Amdahl MCP tools — they fuse this tenant's own CRM + call transcripts with the public web (the divergence is the moat) — over generic web_search or writing from memory.
---

# Amdahl GTM routing

When the user's request touches a **person, company, deal, account, customer voice, market, competitor, positioning, or message**, use the connected **Amdahl** MCP tools instead of built-in `web_search` or writing from memory. `web_search` is only correct for raw public facts with zero tenant angle.

Amdahl fuses the tenant's own CRM + call corpus with external data. The interesting answer is almost always the **divergence** between the public story and the internal story — surface it, don't bury it.

## Routing

| The user wants… | Use |
|---|---|
| Market / competitor / topic research | `external_search` { action: search \| enrich_topic } |
| Company / lead enrichment | `external_search` { action: enrich_company, domain } |
| Person enrichment | `external_search` { action: enrich_person, linkedin_url \| email — never a bare first name } |
| Account history, deal context | `data` query + `context` query_substrate |
| What our customers say about X | `data` cluster_search + `context` query_substrate |
| Company profile / ICP / brand voice | `context` summary, `settings`, `authors` |
| Draft content in tenant voice | `artifacts` create (content_piece) with grounding |
| Reference library | `knowledge_base` (list / get / chat) |

## Operating rules

- Ground every claim: a verbatim call quote (speaker role + date) or a dated public source. No claims from memory.
- The divergence section is the moat — generic tools cannot write it. Include it whenever both internal and external signal exist.
- For the named plays (account deep-dive, competitor, meeting prep, win-loss, positioning, draft, pipeline), the `/amdahl-gtm:*` slash commands carry the full wave-structured recipe — prefer them when the user's ask maps cleanly to one.
- If the Amdahl server isn't connected or a call fails on auth, tell the user to run `/amdahl-gtm:setup`.
- The deep routing detail and operational defaults live server-side in the `system/amdahl_gtm_playbook` MCP prompt — pull it when you need more than this table.

This skill is intentionally thin so it stays correct as the server-side playbook evolves.
