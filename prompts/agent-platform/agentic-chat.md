# Agentic Chat — start, poll, respond

**What this does**: Runs a multi-step Master agent over your workspace — the door for "investigate this," not "get me the number." You **start** a Chat and get handles back immediately; the agent decomposes the question, calls the data / cluster / web tools itself, and composes a cited answer that you **poll** (or **stream**) for. If it needs a human decision mid-run it **pauses**, and you **respond**. Over the REST API and over the MCP `agents` tool.

**When to use it**: The ask is an investigation — "why are enterprise deals stalling at security review, and what did buyers actually say?", "prep me for the Spotify call: who looks like them, what worked, and the exact objection rebuttal." Anything that needs more than one query and a synthesis pass. For a single number, use the [fast lane](fast-lane-search.md) — and note the fast lane hands off here automatically via `escalate_to_chat`.

## Why this matters

A real investigation takes longer than one HTTP request, so **Chat is always asynchronous** — there is no blocking mode, by design. `start` returns handles the instant the run is queued; the reasoning happens server-side. This is the *only* server-side reasoning surface: the fast lane and every primitive tool put the loop on your side, Chat puts it on Amdahl's. The contract is three moves — **start -> watch -> (maybe) answer** — and the handles you get back are all you need to drive it from any language.

## The operations

| Job | Operation | REST | MCP (`agents` tool) | Scope |
|---|---|---|---|---|
| Start a run | `chat.start` | `POST /chat` | `start_chat` | `conversations:write` |
| Poll one run | `chat.get_run` | `GET /chats/:id/runs/:run_id` | `chat_status` | `conversations:read` |
| Read a chat + its runs | `chat.get` | `GET /chats/:id` | (resource `chat://<id>`) | `conversations:read` |
| List chats | `chat.list` | `GET /chats` | (resource `chat://list`) | `conversations:read` |
| Answer a pause | (resume) | `POST /conversations/:id/turns/:run/resume` | `respond` | `workflows:write` |
| Cancel a run | `agents.cancel` | `POST /agents/:run_id/cancel` | `cancel_chat` | `workflows:write` |
| Rename a chat | `chat.rename` | `PATCH /chats/:id` | — | `conversations:write` |

---

## Step 1 — start (returns handles, never the answer)

`input` is the only required field. A new chat is auto-titled from the input unless you pass `name`; pass an existing `chat_id` to continue a thread.

**REST:**

```
POST /chat
Authorization: Bearer <api-key with conversations:write>
Content-Type: application/json

{
  "input": "Prep me for the Spotify call: which of our customers look like them, what worked and what didn't, and the exact rebuttal when they ask why they can't just use their Zoom MCP.",
  "config": { "depth": "standard" }
}
```

**MCP** (the `agents` tool, `start_chat` action):

```
agents start_chat
  input  = "Prep me for the Spotify call: which of our customers look like them, what worked and what didn't, and the exact rebuttal when they ask why they can't just use their Zoom MCP."
  config = { "depth": "standard" }
```

**What comes back — handles, immediately:**

```json
{
  "success": true,
  "chat_id": "c_8f21...",
  "run_id": "r_4a90...",
  "status": "queued",
  "stream_url": "/api/platform/v1/conversations/c_8f21.../turns/r_4a90.../stream",
  "read_url":   "/api/platform/v1/chats/c_8f21.../runs/r_4a90...",
  "resume_url": "/api/platform/v1/conversations/c_8f21.../turns/r_4a90.../resume"
}
```

You now have everything: `read_url` to poll, `stream_url` for SSE, `resume_url` to answer a pause.

### The `config` knobs

All optional. The one to know is `depth`.

| Field | Default | Effect |
|---|---|---|
| `depth` | **`deep`** | `quick` (Sonnet, ~10 turns, lean tool kit) · `standard` (profile default) · `deep` (Opus, ~75 turns, and forces `external_search` + `include_divergence` on) |
| `external_search` | `false` | keep the web fan-out tool in the run's kit (`deep` forces `true`) |
| `include_divergence` | `false` | include the internal-vs-market divergence map (`deep` forces `true`) |
| `write_outputs` | `false` | allow the run to commit a living-doc version |
| `write_memory` | `false` | allow the run to write a durable long-term-memory fact |
| `actions_allowed` | *all* | narrow which outbound actions the run may take; `[]` = none |
| `on_question` | `auto` | `pause` (stop and ask) · `auto` · `none` (never pause; for headless) |

> **Watch the default.** `depth` defaults to **`deep`**, which pins Opus and turns external search + the divergence map on — great answers, higher cost/latency. For a cheap/fast run, set `depth: "quick"` or `"standard"` explicitly, as the examples here do.

## Step 2 — watch (poll or stream)

### Poll

`read_url` (= `chat.get_run`) returns the run's current state. Pass `?wait_ms=` to long-poll — the server holds the request up to the value (**capped at 30000ms**) and returns the instant the run settles (`complete` / `error` / `canceled` / `awaiting_input`). Add `?include=events` to get the tool-by-tool activity trace for replay.

**REST:**

```
GET /chats/c_8f21.../runs/r_4a90...?wait_ms=30000
Authorization: Bearer <api-key with conversations:read>
```

**MCP** (`chat_status`):

```
agents chat_status
  chat_id = "c_8f21..."
  run_id  = "r_4a90..."
  wait_ms = 30000
```

**What comes back:**

```json
{
  "run": {
    "chat_id": "c_8f21...",
    "run_id": "r_4a90...",
    "status": "complete",
    "input": "Prep me for the Spotify call ...",
    "pending_input": null,
    "answer": {
      "answer_text": "Spotify is a close twin of Airbnb, which we closed ...",
      "content_blocks": [ /* see the answer-envelope recipe */ ],
      "follow_ups": [
        "What did Airbnb's winning conversation look like in detail?",
        "Most common objections from VP-level buyers at AI-native companies?"
      ]
    },
    "usage": { "tokens": 48213, "turns_used": 6 },
    "error": null,
    "trigger": "chat",
    "created_at": "2026-07-16T15:04:22Z",
    "completed_at": "2026-07-16T15:04:53Z"
  }
}
```

Loop on `read_url?wait_ms=30000` until `status` is terminal. The `answer` block is the deliverable — render it with the [answer envelope](answer-envelope.md). Note there are **no cost/dollar fields on the wire** — cost is server-internal.

### Stream (SSE)

For live progress, connect to `stream_url` instead of polling. It emits the tool lifecycle (each `tool_start` / `tool_complete` carries a plain-language `label` — "Finding themes across your customer conversations") and the answer blocks as they land — the exact trace the Amdahl console renders as collapsed tool cards.

```
GET /api/platform/v1/conversations/c_8f21.../turns/r_4a90.../stream
Authorization: Bearer <api-key with conversations:read>
Accept: text/event-stream
```

## Step 3 — respond (only when it pauses)

If the run needs a decision (and `on_question` isn't `none`), it settles at `status: "awaiting_input"` with a `pending_input` describing the question and the schema of a valid answer:

```json
{
  "run": {
    "status": "awaiting_input",
    "pending_input": {
      "type": "multiple_choice",
      "context": { "question": "Two accounts match 'Spotify' — which one?" },
      "schema": { "choice": ["Spotify (spotify.com)", "Spotify for Artists (artists.spotify.com)"] }
    }
  }
}
```

Answer it with the run's `resume_url` (REST) or the `respond` action (MCP). The response must match the `pending_input.schema`.

**REST:**

```
POST /conversations/c_8f21.../turns/r_4a90.../resume
Authorization: Bearer <api-key with workflows:write>
Content-Type: application/json

{ "choice": "Spotify for Artists (artists.spotify.com)" }
```

**MCP** (`respond`):

```
agents respond
  run_id   = "r_4a90..."
  response = { "choice": "Spotify for Artists (artists.spotify.com)" }
```

The run re-queues (`status: "queued"`); go back to Step 2 and keep polling. To abandon a run instead, cancel it — `POST /agents/:run_id/cancel` (REST) or `agents cancel_chat run_id=...` (MCP); cancellation cascades to any sub-agents it spawned.

## The whole loop, in pseudocode

```
start = POST /chat { input, config: { depth: "standard" } }
run   = start.run_id
loop:
  r = GET {start.read_url}?wait_ms=30000
  if r.run.status in [complete, error, canceled]:  break
  if r.run.status == awaiting_input:
     POST {start.resume_url} <answer matching r.run.pending_input.schema>
render r.run.answer   # answer_text + content_blocks + follow_ups
```

## Paste this into Claude

The MCP-native version — Claude drives the `agents` tool for you:

```
Investigate this over our own customer data — a full multi-step Chat, not a quick lookup.

{e.g. "Prep me for the Spotify call: which of our customers look like them,
what worked and what didn't in those deals, and give me the exact rebuttal
for when they ask why they can't just use their Zoom MCP. Ground every
claim in real call quotes."}

Use our CRM + call corpus (the divergence map), not generic web knowledge. When you're done, give me the answer plus 3 follow-up questions I could ask next.
```

## Variations

- **Continue a thread**: pass the prior `chat_id` on `start` to add a turn to an existing chat instead of opening a new one.
- **Headless (no pauses)**: `config.on_question: "none"` so a run started by automation never blocks on a human question — it makes its best call and finishes. This is what [Routines](routines.md) use.
- **Pin a saved agent**: `start` with `agent: "<slug>"` to run a [saved agent](saved-agents.md)'s prompt instead of the default Master.
- **Cheapest path**: `config.depth: "quick"` — Sonnet, a lean kit, ~10 turns. Good for a bounded investigation where `deep` is overkill.

## Tips

- **Never expect an answer from `start`.** It returns handles. The answer arrives on `read_url` / `stream_url`. An integration that treats the `start` response as the result will always see `status: "queued"`.
- **Long-poll instead of tight-looping.** `read_url?wait_ms=30000` returns the moment the run settles and caps at 30s — far cheaper than a 1s polling loop.
- **Set `depth` explicitly.** The default is `deep` (Opus + external search + divergence). Say `quick`/`standard` when you don't need that.
- **`answer_text` has links stripped.** The clean prose is in `answer_text`; the clickable `amdahl:q` / `amdahl:cite` links live inside `content_blocks`. Render blocks, not just the text — see the [answer envelope](answer-envelope.md).

## See also

- [Fast lane — `search.run`](fast-lane-search.md) — the synchronous door, and the `escalate_to_chat` handoff into this one.
- [The answer envelope](answer-envelope.md) — how to render `content_blocks` + `follow_ups`.
- [Routines](routines.md) — put a Chat like this on a cron.
- [Saved agents](saved-agents.md) — pin a reusable prompt into a Chat.
