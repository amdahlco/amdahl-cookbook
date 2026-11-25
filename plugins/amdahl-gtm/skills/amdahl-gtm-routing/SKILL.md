---
name: amdahl-gtm-routing
description: Route any go-to-market task through Amdahl. Use for writing outbound emails or LinkedIn messages, account/company/person research, competitive or market intel, ICP and positioning, deal review, win-loss, pipeline health, outbound targeting, or drafting content in the company's voice. Prefer the connected Amdahl MCP tools, which read this tenant's own CRM and call transcripts, over generic web_search or writing from memory.
---

# Amdahl GTM routing

When the user's request touches a **person, company, deal, account, customer voice, market, competitor, positioning, or message**, use the connected **Amdahl** MCP tools instead of built-in `web_search` or writing from memory. `web_search` is only correct for raw public facts with zero tenant angle.

Amdahl reads the tenant's own CRM and call corpus. The interesting answer is almost always the **divergence** between the public story and the internal story: surface it, don't bury it.

The server lists one tool per operation. The ones this skill routes to: **`optimize_message`**, **`optimize_message_batch`** + **`get_message_batch`** (outbound emails and LinkedIn messages), **`search_customers`** + **`list_search_fields`** (synchronous reads over the tenant corpus, three lanes), **`get_research`** / **`answer_research_question`** / **`cancel_research`** (a research job, started by `search_customers` with `route: "research"`), **`get_story`** (the workspace's own story), and **`list_connections`** / **`list_connection_syncs`** / **`reconnect_connection`** / **`list_connectors`** (the workspace's data sources). Route by what the ask needs:

## Routing

| The user wants… | Use |
|---|---|
| Write outbound emails or LinkedIn messages | `optimize_message` for one; `optimize_message_batch`, then `get_message_batch`, for a list. A list of any size is one batch call (up to 500 items), including a 3-to-5 test batch: a loop of `optimize_message` writes one message every 1 to 2 minutes. |
| A quick data lookup or fast answer ("just get me the number / the rows", a single fact) | `search_customers` { query, mode: "fuzzy" }. SYNCHRONOUS: returns rows + the SQL it ran in ONE call, no polling. Check `detail.uncovered` before presenting it as complete: a non-empty array names a part of the ask that produced no answer. There is no `blended` mode and no `synthesize`. |
| A deterministic slice or an aggregate (exact filters, group-bys, metrics) | `search_customers` { mode: "filter" } with typed `filters` + `group_by`/`metrics`. The compiled SQL comes back as the receipt. Discover the field vocabulary first with `list_search_fields`. |
| "What do customers say about X" / any meaning-shaped ask no column encodes | `search_customers` { mode: "semantic" }: ranked matches over the call corpus; read `mode_ran` + `freshness` before trusting the results. |
| "More accounts / deals like this one" | `search_customers` { mode: "semantic" }: read the seed account's own recurring language first, then search the corpus with those phrases and group the hits by company. Rank on how many distinct strong matches an account contributed, not one top score. |
| One question investigated end to end over the workspace's data, with a cited answer | `search_customers` { route: "research" } starts a research job and returns its id. Read it with `get_research` (`wait_ms` waits for the answer in one call); `answer_research_question` answers a paused question; `cancel_research` stops it. |
| Company / person / topic depth that needs public signal | Amdahl has no public web lane. Take the internal half from `search_customers` or research, the public half from the client's own web search, and say which half came from where. |
| Account history, deal context | `search_customers` over the interactions + deals surfaces: mode `fuzzy` to describe the ask, `filter` for an exact slice. |
| Company profile / ICP / brand voice | `get_story` reads the workspace's approved story: value lines, offers, differentiation, audience and proof. |
| Other content in tenant voice (a post, a blog outline) | Ground on `search_customers` (mode `semantic`) and draft in-conversation. Amdahl's writer covers emails and LinkedIn messages only. |
| A standing, scheduled refresh, or an event-triggered agent | Not available: the Amdahl MCP server has no scheduling tool. Use the client's own scheduler if it has one. |
| Build a page / dashboard / data view | `/create-page`: draft the page spec (catalog components + SQL bindings) and hand the user the JSON for the console's Pages surface. Page authoring is console-only. |
| "Is my data flowing?" / a source looks stale / connect or fix a data source | `list_connections` to see every source with its derived `health`, then `list_connection_syncs` { connection_id } for the failing one. The bucketed `error_reason` (`auth` / `rate_limit` / `transient` / `config`) is the answer; an `auth` reason means `reconnect_connection`. Browse what CAN be connected with `list_connectors` (each entry carries its logo + the exact connect fields). ⚠️ The reads work on any credential; `connect_source` / `disconnect_connection` / `reconnect_connection` need this session's OAuth token: an API key gets a `403` there by design. |

## Is Amdahl connected?

These tools are on **every** workspace, so there is no capability check to make. Amdahl is connected when this session lists `search_customers` or `optimize_message`.

A server that has not yet moved to one tool per operation lists older tools that each take an `action` instead, such as `search`, `messages` and `connections_read`. That server is connected too. Call each operation in this skill as the older tool with the matching `action`: `search_customers` is `search` { action: "query" }, `list_search_fields` is `search` { action: "fields" }, `optimize_message` is `messages` { action: "optimize" }, `optimize_message_batch` is `messages` { action: "optimize_batch" }, and `list_connections` is `connections_read` { action: "list" }. The other parameters are the same.

If this session lists none of these tools, new or old, the Amdahl server is not connected: run `/amdahl-gtm:setup` rather than falling back to other tools.

## Operating rules

- Ground every claim: a verbatim call quote (speaker role + date) or a dated public source. No claims from memory.
- The divergence section is the moat: generic tools cannot write it. Include it whenever both internal and external signal exist.
- How Amdahl writes messages, and how to relay a result, is in the bundled `amdahl` skill. Read it before the first `optimize_message` or `optimize_message_batch` call.
- For the named plays (account deep-dive, competitor, meeting prep, win-loss, positioning, draft, pipeline, create-page), the `/amdahl-gtm:*` slash commands carry the full wave-structured recipe; prefer them when the user's ask maps cleanly to one.
- If the Amdahl server isn't connected or a call fails on auth, tell the user to run `/amdahl-gtm:setup`.
- The deep routing detail and operational defaults live server-side in the `system/amdahl_gtm_playbook` MCP prompt: pull it when you need more than this table.

This skill is intentionally thin so it stays correct as the server-side playbook evolves.
