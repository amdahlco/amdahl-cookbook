# Grade cold outbound with web evidence - the external tier

**What this does**: Adds a fourth evidence tier to an eval run. Pass `include_external: true` on `evals.run` and the grader searches the public web for market signal relevant to your copy, folds the results in as `external`-tier quotes, and grades market claims against them - alongside (never instead of) the customer-voice tiers.

**When to use it**: You are grading COLD outbound. The [LangSmith recipe's trap list](evals-in-langsmith.md#traps) ends on the structural gap: *a cold prospect has no account-tier evidence by definition* - your workspace corpus holds nothing they ever said. Before this flag, market claims in cold copy ("teams are consolidating their RevOps stack", "the category moved to seat pricing") could only lean on corpus-tier customer quotes that may not cover them. With it, those claims get graded against what the public web actually says.

## The one flag

Everything else about [the eval](evals.md) is unchanged - same call, same handle, same poll. Add two fields to the run request:

```
POST https://app.amdahl.ai/api/platform/v1/evals/run
Authorization: Bearer <api-key with evals:execute AND external_search:execute>
Content-Type: application/json

{
  "inputs": {
    "message": "<the cold email>",
    "audience": "VP of Sales, mid-market SaaS"
  },
  "include_external": true,
  "external_cap": 15
}
```

- `include_external` - opt-in, default off. The run plans ONE web search from your submission (a lightweight model writes the query; a deterministic fallback covers it), retrieves ranked public citations, and tags each as an `external`-tier quote.
- `external_cap` - optional; how many web quotes to retrieve. Default 15, clamped 1-25. The ack echoes the CLAMPED value back as `external: { "cap": ... }`, so an over-asked cap is visible, never silent.

On MCP it is the same two fields on the `evals` tool's `run` action.

**Two refusals happen at dispatch, before anything runs:**

- **Missing scope.** The web fan-out is paid HTTP, so it is gated on `external_search:execute` in addition to `evals:execute`. A key without it is refused with `details.missing_scope` naming the scope - mint a key that carries both (the customer-agent bundle does; read-only keys do not).
- **Pinned evidence.** `include_external` cannot combine with `evidence_from_run`. A pin says "hold the evidence fixed so the delta is about my copy"; a web fan-out adds fresh quotes to the pool. The pair is refused with `details.conflict` rather than silently preferring one - pick which property you want per run.

## What changes in the report

**The tier, and its licence.** Every web quote carries `tier: "external"` with its source (the publication or domain). The tier is a LICENCE, exactly like the customer tiers: `account` backs "you told us", `segment` backs "teams like yours", `corpus` backs "the leaders we talk to" - and `external` backs **market and public-record claims only, never "our customers say"**. The judge is told this, the report renders it (the console draws the quote outlined, labelled "From the web"), and a claim that reaches past it fails grounding the same way an over-claimed customer quote does.

**Customer voice keeps its seats.** The prompt seeds evidence narrowest-first - account, then segment, then a few external quotes, then the corpus fan-out, then the external tail - and the budgets are sized so customer quotes always reach the judge. Web evidence extends the pool; it cannot crowd out what your buyers said.

**Disclosure on the verdict.** The grader's evidence block records what the web leg did: `external_status` (retrieved, or WHY not - `no_results`, `lookup_failed`, `no_scope`), `external_query` (the exact search that ran), `external_sources`, `external_quotes`. A failed web leg DEGRADES - the run still grades on the customer tiers and says the leg failed - it never fails the run and never presents as "the web says nothing".

**Reuse re-addresses.** The cached-reuse fingerprint includes the flag and the cap, so `reuse: "cached"` never hands an external run back to an internal request, or a cap-25 run back to a cap-5 request.

## Worked example - a market claim in cold copy

Submit a cold email whose spine is a market claim:

> "Most mid-market sales teams are consolidating three point tools into one platform this year - we help you get ahead of that."

- **Without** `include_external`: the claim can only be checked against corpus-tier customer quotes. If your buyers never discussed consolidation, the claim reads as ungrounded and fails Verified specifics - even if it is true in the market.
- **With** `include_external`: the run searches the web for consolidation-in-mid-market-sales signal. A supporting analyst piece or industry survey becomes an `external` quote the claim can cite; a contradicting one is the highest-signal thing the report can hand you - the market saying the opposite of your opener.

Either way the customer tiers still grade everything they cover, so a claim your buyers DID talk about is held to their words first.

## Traps

- **External evidence is not customer voice, and the report will not let it pretend to be.** A web quote can verify "the category moved to X"; it can never verify "our customers tell us X". If your copy claims customer proof, only the customer tiers can ground it - no cap raise changes that.
- **It costs money and time.** The web leg is a paid search fan-out plus extra judge input. Leave it off for warm accounts where the corpus already covers the copy; turn it on for cold lists and market-claim-heavy messaging.
- **A/Bs with web evidence are noisier.** The pin refusal means you cannot freeze a pool that includes web quotes - each external run retrieves fresh. For "did v2 beat v1" comparisons, either pin (and give up web evidence for that A/B) or run a median of N per side, per the [LangSmith trap list](evals-in-langsmith.md#traps).
- **`no_results` is an answer.** A niche claim can come back with zero usable citations. The run grades without the tier and `external_status` says so - do not read that as the market disagreeing, and do not retry expecting different weather.

## See also

- [Evals - grade a message against customer voice](evals.md) - the full surface this flag extends: the report card, the rewrite, audience scoping, reuse.
- [Amdahl evals in LangSmith](evals-in-langsmith.md) - the pipeline-gate slice; its cold-prospect trap is the gap this tier closes.
- [Personalize cold outreach](../content-and-outbound/personalize-cold-outreach.md) - write the cold openers this recipe grades.
- [Prospect cold research](../customer-research/prospect-cold-research.md) - the deep pre-send brief on a cold account.
