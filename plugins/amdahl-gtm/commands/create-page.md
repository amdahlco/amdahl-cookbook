---
description: Author a Page — a spec-defined dashboard (stats, charts, tables built from catalog components) over this tenant's live data. Validate it through the Amdahl pages tool, then create it as a draft you open in the console.
argument-hint: <what the page should show>  (e.g. "pipeline health by stage")
---

Run the Amdahl create-a-page play. Use the connected **Amdahl** MCP `pages` tool. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

What to build: **$ARGUMENTS**

A **Page** is a **spec** — a tree of pre-built catalog components with data bindings, NOT a code file. The host renders it in the console over this tenant's live data, so the output is a real, designed dashboard, not a chat transcript. You describe the layout with catalog nodes and declare the SQL that feeds them; the platform handles the tenant binding, per-viewer access, and rendering. You never write or ship component code — you assemble catalog components.

## The contract — get this exactly right or `validate` rejects it

**The spec**
- A page body is `{ "version": 1, "root": <node> }`. There is exactly one `root`.
- A **node** is `{ "type": <CatalogComponent>, "props"?: { … }, "children"?: [ <node>, … ] }`.
- `type` must be a **catalog component** — you cannot invent one. The catalog:
  - **Layout:** `Section`, `Row`, `Grid`, `Card`
  - **Content:** `Heading`, `Text`, `Markdown`, `Stat`, `StatRow`, `Badge`, `Callout`, `List`, `Table`
  - **Data-viz:** `BarChart`, `LineChart`, `PieChart`
  - **Escape hatch:** `Custom` — a bespoke sandbox node, **gated by the `pages:admin` scope** and **not for normal authoring**. Don't reach for it; assemble the page from the catalog above. (If you genuinely think you need `Custom`, say so and stop — it's an admin-only path, not a fallback.)
- Compose by nesting: `Section` → `Grid`/`Row` → `Card` → content/viz nodes. `props` and `children` are both optional per node.

**The data**
- The page declares **named queries** up front in `declared_queries`: `[{ name, source: 'sql', sql }]`.
- Each `sql` is a single **`SELECT`** against the whitelisted tenant tables. Read-only — no DDL/DML.
- SQL is **tenant-agnostic**: do **NOT** put `business_id` (or any tenant id) in the SQL. The host injects the tenant filter AND the per-viewer access predicate at run time. Writing your own `business_id` is both unnecessary and a validation failure.
- There is **no raw SQL at render time** and no ad-hoc querying. A component prop can only reference a query you already declared, by name. Two binding shapes:
  - **`{ "$query": "<name>" }`** — binds the named query's **rows**. Use for row-shaped props: a `Table`'s data, a chart's series.
  - **`{ "$value": { "query": "<name>", "field": "<col>" } }`** — binds a **single scalar** from the first row. Use for a `Stat`'s value.
- Every referenced query name must exist in `declared_queries`, or validate fails with an unbound-query error.

## The loop — validate before you create

1. **Draft** the `spec` + its `declared_queries`.
2. Call `pages` action **`validate`** with `{ spec, declared_queries }`. Read the **structured verdict** — it reports failures by kind: **unknown component** (a `type` not in the catalog), **bad prop** (a prop the component doesn't accept, or a malformed binding), **unbound query** (a `$query` / `$value` name with no matching `declared_queries` entry), and **invalid SQL** (not a plain `SELECT`, a stray `business_id`, an off-whitelist table).
3. **Fix every rejection** and re-validate. Common ones: a made-up `type`, a `Stat` bound with `$query` instead of `$value` (or vice-versa), a `useless` raw value where a binding is required, a query name typo, a non-`SELECT` SQL, or a tenant id in the SQL.
4. Once validate passes clean, call `pages` action **`create`** with the same payload. It lands as a **`draft`**.
5. **Rendering happens in the console, not over MCP.** `create` returns a URL — give it to the user so they can open the page and see it render over live data. Do not try to "run" or screenshot the page from here.

Be concise in chat: show the user the spec tree, the declared queries, and the validate verdict. Don't paste the whole spec twice.

## Worked example — a "Pipeline Health" page

Three named SQL queries (note: NO `business_id` anywhere) feeding a `StatRow` of `Stat`s (scalar `$value` bindings) and a `BarChart` (row-shaped `$query` binding), each inside its own `Section`.

`declared_queries`:

```json
[
  {
    "name": "open_pipeline_total",
    "source": "sql",
    "sql": "SELECT COUNT(*) AS open_deals, COALESCE(SUM(amount), 0) AS open_acv FROM interactions WHERE deal_stage NOT IN ('closed_won', 'closed_lost')"
  },
  {
    "name": "win_rate_90d",
    "source": "sql",
    "sql": "SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE deal_stage = 'closed_won') / NULLIF(COUNT(*) FILTER (WHERE deal_stage IN ('closed_won', 'closed_lost')), 0)) AS win_pct FROM interactions WHERE closed_at >= CURRENT_DATE - INTERVAL '90 days'"
  },
  {
    "name": "pipeline_by_stage",
    "source": "sql",
    "sql": "SELECT deal_stage, COUNT(*) AS deals, SUM(amount) AS acv FROM interactions WHERE deal_stage IS NOT NULL GROUP BY deal_stage ORDER BY acv DESC"
  }
]
```

`spec`:

```json
{
  "version": 1,
  "root": {
    "type": "Section",
    "props": { "title": "Pipeline Health" },
    "children": [
      {
        "type": "Section",
        "children": [
          {
            "type": "StatRow",
            "children": [
              {
                "type": "Stat",
                "props": {
                  "label": "Open deals",
                  "value": { "$value": { "query": "open_pipeline_total", "field": "open_deals" } }
                }
              },
              {
                "type": "Stat",
                "props": {
                  "label": "Open ACV",
                  "format": "currency",
                  "value": { "$value": { "query": "open_pipeline_total", "field": "open_acv" } }
                }
              },
              {
                "type": "Stat",
                "props": {
                  "label": "Win rate (90d)",
                  "format": "percent",
                  "value": { "$value": { "query": "win_rate_90d", "field": "win_pct" } }
                }
              }
            ]
          }
        ]
      },
      {
        "type": "Section",
        "props": { "title": "ACV by stage" },
        "children": [
          {
            "type": "BarChart",
            "props": {
              "data": { "$query": "pipeline_by_stage" },
              "x": "deal_stage",
              "y": "acv"
            }
          }
        ]
      }
    ]
  }
}
```

Notice: every `type` is a catalog component (no invented nodes, no `Custom`), each `Stat` binds a single scalar with `$value` while the `BarChart` binds rows with `$query`, every bound query name matches a `declared_queries` entry, and the SQL carries no tenant id.

When the example is clear, write the user's actual page for **$ARGUMENTS**, run the validate → fix → create loop, and hand back the console URL.
