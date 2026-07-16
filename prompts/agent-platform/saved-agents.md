# Saved agents — reuse a prompt

**What this does**: Saves a named, reusable agent — a slug, a display name, and a system prompt — into your workspace's agent library, so a prompt you tuned once can be pinned into any [Chat](agentic-chat.md) or fired on a schedule by a [Routine](routines.md). Create / list / get / update / delete over the REST API and the MCP `agents` tool.

**When to use it**: You've landed a Master prompt that works — "our SDR-brief agent," "our win-loss postmortem agent" — and you want it once, reusable, instead of pasting the same 300-word instruction every time. A saved agent is that prompt, given a handle.

## Why this matters

A Chat's default Master is a generalist. A saved agent is a specialist you define: bake your framing, your rules, your output shape into the prompt once, then reference it by slug everywhere. It's the reuse primitive that ties the platform together — the *same* saved agent can be pinned into an ad-hoc Chat today and wired into a weekly Routine tomorrow, and it stays one source of truth. (Amdahl also ships a set of library agents; those are read-only — you fork the pattern by creating your own.)

## The operations

| Job | Operation | REST | MCP (`agents` tool) | Scope |
|---|---|---|---|---|
| Create an agent | `agents.create_agent` | `POST /agents` | `create_agent` | `agents:write` |
| List agents | `agents.list_agents` | `GET /agents` | `list_agents` | `agents:read` |
| Get one | `agents.get_agent` | `GET /agents/:id` | `get_agent` | `agents:read` |
| Update | `agents.update_agent` | `PATCH /agents/:id` | `update_agent` | `agents:write` |
| Delete | `agents.delete_agent` | `DELETE /agents/:id` | `delete_agent` | `agents:write` |

Reads project the `agent://` resource scheme on MCP (`agent://list`, `agent://<id>`); writes are the `agents`-tool actions above.

---

## Create an agent

Required: `slug`, `name`, `prompt`. The `slug` is the handle you'll reference in a Chat or Routine (library slugs are reserved).

**REST:**

```
POST /agents
Authorization: Bearer <api-key with agents:write>
Content-Type: application/json

{
  "slug": "sdr-brief",
  "name": "SDR call-prep brief",
  "description": "One-page pre-call brief grounded in our own call corpus.",
  "prompt": "You are our SDR call-prep specialist. Given a company, produce a one-page brief: (1) who looks like them among our closed-won deals and what worked, (2) the 3 things they'll care about most, (3) the 2 risks, (4) the single best next step. Ground every claim in real call quotes from our corpus; never invent a number. End with the exact rebuttal to the most likely objection."
}
```

**MCP** (`agents` tool, `create_agent`):

```
agents create_agent
  slug   = "sdr-brief"
  name   = "SDR call-prep brief"
  prompt = "You are our SDR call-prep specialist. Given a company, produce a one-page brief: ..."
```

**What comes back:**

```json
{
  "id": "ag_5c40...",
  "slug": "sdr-brief",
  "name": "SDR call-prep brief",
  "authored_by": "tenant",
  "status": "draft"
}
```

## Pin it in a Chat

Reference the slug on `chat.start` and the run uses your agent's prompt instead of the default Master.

**REST:**

```
POST /chat
{
  "input": "Prep me for the Artisian call.",
  "agent": "sdr-brief",
  "config": { "depth": "standard" }
}
```

**MCP:**

```
agents start_chat
  input = "Prep me for the Artisian call."
  agent = "sdr-brief"
```

Everything else about the run is identical to [agentic Chat](agentic-chat.md) — you get handles back and poll `read_url` for the answer.

## Schedule it as a Routine

The same slug wires into a [Routine](routines.md) so the agent fires on a cron:

```
POST /routines
{
  "name": "Monday account briefs",
  "prompt": "Produce call-prep briefs for every account with a meeting on the calendar this week.",
  "cron": "0 8 * * 1",
  "agent": "sdr-brief"
}
```

## List, get, update, delete

```
GET /agents                 -> { "agents": [ { "id", "slug", "name", "authored_by", ... } ] }   (your agents + the library)
GET /agents/ag_5c40...      -> the full agent incl. its prompt text
PATCH /agents/ag_5c40...    -> edit name / description / prompt
DELETE /agents/ag_5c40...   -> soft-archive it
```

On MCP these are `list_agents` / `get_agent` / `update_agent` / `delete_agent`. Library agents are locked — you can read them, but create your own to customize the pattern.

## Paste this into Claude

```
Save a reusable agent in Amdahl for our call-prep briefs.

Slug: sdr-brief. Name: "SDR call-prep brief". Prompt: {paste the tuned
instruction — who it is, the exact sections it should output, the rule to
ground every claim in real call quotes and never invent a number}.

Use the agents tool's create_agent. Then start a Chat pinned to sdr-brief
to prep {company} so I can see it in action.
```

## Variations

- **Fork the pattern**: read a library agent (`GET /agents/:id`), copy its prompt, and `create_agent` your own slug with your edits. Library agents are read-only; your copy is yours to change.
- **Iterate the prompt**: `PATCH /agents/:id` with a new `prompt` — every future Chat/Routine that pins the slug picks up the change; one source of truth.
- **Retire without losing history**: `DELETE` soft-archives. Chats and Routines that already ran survive.

## Tips

- **The slug is the contract.** Pin agents by slug in Chats and Routines; keep it stable so scheduled jobs don't break.
- **Put the rules in the prompt.** Grounding discipline ("quote real calls, never invent a number") lives in the agent's prompt, so every run inherits it — that's the whole point of saving it.
- **One agent, two lives.** The same saved agent works pinned in an ad-hoc Chat and fired by a Routine. Define it once.

## See also

- [Agentic Chat](agentic-chat.md) — pin a saved agent with `agent: "<slug>"`.
- [Routines](routines.md) — schedule a saved agent on a cron.
- [Agent platform overview](README.md) — the scope table and the flag prerequisite.
