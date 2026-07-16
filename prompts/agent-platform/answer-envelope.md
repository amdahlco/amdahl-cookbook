# The answer envelope

**What this does**: Explains the shape a Chat hands back so you can render it in your own UI — the `answer` object with its typed `content_blocks`, `follow_ups`, and the `amdahl:q` / `amdahl:cite` link grammar embedded in the markdown. This is the "how do I display a Chat result" reference for [agentic Chat](agentic-chat.md).

**When to use it**: You're building a surface that shows Chat answers — a dashboard, an internal tool, a Slack unfurl — and you want the metric cards, tables, theme findings, and clickable data phrases the Amdahl console renders, not just a wall of text.

## The `answer` object

Every settled Chat run carries an `answer` (on `read_url` / `chat_status`):

```json
{
  "answer": {
    "answer_text": "Artisian is a close twin of 11x.ai, which we closed ...",
    "content_blocks": [ /* ordered, typed — see below */ ],
    "follow_ups": [
      "What did 11x.ai's winning conversation look like in detail?",
      "Most common objections from VP-level buyers at AI-native companies?"
    ]
  }
}
```

- **`answer_text`** — the flattened markdown answer. Safe to show as-is, but note the clickable links are **stripped** from it (they live in the blocks). `null` until the run completes.
- **`content_blocks`** — the ordered, typed payload. This is what you render for the rich view.
- **`follow_ups`** — up to 4 suggested next questions. Render them as clickable chips that seed a new [Chat](agentic-chat.md) turn (this is exactly what the product's suggestion pills do).

## The seven content-block types

Every block is one of seven types (unknown types should be ignored by a forward-compatible client). Each carries an `id`.

| Type | What it is | Key fields |
|---|---|---|
| `text` | a markdown paragraph | `markdown` |
| `callout` | a highlighted note | `tone` (`info` / `warn` / `note`), `markdown` |
| `citation` | a static evidence pointer | `kind` (`utterance` / `url` / `query` / `doc`), `ref`, `label?`, `snippet?` |
| `table` | a data-backed table | `columns[{key,label}]`, `data[]` (rows), `query` |
| `chart_spec` | a data-backed chart | `chart_type` (bar/line/area/pie/scatter/funnel/radar/treemap/gauge), `encoding`, `query`, `data[]` |
| `metric` | a single figure | `label`, `format?`, and either `value`/`delta` literal or `query`+`data` |
| `cluster_finding` | a customer-conversation theme | `cluster_id`, `label`, `insight?`, `narrative_hook?`, `member_count?` |

`table` and `chart_spec` carry both the `query` that produced them and the resolved `data` rows, so you can render immediately or re-run the query yourself. `cluster_finding` is the one that has **no** SQL query — a theme comes from the cluster index, not a warehouse `SELECT` — which is why it's its own type: a count like "349 SMB deals lost" is anchored to the theme it came from, not to a table row.

Example — the theme card at the bottom of a call-prep answer:

```json
{
  "id": "b_theme_1",
  "type": "cluster_finding",
  "cluster_id": "…_62",
  "label": "Reverse-Engineering Own Customer Data Mid-Call",
  "insight": "Internet-native teams treat sales calls as live strategy sessions ...",
  "narrative_hook": "367 conversations where the prospect forgot they were being sold to ...",
  "member_count": 367
}
```

## The link grammar — figures explore, claims prove

The markdown inside blocks can carry two closed link schemes. Both render as special affordances, not plain `http` links.

- **`amdahl:q` — a figure to EXPLORE.** `[349 SMB deals](amdahl:q?fu=<url-encoded follow-up>&block=<id>&sql=<url-encoded sql>)`. A bare figure the user can click to drill in; hovering previews the backing query, clicking seeds a follow-up. `fu` (the follow-up) is required.
- **`amdahl:cite` — a claim to PROVE.** `[we lose to their SOC 2 bridge letter](amdahl:cite?block=<id>&fu=<follow-up>)`. Anchors a claim to a presented evidence block (`citation` / `table` / `chart_spec` / `metric` / `cluster_finding`). `block` is required and must name a block that's actually in the answer.

The mental model: **figures explore (`amdahl:q`), claims prove (`amdahl:cite`).** Anything off-grammar (an unknown param, a `block` that isn't present) is unwrapped to plain text server-side, so a link you render is always valid. If you only show `answer_text`, you get clean prose with the links removed; render `content_blocks` to get the interactive version.

## Rendering checklist

1. Poll [Chat](agentic-chat.md) until `status: "complete"`, then read `run.answer`.
2. Render `content_blocks` in order. Map each `type` to a component; fall back to `text` (or skip) for a type you don't recognize.
3. Turn `amdahl:q` links into "explore" affordances (click -> seed a new turn with the `fu`) and `amdahl:cite` links into "jump to evidence" affordances (scroll to `block`).
4. Render `follow_ups` as clickable chips that start the next turn.
5. If you can't render rich blocks, show `answer_text` — it's the clean, link-stripped prose fallback.

## Tips

- **Ignore unknown block types.** The set can grow; a forward-compatible client renders what it knows and drops the rest rather than erroring.
- **`cluster_finding` counts aren't SQL.** Don't expect a `query` on them — they're anchored to a theme from the cluster index, which is exactly why they're citable.
- **Don't reconstruct links from `answer_text`.** It has them stripped by design. The links live in the blocks' markdown.
- **No cost fields.** The wire never carries a dollar/token-cost figure for the end user; usage tokens are on `run.usage` for your own accounting.

## See also

- [Agentic Chat](agentic-chat.md) — how to get an `answer` back in the first place.
- [Agent platform overview](README.md) — the two doors and the scope table.
