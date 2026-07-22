# Structured search — typed filters over `search.query`

**What this does**: Slices your warehouse with **declarative, typed filters** instead of prose or hand-written SQL — "open deals over $50K, largest first", "external-speaker utterances at Acme in June", "deal count + total amount by stage" — in one synchronous call. You send `filters: [{field, op, value}]` against a discoverable field catalog; Amdahl compiles them into one tenant-scoped query and returns the rows **and the compiled SQL**.

**When to use it**: You know exactly which fields and conditions you want, and you want a deterministic result — no model interpreting your wording. It's the config-DSL lane of the routed `search.query` verb: same door as [semantic search](semantic-search.md), different lane. If your ask is plain language rather than predicates, use [`search.run`](fast-lane-search.md) (the NL lane) or let `search.query`'s auto-router pick.

## Why this matters

The fast lane (`search.run`) is great when a model should interpret your question — but interpretation is the part you sometimes don't want. A dashboard tile, a nightly job, or an agent step that must return the *same* slice every run needs predicates, not prose. The filter lane is that: every field name is validated against the live per-surface catalog, every operator is type-checked against the field (you can't `gte` a string), and the compiled SELECT runs through the same tenant-scoped, access-checked query gate as everything else. A bad field or operator comes back as a typed `invalid_argument` that names the offender **and** the allowed set — the error message is the documentation.

## The operations

| | |
|---|---|
| Operation | `search.query` (filter lane) |
| REST | `POST /search/query` |
| MCP | `search` tool, action `query` |
| Scope | `data:read` |

| | |
|---|---|
| Operation | `search.fields` (the field catalog) |
| REST | `GET /search/fields` |
| MCP | `search` tool, action `fields` |
| Scope | `data:read` |

## Step 0 — discover the vocabulary

Never guess at field names. The catalog lists every filterable field per surface — name, type, description, and the operators that field admits — and it's derived from the same schema the compiler validates against, so it can't drift.

**REST:**

```
GET /search/fields
Authorization: Bearer <api-key with data:read>
```

**MCP:**

```
search fields
```

**What comes back** — one entry per surface (`interactions`, `deals`, `deal_qualification`):

```json
{
  "surfaces": [
    {
      "surface": "deals",
      "fields": [
        { "name": "deal_amount", "type": "FLOAT", "description": "The CRM's amount field ...", "operators": ["eq", "neq", "in", "not_in", "gt", "gte", "lt", "lte", "between", "is_null", "not_null"] },
        { "name": "deal_stage_status", "type": "STRING", "description": "Funnel OUTCOME of the deal's stage: \"open\" | \"won\" | \"lost\" ...", "operators": ["eq", "neq", "in", "not_in", "contains", "is_null", "not_null"] }
      ]
    }
  ]
}
```

A field advertised with an **empty** `operators` list (JSON / repeated columns) exists but is not filterable — you'll see it in results, you just can't predicate on it.

## The request shape

| Field | Type | Default | Notes |
|---|---|---|---|
| `surface` | `interactions` \| `deals` \| `deal_qualification` | `interactions` | which warehouse surface to slice |
| `filters` | array (max 32) | `[]` | `{field, op, value}` predicates, ANDed together |
| `order_by` | `{field, dir}` | — | a vocabulary field, or a metric alias in aggregate mode |
| `limit` | int | `100` | row cap, max `1000` |
| `group_by` | array (max 8) | — | group fields; requires at least one metric |
| `metrics` | array (max 8) | — | `{fn, field}` aggregations |
| `mode` | string | `auto` | filters with no `query` auto-route to the filter lane; pass `"filter"` to force it |

Operator → value shapes: a scalar for `eq` / `neq` / `gt` / `gte` / `lt` / `lte` / `contains` (case-insensitive substring), an array for `in` / `not_in` (max 200 values), a two-element `[low, high]` for `between`, and no value at all for `is_null` / `not_null`. Timestamps and dates take ISO strings.

## Example 1 — the open pipeline slice, largest first

**REST:**

```
POST /search/query
Authorization: Bearer <api-key with data:read>
Content-Type: application/json

{
  "surface": "deals",
  "filters": [
    { "field": "deal_stage_status", "op": "eq", "value": "open" },
    { "field": "deal_amount", "op": "gte", "value": 50000 }
  ],
  "order_by": { "field": "deal_amount", "dir": "desc" },
  "limit": 25
}
```

**MCP** (the `search` coarse tool, `query` action):

```
search query
  surface  = "deals"
  filters  = [
    { "field": "deal_stage_status", "op": "eq", "value": "open" },
    { "field": "deal_amount", "op": "gte", "value": 50000 }
  ]
  order_by = { "field": "deal_amount", "dir": "desc" }
  limit    = 25
```

**What comes back** — which lane ran, the rows, and the compiled SQL:

```json
{
  "success": true,
  "mode_ran": "filter",
  "results": [
    { "deal_id": "9214…", "deal_name": "Northwind expansion", "deal_amount": 180000, "deal_stage_label": "Contract Sent", "deal_stage_status": "open", "company_id": "1852…" }
  ],
  "compiled": {
    "sql": "SELECT `deal_id`, `deal_name`, `deal_amount`, … FROM deals WHERE `deal_stage_status` = 'open' AND `deal_amount` >= 50000 ORDER BY `deal_amount` DESC",
    "filters": [ { "field": "deal_stage_status", "op": "eq", "value": "open" }, { "field": "deal_amount", "op": "gte", "value": 50000 } ]
  },
  "timing": { "total_ms": 900 }
}
```

Non-aggregate results return the surface's full advertised column set per row. `compiled.sql` is the receipt — the tenant filter and any data-scope predicate are injected by the query gate before it runs.

## Example 2 — a date window, by speaker

Who said what at one account in a window — external (customer) speakers only. On `interactions` the event-time column is named `timestamp`:

```
POST /search/query
{
  "surface": "interactions",
  "filters": [
    { "field": "timestamp", "op": "between", "value": ["2026-06-01", "2026-06-30"] },
    { "field": "speaker_type", "op": "eq", "value": "external" },
    { "field": "company_name", "op": "contains", "value": "acme" }
  ],
  "order_by": { "field": "timestamp", "dir": "desc" },
  "limit": 50
}
```

## Example 3 — group + aggregate: the funnel in one call

`group_by` + `metrics` turns the slice into an aggregation. Metric aliases are `count` for `{"fn":"count"}` and `<fn>_<field>` otherwise (`sum_deal_amount`), and `order_by` can target an alias:

```
POST /search/query
{
  "surface": "deals",
  "filters": [ { "field": "deal_stage_status", "op": "eq", "value": "open" } ],
  "group_by": [ "deal_stage_label" ],
  "metrics": [ { "fn": "count" }, { "fn": "sum", "field": "deal_amount" } ],
  "order_by": { "field": "sum_deal_amount", "dir": "desc" }
}
```

```json
{
  "success": true,
  "mode_ran": "filter",
  "results": [
    { "deal_stage_label": "Contract Sent", "count": 14, "sum_deal_amount": 1240000 },
    { "deal_stage_label": "Discovery", "count": 32, "sum_deal_amount": 890000 }
  ],
  "compiled": { "sql": "SELECT `deal_stage_label`, COUNT(*) AS `count`, SUM(`deal_amount`) AS `sum_deal_amount` FROM deals WHERE …" }
}
```

Rules the compiler enforces (each violation is a named `invalid_argument`): `group_by` requires at least one metric; `sum` / `avg` need a numeric field; in aggregate mode `order_by` must be a group field or a metric alias.

## Paste this into Claude

The MCP-native version — Claude discovers the fields and composes the filters for you:

```
Structured slice of our data — use the search tool's query action with typed
filters, not a plain-language search.

First call the fields action and check the exact field names for the {deals |
interactions | deal_qualification} surface. Then run: {e.g. "open deals with
amount >= 50000, ordered by amount descending, top 25" — or "count + total
amount grouped by stage label"}.

Show me the filters you sent AND the compiled SQL that came back, so I can
reuse the exact slice later.
```

## Variations

- **Force the lane**: pass `mode: "filter"`. In `auto`, filters with no free-text `query` route to the filter lane anyway; being explicit protects the call if someone later adds a `query` to it.
- **Qualification slice**: `surface: "deal_qualification"` (one row per company) — e.g. `{ "field": "outcome_band", "op": "eq", "value": "low" }` with `not_null` on `outcome_score` for the at-risk board.
- **Exclusion lists**: `not_in` takes up to 200 values — handy for "everything except these accounts."
- **Null hygiene**: `is_null` / `not_null` take no value; use them to separate "unmapped" from real values (e.g. `deal_stage_label is_null`).

## Tips

- **Read `search.fields` once, then trust the errors.** A wrong field or operator returns `invalid_argument` naming the allowed set — the API teaches its own vocabulary.
- **Prefer the resolved stage facts.** On `deals`, filter and group on `deal_stage_status` / `deal_stage_label` / `deal_stage_is_won`, not the raw `deal_stage` id (tenant CRMs carry opaque stage ids).
- **Aggregate in the query, not over a capped row set.** `limit` caps rows at 1000; a metric computed client-side over a capped slice is a metric over an arbitrary subset. `group_by` + `metrics` aggregates over the full population and returns a few rows.
- **`contains` is case-insensitive substring match** — good for names, wrong for exact ids (use `eq` / `in`).

## See also

- [Semantic search](semantic-search.md) — the meaning-shaped lane of the same `search.query` door.
- [Fast lane — `search.run`](fast-lane-search.md) — the plain-language NL lane when you'd rather describe than predicate.
- [The expansion motion, end to end](expansion-motion-end-to-end.md) — filter slices as the connective tissue of a multi-verb workflow.
- [Agent platform overview](README.md) — the flag prerequisite and the scope table.
