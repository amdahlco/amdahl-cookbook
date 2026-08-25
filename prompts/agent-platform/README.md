# Agent platform (API + MCP)

The rest of the cookbook is paste-ready prompts. This section is the **developer-facing** view of the same engine: how to drive Amdahl's two "ask Amdahl" doors — and the automation around them — from **your own code**, over the **REST API** and over **MCP**.

Two doors, and the whole trick is knowing which one you're at:

- **Fast lane — `search.query`, mode `fuzzy`.** One synchronous call. You ask a concrete question, it writes SQL over your tenant data, runs it, and hands back the rows **and the SQL it ran** in a single blocking response. For "get me the number." It **blocks and returns the answer**.
- **Agentic lane — Chat.** A multi-step Master agent that decomposes the question, calls the data/cluster/web tools itself, and composes a cited answer. Because a real investigation takes longer than one HTTP request, Chat is **always asynchronous**: you `start` it and get **handles** back immediately, then poll (or stream) for the result.

> **The one seam worth learning:** the fast lane returns `escalate_to_chat: true` when your ask outgrows it. That field is the designed bridge — fire fast, and if it comes back `escalate_to_chat`, re-fire the same question as a Chat. [Fast lane -> Chat](fast-lane-search.md#escalate-to-chat) walks it end to end.

All three synchronous lanes are the SAME endpoint. `search.query` (`POST /search/query`) routes each ask to one of `fuzzy` (the fast lane above), [`filter`](structured-search.md) (typed predicates), or [`semantic`](semantic-search.md) (meaning over the call corpus). Omit `mode` and a router picks; pass it and your choice wins.

## No prerequisite — this surface ships to every workspace

Everything in this section (the `search` + `agents` tools on MCP; `POST /search/query`, `GET /search/fields`, `POST /chat`, `/routines`, `/subscriptions`, `/agents` on REST) is available on **every** workspace.

Earlier versions of this page named an `agent_v2` per-workspace flag and a `403` with `error.code: "feature_disabled"`. **Neither exists** — the flag is retired and there is one code path. If you built a capability check around that error, delete it.

The MCP surface is four coarse tools: **`search`**, **`agents`**, **`evals`**, and **`connections`**. The `blueprints` and `pages` tools were retired (those are console surfaces now).

## Scopes — what an MCP key / API key needs

Everything here is covered by the **`mcp_customer_agent`** scope bundle (the default an OAuth connection is granted). Per operation:

| Door / family | Scope |
|---|---|
| `search.query` (fast lane, structured, semantic) / `search.fields` | `data:read` |
| Start / rename a Chat | `conversations:write` |
| Read a Chat / poll a run | `conversations:read` |
| Answer a pause / cancel a run | `workflows:write` |
| Agent library read / write | `agents:read` / `agents:write` |
| Routines read / write | `routines:read` / `routines:write` |
| Subscriptions read / write | `subscriptions:read` / `subscriptions:write` |
| Grade a message / run an eval (`evals.run`, MCP `evals` action `run`) | `evals:execute` |
| Author or validate an eval (`evals.create` / `evals.update` / `evals.validate`) | `evals:write` |
| Browse evals, poll runs, grader kinds | `evals:read` |
| Connections reads (catalog, instances, status, runs, summary) | `connections:read` |
| Connections writes (connect / disconnect / reconnect / config) | `connections:write` / `connections:delete` — OAuth sessions only; not on any API-key bundle |

A read-only key (`mcp_read_only`) can run every synchronous endpoint and read chats — but cannot start a Chat, answer a pause, or write an agent/routine/subscription.

## Start with the mental model

Before the individual calls, the shape of the whole thing — where Amdahl sits in a GTM agent stack, and the four shapes a play takes.

- [Amdahl is one layer of your GTM brain](gtm-brain-architecture.md) — skills + agents + a shared MCP belt; Amdahl is one server on the belt, wired once. Why hand-rolled context breaks, the reference-architecture stack, and why it's a layer and not an integration.
- [The four shapes of an Amdahl play](four-flows.md) — automated / interactive / scheduled / ad hoc, and the one contract they share (your skill asks, Amdahl answers, your skill acts). Includes the outbound motion worked in full.

## The recipes

- [Fast lane — `search.query`, mode `fuzzy`](fast-lane-search.md) — one synchronous call over REST + MCP: the request, the full response envelope (`detail.internal.status`, the SQL, `uncovered` + `retry_guidance`), the typed-failure contract (it never throws past validation), the async/`max_subqueries` path for broad asks, and the `escalate_to_chat` handoff into Chat.
- [Structured search — typed filters](structured-search.md) — the config-DSL lane of `search.query`: declarative `{field, op, value}` filters, `group_by` + `metrics` aggregations, the compiled SQL as the receipt, and the `GET /search/fields` vocabulary catalog.
- [Semantic search — meaning over the call corpus](semantic-search.md) — the vector lane of the same endpoint: meaning-shaped asks, combining a semantic query with the narrow semantic filter set, and reading `mode_ran` + `freshness` before you trust the results.
- [Agentic Chat — start, poll, respond](agentic-chat.md) — the async lane end to end: `start` -> poll `read_url` (or `chat_status`) -> render the answer -> `respond` to an `awaiting_input` pause -> stream a run live. Over REST and over the MCP `agents` tool. Includes the `depth` knob (and why the default is `deep`).
- [Routines — make a Chat recur](routines.md) — a cron that fires a fresh Chat each occurrence: create / list / update / delete / run-now over REST + MCP, the `config` (incl. `actions_allowed` for autonomous sends), and when a Routine beats a Workflow.
- [Subscriptions — fire a Chat on an event](subscriptions.md) — the event-driven sibling of a Routine: a source (first: a configurable lead time before each Google Calendar event) fires a fresh Chat per occurrence, with the event rendered into the turn. The self-describing kinds catalog, the timing rules, the fire ledger, and test-fire.
- [Saved agents — reuse a prompt](saved-agents.md) — the agent library: create a named, reusable agent, pin it in a Chat, and schedule it as a Routine. CRUD over REST + MCP.
- [Evals — grade a message against customer voice](evals.md) — `evals.run` (MCP `evals` action `run`): pass in a drafted message + its prompt, poll the run, and read the scorecard — a `pass` / `partial` / `fail` / `not_applicable` verdict, a per-dimension breakdown (relevant positioning / grounding / verified specifics / differentiation / cta clarity), the verbatim customer quotes that support or contradict it, and a grounded rewrite. Plus the builder for authoring your own eval (`rule` / `sor_anchored` / `evidence_judge` graders).
- [Amdahl evals in LangSmith](evals-in-langsmith.md) — wire the eval as a pipeline gate: connect the MCP server in LangSmith, fire `evals.run` with `mode: "gate"` (grade-only, no rewrite), poll the `/gate` read, and a copy-paste LangSmith custom evaluator that turns `gate.passed` into feedback. Plus the trap list (why `overall_score` and `lift` must never gate a pipeline, and how to pin evidence for A/Bs).
- [Eval feedback loop](evals-feedback-loop.md) — close the loop: report what happened *after* a run (`feedback`), read one run's reports back (`feedback_status`), and roll adoption up across runs (`adoption`). The `evidence` field an agent must be honest about, the three-state `verified`, the narrowing denominators on the roll-up, and why adoption is a signal to cull with rather than optimize for.
- [Connections — connector CRUD](connections.md) — manage the workspace's data sources from code or an agent turn: the self-describing catalog (logo + connect-flow spec per entry), connect over api_key / handle / OAuth, watch health + sync runs + the data summary, and repair in place. Reads on any key; the writes are OAuth-session-only.
- [The answer envelope](answer-envelope.md) — how to render a Chat answer in your own UI: the seven `content_block` types (`text` / `callout` / `citation` / `table` / `chart_spec` / `metric` / `cluster_finding`), `follow_ups`, and the `amdahl:q` / `amdahl:cite` link grammar (figures explore, claims prove).

## End-to-end use cases

The recipes above are the doors in isolation. These two assemble them into a real GTM job — over both REST and MCP — and are the best place to start if you're integrating.

- [Voice of customer, end to end](voice-of-customer-end-to-end.md) — one question across both doors, and the exact `escalate_to_chat` handoff from the fast lane into Chat. The recipe that teaches the seam.
- [Call prep + objection handling, end to end](call-prep-objection-end-to-end.md) — the flagship: who looks like this prospect, what worked/didn't, and the exact rebuttal — one Chat, grounded in your own corpus, then delivered.
- [The expansion motion, end to end](expansion-motion-end-to-end.md) — the flagship chain: read what your best closed-won sounded like, semantic-search the corpus for the accounts that sound like it, then semantic-search the objections they already raised — a briefed expansion list from synchronous calls only.

## Reference

- [Operation reference](reference.md) — where the authoritative contracts live (the docs tool catalog + the OpenAPI-driven API reference on docs.amdahl.ai), and the recipe-to-operation map for the public surface.

New here? Start with the [main README](../../README.md) for the OAuth connect flow, then the [recipe library](../README.md) for the GTM prompts these doors were built to serve.
