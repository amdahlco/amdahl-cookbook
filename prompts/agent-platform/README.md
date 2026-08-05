# Agent platform (API + MCP)

The rest of the cookbook is paste-ready prompts. This section is the **developer-facing** view of the same engine: how to drive Amdahl's two "ask Amdahl" doors — and the automation around them — from **your own code**, over the **REST API** and over **MCP**.

Two doors, and the whole trick is knowing which one you're at:

- **Fast lane — `search.run`.** One synchronous call. You ask a concrete question, it writes SQL over your tenant data, runs it, and hands back the rows **and the SQL it ran** in a single blocking response (optionally blended with a quick public web read). For "get me the number." It **blocks and returns the answer**.
- **Agentic lane — Chat.** A multi-step Master agent that decomposes the question, calls the data/cluster/web tools itself, and composes a cited answer. Because a real investigation takes longer than one HTTP request, Chat is **always asynchronous**: you `start` it and get **handles** back immediately, then poll (or stream) for the result.

> **The one seam worth learning:** `search.run` returns `escalate_to_chat: true` when your ask outgrows the fast lane. That field is the designed bridge — fire fast, and if it comes back `escalate_to_chat`, re-fire the same question as a Chat. [Fast lane -> Chat](fast-lane-search.md#escalate-to-chat) walks it end to end.

Beside the two doors sit the **endpoints** — synchronous primitives for when you already know the shape of the answer: [structured + semantic search](structured-search.md) (`search.query`, one routed endpoint with a typed-filter lane, an NL lane, and a meaning-based lane), [tiered enrichment](tiered-enrichment.md) (`enrich.company` / `person` / `topic` — cached brief now, full brief backfilling behind you), and [lookalikes](lookalikes.md) (`lookalike.find` / `themes` — "more like this one" over your own corpus). Each is one blocking call, same as the fast lane.

## Prerequisite — your workspace must be on Agent Platform v2

Everything in this section (the `search` / `enrich` / `lookalike` + `agents` tools on MCP; `POST /search`, `/search/query`, `/enrich/*`, `/lookalike*`, `POST /chat`, `/routines`, `/agents` on REST) is gated **per workspace** by the `agent_v2` flag.

- **On MCP:** if your connected session lists a `search` tool and an `agents` tool (the newest surface also carries `enrich` + `lookalike`), you're on v2. If it still lists `blueprints` / `pages` and **no** `search` / `agents`, your workspace is on the pre-rollout surface — ask your Amdahl admin to enable Agent Platform v2.
- **On REST:** a gated call on a flag-off workspace returns `403` with `error.code: "feature_disabled"`.

## Scopes — what an MCP key / API key needs

Everything here is covered by the **`mcp_customer_agent`** scope bundle (the default an OAuth connection is granted). Per operation:

| Door / family | Scope |
|---|---|
| `search.run` (fast lane) | `data:read` |
| `search.query` / `search.fields` (structured + semantic search) | `data:read` |
| `enrich.company` / `enrich.person` / `enrich.topic` | `data:read` (paid tiers — the background refresh + `mode: "full"` — additionally need `external_search:execute`, and degrade without it) |
| `lookalike.find` / `lookalike.similar_themes` | `data:read` |
| Start / rename a Chat | `conversations:write` |
| Read a Chat / poll a run | `conversations:read` |
| Answer a pause / cancel a run | `workflows:write` |
| Agent library read / write | `agents:read` / `agents:write` |
| Routines read / write | `routines:read` / `routines:write` |
| Grade a message / run an eval (`evals.run`, MCP `grade`) | `evals:execute` |
| Author or validate an eval (`evals.create` / `evals.update` / `evals.validate`) | `evals:write` |
| Browse evals, poll runs, grader kinds | `evals:read` |

A read-only key (`mcp_read_only`) can run `search.run`, all three endpoints (enrich serves its cache + first-party tiers and reports `refresh_omitted: "missing_scope"` instead of queueing the paid refresh), and read chats — but cannot start a Chat, answer a pause, or write an agent/routine.

## Start with the mental model

Before the individual calls, the shape of the whole thing — where Amdahl sits in a GTM agent stack, and the four shapes a play takes.

- [Amdahl is one layer of your GTM brain](gtm-brain-architecture.md) — skills + agents + a shared MCP belt; Amdahl is one server on the belt, wired once. Why hand-rolled context breaks, the reference-architecture stack, and why it's a layer and not an integration.
- [The four shapes of an Amdahl play](four-flows.md) — automated / interactive / scheduled / ad hoc, and the one contract they share (your skill asks, Amdahl answers, your skill acts). Includes the outbound motion worked in full.

## The recipes

- [Fast lane — `search.run`](fast-lane-search.md) — one synchronous call over REST + MCP: the request, the full response envelope (`internal.status`, the SQL, blended citations), the typed-failure contract (it never throws past validation), and the `escalate_to_chat` handoff into Chat.
- [Structured search — typed filters](structured-search.md) — the config-DSL lane of `search.query`: declarative `{field, op, value}` filters, `group_by` + `metrics` aggregations, the compiled SQL as the receipt, and the `GET /search/fields` vocabulary catalog.
- [Semantic search — meaning over the call corpus](semantic-search.md) — the vector lane of the same endpoint: meaning-shaped asks, combining a semantic query with the narrow semantic filter set, and reading `mode_ran` + `freshness` before you trust the results.
- [Tiered enrichment — company, person, topic](tiered-enrichment.md) — `enrich.*`: cached brief instantly, first-party evidence on a miss with the full brief rebuilding behind the scenes (`refresh_enqueued`), and `mode: "full"` when you'd rather wait.
- [Lookalikes — nearest accounts, deals, and themes](lookalikes.md) — `lookalike.find` + `themes`: "more like this one" over your own corpus, and the honest `available: false` contract while centroids materialize.
- [Agentic Chat — start, poll, respond](agentic-chat.md) — the async lane end to end: `start` -> poll `read_url` (or `chat_status`) -> render the answer -> `respond` to an `awaiting_input` pause -> stream a run live. Over REST and over the MCP `agents` tool. Includes the `depth` knob (and why the default is `deep`).
- [Routines — make a Chat recur](routines.md) — a cron that fires a fresh Chat each occurrence: create / list / update / delete / run-now over REST + MCP, the `config` (incl. `actions_allowed` for autonomous sends), and when a Routine beats a Workflow.
- [Saved agents — reuse a prompt](saved-agents.md) — the agent library: create a named, reusable agent, pin it in a Chat, and schedule it as a Routine. CRUD over REST + MCP.
- [Evals — grade a message against customer voice](evals.md) — `evals.run` (MCP `grade`): pass in a drafted message + its prompt, poll the run, and read the scorecard — a `pass` / `partial` / `fail` / `not_applicable` verdict, a per-dimension breakdown (grounding / specificity / differentiation / cta_clarity / tone_fit), the verbatim customer quotes that support or contradict it, and a grounded rewrite. Plus the builder for authoring your own eval (`rule` / `sor_anchored` / `evidence_judge` graders).
- [Amdahl evals in LangSmith](evals-in-langsmith.md) — wire the eval as a pipeline gate: connect the MCP server in LangSmith, fire `evals.run` with `mode: "gate"` (grade-only, no rewrite), poll the `/gate` read, and a copy-paste LangSmith custom evaluator that turns `gate.passed` into feedback. Plus the trap list (why `overall_score` and `lift` must never gate a pipeline, and how to pin evidence for A/Bs).
- [The answer envelope](answer-envelope.md) — how to render a Chat answer in your own UI: the seven `content_block` types (`text` / `callout` / `citation` / `table` / `chart_spec` / `metric` / `cluster_finding`), `follow_ups`, and the `amdahl:q` / `amdahl:cite` link grammar (figures explore, claims prove).

## End-to-end use cases

The recipes above are the doors in isolation. These two assemble them into a real GTM job — over both REST and MCP — and are the best place to start if you're integrating.

- [Voice of customer, end to end](voice-of-customer-end-to-end.md) — one question across both doors, and the exact `escalate_to_chat` handoff from the fast lane into Chat. The recipe that teaches the seam.
- [Call prep + objection handling, end to end](call-prep-objection-end-to-end.md) — the flagship: who looks like this prospect, what worked/didn't, and the exact rebuttal — one Chat, grounded in your own corpus, then delivered.
- [The expansion motion, end to end](expansion-motion-end-to-end.md) — the multi-endpoint flagship: lookalike your best closed-won, fast-enrich each match, then semantic-search the objections they already raised — a briefed expansion list from four synchronous endpoints.

## Reference

- [Operation reference](reference.md) — where the authoritative contracts live (the docs tool catalog + the OpenAPI-driven API reference on docs.amdahl.ai), and the recipe-to-operation map for the public surface.

New here? Start with the [main README](../../README.md) for the OAuth connect flow, then the [recipe library](../README.md) for the GTM prompts these doors were built to serve.
