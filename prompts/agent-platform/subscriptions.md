# Subscriptions — fire a Chat on an event

**What this does**: Puts an agent behind an event. A **Subscription** is the event-driven sibling of a [Routine](routines.md): where a routine fires on a cron, a subscription fires when its **source** observes an occurrence — each fire is one server-side Master turn (or the [saved agent](saved-agents.md) you pin) in a **fresh Chat**, with the triggering event rendered into the turn so the agent knows exactly what woke it. First source: **`calendar.event_upcoming`** — a configurable lead time before each event on a connected Google Calendar. Create / list / update / delete / test-fire over the REST API and the MCP `agents` tool.

**When to use it**: Any GTM job that should react to *something happening* rather than a clock. "Prep me 6 hours before every customer meeting, and again 10 minutes before" is two subscriptions on the same calendar connection — one per lead time, each with its own prompt, agent, and per-fire policy. If the work repeats on a schedule, use a [Routine](routines.md); if it's a one-off, just run a [Chat](agentic-chat.md).

## Why this matters

A cron fires whether or not anything happened; an event fires because it did. The subscription carries the event *into* the prompt — the fired turn sees the meeting title, start time, organizer, and attendees, so "prep me for this meeting" needs no placeholders. Each fire is a normal headless Chat (`on_question: "none"` — it never stops to ask a human), so everything you know about Chat carries over: each occurrence is its own Session you can open and read, and a fired run can do anything a Chat can — investigate, compose the prep doc, and (if you grant it) email it to the room.

## The operations

| Job | Operation | REST | MCP (`agents` tool) | Scope |
|---|---|---|---|---|
| Discover source kinds | `subscriptions.list_kinds` | `GET /subscriptions/kinds` | `list_subscription_kinds` | `subscriptions:read` |
| Create a subscription | `subscriptions.create` | `POST /subscriptions` | `create_subscription` | `subscriptions:write` |
| List subscriptions | `subscriptions.list` | `GET /subscriptions` | `list_subscriptions` | `subscriptions:read` |
| Get one | `subscriptions.get` | `GET /subscriptions/:id` | `get_subscription` | `subscriptions:read` |
| The fire ledger | `subscriptions.list_fires` | `GET /subscriptions/:id/fires` | `list_subscription_fires` | `subscriptions:read` |
| Update | `subscriptions.update` | `PATCH /subscriptions/:id` | `update_subscription` | `subscriptions:write` |
| Delete | `subscriptions.delete` | `DELETE /subscriptions/:id` | `delete_subscription` | `subscriptions:write` |
| Test-fire now | `subscriptions.test_fire` | `POST /subscriptions/:id/test-fire` | `test_fire_subscription` | `subscriptions:write` |

The reads are also MCP resources: `subscription://kinds`, `subscription://list`, `subscription://<id>`, `subscription://<id>/fires`.

## Connect a calendar first

The calendar source reads through a **`google_calendar` connection** (Connections → Google Calendar; OAuth, per-member — each member connects their own calendar). A subscription then names the connection it watches via `config.connection_id`, and may only name a connection in its own workspace. See [Connections](connections.md) for the connect flow.

## The kinds catalog is the contract — read it first

`GET /subscriptions/kinds` (MCP `list_subscription_kinds`) is **self-describing**: each source kind ships its config fields — key, type, required, description — so the `config` you write matches what the kind expects, and a new source kind shows up here with its fields the day it ships, no doc update required. Don't hardcode a field list from this page; discover it.

## Create a subscription

Required: `name`, `source_kind`, `prompt`. Optional: `agent` (pin a [saved agent](saved-agents.md)), `run_config` (the same Chat run-config as [agentic Chat](agentic-chat.md)), `enabled` (defaults `true`). `config` carries the per-kind event config, validated against the kind's own schema.

**REST:**

```
POST /subscriptions
Authorization: Bearer <api-key with subscriptions:write>
Content-Type: application/json

{
  "name": "Meeting prep",
  "source_kind": "calendar.event_upcoming",
  "prompt": "Prep me for this meeting: who is attending, what we last discussed with their company, open deals, and the three things to bring up.",
  "config": {
    "connection_id": "<google_calendar connection id>",
    "lead_minutes": 360,
    "require_attendees": true
  },
  "agent": "gtm-strategist",
  "run_config": { "depth": "standard", "actions_allowed": ["email_member"] }
}
```

**MCP** (`agents` tool, `create_subscription`):

```
agents create_subscription
  name        = "Meeting prep"
  source_kind = "calendar.event_upcoming"
  prompt      = "Prep me for this meeting: who is attending, what we last discussed with their company, open deals, and the three things to bring up."
  config      = { "connection_id": "<id>", "lead_minutes": 360, "require_attendees": true }
  agent       = "gtm-strategist"
```

### `calendar.event_upcoming` config

| Key | Required | Notes |
|---|---|---|
| `connection_id` | yes | The `google_calendar` connection to watch. Must belong to this workspace. |
| `calendar_id` | no | Google calendar id. Defaults to `primary`. |
| `lead_minutes` | yes | Minutes before the event start to fire (`360` = 6 hours, `10` = 10 minutes). One subscription = one lead time. |
| `summary_contains` | no | Only fire for events whose title contains this text (case-insensitive). |
| `require_attendees` | no | Only fire for events with at least one attendee. |

### The timing rules (calendar)

- A fire is due at **`max(now, start − lead)`** — an event discovered already inside its lead window fires immediately; one whose start has passed **never fires** (a "prep me before the meeting" agent is never woken after the meeting began).
- A **rescheduled** event is a new occurrence: its old pending fires cancel and the new start plans fresh. A **cancelled** event's pending fires cancel.
- One fire per occurrence, **structurally**: the ledger dedupes on (event, start time, lead), so sweep re-runs and concurrent workers cannot double-fire.
- Fires that start runs are **rate-capped per workspace per hour** (default 30), so a calendar with hundreds of imminent events cannot start hundreds of agent runs.

## List, get, update, delete

```
GET /subscriptions                        -> { "subscriptions": [ ... ], "total": ... }   (filter ?source_kind= / ?enabled=)
GET /subscriptions/sub_7c20...            -> the full subscription + its last fire's Chat/run pointers
PATCH /subscriptions/sub_7c20...          -> edit name / prompt / config / agent / run_config; { "enabled": false } pauses
DELETE /subscriptions/sub_7c20...         -> remove it and its fire history (Chats it already fired survive)
```

On MCP these are `list_subscriptions` / `get_subscription` / `update_subscription` / `delete_subscription`. To clear a pinned agent on update, pass `agent: null`. **`source_kind` is immutable** — changing the kind re-means the stored config and every pending fire, so make a new subscription instead.

## Test-fire — watch one before you trust it

Fire once now with a labeled synthetic event, without waiting for a real occurrence. It returns the same handles a Chat start does, so you watch the fire live exactly as in [agentic Chat](agentic-chat.md):

```
POST /subscriptions/sub_7c20.../test-fire
-> { "chat_id": "c_9d02...", "run_id": "r_1f83...", "status": "queued", "read_url": "...", "stream_url": "..." }
```

A test fire is a preview, not an occurrence — it is **not** written to the fires ledger.

## The fires ledger — "is my trigger actually firing?"

`GET /subscriptions/:id/fires` (MCP `list_subscription_fires`) lists planned occurrences with due times, outcomes, and the event snapshot each carried:

| Status | Meaning |
|---|---|
| `pending` | Planned, waiting for its due time. |
| `fired` | Started a run — the row carries the `chat_id` + run id. |
| `skipped` | Deliberately not run; `skip_reason` says why (`subscription_disabled`, `rate_limited`, `agent_unresolvable`, …). |
| `failed` | The run could not start, or a dead worker's claim was reaped. |
| `canceled` | The occurrence no longer stands (`event_canceled`, `event_rescheduled`). |

Every fired Chat also shows up in the normal Chats list — `GET /chats?subscription_id=<id>` scopes the list to one subscription's fires, and each carries a `subscription` trigger badge.

## Paste this into Claude

The MCP-native way — just ask, and Claude creates the Subscription:

```
Set up an event Subscription in Amdahl.

Before every meeting on my connected Google Calendar — {6 hours} ahead —
{prep me: who is attending, what we last discussed with their company, open
deals, and the three things to bring up}.

Use the agents tool: list_subscription_kinds first to read the calendar
kind's config fields, then create_subscription with the right
connection_id and lead_minutes. Test-fire it once so I can see a run, and
show me what you created.
```

## Variations

- **Two lead times**: create two subscriptions on the same connection — `lead_minutes: 360` for the deep prep, `lead_minutes: 10` for the 3-bullet refresher. Each has its own prompt and ledger.
- **Only customer meetings**: `summary_contains` + `require_attendees: true` so internal blocks and solo focus time never fire it.
- **Pause instead of delete**: `PATCH { "enabled": false }`. Pending fires are skipped as `subscription_disabled`; re-enable later.
- **Deliver the prep**: `run_config.actions_allowed: ["email_member"]` so the fired run emails the prep doc — same send contract as a Routine ([the notifications guardrails](../notifications/notify-the-workspace-team.md) apply).

## Subscription vs. Routine

Same fire spine, different trigger: a **Routine** answers "every Monday at 9", a **Subscription** answers "when this happens". Both fire one headless Master turn in a fresh Chat, both accept an agent pin and the same `run_config`, and both surface every fire as a readable Session. If you're tempted to poll for an event with a tight cron, that's a subscription.

## Tips

- **Discover, don't hardcode.** The kinds catalog carries each source's config fields; a config the kind doesn't declare is rejected at create time with the field named.
- **A fire is a headless Chat.** `on_question` is always `"none"` — write the prompt so the run can finish without asking anyone anything.
- **The ledger is the debug surface.** A subscription that "isn't working" is one `list_subscription_fires` read: no rows means the source never observed a matching event; `skipped` rows name why.
- **`actions_allowed` defaults permissive**, exactly as on Routines — absent means every cataloged action. Pass a list to narrow, `[]` for investigate-only.

## See also

- [Routines](routines.md) — the cron-driven sibling; everything about a fired run is shared.
- [Agentic Chat](agentic-chat.md) — what each fire actually is, and how to poll/stream it.
- [Saved agents](saved-agents.md) — the reusable prompt you can pin into a subscription.
- [Connections](connections.md) — connecting the Google Calendar the source reads through.
