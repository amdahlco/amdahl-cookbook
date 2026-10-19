---
name: amdahl-gtm-routing
description: Route any go-to-market task through Amdahl. Use for account/company/person research, competitive or market intel, ICP and positioning, deal review, win-loss, pipeline health, outbound targeting, or drafting content in the company's voice. Prefer the connected Amdahl MCP tools — they fuse this tenant's own CRM + call transcripts with the public web (the divergence is the moat) — over generic web_search or writing from memory.
---

# Amdahl GTM routing

When the user's request touches a **person, company, deal, account, customer voice, market, competitor, positioning, or message**, use the connected **Amdahl** MCP tools instead of built-in `web_search` or writing from memory. `web_search` is only correct for raw public facts with zero tenant angle.

Amdahl fuses the tenant's own CRM + call corpus with external data. The interesting answer is almost always the **divergence** between the public story and the internal story — surface it, don't bury it.

The server lists one tool per operation. The ones this skill routes to: **`search_customers`** + **`list_search_fields`** (synchronous reads over the tenant corpus — three lanes), **`start_chat`** / **`get_chat_run`** / **`answer_chat_question`** / **`cancel_chat`** (agentic Chat), **`create_routine`** / **`run_routine_now`** (Routines), **`list_connections`** / **`list_connection_syncs`** / **`reconnect_connection`** / **`list_connectors`** (the workspace's data sources), and **`run_eval`** / **`get_eval_run`** (grade content against the corpus). Route by what the ask needs:

## Routing

| The user wants… | Use |
|---|---|
| A quick data lookup or fast answer ("just get me the number / the rows", a single fact) | `search_customers` { query, mode: "fuzzy" } — SYNCHRONOUS: returns rows + the SQL it ran in ONE call, no polling. Check `detail.uncovered` before presenting it as complete: a non-empty array names a part of the ask that produced no answer. There is no `blended` mode and no `synthesize` — public signal is a Chat. |
| A deterministic slice or an aggregate (exact filters, group-bys, metrics) | `search_customers` { mode: "filter" } with typed `filters` + `group_by`/`metrics` — the compiled SQL comes back as the receipt. Discover the field vocabulary first with `list_search_fields`. |
| "What do customers say about X" / any meaning-shaped ask no column encodes | `search_customers` { mode: "semantic" } — ranked matches over the call corpus; read `mode_ran` + `freshness` before trusting the results. |
| Company / person / topic depth, or anything needing public signal | `start_chat` — the Master holds the web fan-out and returns the market-vs-customers divergence read. There is no synchronous enrichment verb; a Chat is the door. ⚠️ This is the one gather that needs a WRITE scope (`conversations:write`) — the corpus rows above are all `data:read`. On a read-only key it will refuse: say so and deliver the corpus half rather than dropping the section silently. |
| "More accounts / deals like this one" | `search_customers` { mode: "semantic" } — read the seed account's own recurring language first, then search the corpus with those phrases and group the hits by company. Rank on how many distinct strong matches an account contributed, not one top score. |
| A multi-step investigation Amdahl should run end-to-end | `start_chat` — opens a named Session and runs one Master agent turn server-side; returns handles immediately. Poll `get_chat_run` (long-poll with `wait_ms` up to 30000) until it settles; `answer_chat_question` answers a paused question; `cancel_chat` stops it. Never expect the answer inside one tool call. Set `depth` — `quick` / `standard` (default) / `deep` (Opus + web fan-out + the divergence map) — to match the ask. |
| A standing, scheduled refresh ("every Monday…") | `create_routine` — a cron that fires a Chat each occurrence, in a fresh Session. `run_routine_now` fires one immediately. Mind `actions_allowed`: absent = ALL outbound actions allowed; name a list to narrow, `[]` to disable. |
| An event-triggered agent ("prep me before every calendar meeting", "when X happens, do Y") | Not available: Subscriptions are not on the Amdahl MCP server, and their only event source (Google Calendar) is retired, so none can fire. Offer a Routine (`create_routine`) on a cron instead, for example every weekday morning. |
| Account history, deal context | `search_customers` over the interactions + deals surfaces — mode `fuzzy` to describe the ask, `filter` for an exact slice. |
| Company profile / ICP / brand voice | These live server-side — run the ask as a Chat (`start_chat`); the Master pulls the workspace context itself. |
| Draft content in tenant voice | Ground on `search_customers` (mode `semantic`) and draft in-conversation; for an on-voice draft or one that should persist, run it as a Chat (`write_outputs: true` lands a knowledge-base version the user promotes). |
| Build a page / dashboard / data view | `/create-page` — draft the page spec (catalog components + SQL bindings) and hand the user the JSON for the console's Pages surface. Page authoring is console-only. |
| Reference library (knowledge base) | Console capability. Feed it via a Chat/Routine with `write_outputs: true`; the user promotes in the console. |
| "Is my data flowing?" / a source looks stale / connect or fix a data source | `list_connections` to see every source with its derived `health`, then `list_connection_syncs` { connection_id } for the failing one — the bucketed `error_reason` (`auth` / `rate_limit` / `transient` / `config`) is the answer; an `auth` reason means `reconnect_connection`. Browse what CAN be connected with `list_connectors` (each entry carries its logo + the exact connect fields). ⚠️ The reads work on any credential; `connect_source` / `disconnect_connection` / `reconnect_connection` need this session's OAuth token — an API key gets a `403` there by design. |

## Is Amdahl connected?

These tools are on **every** workspace — the per-workspace rollout flag that once gated them is retired, so there is no capability check to make. Amdahl is connected when this session lists `search_customers`, `start_chat` or `run_eval`.

A server that has not yet moved to one tool per operation lists ten older tools that each take an `action` instead: `search`, `messages`, `agents_read` / `agents_manage`, `evals_read` / `evals_manage`, `research_read` / `research_manage` and `connections_read` / `connections_manage` (older still: `agents`, `evals`, `research`, `connections`). That server is connected too. Call each operation in this skill as the older tool with the matching `action`: `search_customers` is `search` { action: "query" }, `list_search_fields` is `search` { action: "fields" }, `start_chat` is `agents_manage` { action: "start_chat" }, `get_chat_run` is `agents_read` { action: "chat_status" }, `create_routine` is `agents_manage` { action: "create_routine" }, `list_connections` is `connections_read` { action: "list" }, and `run_eval` is `evals_manage` { action: "run" }. The other parameters are the same.

If this session lists none of these tools, new or old, the Amdahl server is not connected: run `/amdahl-gtm:setup` rather than falling back to other tools.

## Operating rules

- Ground every claim: a verbatim call quote (speaker role + date) or a dated public source. No claims from memory.
- The divergence section is the moat — generic tools cannot write it. Include it whenever both internal and external signal exist.
- For the named plays (account deep-dive, competitor, meeting prep, win-loss, positioning, draft, pipeline, create-page), the `/amdahl-gtm:*` slash commands carry the full wave-structured recipe — prefer them when the user's ask maps cleanly to one.
- If the Amdahl server isn't connected or a call fails on auth, tell the user to run `/amdahl-gtm:setup`.
- The deep routing detail and operational defaults live server-side in the `system/amdahl_gtm_playbook` MCP prompt — pull it when you need more than this table.

This skill is intentionally thin so it stays correct as the server-side playbook evolves.
