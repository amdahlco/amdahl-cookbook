# Pages & dashboards

How to turn an Amdahl answer into a real, designed **Page** in your console — a workspace-authored data UI rendered over your live tenant data, not a chat transcript. A Page is a **spec** (a tree of pre-built catalog components — stats, charts, tables, prose blocks) plus the declared SQL that feeds it; the platform handles the tenant binding, per-viewer access, and rendering. You assemble catalog components and let Claude run the validate → create loop.

A Page can take three shapes, set by its top-level `layout`:

- **dashboard** (default) — a multi-component grid of cards, stats, and charts.
- **single** — one visualization rendered full-bleed (a gauge, a funnel, a treemap).
- **document** — a centered, readable prose column for long-form narrative / report pages (a competitive brief, an account one-pager, a positioning memo), built from `Markdown` + the other content components. A pure-prose report needs no SQL.

- [Build a markdown report page](markdown-report-page.md) — publish a written deliverable (competitive brief, account one-pager, positioning memo) as a `document`-layout Page: a centered prose column built almost entirely from `Markdown` blocks, with `declared_queries: []` (prose binds no data). The shareable-link home for the briefs the rest of the cookbook produces.
- [Embed a live page](embed-a-page.md) — build a Page, then mint a **self-scoped embed link** for it: a signed, short-lived iframe URL that renders the page live over your tenant data inside another site. Fails closed (no/invalid/empty-scope token shows nothing), the mint is clamped to your own access, and public/workspace embeds are admin-gated — rotating the per-tenant secret revokes every live embed at once.

The authoritative reference for the full Pages contract — the component catalog, all three layouts, data bindings, page templates, and the validate → create loop — is the [create-a-page command](../../plugins/amdahl-gtm/commands/create-page.md). Drive the whole loop hands-on with `/amdahl-gtm:create-page <what the page should show>`.

New here? Start with the [main README](../../README.md) for setup, then the [recipe library](../README.md) for the GTM prompts that produce the readouts worth publishing.
