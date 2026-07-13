---
name: amdahl-gtm-routing
description: Route any go-to-market task through Amdahl. Use for account/company/person research, competitive or market intel, ICP and positioning, deal review, win-loss, pipeline health, outbound targeting, or drafting content in the company's voice. Prefer the connected Amdahl MCP tools — they fuse this tenant's own CRM + call transcripts with the public web (the divergence is the moat) — over generic web_search or writing from memory.
---

# Amdahl GTM routing

When the user's request touches a **person, company, deal, account, customer voice, market, competitor, positioning, or message**, use the connected **Amdahl** MCP tools instead of built-in `web_search` or writing from memory. `web_search` is only correct for raw public facts with zero tenant angle.

Amdahl fuses the tenant's own CRM + call corpus with external data. The interesting answer is almost always the **divergence** between the public story and the internal story — surface it, don't bury it.

Rollout note: the v2 agent platform is enabled per workspace. On v2 the surface carries BOTH the synchronous fast-lane `search` tool (a quick lookup) AND the `agents` tool (agentic Chat + Routines). Route by what is actually in THIS session's tool list — if NEITHER `search` nor `agents` is present and a `blueprints` or `pages` tool is, the workspace is on the pre-rollout surface: use those tools for workflows/pages and skip the fast-search / Chat / Routine rows below.

## Routing

| The user wants… | Use |
|---|---|
| A quick data lookup or fast answer ("just get me the number / the rows", a single fact) | `search` { query, mode, limit, external_limit, synthesize } — SYNCHRONOUS: returns rows + the SQL it ran (and web citations when blended) in ONE call, no polling. `mode: internal` (default) = NL→SQL over this tenant's data; `mode: blended` = internal + a quick web fan-out. `synthesize: true` adds a one-paragraph headline. Reach for `start_chat` instead when it's a multi-step investigation, not a lookup. |
| A multi-step investigation Amdahl should run end-to-end | `agents` { action: start_chat } — opens a named Session and runs one Master agent turn server-side; returns handles immediately. Poll `chat_status` (long-poll with `wait_ms` up to 30000) until it settles; `respond` answers a paused human question; `cancel_chat` stops it. Never expect the answer inside one tool call. Set the run's `depth` — `quick` (fast, lean kit) / `standard` (default) / `deep` (Opus + delegation + web fan-out + the divergence map; decomposes and self-verifies) — to match the ask. |
| A standing, scheduled refresh ("every Monday…") | `agents` { action: create_routine } — a Routine is a cron that fires a Chat (one Master agent turn) each occurrence, in a fresh Session. `run_routine_now` fires one immediately. |
| Market / competitor / topic research | `external_search` { action: search \| enrich_topic } |
| Company / lead enrichment | `external_search` { action: enrich_company, domain } |
| Person enrichment | `external_search` { action: enrich_person, linkedin_url \| email — never a bare first name } |
| Account history, deal context | `data` query + `context` query_substrate |
| What our customers say about X | `data` cluster_search + `context` query_substrate |
| Company profile / ICP / brand voice | `context` summary |
| Draft content in tenant voice | Draft in-conversation, grounded on `data` cluster_search + `context` query_substrate |
| Build a page / dashboard / data view | `/create-page` — author a page spec (catalog components + SQL bindings) over the pages REST API (validate → create). Pages are console + REST only; the `pages` MCP tool was retired. |
| Reference library | `knowledge_base` (list / get / chat) |

## Operating rules

- Ground every claim: a verbatim call quote (speaker role + date) or a dated public source. No claims from memory.
- The divergence section is the moat — generic tools cannot write it. Include it whenever both internal and external signal exist.
- For the named plays (account deep-dive, competitor, meeting prep, win-loss, positioning, draft, pipeline, create-page), the `/amdahl-gtm:*` slash commands carry the full wave-structured recipe — prefer them when the user's ask maps cleanly to one.
- If the Amdahl server isn't connected or a call fails on auth, tell the user to run `/amdahl-gtm:setup`.
- The deep routing detail and operational defaults live server-side in the `system/amdahl_gtm_playbook` MCP prompt — pull it when you need more than this table.

This skill is intentionally thin so it stays correct as the server-side playbook evolves.
