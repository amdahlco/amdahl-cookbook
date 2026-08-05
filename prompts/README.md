# Recipe library

48 recipes for go-to-market work. Most are self-contained markdown files with one paste-ready prompt, a "why this matters" explainer, what comes back, variations, and tips; the [agent-platform](agent-platform/README.md) section adds the developer-facing REST + MCP shapes for the same engine. The deeper recipes use a wave structure — explicit parallel sub-tasks the model can fan out on, then a synthesis pass — so a single paste does the work of three rounds of back-and-forth.

New here? Start with the [main README](../README.md) for setup and the six headliner prompts.

---

## Customer research (4)

Walk into any account already smarter than the rep before you — fusing your internal history with what's happening in their world right now.

- [Deep-dive on account](customer-research/deep-dive-on-account.md) — 1-page brief fusing full internal history (deals, calls, support, contacts) with public signal, ending with the divergence between the two.
- [Prospect cold research](customer-research/prospect-cold-research.md) — first read on a company you've never sold to, including the long-tail hooks from your own corpus.
- [What they care about](customer-research/what-they-care-about.md) — the 3 themes one account keeps coming back to, in their words, with seriousness scored.
- [Whose name comes up](customer-research/whose-name-comes-up.md) — shadow champions, blockers, incumbents, and people who aren't in the CRM but are in the calls.

## Competitive intel (4)

The gap between a competitor's marketing site and how buyers actually describe them on your calls — usually the most useful 200 words you'll read this quarter.

- [Competitor deep-dive](competitive-intel/competitor-deep-dive.md) — public posture vs. call reality, with the divergences and the attack angles they imply.
- [Where they show up in our calls](competitive-intel/where-they-show-up-in-our-calls.md) — the volume + trend view: are they showing up earlier, later, more, less, in which segments?
- [How buyers compare us](competitive-intel/how-buyers-compare-us.md) — verbatim head-to-head trade-offs in three buckets, including the tie bucket nobody else looks at.
- [Track a competitor's social presence](competitive-intel/track-competitor-social.md) — their public X / LinkedIn signal (cadence, engagement, follower trend) laid against what buyers actually say on your calls; the divergence is the lever.

## Positioning & messaging (4)

Pressure-test the words you use against the words your customers actually use — and surface the new headlines hiding in their language.

- [Audit our positioning](positioning-messaging/audit-our-positioning.md) — your homepage / one-pager vs. real customer voice, line by line, with grounded rewrites.
- [Rep vs. buyer language](positioning-messaging/rep-vs-buyer-language.md) — where reps and buyers describe the same thing in different words, and which side should win on each topic.
- [Stress-test a message](positioning-messaging/stress-test-a-message.md) — paste a draft, get the parts that won't land and why — with a SHIP / REWRITE / KILL verdict.
- [Rebuild your value narrative by segment](positioning-messaging/rebuild-value-narrative-by-segment.md) — raw customer voice per ICP segment with two anti-contamination filters; the raw material for a positioning pivot.

## Pre-meeting prep (3)

Walk in knowing the room — including the things the CRM forgot.

- [Sales call prep](pre-meeting-prep/sales-call-prep.md) — 1-page brief for tomorrow's discovery, demo, or negotiation, with attendee-specific context.
- [QBR prep](pre-meeting-prep/qbr-prep.md) — recap, risks, expansion angles (grounded in their quotes), and the 3 quotes to reference verbatim in the room.
- [Renewal prep](pre-meeting-prep/renewal-prep.md) — a year-long trajectory view ending in a FLAT / EXPAND / DEFEND posture recommendation.

## Win/loss & deal postmortem (3)

The honest reasons — turning points, unresolved objections, the moments deals actually shifted — not the dropdown reasons.

- [Why we lost this deal](win-loss-deal-postmortem/why-we-lost-this-deal.md) — single-deal postmortem with the turning point named and 3 specific do-overs.
- [Pattern across cohort](win-loss-deal-postmortem/pattern-across-cohort.md) — common threads across many deals, with the single biggest pattern phrased specifically enough to act on.
- [What separates won from lost](win-loss-deal-postmortem/what-separates-won-from-lost.md) — the diff, not two profiles: the 3 sharpest discriminators between deals that closed and ones that didn't.

## Content & outbound (4)

Grounded posts, smarter targeting, openers that aren't Mad Libs.

- [Draft a LinkedIn post (grounded)](content-and-outbound/draft-linkedin-post-grounded.md) — your voice, anchored in an anonymized verbatim buyer phrase, ending in a real question.
- [Find content gaps](content-and-outbound/find-content-gaps.md) — buyer questions your published content doesn't answer, with a ranked content roadmap.
- [Outbound targeting by signal](content-and-outbound/outbound-targeting-by-signal.md) — a target list built from the signals your wins actually shared, with a "stop targeting on" list of filters that don't correlate.
- [Personalize cold outreach](content-and-outbound/personalize-cold-outreach.md) — a non-generic 2-sentence opener per prospect, with skips when the hook isn't real.

## Pipeline pulse (4)

Weekly health, risk surfacing, zombie cleanup, and fast lookups — all on a cadence.

- [Weekly recap](pipeline-pulse/weekly-recap.md) — what moved, what slipped, what's new, what went quiet, plus the one question to ask in standup.
- [Deals at risk](pipeline-pulse/deals-at-risk.md) — deals that look healthy on paper but are at risk in the call content, sorted by ACV × severity.
- [Stalled pipeline triage](pipeline-pulse/stalled-pipeline-triage.md) — chase / nurture / close-lost, with the honest verbatim "why it died" on each loss.
- [Quick lookup (fast lane)](pipeline-pulse/quick-lookup-fast-lane.md) — one concrete question, one synchronous `search` call: the rows plus the SQL it ran, with an optional blended public angle. For "get me the number," not a multi-step investigation.

## Pages & dashboards (2)

Turn an answer into a real, designed Page in your console — a workspace data UI over your live tenant data, not a chat transcript — and embed it live anywhere. Page authoring is a **console capability** (the `pages` MCP tool was retired and the endpoints behind the console aren't reachable with an external API key), so these plays have Claude draft the page spec and you create it in the console's Pages surface. See the [section README](pages-and-dashboards/README.md) for the three page layouts (dashboard / single / document) and the [create-a-page command](../plugins/amdahl-gtm/commands/create-page.md) for the full contract.

- [Build a markdown report page](pages-and-dashboards/markdown-report-page.md) — publish a written deliverable (competitive brief, account one-pager, positioning memo) as a `document`-layout Page: a centered prose column built from `Markdown` blocks, no SQL required.
- [Embed a live page](pages-and-dashboards/embed-a-page.md) — build a Page, then mint a self-scoped, signed, short-lived embed link to drop it live into another site. Fails closed by design; public/workspace embeds are admin-gated; rotating the per-tenant secret revokes every embed at once.

## Knowledge sync (1)

Mirror your Amdahl knowledge base into a Notion database in your own workspace — set it up once, then every document you promote in Amdahl shows up (and stays current) in Notion automatically. See the [section README](knowledge-sync/README.md).

- [Mirror your knowledge base to Notion](knowledge-sync/mirror-knowledge-base-to-notion.md) — the **connect -> configure -> it-syncs-itself -> monitor** loop: connect Notion over OAuth, designate a parent page (provisions a database + backfills), then watch it mirror every promoted doc. One-way, current-version-only, self-healing on an hourly reconcile. Setup and monitoring live in the console; agents feed it through the knowledge base.

## Notifications (1)

Email people on your workspace from an agent run — members-only, rate-capped, idempotent, so an agent can deliver autonomously without becoming a spam cannon. Driven through Chat and Routines (`actions_allowed`). See the [section README](notifications/README.md).

- [Notify the workspace team](notifications/notify-the-workspace-team.md) — the **discover -> send -> verify** discipline, the guardrail contract (member-only / capped / idempotent), and the unattended paths: a Routine with `email_member` granted, or a Workflow `tool` step.

## Workflows & blueprints (1)

Author reusable, typed **Workflow** recipes (blueprints) the platform can validate, version, fork, schedule, and run headlessly. A console capability — from a connected Claude session, recurring work is a Routine and one-shot deep work is a Chat. See the [section README](blueprints/README.md).

- [How to write an Amdahl blueprint](blueprints/authoring-a-blueprint.md) — the mental model, the full DSL anatomy (inputs, outputs, the 8 step kinds, `$`-references, `prompt://` fragments, policy, trigger), validating in the console, and two worked examples (from scratch, and fork-a-starter).

## Agent platform — API + MCP (16)

The developer-facing view of the engine the prompts above run on: how to drive Amdahl's two "ask Amdahl" doors — and the automation around them — from your own code, over REST and MCP. Requires Agent Platform v2 (the `search` + `agents` MCP tools). See the [section README](agent-platform/README.md).

**The mental model:**

- [Amdahl is one layer of your GTM brain](agent-platform/gtm-brain-architecture.md) — skills + agents + a shared MCP belt; Amdahl is one server on it, wired once. Why hand-rolled context breaks, and why it's a layer, not an integration.
- [The four shapes of an Amdahl play](agent-platform/four-flows.md) — automated / interactive / scheduled / ad hoc, the one contract they share, and the outbound motion worked in full.

**The doors + primitives:**

- [Fast lane — `search.run`](agent-platform/fast-lane-search.md) — one synchronous call: the request, the full response envelope (`internal.status`, the SQL, blended citations), the typed-failure contract, and the `escalate_to_chat` handoff.
- [Structured search — typed filters](agent-platform/structured-search.md) — the config-DSL lane of `search.query`: declarative `{field, op, value}` filters, `group_by` + `metrics` aggregations, and the `search.fields` vocabulary catalog (the compiled SQL comes back as the receipt).
- [Semantic search — meaning over the call corpus](agent-platform/semantic-search.md) — the vector lane of the same endpoint: meaning-shaped asks, semantic query + filters, and reading `mode_ran` + `freshness`.
- [Tiered enrichment — company, person, topic](agent-platform/tiered-enrichment.md) — `enrich.*`: cached brief instantly, first-party evidence on a miss with the full brief rebuilding in the background, `mode: "full"` to wait for the deep brief.
- [Lookalikes — nearest accounts, deals, and themes](agent-platform/lookalikes.md) — `lookalike.find` + `themes`: "more like this one" over your own corpus, with the honest `available: false` contract while centroids materialize.
- [Agentic Chat — start, poll, respond](agent-platform/agentic-chat.md) — the always-async lane end to end: start -> poll (or stream) -> render -> answer a pause. REST + the MCP `agents` tool, plus the `depth` knob.
- [Routines — make a Chat recur](agent-platform/routines.md) — a cron that fires a fresh Chat each occurrence: create / list / update / delete / run-now, and `actions_allowed` for autonomous sends.
- [Saved agents — reuse a prompt](agent-platform/saved-agents.md) — the agent library: create a named agent, pin it in a Chat, schedule it as a Routine.
- [Evals — grade a message against customer voice](agent-platform/evals.md) — `evals.run` (MCP `grade`): pass in a drafted message + its prompt, poll the run, and read the scorecard — a `pass` / `partial` / `fail` / `not_applicable` verdict, a per-dimension breakdown, the verbatim customer quotes that support or contradict it, and a grounded rewrite. Plus the builder for authoring your own eval.
- [Amdahl evals in LangSmith](agent-platform/evals-in-langsmith.md) — wire the eval as a pipeline gate: `evals.run` with `mode: "gate"` (grade-only, no rewrite), the `/gate` read, a copy-paste LangSmith custom evaluator, and the trap list for anyone gating a pipeline on eval numbers.
- [Grade cold outbound with web evidence](agent-platform/evals-external-evidence.md) — the external tier: `include_external` on `evals.run` searches the public web and grades market claims against `external`-tier quotes — the answer to the LangSmith trap list's cold-prospect gap. Scope gate, pin conflict, licence, cap clamp.
- [The answer envelope](agent-platform/answer-envelope.md) — render a Chat answer in your own UI: the seven `content_block` types, `follow_ups`, and the `amdahl:q` / `amdahl:cite` link grammar.

**End-to-end use cases + reference:**

- [Voice of customer, end to end](agent-platform/voice-of-customer-end-to-end.md) — one question across both doors, teaching the `escalate_to_chat` fast -> Chat handoff.
- [Call prep + objection handling, end to end](agent-platform/call-prep-objection-end-to-end.md) — the flagship: who looks like this prospect, what worked/didn't, and the exact rebuttal — one Chat, grounded in your corpus.
- [The expansion motion, end to end](agent-platform/expansion-motion-end-to-end.md) — the multi-endpoint flagship: lookalike your best closed-won, fast-enrich each match, then semantic-search the objections they already raised.
- [Operation reference](agent-platform/reference.md) — where the authoritative contracts live (the docs tool catalog + the OpenAPI-driven API reference), and the recipe-to-operation map for the public surface.
