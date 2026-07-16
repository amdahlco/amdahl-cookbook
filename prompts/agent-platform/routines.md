# Routines — make a Chat recur

**What this does**: Puts a Chat on a cron. A **Routine** is a schedule that fires one server-side Master agent turn — a fresh Chat, in its own Session — each occurrence. "Every Monday at 9, compile the pipeline recap and email it to the team." No open session required, no DSL: a name, a prompt, and a cron. Create / list / update / delete / run-now over the REST API and the MCP `agents` tool.

**When to use it**: Any standing GTM job that should repeat *inside Amdahl* without you pasting anything — a weekly customer-voice digest, a Monday pipeline recap, a daily new-competitor-mention sweep. If the work is a one-off, just run a [Chat](agentic-chat.md); a Routine is the "…and keep doing it" wrapper around exactly that.

## Why this matters

The recipes in this cookbook are paste-ready prompts. A Routine is how one of them becomes a standing capability: each fire is a normal headless Chat (`on_question: "none"` — it never stops to ask a human), so everything you know about Chat carries over. Each occurrence shows up as its own Session you can open and read, and because the fired run is a full Master turn, a Routine can do anything a Chat can — investigate, compose a doc, and (if you grant it) email the result to the team.

## The operations

| Job | Operation | REST | MCP (`agents` tool) | Scope |
|---|---|---|---|---|
| Create a routine | `routines.create` | `POST /routines` | `create_routine` | `routines:write` |
| List routines | `routines.list` | `GET /routines` | `list_routines` | `routines:read` |
| Get one | `routines.get` | `GET /routines/:id` | `get_routine` | `routines:read` |
| Update | `routines.update` | `PATCH /routines/:id` | `update_routine` | `routines:write` |
| Delete | `routines.delete` | `DELETE /routines/:id` | `delete_routine` | `routines:write` |
| Fire now (off-cadence) | `routines.run_now` | `POST /routines/:id/run-now` | `run_routine_now` | `routines:write` |

---

## Create a routine

Required: `name`, `prompt`, `cron`. Optional: `timezone` (defaults to UTC), `agent` (pin a [saved agent](saved-agents.md)), `config` (the same Chat run-config as [agentic Chat](agentic-chat.md)), `enabled` (defaults `true`).

**REST:**

```
POST /routines
Authorization: Bearer <api-key with routines:write>
Content-Type: application/json

{
  "name": "Weekly pipeline recap",
  "prompt": "Compile this week's pipeline recap — what moved, what slipped, what went quiet — and email the two-line takeaway to the RevOps team.",
  "cron": "0 9 * * 1",
  "timezone": "America/New_York",
  "config": {
    "depth": "standard",
    "actions_allowed": ["email_member"]
  }
}
```

**MCP** (`agents` tool, `create_routine`):

```
agents create_routine
  name   = "Weekly pipeline recap"
  prompt = "Compile this week's pipeline recap — what moved, what slipped, what went quiet — and email the two-line takeaway to the RevOps team."
  cron   = "0 9 * * 1"
  config = { "depth": "standard", "actions_allowed": ["email_member"] }
```

**What comes back:**

```json
{
  "id": "rt_2b71...",
  "name": "Weekly pipeline recap",
  "cron": "0 9 * * 1",
  "timezone": "America/New_York",
  "enabled": true,
  "next_run_at": "2026-07-20T13:00:00Z"
}
```

Each fire opens a Chat named after the routine and the date (e.g. `Weekly pipeline recap - 2026-07-20`) that you can open and read like any other Session.

### `actions_allowed` — the key to autonomous sends

A headless run may only take an outbound action (like emailing the team) if that action is on its `actions_allowed` list. The default is empty, so a run that wasn't granted the action surfaces the send as a *proposal* instead of firing it, returning a structured `action_not_allowed`. Put `email_member` on the list (as above) and the weekly recap actually lands in the team's inbox — with the notifications primitive's member-only / capped / idempotent guardrails intact. See [Notify the workspace team](../notifications/notify-the-workspace-team.md) for the send contract.

## List, get, update, delete

```
GET /routines                        -> { "routines": [ { "id", "name", "cron", "enabled", "next_run_at", ... } ] }
GET /routines/rt_2b71...             -> the full routine + its last-fire Session/run pointers
PATCH /routines/rt_2b71...           -> edit any field (e.g. { "enabled": false } to pause, { "cron": "0 9 * * 5" } to move to Friday)
DELETE /routines/rt_2b71...          -> remove it (Sessions it already fired survive)
```

On MCP these are `list_routines` / `get_routine` / `update_routine` / `delete_routine`. To clear a pinned agent on update, pass `agent: null`.

## Run it now (off-cadence)

Fire a routine immediately without waiting for its cron — for a test run, or an ad-hoc "run this week's recap now." It returns Chat handles just like `start_chat`, so you watch it the same way.

**REST:**

```
POST /routines/rt_2b71.../run-now
Authorization: Bearer <api-key with routines:write>
```

**MCP** (`run_routine_now`):

```
agents run_routine_now id="rt_2b71..."
```

**What comes back — the same handles as a Chat start:**

```json
{ "chat_id": "c_9d02...", "run_id": "r_1f83...", "status": "queued", "read_url": "...", "stream_url": "..." }
```

Poll `read_url` / stream `stream_url` exactly as in [agentic Chat](agentic-chat.md).

## Paste this into Claude

The MCP-native way — just ask, and Claude creates the Routine:

```
Set up a standing Routine in Amdahl.

Every {Monday at 9am ET}, {compile the weekly pipeline recap — what moved,
what slipped, what went quiet — and email the two-line takeaway to RevOps}.

Use the agents tool's create_routine. Give it a clear name, a cron for that
schedule, and put email_member on actions_allowed so it can actually send.
Show me the routine you created and when it will first run.
```

## Variations

- **Pause instead of delete**: `PATCH { "enabled": false }`. The routine stays; it just stops firing. Re-enable later.
- **Pin a saved agent**: create with `agent: "<slug>"` so every fire runs that [saved agent](saved-agents.md)'s prompt.
- **Investigate-only (no send)**: omit `actions_allowed` (or pass `[]`). The run does the work and leaves the result in its Session; nothing is emailed.
- **Land a living doc**: `config.write_outputs: true` so a recurring report commits a new document version each run (a human promotes it).

## Routine vs. Workflow

A **Routine** is a scheduled *Chat* — a prompt and a cron, created from any connected session. A **Workflow** (blueprint) is a fully-typed recipe with declared inputs, outputs, and a validated step graph — authored in the console or over the REST API, versionable and forkable. For most "email the team a digest every Monday" jobs, the Routine is the simpler build. Reach for a Workflow when you need typed steps, a fixed output contract, or backtesting. See [How to write an Amdahl blueprint](../blueprints/authoring-a-blueprint.md).

## Tips

- **`actions_allowed` is the send gate.** No list = no autonomous send, just a proposal. Name every action the routine should be allowed to take.
- **A fire is a headless Chat.** It runs with `on_question: "none"`, so it never blocks on a human question — write the prompt so it can finish without one.
- **Read a fire like any Session.** Each occurrence is its own Chat; open it to see exactly what the run did (the tool trace + the answer).

## See also

- [Agentic Chat](agentic-chat.md) — what each Routine fire actually is.
- [Saved agents](saved-agents.md) — the reusable prompt you can pin into a Routine.
- [Notify the workspace team](../notifications/notify-the-workspace-team.md) — the `email_member` contract a Routine uses for autonomous sends.
