---
description: Author a Page — a custom TSX component that renders a designed UI (stats, charts, tables) over this tenant's live data. Validate it through the Amdahl pages tool, then create it as a draft you open in the console.
argument-hint: <what the page should show>  (e.g. "pipeline health by stage")
---

Run the Amdahl create-a-page play. Use the connected **Amdahl** MCP `pages` tool. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

What to build: **$ARGUMENTS**

A **Page** is a single React component you author in TSX. The host renders it in the console over this tenant's live data — so the output is a real, designed dashboard, not a chat transcript. You write the component and its SQL; the platform handles the tenant binding, per-viewer access, and rendering.

## The contract — get this exactly right or `validate` rejects it

**The component**
- One file, a **default export**, **no required props** — it must render with empty data (the host mounts it before queries resolve).
- Import ONLY from the allowlist: `react`, `@amdahl/ui`, `recharts`, `lucide-react`, `clsx`. Anything else fails validation.
- Style with `@amdahl/ui` components (e.g. `Card`, `Stat`, `Grid`, `Heading`, `Table`) — do not hand-roll CSS or pull a UI framework.
- No `eval`, no `fetch`, no `window` / `document` / `cookie` / `localStorage`, no dynamic `import()`, no network or browser-storage access of any kind. The component is pure: data in, UI out.

**The data**
- The page declares **named queries** up front in `declared_queries`: `[{ name, source: 'sql', sql }]`.
- Each `sql` is a single **`SELECT`** against the whitelisted tenant tables. Read-only — no DDL/DML.
- SQL is **tenant-agnostic**: do **NOT** put `business_id` (or any tenant id) in the SQL. The host injects the tenant filter AND the per-viewer access predicate at run time. Writing your own `business_id` is both unnecessary and a validation failure.
- The component reads a declared query by name: `const { data, loading, error } = Amdahl.useQuery('<name>')`. It can ONLY call queries it declared — there is no ad-hoc querying from inside the component.

## The loop — validate before you create

1. **Draft** the component + its `declared_queries`.
2. Call `pages` action **`validate`** with `{ source_tsx, declared_queries }`. Read the **structured per-stage verdict** — it reports each stage separately: transpile, import allowlist, forbidden APIs, default-export presence, and per-query SQL validity.
3. **Fix every rejection** and re-validate. Common ones: a forbidden import or API (`fetch`/`eval`/`cookie`), missing default export, a query that isn't a plain `SELECT`, a stray `business_id` in the SQL, or a `useQuery('x')` name with no matching entry in `declared_queries`.
4. Once validate passes clean, call `pages` action **`create`** with the same payload. It lands as a **`draft`**.
5. **Rendering happens in the console, not over MCP.** `create` returns a URL — give it to the user so they can open the page and see it render over live data. Do not try to "run" or screenshot the page from here.

Be concise in chat: show the user the component, the declared queries, and the validate verdict. Don't paste the whole TSX twice.

## Worked example — a "Pipeline Health" page

Two named SQL queries (note: NO `business_id` anywhere) feeding a `@amdahl/ui` `Stat` row and a recharts bar chart.

`declared_queries`:

```json
[
  {
    "name": "pipeline_by_stage",
    "source": "sql",
    "sql": "SELECT deal_stage, COUNT(*) AS deals, SUM(amount) AS acv FROM interactions WHERE deal_stage IS NOT NULL GROUP BY deal_stage ORDER BY acv DESC"
  },
  {
    "name": "open_pipeline_total",
    "source": "sql",
    "sql": "SELECT COUNT(*) AS open_deals, COALESCE(SUM(amount), 0) AS open_acv FROM interactions WHERE deal_stage NOT IN ('closed_won', 'closed_lost')"
  },
  {
    "name": "win_rate_90d",
    "source": "sql",
    "sql": "SELECT COUNT(*) FILTER (WHERE deal_stage = 'closed_won') AS won, COUNT(*) FILTER (WHERE deal_stage IN ('closed_won', 'closed_lost')) AS decided FROM interactions WHERE closed_at >= CURRENT_DATE - INTERVAL '90 days'"
  }
]
```

`source_tsx`:

```tsx
import { Card, Grid, Heading, Stat } from '@amdahl/ui'
import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { TrendingUp } from 'lucide-react'
import { Amdahl } from '@amdahl/ui'

export default function PipelineHealth() {
  const totals = Amdahl.useQuery('open_pipeline_total')
  const byStage = Amdahl.useQuery('pipeline_by_stage')
  const winRate = Amdahl.useQuery('win_rate_90d')

  const totalRow = totals.data?.[0] ?? { open_deals: 0, open_acv: 0 }
  const wr = winRate.data?.[0]
  const winPct = wr && wr.decided > 0 ? Math.round((wr.won / wr.decided) * 100) : 0

  return (
    <Card>
      <Heading icon={<TrendingUp />}>Pipeline Health</Heading>

      <Grid cols={3}>
        <Stat label="Open deals" value={totalRow.open_deals} loading={totals.loading} />
        <Stat label="Open ACV" value={`$${Number(totalRow.open_acv).toLocaleString()}`} loading={totals.loading} />
        <Stat label="Win rate (90d)" value={`${winPct}%`} loading={winRate.loading} />
      </Grid>

      <ResponsiveContainer width="100%" height={280}>
        <BarChart data={byStage.data ?? []}>
          <XAxis dataKey="deal_stage" />
          <YAxis />
          <Tooltip />
          <Bar dataKey="acv" />
        </BarChart>
      </ResponsiveContainer>
    </Card>
  )
}
```

Notice: default export, no props, allowlist-only imports, every `useQuery` name matches a `declared_queries` entry, the component renders sensibly while `loading` is true and `data` is undefined, and the SQL carries no tenant id.

When the example is clear, write the user's actual page for **$ARGUMENTS**, run the validate → fix → create loop, and hand back the console URL.
