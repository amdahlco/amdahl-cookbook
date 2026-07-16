# Agent platform (API + MCP)

The rest of the cookbook is paste-ready prompts. This section is the **developer-facing** view of the same engine: how to drive Amdahl's two "ask Amdahl" doors — and the automation around them — from **your own code**, over the **REST API** and over **MCP**.

Two doors, and the whole trick is knowing which one you're at:

- **Fast lane — `search.run`.** One synchronous call. You ask a concrete question, it writes SQL over your tenant data, runs it, and hands back the rows **and the SQL it ran** in a single blocking response (optionally blended with a quick public web read). For "get me the number." It **blocks and returns the answer**.
- **Agentic lane — Chat.** A multi-step Master agent that decomposes the question, calls the data/cluster/web tools itself, and composes a cited answer. Because a real investigation takes longer than one HTTP request, Chat is **always asynchronous**: you `start` it and get **handles** back immediately, then poll (or stream) for the result.

> **The one seam worth learning:** `search.run` returns `escalate_to_chat: true` when your ask outgrows the fast lane. That field is the designed bridge — fire fast, and if it comes back `escalate_to_chat`, re-fire the same question as a Chat. [Fast lane -> Chat](fast-lane-search.md#escalate-to-chat) walks it end to end.

## Prerequisite — your workspace must be on Agent Platform v2

Everything in this section (`search` + the `agents` tool on MCP; `POST /search`, `POST /chat`, `/routines`, `/agents` on REST) is gated **per workspace** by the `agent_v2` flag.

- **On MCP:** if your connected session lists a `search` tool and an `agents` tool, you're on v2. If it still lists `blueprints` / `pages` and **no** `search` / `agents`, your workspace is on the pre-rollout surface — ask your Amdahl admin to enable Agent Platform v2.
- **On REST:** a gated call on a flag-off workspace returns `403` with `error.code: "feature_disabled"`.

## Scopes — what an MCP key / API key needs

Everything here is covered by the **`mcp_customer_agent`** scope bundle (the default an OAuth connection is granted). Per operation:

| Door / family | Scope |
|---|---|
| `search.run` (fast lane) | `data:read` |
| Start / rename a Chat | `conversations:write` |
| Read a Chat / poll a run | `conversations:read` |
| Answer a pause / cancel a run | `workflows:write` |
| Agent library read / write | `agents:read` / `agents:write` |
| Routines read / write | `routines:read` / `routines:write` |

A read-only key (`mcp_read_only`) can run `search.run` and read chats, but cannot start one, answer a pause, or write an agent/routine.

## The recipes

- [Fast lane — `search.run`](fast-lane-search.md) — one synchronous call over REST + MCP: the request, the full response envelope (`internal.status`, the SQL, blended citations), the typed-failure contract (it never throws past validation), and the `escalate_to_chat` handoff into Chat.
- [Agentic Chat — start, poll, respond](agentic-chat.md) — the async lane end to end: `start` -> poll `read_url` (or `chat_status`) -> render the answer -> `respond` to an `awaiting_input` pause -> stream a run live. Over REST and over the MCP `agents` tool. Includes the `depth` knob (and why the default is `deep`).
- [Routines — make a Chat recur](routines.md) — a cron that fires a fresh Chat each occurrence: create / list / update / delete / run-now over REST + MCP, the `config` (incl. `actions_allowed` for autonomous sends), and when a Routine beats a Workflow.
- [Saved agents — reuse a prompt](saved-agents.md) — the agent library: create a named, reusable agent, pin it in a Chat, and schedule it as a Routine. CRUD over REST + MCP.
- [The answer envelope](answer-envelope.md) — how to render a Chat answer in your own UI: the seven `content_block` types (`text` / `callout` / `citation` / `table` / `chart_spec` / `metric` / `cluster_finding`), `follow_ups`, and the `amdahl:q` / `amdahl:cite` link grammar (figures explore, claims prove).

## End-to-end use cases

The recipes above are the doors in isolation. These two assemble them into a real GTM job — over both REST and MCP — and are the best place to start if you're integrating.

- [Voice of customer, end to end](voice-of-customer-end-to-end.md) — one question across both doors, and the exact `escalate_to_chat` handoff from the fast lane into Chat. The recipe that teaches the seam.
- [Call prep + objection handling, end to end](call-prep-objection-end-to-end.md) — the flagship: who looks like this prospect, what worked/didn't, and the exact rebuttal — one Chat, grounded in your own corpus, then delivered.

## Reference

- [Operation reference — the live catalog](reference.md) — read the self-describing operation catalog (`GET /operations` / `operation://list`) for the exact, current input schema and required scope of any operation.

New here? Start with the [main README](../../README.md) for the OAuth connect flow, then the [recipe library](../README.md) for the GTM prompts these doors were built to serve.
