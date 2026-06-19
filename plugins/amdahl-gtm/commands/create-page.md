---
description: Author a Page — a spec-defined dashboard (stats, charts, tables built from catalog components) over this tenant's live data. Validate it through the Amdahl pages tool, then create it as a draft you open in the console.
argument-hint: <what the page should show>  (e.g. "pipeline health by stage")
---

Run the Amdahl create-a-page play. Use the connected **Amdahl** MCP `pages` tool. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

What to build: **$ARGUMENTS**

A **Page** is a **spec** — a tree of pre-built catalog components with data bindings, NOT a code file. The host renders it in the console over this tenant's live data, so the output is a real, designed dashboard, not a chat transcript. You describe the layout with catalog nodes and declare the SQL that feeds them; the platform handles the tenant binding, per-viewer access, and rendering. You never write or ship component code — you assemble catalog components.

## Start from a template first

Amdahl ships **page templates** — vetted, catalog-only specs you adapt instead of building from a blank slate. Always check them before drafting from scratch:

1. **List** them by reading the resource **`page_template://list`** (slug, name, intent for each — today: dashboards `pipeline-health`, `voice-of-customer`, `competitive-battlecard`, plus single-viz starters `win-rate-gauge`, `pipeline-funnel`, `deal-size-distribution`). The same set shows for every tenant; they live in code, not as pages in this workspace.
2. **If one fits $ARGUMENTS**, read **`page_template://<slug>`** for its full `spec` + `declared_queries`. That's your starting point — the layout is already correct.
3. **Adapt it to THIS tenant's data.** The template's SQL is tenant-agnostic boilerplate; the table/column names won't match every workspace. Use the `data` tool (`explore` to see real tables/columns, `query` to sanity-check a `SELECT`) and rewrite each declared query to match what this tenant actually has. Keep the catalog spec structure; change query SQL and any labels/titles that should reflect this tenant.
4. Then run the **validate → create loop** below on the adapted spec, exactly as if you'd authored it.

If no template fits, draft the spec from scratch per the contract below. Either way, the validate → create loop is the same.

## Dashboard, single visualization, or document?

A page can be a **dashboard** (several components laid out together), a **single visualization** (one chart that fills the whole canvas), or a **document** (a centered, readable prose column). Set it with the optional top-level `layout`:

- Omit `layout` (or `"dashboard"`) → the normal multi-component grid of cards, stats, and charts.
- `"single"` → the page IS one visualization, rendered full-bleed. Use it when the answer is one chart: a win-rate gauge, a pipeline funnel, an ACV-by-stage bar. The `root` is just that one viz node (no `Section` wrapper needed).
- `"document"` → a centered, readable prose column for long-form narrative / report pages — a competitive brief, an account one-pager, a positioning memo, a battlecard. Built from the **content** catalog components (`Heading`, `Text`, `Markdown`, `Stat`, `Callout`, `List`) plus optional supporting charts/tables. `Markdown` is the workhorse here: a free-form markdown block with no data binding, so a pure-prose report needs **no declared queries at all** (`"declared_queries": []`).

Reach for single-viz when $ARGUMENTS is "show me X as a chart"; reach for document when it's "write me a brief / one-pager / report on X" rather than "build me a dashboard of X."

## The contract — get this exactly right or `validate` rejects it

**The spec**
- A page body is `{ "version": 1, "root": <node>, "layout"?: "dashboard" | "single" | "document" }`. There is exactly one `root`.
- A **node** is `{ "type": <CatalogComponent>, "props"?: { … }, "children"?: [ <node>, … ] }`.
- `type` must be a **catalog component** — you cannot invent one. The catalog:
  - **Layout:** `Section`, `Row`, `Grid`, `Card`, `Divider`, `Spacer`
  - **Content:** `Heading`, `Text`, `Markdown`, `Stat`, `StatRow`, `Badge`, `Callout`, `List`
  - **Data-viz:** `Table`, `BarChart`, `LineChart`, `PieChart`, `AreaChart`, `ScatterChart`, `ComposedChart`, `FunnelChart`, `RadarChart`, `GaugeChart`, `Treemap`, `Sankey`, `SignalMap`, `Insight`
  - **Escape hatch:** `Custom` — a bespoke sandbox node, **gated by the `pages:admin` scope** and **not for normal authoring**. Don't reach for it; assemble the page from the catalog above. (If you genuinely think you need `Custom`, say so and stop — it's an admin-only path, not a fallback.)
- **`Markdown` is the prose workhorse** — a free-form markdown content block (headings, paragraphs, lists, bold, links) with **no data binding**. It's the right node for the written parts of a report: a competitive brief, an account one-pager, a positioning memo, a battlecard, an exec summary above a chart. Pair it with `Heading` / `Callout` / `List` for structure and (optionally) a chart or `Table` for the supporting data. A page made only of `Markdown` (and other content nodes) declares **no queries** — see the `layout: "document"` example below.
- **Pick the chart that fits the data:** trend over time → `LineChart` / `AreaChart`; compare categories → `BarChart`; ranking by magnitude → `Treemap` or horizontal `BarChart`; share of a whole → `PieChart`; conversion stages → `FunnelChart`; one number vs a target → `GaugeChart`; correlation → `ScatterChart`; multi-axis profile (e.g. competitor scorecard) → `RadarChart`; two measures on one frame → `ComposedChart`; flow between stages → `Sankey`; a single headline number → `Stat` (supports `trend` + `sparkline`); a written finding → `Insight`. Most viz bind their rows via `{ "$query": "<name>" }` and name columns by string (`x`, `y`, `value`, `label`, …); a few take richer shapes (`Sankey` takes `nodes` + `links`; `GaugeChart` takes a scalar `value`). When unsure of a type's props, read its schema — the `validate` verdict also tells you exactly what's wrong.
- Compose by nesting: `Section` → `Grid`/`Row` → `Card` → content/viz nodes. `props` and `children` are both optional per node. (A single-viz page skips the nesting — `root` is the one viz node.)

**The data**
- The page declares **named queries** up front in `declared_queries`: `[{ name, source, … }]`. Most are `source: 'sql'`, but a query can also draw from two other host sources (below).
- For `source: 'sql'`: each `sql` is a single **`SELECT`** against the whitelisted tenant tables. Read-only — no DDL/DML.
- SQL is **tenant-agnostic**: do **NOT** put `business_id` (or any tenant id) in the SQL. The host injects the tenant filter AND the per-viewer access predicate at run time. Writing your own `business_id` is both unnecessary and a validation failure.
- **Two non-SQL sources** let a page bind to more than rows of SQL — the rows bind exactly the same way via `$query` / `$value`:
  - `source: 'cluster_search'` — a semantic search over a corpus. Set `query` (the search text) + `target` (the corpus, e.g. `'interactions'`). Rows are the matching clusters.
  - `source: 'kb_search'` — a search over the workspace Knowledge Base. Set `query` (the search text). Rows are the matching documents.
- **Optional `params`** — a query may declare named `params` (a map of `name` → type hint) referenced as `@name` in the SQL. These are runtime inputs the page supplies when it renders (e.g. a date range), so you don't rewrite SQL to refilter.
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

## Worked example — a `layout: "document"` competitive brief

When $ARGUMENTS is "write me a brief / one-pager / report on X," reach for `layout: "document"`: a centered prose column built from content nodes. Pure prose binds no data, so `declared_queries` is **empty**.

`declared_queries`:

```json
[]
```

`spec`:

```json
{
  "version": 1,
  "layout": "document",
  "root": {
    "type": "Section",
    "props": { "title": "Competitive brief — Acme vs. us" },
    "children": [
      {
        "type": "Heading",
        "props": { "text": "Where we win", "level": 2 }
      },
      {
        "type": "Markdown",
        "props": {
          "body": "Buyers pick us over Acme when **time-to-value** is the deciding factor. On three closed-won calls this quarter the champion cited our onboarding finishing in days where Acme quoted weeks. Lead with the 30-day rollout story.\n\n- **Speed of deployment** — our strongest, most-repeated edge.\n- **Support responsiveness** — named on every win where Acme was shortlisted.\n- **Transparent pricing** — buyers contrast it with Acme's custom-quote friction."
        }
      },
      {
        "type": "Heading",
        "props": { "text": "Where they win", "level": 2 }
      },
      {
        "type": "Markdown",
        "props": {
          "body": "Acme wins on **breadth of integrations** and enterprise brand trust. When the buyer's evaluation is integration-led, we lose on the long-tail connector list.\n\n**Sidestep:** reframe the conversation from \"how many integrations\" to \"the three you actually run daily\", where our depth beats their breadth."
        }
      },
      {
        "type": "Callout",
        "props": { "title": "Provenance", "tone": "neutral" },
        "children": [
          {
            "type": "Text",
            "props": {
              "text": "Sources: 3 closed-won + 2 closed-lost calls, last 90 days. Re-run quarterly — Acme's posture shifts."
            }
          }
        ]
      }
    ]
  }
}
```

Notice: `layout` is `"document"`, the `root` is a `Section` of content nodes (`Heading` + `Markdown` + `Callout`), no node binds data, and `declared_queries` is `[]` — a pure-prose report needs no SQL. The `Markdown` node's prop is `body` (its raw markdown string); the `Callout` carries its message in a child `Text` node (its props are `title` + `tone`, where `tone` is `neutral` / `positive` / `warning`). If you wanted to anchor a number in the brief, you'd add one declared query and a `Stat` (`$value` binding) — or a small `Table` / chart — beside the prose; the rest of the document stays markdown.

When the examples are clear, build the user's actual page for **$ARGUMENTS**: check `page_template://list` for a template that fits and adapt it (per "Start from a template first"), or write the spec from scratch if none does. Either way, run the validate → fix → create loop and hand back the console URL.
