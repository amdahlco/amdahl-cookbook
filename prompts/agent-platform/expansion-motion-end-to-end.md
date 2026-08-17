# Use case: the expansion motion, end to end

**What this does**: Chains the search lanes into one workflow: take a top closed-won account as the seed, read what made its conversations distinctive, [semantic-search](semantic-search.md) your corpus for the accounts that sound most like it, then run a second semantic pass across those matches for the objections that will come up — ending in a ranked expansion list where every account carries a "why them" and a "what they'll push back on."

**When to use it**: You're building an expansion / reactivation push from evidence instead of intuition. Every step is a fast synchronous call, so the whole motion runs inline in an agent turn or a script — no multi-step Chat required (though the *interpretation* at the end is a good [Chat](agentic-chat.md) ask).

## Why this matters

The usual expansion list is firmographic: same industry, same size band as your wins. This motion ranks by something sharper — **accounts whose conversations resemble your best win's conversations** — and then arms each name before anyone reaches out. It also composes honestly: every match is an entity already in your corpus (dormant accounts, stalled deals, early conversations), so this is a *mine-your-own-data* motion; the objection pass at the end reads what those exact accounts already told you, which is prep no external tool can generate.

## Step 1 — pick the seed (structured search)

Your biggest closed-won deals, via the [filter lane](structured-search.md). The rows carry both `deal_id` and `company_id`.

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

## Step 2 — read what made the seed distinctive

Before you can find accounts that sound like the seed, you need to know what the seed sounded like. One semantic pass scoped to that one company, external speakers only:

```
POST /search/query
{
  "query": "why they bought, what problem they were solving, what they compared us against",
  "mode": "semantic",
  "filters": [
    { "field": "company_id", "op": "eq", "value": "<seed company_id>" },
    { "field": "speaker_type", "op": "eq", "value": "external" }
  ],
  "limit": 20
}
```

Read the returned utterances and write down the two or three phrases that actually recur — the problem in the buyer's words, the trigger, the alternative they weighed. **Those phrases are the query for step 3.** Do not paraphrase them into your own vocabulary; the whole point is to match on how buyers talk, not how you pitch.

## Step 3 — find the accounts that sound like it (semantic search)

Feed those phrases back as a meaning-shaped query across the whole corpus, and exclude the seed so it does not rank against itself:

```
POST /search/query
{
  "query": "<the recurring phrases from step 2, in the buyer's words>",
  "mode": "semantic",
  "filters": [ { "field": "speaker_type", "op": "eq", "value": "external" } ],
  "limit": 50
}
```

Group the results by `company_id`. An account with many strong matches is a better candidate than one with a single high-scoring line — **breadth of agreement beats a single good quote**, and grouping is what tells them apart.

## Step 4 — size each candidate (structured search)

The semantic pass ranks utterances; you want accounts. One aggregate slice over `interactions` turns the match ids into accounts with domains and tells you how much history you hold on each:

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

## Step 5 — the objection pass (semantic search across the matches)

Ask one meaning-shaped question scoped to the whole match list with a `company_id in […]` filter:

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

Group by `company_id` and you have, per target account, the pushback **they already voiced** — the difference between a cold re-open and a first line that lands.

## The whole motion, in pseudocode

```
won    = POST /search/query { surface: "deals", filters: [is_won], order_by: amount desc, limit: 5 }
seed   = won.results[0].company_id

voice  = POST /search/query { query: "why they bought, what they compared us against",
                              mode: "semantic",
                              filters: [company_id = seed, speaker_type = external] }
phrases = the recurring language in voice.results, verbatim

near   = POST /search/query { query: phrases, mode: "semantic",
                              filters: [speaker_type = external], limit: 50 }
ids    = group near.results by company_id, drop the seed, keep the accounts
         with SEVERAL strong matches rather than one

rows   = POST /search/query { surface: "interactions", filters: [company_id in ids],
                              group_by: [company_id, company_domain, company_name],
                              metrics: [count] }

obj    = POST /search/query { query: "objections about pricing, rollout, security…",
                              mode: "semantic",
                              filters: [company_id in ids, speaker_type = external] }

rank by how many matches each account contributed, weight by history volume,
attach per-account objections
```

## Paste this into Claude

The MCP-native version — Claude drives `search` for you:

```
Build me an expansion target list from our own corpus, grounded at every step.

1. Find our top 5 closed-won deals by amount (structured search on the deals
   surface, deal_stage_is_won = true). Tell me which one looks like the most
   repeatable win and use its company as the seed.
2. Semantic-search that one company (external speakers only) for why they
   bought and what they compared us against. Quote back the two or three
   phrases that actually recur — in the buyer's words, not ours.
3. Semantic-search the whole corpus with those phrases, external speakers
   only. Group the hits by company and drop the seed. Rank by how many
   distinct strong matches each account contributed, not by a single top
   score, and say which accounts are thin.
4. Bridge those ids with a structured search over interactions (group by
   company_id, company_domain, company_name with a count), and note how much
   conversation history we hold on each.
5. Semantic-search objections across the match list (external speakers only)
   and attach each account's own past pushback.

End with a ranked table: account, why it matched (quote one line), how much
history we hold, the strongest hook, and the likely first objection. Flag any
account where the evidence is thin instead of padding it.
```

## What you'll see back

- A named seed win with the reasoning for choosing it.
- The seed's own recurring language, quoted — the thing the ranking is actually built on.
- A ranked candidate list with per-account evidence, and thin-evidence accounts flagged rather than padded.
- Per account: the objections that account has already raised, verbatim.

## Variations

- **Reactivation cut**: intersect the match list with a structured search for accounts whose last interaction `timestamp` is older than 90 days — near-matches that went quiet are the warmest cold list you own.
- **Hand the interpretation to a Chat**: once the data's assembled, "which 3 of these should we work first, and with what play?" is a judgment call — a good [Chat](agentic-chat.md) ask with this list as input.
- **Deep briefs on the shortlist**: once a human has picked the top few, a [Chat](agentic-chat.md) can research those accounts properly, market signal included. That is the right place for depth — a per-account brief across fifty candidates is work nobody reads.
- **Make it a Routine**: wrap the whole prompt in a [Routine](routines.md) so the expansion list refreshes itself monthly as new calls land.

## Tips

- **This motion mines your corpus, not the open market.** Every name on the list is an account you've already talked to — which is exactly why the objection pass works. For net-new targets, pair with [outbound targeting by signal](../content-and-outbound/outbound-targeting-by-signal.md).
- **Weight by volume at every step.** One strong match over 6 utterances is a hint; a pattern over 200 is a signal. Step 4 exists to make that difference visible before anyone works the list.
- **Let the buyer's words drive step 3.** The most common way this motion goes wrong is substituting your positioning language for theirs in the query — you then find the accounts that already sound like your website, which is the opposite of the point.
- **Drop the seed from its own results.** It will rank first every time, and leaving it in silently costs you a real candidate at the bottom of the list.

## See also

- [Structured search](structured-search.md) · [Semantic search](semantic-search.md) — the two lanes this motion chains.
- [Call prep + objection handling, end to end](call-prep-objection-end-to-end.md) — the single-account sibling of this play.
- The GTM prompt version: [outbound targeting by signal](../content-and-outbound/outbound-targeting-by-signal.md) — the market-side complement.
