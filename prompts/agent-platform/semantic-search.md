# Semantic search — meaning over the call corpus

**What this does**: Finds the moments in your conversation data that **mean** what you asked, not the rows that literally match it — "what do customers say about onboarding friction", "complaints that sound like security review fatigue" — in one synchronous call. Matches come back ranked by similarity, with a `freshness` stamp telling you which index answered and how current it is.

**When to use it**: The thing you're looking for is a *concept*, and no column encodes it. Filters answer "rows WHERE stage = open"; semantic answers "utterances that sound like pricing pushback." It's the third lane of the routed `search.query` verb, beside [typed filters](structured-search.md) and the fuzzy NL→SQL lane.

## Why this matters

Content discovery over calls is exactly where literal filters fail: nobody's CRM has an `objection_flavor` column, and a `contains: "expensive"` filter misses "the CFO choked on the number." The semantic lane embeds your query and ranks your corpus by meaning. And you often don't even have to ask for it — `search.query`'s **auto-router** sends meaning-shaped wording ("say about", "themes around", "complaints like", "concerns", "frustrated with") to the semantic lane on its own, literal filter-only requests to the filter lane, and everything else to the fuzzy NL lane. The response always carries `mode_ran`, so you know which lane actually answered.

## The operation

| | |
|---|---|
| Operation | `search.query` (semantic lane) |
| REST | `POST /search/query` |
| MCP | `search` tool, action `query` |
| Scope | `data:read` |

## Request

```
POST /search/query
Authorization: Bearer <api-key with data:read>
Content-Type: application/json

{
  "query": "What do customers say about onboarding friction and time-to-value?",
  "mode": "semantic",
  "limit": 20
}
```

**MCP** (the `search` coarse tool, `query` action):

```
search query
  query = "What do customers say about onboarding friction and time-to-value?"
  mode  = "semantic"
  limit = 20
```

`mode: "semantic"` forces the lane. Under `mode: "auto"` (the default) this query routes semantic anyway — the wording is meaning-shaped — but force the mode when your integration depends on getting similarity matches back.

## Response — matches, `mode_ran`, and `freshness`

```json
{
  "success": true,
  "mode_ran": "semantic",
  "results": [
    {
      "id": "e2b1…",
      "source_row_id": "utt_48213",
      "company_id": "1852…",
      "occurred_at": "2026-06-11T15:20:00Z",
      "speaker_type": "external",
      "content_preview": "honestly the rollout took longer than the eval — six weeks before the team saw value…",
      "similarity": 0.83
    }
  ],
  "freshness": { "source": "pgvector", "synced_at": "2026-07-21T04:12:09Z" },
  "timing": { "total_ms": 640, "embed_ms": 210 }
}
```

Read two fields before you use the results:

- **`mode_ran`** — which lane actually executed. If an auto-routed ask landed on `fuzzy`, you got SQL-derived rows (and `compiled.sql`), not similarity matches. Branch on this, don't assume.
- **`freshness.source`** — where the matches came from. `pgvector` = the fast vector mirror, with `synced_at` telling you how recently it was synced (a result can't contain a call from after that stamp). `bigquery` = the lane transparently fell back to the warehouse **theme index** — the results are then theme-level matches (`cluster_id`, `label`, `score`) rather than utterance-level rows. The fallback is honest coverage, not an error: it fires when the fast mirror isn't enabled or hasn't synced for your workspace yet.

## Combining a semantic query with filters

Semantic mode accepts a **narrow** filter set — enough to scope the similarity search without breaking it:

| Field | Operators |
|---|---|
| `company_id` | `eq`, `in` |
| `occurred_at` | `gte`, `gt`, `lte`, `lt`, `between` |
| `speaker_type` | `eq` |

"Customer-voice pricing pushback at these three accounts, this quarter":

```
POST /search/query
{
  "query": "pushback and hesitation about pricing or contract terms",
  "mode": "semantic",
  "filters": [
    { "field": "company_id", "op": "in", "value": ["1852…", "9b03…", "77aa…"] },
    { "field": "occurred_at", "op": "gte", "value": "2026-04-01" },
    { "field": "speaker_type", "op": "eq", "value": "external" }
  ],
  "limit": 25
}
```

Any other field or operator in semantic mode returns a typed `invalid_argument` naming the supported set — switch those predicates to the [filter lane](structured-search.md), or drop them. (Note the semantic lane's time field is `occurred_at`; the filter lane's `interactions` catalog calls the same event time `timestamp`.)

One more routing rule worth knowing: the **fuzzy** NL lane takes a free-text query *only* — structured `filters` can't ride along with it. If you send both and the router lands on fuzzy, you get a typed refusal telling you to fold the constraint into the question or use the filter/semantic lanes.

## Paste this into Claude

```
Meaning search over our call corpus — use the search tool's query action in
semantic mode, not a literal filter and not a SQL lookup.

Find: {e.g. "what customers say about onboarding friction and time-to-value"}.
Scope it to {external speakers | these companies | since {date}} using the
semantic-mode filters (company_id / occurred_at / speaker_type only).

Report which lane ran (mode_ran) and the freshness stamp (source + synced_at)
alongside the top matches, and quote the strongest 3 verbatim with their
similarity scores.
```

## Variations

- **Let the router decide**: send the query with `mode: "auto"` (or no mode). Meaning-shaped wording routes semantic on its own; check `mode_ran` to see where it landed.
- **Theme-level instead of utterance-level**: when you want "which *themes* sound like this" rather than individual moments, use [`lookalike` `themes`](lookalikes.md) — it's the theme-centroid version of the same idea.
- **Concept + hard slice**: run semantic with a `company_id in […]` filter to ask one question across a specific account list — the pattern the [expansion motion](expansion-motion-end-to-end.md) is built on.
- **Escalate when "find" becomes "explain"**: similarity finds the moments; it doesn't explain the trend. "Which of these themes are growing and why" is a [Chat](agentic-chat.md).

## Tips

- **Branch on `mode_ran`, not on hope.** Auto-routing is a convenience; integrations that need similarity matches should force `mode: "semantic"` and treat `mode_ran` as the confirmation.
- **`freshness` is the staleness contract.** Surface `synced_at` next to anything user-facing; if `source` is `bigquery`, render theme cards, not utterance quotes.
- **Similarity scores are ordinal, not calibrated.** Use them to rank within one response; don't compare absolute values across different queries.
- **Scope to `speaker_type: "external"` for customer voice.** Otherwise your own reps' phrasing ranks alongside the customers'.

## See also

- [Structured search](structured-search.md) — the typed-filter lane of the same door, and the full filter vocabulary.
- [Lookalikes](lookalikes.md) — centroid similarity over entities and themes (the "more like this one" siblings).
- [Fast lane — `search.run`](fast-lane-search.md) — the plain-language NL lane for countable asks.
- [Agent platform overview](README.md) — the flag prerequisite and the scope table.
