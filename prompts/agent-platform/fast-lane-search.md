# Fast lane — `search.query`, mode `fuzzy`

**What this does**: Answers one concrete question about your data in a single **synchronous** call — "how many open deals over $50K?", "which accounts went quiet in the last 14 days?" — and returns the matching rows plus the **exact SQL** it ran. This is the developer view (REST + MCP payloads) of the [quick lookup](../pipeline-pulse/quick-lookup-fast-lane.md) prompt recipe.

**When to use it**: You want a number or a short list *right now*, from your own code or an agent turn, and you want to hand the answer back without waiting on a multi-step investigation. If the ask is "figure out *why* X across the whole pipeline," that's a [research job](#routing-and-research) instead, and the fast lane will tell you so via `escalate_to_chat` or a `research_offer`.

> **The endpoint changed.** This lane used to be its own operation, `search.run` at `POST /search`. It is now one lane of the routed `search.query` verb at `POST /search/query`, reached with `mode: "fuzzy"`. Same engine, same envelope — the envelope just rides on `detail` now. The old door is gone, not deprecated: `POST /search` returns 404. Two features went with it and have no replacement on this lane — see [What is gone](#what-is-gone).

## Why this matters

The fast lane is the one door that **blocks and returns the answer**. It turns your question into SQL over your tenant's warehouse, runs it through the same tenant-scoped, access-checked query gate everything else uses, and returns the rows **and the query** in one response — so the answer is immediate and the SQL is the receipt. It's also **frictionless by construction**: past input validation it never throws and never returns a raw error. Every failure mode — an unsupported ask, a SQL miss, zero rows, a part of a multi-intent ask that ran out of time — comes back as a typed field on a `success` response, so your integration reads fields instead of catching exceptions. The whole call is bounded under a hard ceiling, so a partial answer always beats a 500.

## The operation

| | |
|---|---|
| Operation | `search.query` |
| REST | `POST /search/query` |
| MCP | `search_customers` |
| Scope | `data:read` |

One verb, three lanes. `mode: "fuzzy"` is this one; the siblings are [structured search](structured-search.md) (`filter`) and [semantic search](semantic-search.md) (`semantic`). Omit `mode` and an auto-router picks; pass it and your choice always wins.

## Request

`query` is the only required field.

| Field | Type | Default | Notes |
|---|---|---|---|
| `query` | string | — (required) | the ask, in plain language |
| `mode` | `auto` \| `fuzzy` \| `filter` \| `semantic` | `auto` | pass `fuzzy` to pin this lane |
| `limit` | int | `50` | row cap |
| `max_subqueries` | int | `3` | how many parts a multi-intent ask may split into (sync cap `5`) |
| `async` | bool | `false` | return a job handle instead of blocking — see [Broad asks](#broad-asks) |
| `job_id` | string | — | poll a handle from a previous `async` call |
| `route` | `auto` \| `search` \| `research` | `auto` | pass `research` to start a research job, or `search` to stay on a search lane. See [Routing and research](#routing-and-research) |
| `from_query_id` | string (UUID) | none | REST: the `query_id` of the earlier answer whose `research_offer` you are taking. Send it with `route: "research"` |
| `research_id` | string (UUID) | none | poll a research job this call started. Needs `conversations:read` |

**REST:**

```
POST /search/query
Authorization: Bearer <api-key with data:read>
Content-Type: application/json

{
  "query": "How many open opportunities over $50K ACV have had no meaningful touch in the last 14 days? List deal name, ACV, owner, and last-touch date, newest activity first.",
  "mode": "fuzzy",
  "limit": 50
}
```

**MCP** (`search_customers`):

```
search_customers
  query = "How many open opportunities over $50K ACV have had no meaningful touch in the last 14 days? List deal name, ACV, owner, and last-touch date, newest activity first."
  mode  = "fuzzy"
  limit = 50
```

## Response — the envelope

Success is always a `success: true` object. The rows are at the top level; the fast lane's full envelope is on `detail`.

```json
{
  "success": true,
  "mode_ran": "fuzzy",
  "results": [
    { "deal_name": "Netflix", "deal_amount": 84000, "owner": "Sam Rivera", "last_touch_at": "2026-06-02" }
  ],
  "compiled": {
    "sql": "SELECT deal_name, deal_amount, owner, last_touch_at FROM interactions WHERE ..."
  },
  "corpus": { "row_count": 12, "surface": "interactions", "filters_applied": false },
  "timing": { "total_ms": 4120, "plan_ms": 1714, "fan_out_ms": 2280 },
  "detail": {
    "internal": {
      "status": "ok",
      "sql": "SELECT deal_name, deal_amount, owner, last_touch_at FROM interactions WHERE ...",
      "explanation": "Open opportunities over $50K ACV with no interaction in 14 days.",
      "rows": [ /* ... */ ],
      "row_count": 12,
      "truncated": false,
      "cached": false,
      "repaired": false
    },
    "uncovered": [],
    "message": "12 open deals over $50K with no touch in 14 days.",
    "escalate_to_chat": false
  }
}
```

The load-bearing fields:

- **`detail.internal.status`** — `ok` | `empty` | `unsupported` | `failed`. This is your control flow, not an exception. `ok` = rows returned. `empty` = the query ran and matched nothing (often a too-narrow filter) — an honest zero, and a real answer. `unsupported` = the ask does not fit a single query (`escalate_to_chat` will be `true`). `failed` = the SQL could not be produced or run even after one self-repair round.
- **`compiled.sql`** — the exact query it ran. The receipt: skim it before you quote the number. Read it here, not at `detail.internal.sql`: every lane sets `compiled.sql`, while `detail` is the fuzzy lane's envelope and is absent on a `filter` run. The two carry the same string when both are present.
- **`detail.internal.truncated`** — `true` when the row set hit `limit`. A metric computed over a truncated set is a metric over an arbitrary slice — narrow the filter or raise `limit` instead of trusting it.
- **`detail.uncovered`** — parts of a multi-intent ask that produced no answer, each with a reason (`breadth_cap`, `deadline`, `planner_incomplete`). **An empty array is the only thing that means full coverage.** A non-empty one means the answer you got is real but partial.
- **`detail.retry_guidance`** — present when something was missed: the remedy as a parameter to set (`raise_max_subqueries` / `run_async` / `narrow_query`) rather than a hint to interpret.
- **`corpus`** — which store answered, over how many rows, whether your filters ran, and why an empty is empty.
- **`timing`** — `total_ms` plus this lane's phase split (`plan_ms` / `fan_out_ms` / `coverage_ms`), so a slow call is attributable without guessing.
- **`detail.message`** — a one-line plain-language summary, always safe to show a user; never a raw error string.
- **`detail.escalate_to_chat`**: see [Routing and research](#routing-and-research). The field keeps its old name.

**The only `success: false` shape is input validation / routing / quota:**

```json
{ "error": { "code": "invalid_argument", "message": "Provide a `query`, `filters`, or a `group_by`+`metrics` aggregation." } }
```

## <a id="broad-asks"></a>Broad asks — raise the breadth, or go async

A multi-part ask is split into sub-questions that run in parallel. `max_subqueries` bounds how many (default `3`, up to `5` synchronously). Past that, the synchronous budget is the constraint, not the breadth — so `async: true` returns a handle immediately and runs the whole thing on a far larger budget:

```
POST /search/query
{ "query": "<a five-part ask>", "async": true, "max_subqueries": 12 }
->  { "success": true, "job": { "job_id": "sj_...", "status": "queued", "poll": "Not finished yet..." } }

# collect by calling the same verb with just the handle:
POST /search/query  { "job_id": "sj_..." }
```

Job results are kept for a limited time; re-run the query if a handle has expired.

## <a id="routing-and-research"></a>Routing and research

Chat is retired: `POST /chat` and the other Chat routes now answer `410` with `error.code: "gone"`. For one question and one cited answer, use a research job. `search.query` routes each ask to a search lane or to research, and tells you which.

**A successful answer carries the route** as `routing`, with a `query_id` you can quote later:

```json
{
  "success": true,
  "mode_ran": "fuzzy",
  "query_id": "6b1f0f0e-...",
  "routing": { "route": "research", "reason": "deal_facts", "signals": ["last contact"] },
  "research_offer": { "reason": "This asks about deal facts, such as last contact or close date. Research can check them across your deals." }
}
```

- **`routing.route`**: `search`, `research` or `both` (a written answer such as a prep needs both).
- **`routing.reason`**: one of `structured`, `explicit`, `recipe`, `written_answer`, `statistical`, `deal_facts`, `counts`, `comparison`, `cause`, `multi_step`, `long_query`, `what_was_said`, `plain`. What people said stays on search. Deal facts, counts, comparisons, causes and multi-step asks need research.
- **`routing.signals`**: the words or patterns that led to the choice.

**Pick the route yourself with `route`:**

- **`route: "search"`** stays on a search lane whatever the ask says.
- **`route: "research"`** hands the query to a research job, on every workspace. The answer has `mode_ran: "research"`, no rows, and `research: { research_id, chat_id, status, poll }`.
- **`route: "auto"`** (the default) reads the ask. On a workspace that has search-to-research routing on, the server starts the job itself. Where it is off, the search runs and the answer carries a `research_offer`. A query longer than a search lane reads also goes to research.

**`research_offer`** is `{ reason }`: one plain sentence on why research could answer better. It appears only on a `route: "auto"` search answer. To take the offer, send the same question with `route: "research"` and `from_query_id` set to the answer's `query_id`.

**Read the job** with `GET /research/{research_id}` (add `?wait_ms=45000` to block until it settles), MCP `get_research`, or `POST /search/query` with only `research_id`. The body has `status` (`running`, `needs_input`, `complete`, `failed` or `canceled`) and, once complete, `answer` with `text`, `content_blocks` and `follow_ups`.

```
POST /search/query
{ "query": "Which objections come up before a deal stalls in security review?", "route": "research" }
->  { "success": true, "mode_ran": "research", "results": [],
      "research": { "research_id": "...", "chat_id": "...", "status": "running",
                    "poll": "Poll GET /research/:id (add ?wait_ms=<ms>, max 45000, to block until it settles)." } }

GET /research/{research_id}?wait_ms=45000
->  { "research_id": "...", "status": "complete", "answer": { "text": "...", "partial": false, "follow_ups": [] } }
```

**Notes on a handoff:**

- A handoff from `search.query` starts the job without clarifying questions. Start one yourself with `POST /research` (MCP `start_research`) if you want to answer them. That start is deprecated in favour of `route: "research"`, and removal is not before 2026-11-23.
- A job spends the workspace's monthly research cap. A repeat of a question the workspace already had answered returns the finished job (`cache_hit: true`) and spends nothing.
- A credential that cannot start a job (it needs `conversations:write`), or a quota or setup refusal, does not fail the call. The search runs and a note says why.
- `from_query_id` is not a parameter of the MCP `search_customers` tool. `route` is.

**The fast lane's own escalation.** When the question needs decomposition or a "why," the lane returns `detail.internal.status: "unsupported"` and `detail.escalate_to_chat: true` rather than forcing a bad SQL answer. The field keeps its old name. `detail.escalate_reason` says why, and for a part the lane could not answer it points to research. Treat the flag as the signal to send the same question with `route: "research"`.

```
POST /search/query  { "query": "Why are our enterprise deals stalling at security review this quarter?" }
->  { "detail": { "internal": { "status": "unsupported" }, "escalate_to_chat": true } }

# then, the same question, as a research job:
POST /search/query  { "query": "Why are our enterprise deals stalling at security review this quarter?", "route": "research" }
```

## <a id="what-to-ask-next"></a>What to ask next: `GET /search/suggestions`

One read returns the questions worth asking next, as ready-made recipes. Scope `data:read`. Over MCP it is the resource `suggestions://current`.

```json
{
  "for_you": [
    { "recipe_id": "stalled-deals", "kind": "try", "reason": "3 deals stuck in Proposal for 30+ days", "fills": {} }
  ],
  "library": [ { "id": "stalled-deals", "title": "...", "route": "research", "search": { "question": "..." } } ],
  "generated_at": "2026-11-18T09:00:00.000Z"
}
```

- **`for_you`**: up to 4 recipes ranked for the caller. Each is `{ recipe_id, kind, reason, fills }`. `kind` is `used` (the caller ran it), `team` (the team runs it) or `try` (the workspace's data says it is worth a look). `reason` is a plain sentence.
- **`library`**: every recipe. Each has `id`, `title`, `blurb`, `category`, `needs` (the data it reads), `route` (`search`, `research` or `both`) and `search.question`, the text to send to `search.query`. A `{key}` in the question is filled from the recipe's `fills`.
- **`pending: true`**: the workspace's data rows are still being worked out. Read again in a few seconds.
- **`setup_needed`**: present only when no data source is connected. It carries a message and a link for the user.
- **`hidden_recipe_ids`**: recipes the caller hid for 30 days. Present only when there are some.
- **A new workspace** with nothing to rank and no runs gets four featured recipes.

Send a recipe's question to `search.query` with `recipe_id` set to the recipe's id. The server then counts the run for that recipe. It stores no question text with it. A `recipe_id` that is not in the library is refused with a `400`.

## <a id="what-is-gone"></a>What is gone

Two features of the old `search.run` were removed with it, and neither has a drop-in replacement on this lane:

- **`mode: "blended"`**: the web + news fan-out that returned `external` citations alongside your rows, plus `external_limit`, `external_omitted` and `sources_timed_out`. For synchronous market signal, call `external_search.execute` directly; for a market question answered *in context with your data*, start a [research job](#routing-and-research).
- **`synthesize: true`** and the `synthesis` block: the one-paragraph headline over the rows. For a short cited answer over the rows, send `answer: true`. `detail.message` still gives you the one-line summary.

## Paste this into Claude

The MCP-native version of the same lookup — Claude picks `search_customers` for you:

```
Fast lookup, not a deep investigation — use the synchronous search over our data and return the answer in one pass.

Question: {e.g. "How many open opportunities over $50K ACV have had no meaningful touch in the last 14 days? List deal name, ACV, owner, and last-touch date, newest activity first."}

Return the matching rows AND the SQL you ran. If the result hit the row cap, say so and tell me the filter to narrow it. If any part of my question went unanswered, name that part rather than presenting the rest as complete. If this really needs a multi-step investigation, say so instead of forcing a lookup.
```

## Variations

- **Bigger list**: raise `limit`. A genuinely large export is a job for a Page, not a lookup.
- **Broader question**: raise `max_subqueries`, or set `async: true` for the parts a synchronous budget cannot cover.
- **Read-only key**: this lane needs only `data:read`, so a `mcp_read_only` key can run it.

## Tips

- **Branch on `detail.internal.status`, not on exceptions.** The contract is: past validation, always `success: true` with a typed status. Treat `unsupported` + `escalate_to_chat` as the signal to switch doors, not as an error.
- **The SQL is the trust.** Every answer returns the query it ran. Skim it before you put the number in a forecast.
- **`truncated: true` means "arbitrary slice."** Don't aggregate over a truncated row set — narrow the filter or raise the cap.
- **Check `uncovered` before you report the answer as complete.** A partial answer is still a real answer; presenting it as the whole one is the failure mode this field exists to prevent.

## See also

- [Quick lookup (fast lane)](../pipeline-pulse/quick-lookup-fast-lane.md) — the paste-ready prompt version of this door.
- [Routing and research](#routing-and-research): where an `escalate_to_chat` ask goes to get finished.
- The sibling lanes of the same verb: [Structured search](structured-search.md) (typed filters + aggregations instead of prose) and [Semantic search](semantic-search.md) (meaning over the call corpus).
- [Agent platform overview](README.md) — the doors, the scopes, the surface.
