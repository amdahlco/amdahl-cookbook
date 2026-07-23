# Use case: the expansion motion, end to end

**What this does**: Chains the three endpoints into one workflow: take a top closed-won account as the seed, [`lookalike`](lookalikes.md) the accounts in your corpus that sound most like it, [`enrich`](tiered-enrichment.md) each match on the fast tier, then run a [semantic search](semantic-search.md) across the matches for the objections that will come up — ending in a ranked expansion list where every account carries a "why them" and a "what they'll push back on."

**When to use it**: You're building an expansion / reactivation push from evidence instead of intuition. Every step is a fast synchronous call, so the whole motion runs inline in an agent turn or a script — no multi-step Chat required (though the *interpretation* at the end is a good [Chat](agentic-chat.md) ask).

## Why this matters

The usual expansion list is firmographic: same industry, same size band as your wins. This motion ranks by something sharper — **accounts whose conversations resemble your best win's conversations** — and then arms each name before anyone reaches out. It also composes honestly: lookalike matches are entities already in your corpus (dormant accounts, stalled deals, early conversations), so this is a *mine-your-own-data* motion; the semantic pass at the end reads what those exact accounts already told you, which is prep no external tool can generate. One seed in, a briefed target list out, four endpoints, no waiting on a deep investigation.

## Step 1 — pick the seed (structured search)

Your biggest closed-won deals, via the [filter lane](structured-search.md). The rows carry both `deal_id` and `company_id` — the company id is the seed for step 2.

```
POST /search/query
Authorization: Bearer <api-key with data:read>
Content-Type: application/json

{
  "surface": "deals",
  "filters": [ { "field": "deal_stage_is_won", "op": "eq", "value": true } ],
  "order_by": { "field": "deal_amount", "dir": "desc" },
  "limit": 5
}
```

Pick the winner that best represents the motion you want to repeat (a reference-status win beats a one-off whale), and take its `company_id`.

## Step 2 — find the lookalikes

```
POST /lookalike
{ "entity_type": "company", "entity_id": "<seed company_id>", "limit": 10 }
```

```json
{
  "success": true,
  "available": true,
  "seed": { "entity_id": "1852…", "member_count": 214, "computed_at": "2026-07-19T03:40:11Z" },
  "matches": [
    { "entity_id": "9b03…", "score": 0.91, "member_count": 88 },
    { "entity_id": "77aa…", "score": 0.87, "member_count": 45 }
  ]
}
```

**If it comes back `available: false`** with `centroids_not_materialized`, the similarity data hasn't been materialized for your workspace yet (it builds on the pipeline's cadence). Don't abort the motion — run the degraded version: `POST /lookalike/themes` with a description of what made the seed great, then use a [semantic search](semantic-search.md) for accounts discussing those themes. Re-check `find` on a later run.

## Step 3 — the id -> domain bridge (structured search again)

Lookalike matches come back as pipeline **company ids**; enrichment keys on **domains**. One aggregate slice over `interactions` bridges them — and tells you how much history you hold on each match for free:

```
POST /search/query
{
  "surface": "interactions",
  "filters": [ { "field": "company_id", "op": "in", "value": ["9b03…", "77aa…"] } ],
  "group_by": [ "company_id", "company_domain", "company_name" ],
  "metrics": [ { "fn": "count" } ],
  "order_by": { "field": "count", "dir": "desc" }
}
```

```json
{
  "results": [
    { "company_id": "9b03…", "company_domain": "northwind.com", "company_name": "Northwind", "count": 412 },
    { "company_id": "77aa…", "company_domain": "contoso.io", "company_name": "Contoso", "count": 63 }
  ]
}
```

## Step 4 — enrich each match, fast tier

One quick tiered call per domain. You get a cached brief or first-party evidence *now*; every cache miss queues the full brief rebuild in the background (`refresh_enqueued: true`), so by the time a human works the list, the deep briefs are waiting.

```
POST /enrich/company
{ "domain": "northwind.com", "name": "Northwind" }
```

Branch on `tier`: `cached` gives you the brief + `captured_at`; `first_party` gives you the account's own words to you plus the queued refresh. Don't pass `mode: "full"` in this loop — blocking on N deep composites defeats the fast motion; let the background refreshes do that work.

## Step 5 — the objection pass (semantic search across the matches)

Ask one meaning-shaped question scoped to the whole match list with a `company_id in […]` filter — the same ids lookalike returned:

```
POST /search/query
{
  "query": "objections, hesitations, and concerns about pricing, rollout effort, or security review",
  "mode": "semantic",
  "filters": [
    { "field": "company_id", "op": "in", "value": ["9b03…", "77aa…"] },
    { "field": "speaker_type", "op": "eq", "value": "external" }
  ],
  "limit": 30
}
```

Group the matches by `company_id` and you have, per target account, the pushback **they already voiced** — the difference between a cold re-open and a first line that lands.

## The whole motion, in pseudocode

```
won   = POST /search/query { surface: "deals", filters: [is_won], order_by: amount desc, limit: 5 }
seed  = won.results[0].company_id

lk    = POST /lookalike { entity_type: "company", entity_id: seed, limit: 10 }
if not lk.available:                       # centroids_not_materialized — degrade, don't abort
    themes = POST /lookalike/themes { query: "<what made the seed great>" }
    …fall back to semantic search over those themes…

ids   = [m.entity_id for m in lk.matches]
rows  = POST /search/query { surface: "interactions", filters: [company_id in ids],
                             group_by: [company_id, company_domain, company_name],
                             metrics: [count] }

for r in rows.results:                     # fast enrich; misses queue the deep briefs
    POST /enrich/company { domain: r.company_domain, name: r.company_name }

obj   = POST /search/query { query: "objections about pricing, rollout, security…",
                             mode: "semantic",
                             filters: [company_id in ids, speaker_type = external] }

rank by lk.score, weight by member_count, attach per-account objections
```

## Paste this into Claude

The MCP-native version — Claude drives `search`, `lookalike`, and `enrich` for you:

```
Build me an expansion target list from our own corpus, grounded at every step.

1. Find our top 5 closed-won deals by amount (structured search on the deals
   surface, deal_stage_is_won = true). Tell me which one looks like the most
   repeatable win and use its company as the seed.
2. Run lookalike find on that seed company (limit 10). If similarity data
   isn't materialized (available: false), say so and fall back to lookalike
   themes + a semantic search — don't invent a list.
3. Bridge the match ids to domains with a structured search over interactions
   (group by company_id, company_domain, company_name with a count), and note
   how much conversation history we hold on each.
4. Enrich each match in fast mode. Report the tier per account; where it's
   first_party, quote the strongest thing they've said to us and confirm the
   full-brief refresh was enqueued.
5. Semantic-search objections across the match list (external speakers only)
   and attach each account's own past pushback.

End with a ranked table: account, similarity score, member_count, how much
history we hold, the strongest hook, and the likely first objection. Flag any
account where the evidence is thin instead of padding it.
```

## What you'll see back

- A named seed win with the reasoning for choosing it.
- A ranked lookalike list — or an explicit "similarity data not materialized yet" with the themes-based fallback, never an invented ranking.
- Per account: the enrichment tier that answered, the strongest first-party hook, and the objections that account has already raised, verbatim.
- A final table sorted by similarity, with thin-evidence accounts flagged.

## Variations

- **Deal-shaped seed**: run step 2 with `entity_type: "deal"` and the won deal's id to rank *deals* that talked like it — then triage the open ones.
- **Reactivation cut**: intersect the match list with a structured search for accounts whose last interaction `timestamp` is older than 90 days — lookalikes that went quiet are the warmest cold list you own.
- **Hand the interpretation to a Chat**: once the data's assembled, "which 3 of these should we work first, and with what play?" is a judgment call — a good [Chat](agentic-chat.md) ask with this list as input.
- **Make it a Routine**: wrap the whole prompt in a [Routine](routines.md) so the expansion list refreshes itself monthly as new calls land and centroids re-materialize.

## Tips

- **This motion mines your corpus, not the open market.** Every name on the list is an account you've already talked to — which is exactly why the objection pass works. For net-new targets, pair with [outbound targeting by signal](../content-and-outbound/outbound-targeting-by-signal.md).
- **Weight by `member_count` at every step.** A 0.9 similarity over 6 utterances is a hint; over 200 it's a signal.
- **Fast enrich in the loop, deep briefs after.** The loop stays quick because misses only *queue* the full rebuild — re-pull the briefs (now cached) when a human picks up the list.
- **Degrade, don't abort.** `available: false` on lookalike has a designed fallback (themes + semantic). Build it in; the motion still produces a grounded list.

## See also

- [Lookalikes](lookalikes.md) · [Tiered enrichment](tiered-enrichment.md) · [Structured search](structured-search.md) · [Semantic search](semantic-search.md) — the four endpoints this motion chains.
- [Call prep + objection handling, end to end](call-prep-objection-end-to-end.md) — the single-account sibling of this play.
- The GTM prompt version: [outbound targeting by signal](../content-and-outbound/outbound-targeting-by-signal.md) — the market-side complement.
