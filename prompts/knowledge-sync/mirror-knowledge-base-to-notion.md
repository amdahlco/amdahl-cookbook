# Mirror your knowledge base to Notion

**What this does**: Keeps a Notion database in your own workspace continuously in sync with your Amdahl knowledge base — one-way, Amdahl -> Notion. You connect Notion once and pick a parent page; from then on every document you promote in Amdahl mirrors itself into Notion automatically, with no human in the loop. It's the "make our KB readable where my team already works" primitive: set it up, then forget it.

**When to use it**: Your team lives in Notion but your canonical reference library — competitive briefs, positioning memos, account one-pagers, the research your agents keep producing — lives in Amdahl. Instead of copy-pasting, you mirror it: write or promote a doc in Amdahl, and it shows up (and stays current) in a Notion database your whole team can read and link to.

## Why this matters

Every other Amdahl connector is **inbound** — it pulls a provider's data *into* Amdahl. This one is the inverse: it pushes your Amdahl knowledge base *out* to Notion. That makes it the bridge between "where the intelligence is produced" (Amdahl) and "where your team reads" (Notion).

Three things make it safe to leave running unattended:

- **It runs server-side, not in a chat.** Unlike a paste-and-go recipe, the sync is a standing background job. The moment you promote a KB version in Amdahl, the change is queued for Notion off the write path (so it never slows your KB write). An **hourly reconcile sweep** backfills anything missed and self-heals drift. There is genuinely no human or open session required — this is the unattended path.
- **Current version only.** Amdahl documents are version families with a human promotion gate; the sync mirrors the **current (promoted)** version, never proposed drafts. What lands in Notion is your canonical reference library, not work-in-progress.
- **It respects human edits and never duplicates.** Each KB document maps to exactly one Notion page (stable across re-syncs, so links and bookmarks survive). If someone edits the mirrored page in Notion, a `preserve` drift policy keeps their edit; an unchanged document is skipped without even touching Notion (a content hash is compared).

The split that matters: **setup is a write** (connect + configure — done once, from the console or REST, *not* over MCP, because configuring where a workspace exports its KB is workspace configuration). **Monitoring is a read** (config / status / activity ledger — available over MCP *and* REST). So an agent can tell you whether the sync is healthy and what just mirrored, but it can't silently re-point where your knowledge base exports to.

## The operations

| Job | Operation | MCP | REST | Scope |
|---|---|---|---|---|
| Connect Notion (OAuth) | `connections.connect` | — (console / REST only) | `POST /connections` | `connections:write` |
| Configure (pick parent page, provision DB, backfill) | `notion_sync.configure` | — (console / REST only) | `POST /notion-sync/:id/configure` | `notion_sync:write` |
| Read the sync config | `notion_sync.get` | resource `notion_sync://<id>` | `GET /notion-sync/:id` | `notion_sync:read` |
| Poll the live status | `notion_sync.status` | resource `notion_sync://<id>/status` | `GET /notion-sync/:id/status` | `notion_sync:read` |
| See the activity ledger | `notion_sync.list_sends` | resource `notion_sync://<id>/sends` | `GET /notion-sync/:id/sends` | `notion_sync:read` |
| Force a full re-mirror | `notion_sync.backfill` | — (console / REST only) | `POST /notion-sync/:id/backfill` | `notion_sync:write` |
| Stop mirroring (keep Notion pages) | `notion_sync.unsync` | — (console / REST only) | `POST /notion-sync/:id/unsync` | `notion_sync:delete` |

The three reads are on MCP as `notion_sync://` resources; the four writes are console + REST only by design.

---

## Step 1 — connect Notion (one time)

Connect the `notion_knowledge_sync` connector. It's an OAuth flow: easiest from the console **Connections** page (pick "Notion Knowledge Sync", click Connect), or via REST:

```
POST /connections
Authorization: Bearer <api-key with connections:write>
Content-Type: application/json

{ "connector_type": "notion_knowledge_sync", "name": "Acme KB -> Notion" }
```

**What comes back** — an authorize URL to send the user to:

```json
{
  "mode": "oauth_redirect",
  "authorize_url": "https://api.notion.com/v1/oauth/authorize?...",
  "connection": { "id": "11111111-1111-1111-1111-111111111111", "status": "pending" }
}
```

Open `authorize_url`, approve the integration in Notion, and **grant it access to the page you want the synced database created under** (Notion only lets an integration write where you've given it access). The connection lands in `pending` until you configure it. Hold onto the `connection.id` — it's the `:id` in every call below.

## Step 2 — configure (pick a parent page; one time)

Designate the parent Notion page. This provisions an "Amdahl Knowledge Base" database under it (with `Name`, `Amdahl Doc ID`, `Version`, and `Last Synced` properties) and kicks off a full backfill of your current KB.

```
POST /notion-sync/:id/configure
Authorization: Bearer <api-key with notion_sync:write>
Content-Type: application/json

{
  "parent_page_id": "<notion-page-id>",
  "version_policy": "current_only",
  "on_kb_delete": "archive",
  "drift_policy": "preserve",
  "include": { "starred_only": false }
}
```

Only `parent_page_id` is required; everything else defaults sensibly (see [Configure knobs](#configure-knobs)). The response tells you how many documents were queued for the initial mirror:

```json
{
  "connection_id": "11111111-1111-1111-1111-111111111111",
  "config": { "enabled": true, "database_id": "<db>", "data_source_id": "<ds>", "version_policy": "current_only", "provisioned_at": "2026-06-27T12:00:00.000Z" },
  "backfill_enqueued": 42
}
```

That's the whole setup. From here it's automatic.

## Step 3 — it syncs itself

You don't call anything to keep it running. Two paths keep Notion current:

- **Instantly, off your KB writes.** Upload or append a knowledge-base document, or promote a version to current, and the change is queued for Notion right away. This includes writes an **agent** makes — the `knowledge_base` MCP tool's `upload` and `promote` actions are how a Claude session adds a doc that then mirrors. (Promotion is the human gate: a proposed version doesn't mirror until someone promotes it.)
- **Hourly, via the reconcile sweep.** A background sweep compares your current KB against what's mirrored and queues anything out of sync — unmapped, version-drifted, errored, or needing archival. This is the unattended safety net: it backfills first-connect, and self-heals a page you deleted in Notion or a sync that hit a transient error.

So the loop for an agent is: **add knowledge to Amdahl, and it appears in Notion.** For example, after a [competitor deep-dive](../competitive-intel/competitor-deep-dive.md) or a [win-loss postmortem](../win-loss-deal-postmortem/why-we-lost-this-deal.md), save the brief to the KB (`knowledge_base upload`) — and if the Notion sync is configured, it mirrors on the next tick with no extra step.

## Step 4 — check it's healthy (over MCP or REST)

These three reads are the monitoring surface — available to an agent over MCP or to your code over REST.

**Live status** (the polling badge): enabled, provisioned, how many docs are mirrored, and a recent-activity summary.

**MCP** (read it as a resource):

```
# resource notion_sync://<id>/status
```

**REST:**

```
GET /notion-sync/:id/status
Authorization: Bearer <api-key with notion_sync:read>
```

```json
{
  "connection_id": "1111…",
  "status": "connected",
  "enabled": true,
  "provisioned": true,
  "mapped_count": 42,
  "recent": { "syncedLastHour": 7, "failedLastHour": 0, "skippedLastHour": 3 }
}
```

**Activity ledger** (what mirrored, and why something didn't). Outbound connectors have no upstream sync-run history, so this per-document ledger is the activity log. Optional `?limit=` (1–200, default 50):

```
GET /notion-sync/:id/sends?limit=10
# MCP: resource notion_sync://<id>/sends
```

```json
{
  "rows": [
    { "documentGroupId": "<doc>", "event": "promote", "status": "synced", "notionPageId": "<page>", "createdAt": "2026-06-27T12:01:00Z" },
    { "documentGroupId": "<doc>", "event": "upload", "status": "skipped", "skipReason": "unchanged_hash", "createdAt": "2026-06-27T11:55:00Z" }
  ],
  "summary": { "syncedLastHour": 7, "failedLastHour": 0, "skippedLastHour": 3 }
}
```

Each row's `status` is `synced` / `skipped` / `failed`. A skip's `skipReason` tells you why it was a no-op (`unchanged_hash`, `proposed_only`, `out_of_scope`, `disabled`, `not_configured`, `drift_preserved`); a failure's `error` carries the message. A high `failedLastHour` is your signal to check whether Notion access was revoked (the connection flips to a needs-reauthorization state — reconnect to resume).

## Backfill and unsync

- **Force a full re-mirror** — `POST /notion-sync/:id/backfill` queues every current document. Unchanged docs are skipped cheaply, so it's safe to run repeatedly; use it after a big KB import or if you ever suspect drift. Returns `{ "enqueued": <n> }`.
- **Stop mirroring but keep the Notion pages** — `POST /notion-sync/:id/unsync` disables the sync and clears the page-mapping ledger so a later reconfigure starts clean. **Your existing Notion pages stay in place** — their data is preserved; this only stops future syncing. To remove the connection entirely, use `DELETE /connections/:id`.

## Configure knobs

Set these at configure time (or in the console settings panel). They're stored on the connection and applied to every sync.

| Knob | Values | Default | What it controls |
|---|---|---|---|
| `parent_page_id` | a Notion page id | *(required)* | The page the synced database is created under. |
| `version_policy` | `current_only` / `all_promoted` | `current_only` | Which versions mirror. `current_only` mirrors just the promoted version (respects the human promotion gate). |
| `on_kb_delete` | `archive` / `leave` | `archive` | What happens to the Notion page when the source doc is archived/deleted in Amdahl. `archive` trashes it; `leave` keeps it. |
| `drift_policy` | `preserve` / `overwrite` | `overwrite` | What happens when a human edited the Notion page since the last sync. `preserve` keeps their edit (logs `drift_preserved`); `overwrite` re-writes from Amdahl. |
| `include` | `{ document_types, starred_only, group_ids }` | all current docs | Narrow which docs are in scope. Leave empty to mirror everything current. |
| `enabled` | `true` / `false` | `true` | Master on/off for the connection's sync. |

---

## Paste this into Claude

Setup (connect + configure) happens in the console or via REST — not over MCP — but once it's running, Claude can **monitor** the sync and **feed** it (anything it saves to the KB mirrors automatically). Paste this to get a health read:

```
Check my Amdahl -> Notion knowledge sync and tell me if it's healthy.

1. Read the Notion sync status (resource notion_sync://<connection-id>/status).
   Tell me: is it enabled and provisioned, how many documents are mirrored,
   and the recent synced/failed/skipped counts.

2. Read the activity ledger (resource notion_sync://<connection-id>/sends,
   limit 10). Summarize the last few outcomes. If anything shows status
   "failed", quote the error and tell me whether it looks like a revoked
   Notion access (needs-reauthorization) vs a transient error the hourly
   reconcile will retry.

3. If failedLastHour is 0 and the doc count matches what I expect, just say
   "sync is healthy, N docs mirrored, last sync <when>." Don't invent a
   problem that isn't there.
```

To get a freshly-produced brief into Notion, just have Claude save it to the KB after a research recipe — `knowledge_base upload` (then promote when you're ready) — and the configured sync mirrors it on the next tick. No Notion-specific step.

## What you'll see back

- A one-line health verdict (enabled + provisioned + mirrored-doc count + last-sync recency).
- A short read of the recent ledger, with any `failed` rows quoted and triaged (reauth vs transient).
- If you fed the KB: a confirmation the doc was saved (and, once promoted, that it's queued to mirror).

## Variations

- **Scope it to your canon only:** configure with `include: { starred_only: true }` so only starred ("canon") KB documents mirror — keep the Notion database to your vetted reference set, not every draft.
- **By document type:** `include: { document_types: ["competitive_brief", "positioning"] }` mirrors only those types.
- **Protect hand-edited Notion pages:** set `drift_policy: "preserve"` so a teammate's edits in Notion are never overwritten by a re-sync (the sync logs `drift_preserved` and moves on).
- **Keep Notion pages after a teardown:** `unsync` (not `DELETE /connections/:id`) stops syncing but leaves every mirrored page intact — the safe "pause it" move.
- **From code, not chat:** the whole lifecycle is REST — `POST /connections` -> `POST /notion-sync/:id/configure` -> poll `GET /notion-sync/:id/status` -> `GET /notion-sync/:id/sends`. Same contracts as the MCP reads.

## Tips

- **Promote, don't just upload, to publish.** With the default `version_policy: current_only`, a proposed version doesn't mirror until a human promotes it. That's the gate that keeps drafts out of Notion — use it on purpose.
- **Check `notion_sync://<id>/sends` before assuming a doc didn't sync.** A "missing" doc is usually a deliberate skip — `unchanged_hash` (nothing changed), `proposed_only` (not promoted yet), or `out_of_scope` (your include filters). The ledger names the reason.
- **A spike in `failedLastHour` almost always means revoked Notion access.** Reconnect the connector to re-grant; the hourly reconcile sweep backfills everything that failed while it was down.
- **Backfill is cheap and idempotent** — unchanged docs are skipped without a Notion round-trip, so `POST /notion-sync/:id/backfill` is a safe "make sure everything's current" button.
- **Pair it with the research recipes.** The recipes that produce a saved brief — [competitor deep-dive](../competitive-intel/competitor-deep-dive.md), [deep-dive on account](../customer-research/deep-dive-on-account.md), [rebuild your value narrative](../positioning-messaging/rebuild-value-narrative-by-segment.md) — become Notion pages the moment they hit the KB. This sync is the delivery; those are the payload.

## See also

- [Notify the workspace team](../notifications/notify-the-workspace-team.md) — the other last-mile primitive: email a teammate a readout instead of (or as well as) mirroring it to Notion.
- [How to write an Amdahl blueprint](../blueprints/authoring-a-blueprint.md) — wrap "research -> save to KB" in a repeatable recipe so the doc that mirrors to Notion is produced the same way every time.
- The rest of the cookbook: [recipe library](../README.md) — the GTM prompts whose outputs are worth keeping in your KB.
- Product docs: <https://amdahl.co/mcp>.
