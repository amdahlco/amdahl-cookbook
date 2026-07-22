# Fast lane — `search.run`

**What this does**: Answers one concrete question about your data in a single **synchronous** call — "how many open deals over $50K?", "which accounts went quiet in the last 14 days?" — and returns the matching rows plus the **exact SQL** it ran. Optionally blends in a quick public web read. This is the developer view (REST + MCP payloads) of the [quick lookup](../pipeline-pulse/quick-lookup-fast-lane.md) prompt recipe.

**When to use it**: You want a number or a short list *right now*, from your own code or an agent turn, and you want to hand the answer back without waiting on a multi-step investigation. If the ask is "figure out *why* X across the whole pipeline," that's the [agentic Chat](agentic-chat.md) lane instead — and `search.run` will tell you so via `escalate_to_chat`.

## Why this matters

The fast lane is the one door that **blocks and returns the answer**. It turns your question into SQL over your tenant's `interactions` warehouse, runs it through the same tenant-scoped, access-checked query gate everything else uses, and returns the rows **and the query** in one response — so the answer is immediate and the SQL is the receipt. It's also **frictionless by construction**: past input validation it never throws and never returns a raw error. Every failure mode — an unsupported ask, a SQL miss, zero rows, a slow web source — comes back as a typed field on a `success` response, so your integration reads fields instead of catching exceptions. The whole call is bounded under a hard ceiling, so a partial answer always beats a 500.

## The operation

| | |
|---|---|
| Operation | `search.run` |
| REST | `POST /search` |
| MCP | `search` tool, action `run` |
| Scope | `data:read` |

## Request

`query` is the only required field.

| Field | Type | Default | Notes |
|---|---|---|---|
| `query` | string | — (required) | the ask, in plain language (1–2000 chars) |
| `mode` | `internal` \| `blended` | `internal` | `blended` also fans out a quick web + news read |
| `limit` | int | `50` | internal row cap, max `1000` |
| `external_limit` | int | `10` | blended citation cap, max `24` |
| `synthesize` | bool | `false` | opt into a one-paragraph headline over the rows |

**REST:**

```
POST /search
Authorization: Bearer <api-key with data:read>
Content-Type: application/json

{
  "query": "How many open opportunities over $50K ACV have had no meaningful touch in the last 14 days? List deal name, ACV, owner, and last-touch date, newest activity first.",
  "mode": "internal",
  "limit": 50
}
```

**MCP** (the `search` coarse tool, `run` action):

```
search run
  query = "How many open opportunities over $50K ACV have had no meaningful touch in the last 14 days? List deal name, ACV, owner, and last-touch date, newest activity first."
  mode  = "internal"
  limit = 50
```

## Response — the envelope

Success is always a `success: true` object. The shape:

```json
{
  "success": true,
  "query": "How many open opportunities over $50K ACV ...",
  "mode": "internal",
  "internal": {
    "status": "ok",
    "sql": "SELECT deal_name, deal_amount, owner, last_touch_at FROM interactions WHERE ...",
    "explanation": "Open opportunities over $50K ACV with no interaction in 14 days.",
    "rows": [
      { "deal_name": "Netflix", "deal_amount": 84000, "owner": "Sam Rivera", "last_touch_at": "2026-06-02" }
    ],
    "row_count": 12,
    "truncated": false,
    "cached": false,
    "repaired": false,
    "note": null
  },
  "external": null,
  "external_omitted": null,
  "synthesis": null,
  "message": "12 open deals over $50K with no touch in 14 days.",
  "escalate_to_chat": false
}
```

The load-bearing fields:

- **`internal.status`** — `ok` | `empty` | `unsupported` | `failed`. This is your control flow, not an exception. `ok` = rows returned. `empty` = the query ran and matched nothing (often a too-narrow filter). `unsupported` = the ask isn't a fast-lane SQL question (`escalate_to_chat` will be `true`). `failed` = the SQL couldn't be produced/run even after one self-repair round.
- **`internal.sql`** — the exact query it ran (or last attempted). The receipt: skim it before you quote the number. `null` only if the model declined to write SQL.
- **`internal.truncated`** — `true` when the row set hit `limit`. A metric computed over a truncated set is a metric over an arbitrary slice — narrow the filter or raise `limit` (max 1000) instead of trusting it.
- **`internal.cached`** / **`internal.repaired`** — served from the 1h query cache; and whether a self-repair round rewrote the SQL. Informational.
- **`message`** — a one-line plain-language summary, always safe to show a user; never a raw error string.
- **`escalate_to_chat`** — see below.

**The only `success: false` shape is input validation:**

```json
{ "error": { "code": "invalid_argument", "message": "query must be 1-2000 characters" } }
```

Unknown fields on the request are stripped, not rejected — only a malformed *known* field trips this.

## Blended mode — a quick public angle

`mode: "blended"` runs the same internal query **and** fans out a fast web + news read, returning citations alongside your rows.

```
POST /search
{
  "query": "How many of our open deals mention Competitor X, and what is Competitor X's latest public funding?",
  "mode": "blended",
  "external_limit": 8
}
```

The `external` block fills in:

```json
{
  "external": {
    "citations": [
      { "title": "Competitor X raises $40M Series B", "url": "https://...", "snippet": "...", "source": "news" }
    ],
    "sources_timed_out": [],
    "external_query_used": "Competitor X funding 2026"
  },
  "external_omitted": null
}
```

Two things to handle:

- **`external_omitted: "missing_scope"`** — your key lacks `external_search:execute`, so blended silently degraded to internal-only. The internal answer still came back; the web leg just didn't run.
- **`external_omitted: "not_relevant"`** — an intent gate judged the ask purely internal (e.g. "open deals by stage") and suppressed the web fan-out on purpose, so you don't get web noise stapled to a warehouse question. The gate fails open — on any doubt it runs the fan-out.
- **`external.sources_timed_out`** — a source missed its deadline. You get a partial `external`, never a 500. `internal` is unaffected.

## <a id="escalate-to-chat"></a>Escalate to Chat — the handoff

The fast lane knows its own limits. When the question needs decomposition, cross-source synthesis, or a "why," it returns `internal.status: "unsupported"` and `escalate_to_chat: true` rather than forcing a bad SQL answer. The right integration pattern is: **fire fast, and on escalation re-fire the same question as a Chat.**

```
POST /search  { "query": "Why are our enterprise deals stalling at security review this quarter?" }
->  { "internal": { "status": "unsupported", ... }, "escalate_to_chat": true,
      "message": "This needs a multi-step investigation — ask it as a Chat." }

# then, same question, agentic lane:
POST /chat    { "input": "Why are our enterprise deals stalling at security review this quarter?" }
->  { "chat_id": "...", "run_id": "...", "read_url": "...", "stream_url": "...", "resume_url": "..." }
```

See [Agentic Chat](agentic-chat.md) for the poll/stream loop that finishes the job.

## Paste this into Claude

The MCP-native version of the same lookup — Claude picks the `search` tool for you:

```
Fast lookup, not a deep investigation — use the synchronous search over our data and return the answer in one pass.

Question: {e.g. "How many open opportunities over $50K ACV have had no meaningful touch in the last 14 days? List deal name, ACV, owner, and last-touch date, newest activity first."}

Return the matching rows AND the SQL you ran. If the result hit the row cap, say so and tell me the filter to narrow it. If this really needs a multi-step investigation, say so instead of forcing a lookup.
```

## Variations

- **Just the number**: `synthesize: true` and read `synthesis` for a phrased one-paragraph takeaway on top of the rows.
- **Bigger list**: raise `limit` (max 1000). A genuinely large export is a job for a Page, not a lookup.
- **Read-only key**: `search.run` needs only `data:read`, so a `mcp_read_only` key can run it. Blended will just report `external_omitted: "missing_scope"`.

## Tips

- **Branch on `internal.status`, not on exceptions.** The contract is: past validation, always `success: true` with a typed status. Treat `unsupported` + `escalate_to_chat` as the signal to switch doors, not as an error.
- **The SQL is the trust.** Every internal answer returns the query it ran. Skim it before you put the number in a forecast.
- **`truncated: true` means "arbitrary slice."** Don't aggregate over a truncated row set — narrow the filter or raise the cap.

## See also

- [Quick lookup (fast lane)](../pipeline-pulse/quick-lookup-fast-lane.md) — the paste-ready prompt version of this door.
- [Agentic Chat](agentic-chat.md) — where an `escalate_to_chat` ask goes to get finished.
- The sibling endpoints, when you already know the shape of the answer: [Structured search](structured-search.md) (typed filters + aggregations instead of prose), [Semantic search](semantic-search.md) (meaning over the call corpus), [Tiered enrichment](tiered-enrichment.md) ("tell me about X" with a cached brief now), and [Lookalikes](lookalikes.md) ("more accounts like this one").
- [Agent platform overview](README.md) — the two doors, the flag prerequisite, the scope table.
