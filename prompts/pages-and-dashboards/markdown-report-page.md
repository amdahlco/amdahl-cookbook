# Build a markdown report page

**What this does**: Turns a written deliverable — a competitive brief, an account one-pager, a positioning memo, a battlecard — into a real **Page** in your Amdahl console: a clean, centered, readable prose column you can share by link, instead of a wall of text in the chat. It uses the `document` page layout, built almost entirely from `Markdown` blocks, so a pure-prose report needs **no SQL at all**.

**When to use it**: "Claude just wrote me a sharp competitive brief (or an account one-pager, or a positioning memo) — now I want it to live somewhere my team can open, not buried in a chat transcript." Anything where the output is a document a human reads top-to-bottom, not a dashboard of charts.

## Why this matters

A Page is normally a **dashboard**: stats, charts, and tables bound to your live data. But not every deliverable is a dashboard. A competitive brief is prose. An account one-pager is prose. A positioning memo is prose. Forcing those into cards-and-charts is the wrong shape — and leaving them in the chat means they evaporate the moment the session scrolls away.

The `document` layout is the answer: a Page that renders as a centered, readable column built from the **content** catalog components — `Heading`, `Text`, `Markdown`, `Callout`, `List`, plus the occasional `Stat` or small table when a number earns its place. The workhorse is `Markdown`: a free-form markdown block (headings, paragraphs, bold, lists, links) with **no data binding**. A report made only of `Markdown` and other content nodes declares **no queries** — so there's no SQL to get right, no tenant table to match, just the words.

The payoff: the brief becomes a durable, shareable artifact with its own URL. Re-open it next quarter, hand it to a new AE, paste the link into Slack. It's the difference between a one-shot answer and a living one-pager.

## What you're building (the shape)

- **`layout: "document"`** on the page body — this is what makes it a centered prose column instead of a dashboard grid.
- A `root` `Section` holding the document, with content nodes as children:
  - `Heading` (`{ text, level }`, level 1–3) for section titles.
  - `Markdown` (`{ body }`) for the prose — the `body` prop is your raw markdown string. This is where most of the report lives.
  - `Callout` (`{ title, tone }`, tone `neutral` / `positive` / `warning`) with a child `Text` or `Markdown` node for a boxed aside — a provenance note, a key warning, a headline takeaway.
  - `List` (`{ items: [...] }`) for a bulleted talk track, or just write the bullets inside a `Markdown` body.
- **`declared_queries: []`** — a pure-prose report binds no data, so the query list is empty. (If you want to anchor one live number, add a single declared query and a `Stat` beside the prose; the rest stays markdown.)

You don't write any of this by hand — you ask Claude to, and it runs the platform's **validate → create** loop (the same loop `/amdahl-gtm:create-page` uses) and hands you back a URL. Page authoring is a **console + REST** surface — the `pages` MCP tool was retired — so this play needs a session that can call the REST API (e.g. Claude Code with a platform API key); from a connector-only claude.ai session, have Claude draft the spec and create it in the console yourself.

## Paste this into Claude

```
First, write me a {competitive brief on {competitor} | one-pager on {account} |
positioning memo for {segment}} grounded in our Amdahl data — fuse our internal
call/CRM history with public signal, and call out the divergence between the two.
Keep it tight and readable: a few short sections, each with a clear heading.

Then publish it as an Amdahl Page over the pages REST API, as a long-form document:

- Set the page layout to "document" so it renders as a centered, readable prose
  column (NOT a dashboard).
- Build the body from content catalog components only: a root Section, then
  Heading nodes for each section title and Markdown nodes (the `body` prop holds
  the markdown) for the prose. Use a Callout (with a child Text node) for the
  provenance / sources note at the end.
- This is pure prose, so declared_queries MUST be []. Do not write any SQL and do
  not invent data bindings — there's nothing to bind.
- Run POST /pages/validate first. Fix every rejection (a non-catalog node
  type, a Markdown node missing its `body`, a Callout given a `text` prop instead
  of a child Text node) and re-validate until it passes clean.
- Then POST /pages to create it and give me the console URL. Don't try to render
  or screenshot it from here — I'll open the link.

If anything in the brief is a specific factual claim you can't ground in our data
or a cited source, mark it clearly rather than stating it as fact.
```

## What you'll see back

- The written brief itself, in chat, so you can sanity-check the words before it's published.
- A short rundown of the spec tree: a `Section` of `Heading` + `Markdown` nodes (plus a `Callout`), `layout: "document"`, and `declared_queries: []`.
- The `validate` verdict — ideally clean on the first or second pass.
- A **console URL** for the created Page. Open it and the brief renders as a centered prose column over your workspace.

## How to actually use it

1. **Read the brief in chat first, then let it publish.** The Page is the delivery format; the words are the deliverable. Push back on a thin section ("more verbatim quotes on the security objection") before it gets created — editing the prose is easier than editing the Page.
2. **Keep sections short and headed.** The `document` layout reads best as a handful of titled sections, not one giant `Markdown` wall. One `Heading` + one `Markdown` block per idea.
3. **Use a `Callout` for the provenance note.** End the report with a `neutral` Callout listing sources and the date — it's the "how do I trust this" footer, set off from the body.
4. **Share the URL, don't re-paste the text.** The whole point is a durable link. Drop it in Slack, hand it to the AE, re-open it next quarter.
5. **If `validate` complains about a binding, you have stray SQL.** A pure document declares no queries; an unbound-query or invalid-SQL rejection means a data node snuck in. Tell Claude "this is prose only, remove any queries and data bindings."

## Variations

- **Anchor one live number.** Want the brief to open with "they came up in 7 deals this quarter"? Add a single `declared_queries` entry (a `SELECT` over your interactions) and a `Stat` node with a `$value` binding at the top — the rest of the document stays pure markdown. Now it's a report with one live stat, not a dashboard.
- **Account one-pager.** Swap the prompt's deliverable to "a one-pager on {account}" — snapshot, what they care about, risks, the divergence, a recommended next step — same `document` layout, same no-SQL shape. Pairs with [deep-dive on account](../customer-research/deep-dive-on-account.md).
- **Positioning memo by segment.** "A positioning memo for {segment}" built from raw customer voice — same shape. Pairs with [rebuild your value narrative by segment](../positioning-messaging/rebuild-value-narrative-by-segment.md).
- **Start from a dashboard template instead.** If the answer really is charts (pipeline health, voice-of-customer), skip `document` and reach for the dashboard templates — see the full [create-a-page command](../../plugins/amdahl-gtm/commands/create-page.md).
- **Report + supporting chart.** A long-form `document` page can still carry one chart or `Table` beside the prose (that one needs a declared query). Use it when a single visual supports the narrative — a brief that ends with the competitor's mention-trend line.

## Tips

- **`Markdown` is the workhorse; reach for it first.** Most of a report is just `Markdown` blocks. Use `Heading` / `Callout` / `List` for structure, `Markdown` for everything else.
- **Pure prose = no queries.** The single most common mistake is letting a data binding leak into a document page. If there's no number, there's no query — `declared_queries` is `[]`.
- **`document` is one of three layouts.** `dashboard` (the default grid), `single` (one chart full-bleed), and `document` (this prose column). Pick `document` whenever the ask is "write me a brief / memo / one-pager," not "show me X."
- **Pair with a recipe that produces the words.** This recipe is the publish step; the payload comes from [competitor deep-dive](../competitive-intel/competitor-deep-dive.md), [deep-dive on account](../customer-research/deep-dive-on-account.md), or [audit our positioning](../positioning-messaging/audit-our-positioning.md). Generate the brief, then publish it as a document page.

## See also

- [Create a page (command)](../../plugins/amdahl-gtm/commands/create-page.md) — the full Pages contract: the catalog, the three layouts, data bindings, and the validate → create loop. The authoritative reference; this recipe is the document-layout slice of it.
- The rest of the cookbook: [recipe library](../README.md) — paste-ready GTM prompts that produce the briefs worth publishing.
- Product docs: <https://amdahl.co/mcp>.
