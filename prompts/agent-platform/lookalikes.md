# Lookalikes — nearest accounts, deals, and themes

**What this does**: Answers "more like this one" over your **own** conversation corpus. `find` takes a seed company or deal and returns the entities most similar to it, ranked by centroid cosine similarity; `themes` takes any free-text description and returns the customer-conversation ML themes closest to it. Both are honest about coverage: when the similarity data isn't materialized for your workspace yet, they say so (`available: false`) instead of guessing.

**When to use it**: Expansion targeting ("which accounts sound like our best closed-won?"), deal triage ("which past deals did this one resemble?"), and campaign mapping ("which existing themes does this angle land on?"). The similarity is computed from what was *said* in your calls and threads — accounts that talk like your winners, not accounts that share a firmographic checkbox.

## Why this matters

Every "lookalike audience" tool ranks companies by firmographics: industry, headcount, funding. Amdahl's lookalikes rank by **conversation**: each company / deal / theme gets a centroid vector built from its utterances in your corpus, and similarity is distance between centroids. That's a materially different signal — the account whose buying committee raises the same concerns, in the same words, as your last three wins is a better expansion bet than the one that merely shares an industry code. The flip side is honesty about scope: centroids exist only for entities **in your corpus**, and they're materialized by a background pipeline on its own cadence — so the endpoint tells you plainly when they aren't there yet rather than padding a list.

## The operations

| | |
|---|---|
| Operation | `lookalike.find` |
| REST | `POST /lookalike` |
| MCP | `lookalike` tool, action `find` |
| Scope | `data:read` |

| | |
|---|---|
| Operation | `lookalike.similar_themes` |
| REST | `POST /lookalike/themes` |
| MCP | `lookalike` tool, action `themes` |
| Scope | `data:read` |

## `find` — nearest entities to a seed

| Field | Type | Default | Notes |
|---|---|---|---|
| `entity_type` | `company` \| `deal` | — (required) | which centroid family to search |
| `entity_id` | string | — | the seed's id, as your pipeline emits it — preferred |
| `domain` | string | — | company seeds only: tried **as** the entity id (see below) |
| `limit` | int | `10` | max neighbours, cap `50` |

**REST:**

```
POST /lookalike
Authorization: Bearer <api-key with data:read>
Content-Type: application/json

{ "entity_type": "company", "entity_id": "1852…", "limit": 10 }
```

**MCP** (the `lookalike` coarse tool, `find` action):

```
lookalike find
  entity_type = "company"
  entity_id   = "1852…"
  limit       = 10
```

**What comes back** — the seed's centroid facts plus its ranked neighbours (the seed itself is excluded):

```json
{
  "success": true,
  "available": true,
  "seed": { "entity_type": "company", "entity_id": "1852…", "member_count": 214, "computed_at": "2026-07-19T03:40:11Z" },
  "matches": [
    { "entity_id": "9b03…", "score": 0.91, "member_count": 88 },
    { "entity_id": "77aa…", "score": 0.87, "member_count": 45 }
  ]
}
```

`member_count` is how many corpus utterances back each centroid — treat a match built on 6 utterances more skeptically than one built on 200. `score` is cosine similarity: use it to rank within a response, not as a calibrated probability.

**On `domain`:** company seeds also accept a `domain`, which is tried *as* the entity id (company centroid ids are the pipeline's company ids). If the domain isn't that id for your workspace, you get the honest `available: false` below rather than a guessed match — when you have a company id (from a [structured search](structured-search.md) row, for example), prefer it.

## Handling `available: false` — coverage, not failure

Centroids are materialized by a background pipeline sweep on its own cadence. A new workspace, a just-connected data source, or a seed with no corpus presence yet all land here:

```json
{ "success": true, "available": false, "reason": "centroids_not_materialized", "matches": [] }
```

Two `reason` values, two different reactions:

- **`centroids_not_materialized`** — the similarity data isn't there (yet) for this seed or workspace. Not retryable-right-now, not an error. Fall back to the `themes` action (which degrades gracefully on its own), ask the question as [semantic search](semantic-search.md), or simply re-check after the pipeline's next materialization pass.
- **`error`** — the read itself failed. Transient; retry later.

The HTTP status is 200 either way — branch on `available` and `reason`, not on status codes.

## `themes` — nearest themes to a description

The theme-level sibling: describe an idea, an angle, or a complaint in free text and get the ML conversation themes it lands on.

**REST:**

```
POST /lookalike/themes
{ "query": "frustration with slow security reviews blocking procurement", "limit": 5 }
```

**MCP:**

```
lookalike themes
  query = "frustration with slow security reviews blocking procurement"
  limit = 5
```

```json
{
  "success": true,
  "results": [
    { "cluster_id": "c_0412", "label": "Security review as deal blocker", "score": 0.88, "member_count": 96 },
    { "cluster_id": "c_0197", "label": "Procurement timeline friction", "score": 0.81, "member_count": 143 }
  ],
  "freshness": { "source": "pgvector", "synced_at": "2026-07-21T04:12:09Z" }
}
```

Unlike `find`, `themes` never returns `available: false` — when the fast centroid mirror is off or unsynced it transparently falls back to the warehouse theme index, and `freshness.source` tells you which one answered (`pgvector` with a `synced_at` stamp, or `bigquery` for the fallback).

## Paste this into Claude

```
Similarity read over our own corpus — use the lookalike tool.

Seed: {company id or domain of a top closed-won account | deal id}.
Find the {10} most similar {companies | deals}, with scores and member counts.

If it comes back available: false with centroids_not_materialized, don't
improvise a list — tell me, then run the themes action instead with a
description of what made the seed a great account, and give me the nearest
themes with their labels and member counts.

For every match, note the member_count so I know how much conversation
evidence backs the similarity.
```

## Variations

- **Deal-shaped seeds**: `entity_type: "deal"` + the deal id — "which deals did this one talk like?" pairs well with [what separates won from lost](../win-loss-deal-postmortem/what-separates-won-from-lost.md).
- **Campaign-to-theme mapping**: run `themes` on a draft campaign angle before you write it — if it maps onto a big, well-labeled theme you have grounding; if nothing scores well, your corpus doesn't talk about it yet.
- **Chain it**: seed from your best closed-won, then enrich + interrogate each match — the full play is [the expansion motion](expansion-motion-end-to-end.md).

## Tips

- **Prefer `entity_id` over `domain`.** Centroid ids are pipeline company ids; a structured-search row gives you the real id for free, and an unmapped domain resolves to `available: false` by design.
- **Weight matches by `member_count`.** Similarity over a thin corpus slice is noisy; the score ranks, the member count tells you how much to trust the rank.
- **`available: false` is a state, not a bug.** Centroids materialize on the pipeline's cadence — build the fallback (themes / semantic search / re-check) into any automation instead of treating it as an error path.
- **Lookalike expansion mines your corpus, not the open market.** Matches are entities you've already talked to — dormant accounts, stalled deals, early conversations that resemble your winners. For net-new names outside your data, that's [outbound targeting by signal](../content-and-outbound/outbound-targeting-by-signal.md).

## See also

- [The expansion motion, end to end](expansion-motion-end-to-end.md) — lookalike -> enrich -> semantic search as one chained workflow.
- [Semantic search](semantic-search.md) — utterance-level meaning search; `themes` is its theme-level sibling.
- [Tiered enrichment](tiered-enrichment.md) — what to run on each match once you have the list.
- [Agent platform overview](README.md) — the flag prerequisite and the scope table.
