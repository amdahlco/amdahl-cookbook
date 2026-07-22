# Tiered enrichment — company, person, topic

**What this does**: Returns intelligence on a company, a person, or a topic **fast by default**: a fresh cached brief comes back instantly; on a cache miss you get your own first-party conversation evidence in a bounded read while the full web + LinkedIn + Crunchbase fusion rebuilds in the background (`refresh_enqueued: true`). Pass `mode: "full"` when you'd rather block for the complete fused brief — including the market-vs-customers divergence map — inline.

**When to use it**: Call prep, outreach personalization, account research, topic scoping — any "tell me about X" where you want *something grounded now* and the deep brief soon. The deep composite is a long synchronous call; the tiered flow means your agent step or UI never has to sit through it just to say something useful.

## Why this matters

Enrichment has always had a latency/depth tradeoff: the deep fused brief is the good stuff, but it's a long blocking call — the wrong shape for an agent mid-turn or a hover-card. The tier ladder resolves it without lying:

- **Tier `cached`** — a brief you (or a background refresh) already paid for, served from the store. Company briefs stay fresh for ~7 days, person and topic briefs ~14; the response carries `captured_at` so you can judge staleness yourself, plus the `artifact_id` backing it.
- **Tier `first_party`** — on a miss, a bounded read over your **own** corpus: who's talked to this account, what they said, what your customers say about this topic. It answers in seconds because it never leaves your tenant — and it's evidence generic enrichment tools don't have.
- **The background refresh** — on that same miss, the full composite is enqueued behind the scenes (`refresh_enqueued: true`), so a later call for the same subject lands on tier `cached`. First call seeds; second call feasts.
- **`mode: "full"`** — run the synchronous fused composite inline and return its brief (`tier: "full"`). This is the deep, slow call — use it when you're willing to wait.

The paid tiers (the background refresh and `mode: "full"`) require the `external_search:execute` scope and **degrade instead of failing**: a key without it still gets cache + first-party evidence, with `refresh_omitted: "missing_scope"` telling you why no refresh was queued.

## The operations

| Subject | Operation | REST | MCP (`enrich` tool) | Scope |
|---|---|---|---|---|
| Company (by domain) | `enrich.company` | `POST /enrich/company` | action `company` | `data:read` (+ `external_search:execute` for the paid tiers) |
| Person (by LinkedIn URL or email) | `enrich.person` | `POST /enrich/person` | action `person` | same |
| Topic (by term) | `enrich.topic` | `POST /enrich/topic` | action `topic` | same |

## Company — by domain

**REST:**

```
POST /enrich/company
Authorization: Bearer <api-key with data:read>
Content-Type: application/json

{ "domain": "stripe.com", "name": "Stripe" }
```

**MCP** (the `enrich` coarse tool, `company` action):

```
enrich company
  domain = "stripe.com"
  name   = "Stripe"
```

`domain` is required (it's the cache key); `name` is optional and sharpens both the evidence read and the full fan-out.

**Cache hit** — the stored brief, instantly:

```json
{
  "success": true,
  "tier": "cached",
  "brief": { "summary": "…", "sections": { "positioning": "…", "recent_signals": "…" }, "citations": ["…"], "divergence_map": { "internal_only": ["…"], "market_only": ["…"] } },
  "artifact_id": "a91f…",
  "captured_at": "2026-07-18T02:11:40Z",
  "refresh_enqueued": false
}
```

**Cache miss** — your first-party evidence now, the rebuild queued:

```json
{
  "success": true,
  "tier": "first_party",
  "evidence": {
    "matched_count": 23,
    "utterances": [
      { "text": "we're consolidating vendors this quarter…", "speaker_type": "external", "interaction_id": "int_4812…", "relevance": 0.86 }
    ],
    "narrative_facts": [],
    "entity_lifts": [],
    "call_fingerprints": [],
    "aggregates": { "…": "…" }
  },
  "refresh_enqueued": true
}
```

`evidence` is the bounded internal-evidence envelope — ranked `utterances` plus, when your corpus supports them, `narrative_facts`, `entity_lifts`, and per-call `call_fingerprints`. An account with no history returns the empty envelope (`matched_count: 0`), not an error.

`refresh_enqueued: true` means the full composite is rebuilding in the background — re-call the same subject later and you'll land on `tier: "cached"`. There's no promised completion time; treat it as "soon", and poll by simply re-calling.

## Person — by LinkedIn URL or email

A **bare name is refused** (`invalid_argument`) — a name can't be resolved to one person, and a name-keyed cache would poison lookups. Anchor on `linkedin_url` (preferred — it's the cache key) or `email`:

```
POST /enrich/person
{ "linkedin_url": "https://www.linkedin.com/in/example-person/", "name": "Jordan Lee" }
```

```
enrich person
  linkedin_url = "https://www.linkedin.com/in/example-person/"
  name         = "Jordan Lee"
```

An **email-only** call works, but skips the cache tier by construction (the person-brief cache keys on `linkedin_url`) — it goes straight to first-party evidence (your calls and threads that mention them), with the deep-profile refresh queued behind it.

## Topic — by term

The topic brief keys on the verbatim term; the first-party tier reads what **your customers** say about it (external speakers by construction), so even the fast answer carries the internal half of the divergence story:

```
POST /enrich/topic
{ "topic": "AI SDRs" }
```

```
enrich topic
  topic = "AI SDRs"
```

`mode: "full"` on a topic runs the whole divergence-map synthesis inline — market story vs. your customers' story, with the disagreements called out — the long call worth making when the topic is the deliverable.

## Paste this into Claude

```
Tiered enrichment, fast path first — use the enrich tool.

Enrich: {company {domain} | person {linkedin_url or email} | topic "{term}"}.

Start in fast mode. Tell me which tier answered (cached / first_party), and:
- if cached: summarize the brief and give me captured_at so I know how fresh it is;
- if first_party: give me the strongest first-party evidence verbatim, confirm
  whether refresh_enqueued is true, and re-check the cache before we finish.

Only use mode "full" if I explicitly say I'm willing to wait for the deep brief.
```

## Variations

- **Block for the deep brief**: `mode: "full"` returns `tier: "full"` with the complete fused brief inline. Requires `external_search:execute`; without it the call degrades to the fast path with `refresh_omitted: "missing_scope"` instead of erroring.
- **Warm the cache ahead of a meeting block**: fast-enrich tomorrow's accounts this afternoon; each miss queues a refresh, so by meeting time the same calls land on `tier: "cached"`.
- **Read-only key**: everything still works on `data:read` alone — you get cache hits and first-party evidence; `refresh_omitted: "missing_scope"` just tells you no background rebuild was queued (so a cold subject stays on the first-party tier until a scoped caller warms it).
- **Batch politely**: enriching a list (like the [expansion motion](expansion-motion-end-to-end.md)) is exactly what fast mode is for — N quick tiered calls now, the deep briefs backfilling behind you.

## Tips

- **Branch on `tier`, render accordingly.** `cached` → a brief with `captured_at`; `first_party` → verbatim evidence plus a "full brief refreshing" note; `full` → the fused brief. Same envelope every time.
- **`refresh_enqueued: false` on a miss means look at `refresh_omitted`.** `missing_scope` is the usual reason; it's a degradation, not a failure.
- **Anchor people on identifiers, not names.** `linkedin_url` gets you the cache tier; `email` gets first-party resolution; a bare name gets a typed refusal by design.
- **The first-party tier is not a consolation prize.** "What this account said to *us*" is the half of the brief no external tool can produce — often it's the more useful half for a rep.

## See also

- [Lookalikes](lookalikes.md) — find *which* accounts to enrich (nearest neighbours to your best wins).
- [The expansion motion, end to end](expansion-motion-end-to-end.md) — lookalike -> enrich -> semantic search as one chained play.
- The GTM prompt versions: [deep-dive on account](../customer-research/deep-dive-on-account.md), [prospect cold research](../customer-research/prospect-cold-research.md).
- [Agent platform overview](README.md) — the flag prerequisite and the scope table.
