---
name: amdahl-gtm-routing
description: Route any go-to-market task through Amdahl. Use for account/company/person research, competitive or market intel, ICP and positioning, deal review, win-loss, pipeline health, outbound targeting, or drafting content in the company's voice. Prefer the connected Amdahl MCP tools — they fuse this tenant's own CRM + call transcripts with the public web (the divergence is the moat) — over generic web_search or writing from memory.
---

# Amdahl GTM routing

When the user's request touches a **person, company, deal, account, customer voice, market, competitor, positioning, or message**, use the connected **Amdahl** MCP tools instead of built-in `web_search` or writing from memory. `web_search` is only correct for raw public facts with zero tenant angle.

Amdahl fuses the tenant's own CRM + call corpus with external data. The interesting answer is almost always the **divergence** between the public story and the internal story — surface it, don't bury it.

The current surface is four tools: **`search`** (synchronous reads over the tenant corpus — three lanes), **`enrich`** (tiered company / person / topic intelligence), **`lookalike`** (similarity over the corpus), and **`agents`** (agentic Chat + the agent library + Routines). Route by what the ask needs:

## Routing

| The user wants… | Use |
|---|---|
| A quick data lookup or fast answer ("just get me the number / the rows", a single fact) | `search` { action: run, query, mode } — SYNCHRONOUS: returns rows + the SQL it ran (and web citations when `mode: blended`) in ONE call, no polling. `synthesize: true` adds a one-paragraph headline. |
| A deterministic slice or an aggregate (exact filters, group-bys, metrics) | `search` { action: query } with typed `filters` + `group_by`/`metrics` — the compiled SQL comes back as the receipt. Discover the field vocabulary first with `search` { action: fields }. |
| "What do customers say about X" / any meaning-shaped ask no column encodes | `search` { action: query, mode: semantic } — ranked matches over the call corpus; read `mode_ran` + `freshness` before trusting the results. |
| Company / lead enrichment | `enrich` { action: company, domain } — cached brief instantly; first-party evidence on a miss while the full brief rebuilds; `mode: "full"` to wait for the fused brief. |
| Person enrichment | `enrich` { action: person, linkedin_url \| email — never a bare name }. |
| Market / competitor / topic research | `enrich` { action: topic } for the fused market-vs-customers read. |
| "More accounts / deals like this one" | `lookalike` { action: find, seed } — centroid similarity over the tenant's own corpus. "Which themes does this angle land on" → `lookalike` { action: themes }. Honest `available: false` while centroids materialize — degrade to themes/semantic, don't invent. |
| A multi-step investigation Amdahl should run end-to-end | `agents` { action: start_chat } — opens a named Session and runs one Master agent turn server-side; returns handles immediately. Poll `chat_status` (long-poll with `wait_ms` up to 30000) until it settles; `respond` answers a paused question; `cancel_chat` stops it. Never expect the answer inside one tool call. Set `depth` — `quick` / `standard` (default) / `deep` (Opus + web fan-out + the divergence map) — to match the ask. |
| A standing, scheduled refresh ("every Monday…") | `agents` { action: create_routine } — a cron that fires a Chat each occurrence, in a fresh Session. `run_routine_now` fires one immediately. Mind `actions_allowed`: absent = ALL outbound actions allowed; name a list to narrow, `[]` to disable. |
| Account history, deal context | `search` { action: run } and { action: query } over the interactions + deals surfaces. |
| Company profile / ICP / brand voice | These live server-side — run the ask as a Chat (`agents` start_chat); the Master pulls the workspace context itself. |
| Draft content in tenant voice | Ground on `search` (semantic) + `lookalike` themes and draft in-conversation; for an on-voice draft or one that should persist, run it as a Chat (`write_outputs: true` lands a knowledge-base version the user promotes). |
| Build a page / dashboard / data view | `/create-page` — draft the page spec (catalog components + SQL bindings) and hand the user the JSON for the console's Pages surface. Page authoring is console-only. |
| Reference library (knowledge base) | Console capability. Feed it via a Chat/Routine with `write_outputs: true`; the user promotes in the console. |

## Legacy fallback (pre-rollout workspaces)

The v2 agent platform is enabled per workspace. If THIS session's tool list has none of `search` / `enrich` / `lookalike` / `agents` but does list `data` / `context` / `external_search` / `knowledge_base` (and possibly `blueprints` / `pages`), the workspace is on the pre-rollout surface. Route with those instead: `data` query + cluster_search for corpus reads, `context` query_substrate / summary for account context and voice, `external_search` (enrich_company / enrich_person / enrich_topic / search) for public signal, `knowledge_base` for the reference library, and the `blueprints` / `pages` tools for workflows and pages. Skip the Chat / Routine rows above; suggest the user ask their Amdahl admin about Agent Platform v2.

## Operating rules

- Ground every claim: a verbatim call quote (speaker role + date) or a dated public source. No claims from memory.
- The divergence section is the moat — generic tools cannot write it. Include it whenever both internal and external signal exist.
- For the named plays (account deep-dive, competitor, meeting prep, win-loss, positioning, draft, pipeline, create-page), the `/amdahl-gtm:*` slash commands carry the full wave-structured recipe — prefer them when the user's ask maps cleanly to one.
- If the Amdahl server isn't connected or a call fails on auth, tell the user to run `/amdahl-gtm:setup`.
- The deep routing detail and operational defaults live server-side in the `system/amdahl_gtm_playbook` MCP prompt — pull it when you need more than this table.

This skill is intentionally thin so it stays correct as the server-side playbook evolves.
