# Mirror your knowledge base to Notion

**What this does**: Keeps a Notion database in your own workspace continuously in sync with your Amdahl knowledge base — one-way, Amdahl -> Notion. You connect Notion once and pick a parent page; from then on every document you promote in Amdahl mirrors itself into Notion automatically, with no human in the loop. It's the "make our KB readable where my team already works" primitive: set it up, then forget it.

**When to use it**: Your team lives in Notion but your canonical reference library — competitive briefs, positioning memos, account one-pagers, the research your agents keep producing — lives in Amdahl. Instead of copy-pasting, you mirror it: write or promote a doc in Amdahl, and it shows up (and stays current) in a Notion database your whole team can read and link to.

## Why this matters

Every other Amdahl connector is **inbound** — it pulls a provider's data *into* Amdahl. This one is the inverse: it pushes your Amdahl knowledge base *out* to Notion. That makes it the bridge between "where the intelligence is produced" (Amdahl) and "where your team reads" (Notion).

Three things make it safe to leave running unattended:

- **It runs server-side, not in a chat.** Unlike a paste-and-go recipe, the sync is a standing background job. The moment you promote a KB version in Amdahl, the change is queued for Notion off the write path (so it never slows your KB write). An **hourly reconcile sweep** backfills anything missed and self-heals drift. There is genuinely no human or open session required — this is the unattended path.
- **Current version only.** Amdahl documents are version families with a human promotion gate; the sync mirrors the **current (promoted)** version, never proposed drafts. What lands in Notion is your canonical reference library, not work-in-progress.
- **It respects human edits and never duplicates.** Each KB document maps to exactly one Notion page (stable across re-syncs, so links and bookmarks survive). If someone edits the mirrored page in Notion, a `preserve` drift policy keeps their edit; an unchanged document is skipped without even touching Notion (a content hash is compared).

The split that matters: **setup is workspace configuration** (connect + configure — done once, in the console, because re-pointing where a workspace exports its KB is a trust decision). **Monitoring lives beside it** (the connection's status + activity ledger, on the same Connections page). And **agents feed it without touching either**: anything a run lands in the knowledge base mirrors once promoted — so an agent fills the library, but can't silently re-point where it exports to.

## The lifecycle, and where each piece lives

| Job | Where |
|---|---|
| Connect Notion (OAuth) | Console → Connections → "Notion Knowledge Sync" → Connect |
| Configure (pick parent page, provision DB, backfill) | Console → the connection's settings panel |
| Read config / poll live status / see the activity ledger | Console → the connection's detail page |
| Force a full re-mirror (backfill) | Console → the connection's detail page |
| Stop mirroring (keep Notion pages) | Console → the connection's settings panel |
| Feed it (add documents that mirror) | Any agent run that writes the KB — a Chat or Routine with `write_outputs: true`, promoted by you |

The whole sync lifecycle is a **console capability** — there's no notifications-style agent door for it, by design: an agent can fill the knowledge base, not reconfigure the export.

---

## Step 1 — connect Notion (one time)

In the console, open **Connections**, pick **Notion Knowledge Sync**, and click **Connect**. It's an OAuth flow: approve the integration in Notion, and **grant it access to the page you want the synced database created under** (Notion only lets an integration write where you've given it access). The connection lands in `pending` until you configure it.

## Step 2 — configure (pick a parent page; one time)

In the connection's settings panel, designate the parent Notion page. This provisions an "Amdahl Knowledge Base" database under it (with `Name`, `Amdahl Doc ID`, `Version`, and `Last Synced` properties) and kicks off a full backfill of your current KB.

Only the parent page is required; everything else has sane defaults (see [Configure knobs](#configure-knobs)). One worth knowing up front: `drift_policy` defaults to `overwrite` (Amdahl is the source of truth and re-writes the Notion page each sync); set it to `preserve` instead if you want human edits made directly in Notion to be kept. The panel confirms how many documents were queued for the initial mirror.

That's the whole setup. From here it's automatic.

## Step 3 — it syncs itself

You don't call anything to keep it running. Two paths keep Notion current:

- **Instantly, off your KB writes.** Upload or append a knowledge-base document, or promote a version to current, and the change is queued for Notion right away. This includes documents an **agent** produces — a Chat or Routine with `write_outputs: true` commits a *proposed* KB version, and promotion is the human gate: it doesn't mirror until you promote it in the console.
- **Hourly, via the reconcile sweep.** A background sweep compares your current KB against what's mirrored and queues anything out of sync — unmapped, version-drifted, errored, or needing archival. This is the unattended safety net: it backfills first-connect, and self-heals a page you deleted in Notion or a sync that hit a transient error.

So the loop for an agent is: **land knowledge in Amdahl, and it appears in Notion once promoted.** For example, run a [competitor deep-dive](../competitive-intel/competitor-deep-dive.md) or a [win-loss postmortem](../win-loss-deal-postmortem/why-we-lost-this-deal.md) as a Chat with `write_outputs: true`, promote the resulting doc — and if the Notion sync is configured, it mirrors on the next tick with no extra step.

## Step 4 — check it's healthy (in the console)

The connection's detail page on **Connections** is the monitoring surface. Two reads live there:

**Live status** (the badge): enabled, provisioned, how many docs are mirrored, and a recent-activity summary — synced / failed / skipped counts for the last hour.

**Activity ledger** (what mirrored, and why something didn't). Outbound connectors have no upstream sync-run history, so this per-document ledger is the activity log. Each row's `status` is `synced` / `skipped` / `failed`. A skip's `skipReason` tells you why it was a no-op (`unchanged_hash`, `proposed_only`, `out_of_scope`, `disabled`, `not_configured`, `drift_preserved`); a failure carries the error. A spike in failures is your signal to check whether Notion access was revoked (the connection flips to a needs-reauthorization state — reconnect to resume).

## Backfill and unsync

- **Force a full re-mirror** — the connection's **Backfill** action queues every current document. Unchanged docs are skipped cheaply, so it's safe to run repeatedly; use it after a big KB import or if you ever suspect drift.
- **Stop mirroring but keep the Notion pages** — **Unsync** disables the sync and clears the page-mapping ledger so a later reconfigure starts clean. **Your existing Notion pages stay in place** — their data is preserved; this only stops future syncing. To remove the connection entirely, disconnect it from the Connections page.

## Configure knobs

Set these in the connection's console settings panel. They're stored on the connection and applied to every sync.

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

Setup and monitoring live in the console — but Claude **feeds** the sync: any document a run lands in the knowledge base mirrors automatically once you promote it. Paste this after a research recipe to produce a doc that flows to Notion:

```
Run this as a deep investigation and save the result.

{the research ask — e.g. "a competitive brief on {competitor}: their public
posture vs. how buyers actually describe them on our calls, with the
divergences and attack angles"}

Commit the finished brief to our knowledge base as a document version
(write_outputs on). Tell me the document's title and remind me that it lands
as a PROPOSED version — I'll promote it in the console, and once promoted our
Notion sync mirrors it automatically. No Notion-specific step needed.
```

Then promote the doc when it's right, and check the mirror on the connection's console page.

## What you'll see back

- The research deliverable itself, plus confirmation a proposed KB version was committed.
- A reminder of the promotion gate: proposed versions don't mirror; promoting in the console is what publishes it to Notion.
- On the console's Connections page: the sync status, the mirrored-doc count, and the per-document ledger row once the mirror ticks.

## Variations

- **Scope it to your canon only:** configure with `include: { starred_only: true }` so only starred ("canon") KB documents mirror — keep the Notion database to your vetted reference set, not every draft.
- **By document type:** `include: { document_types: ["competitive_brief", "positioning"] }` mirrors only those types.
- **Protect hand-edited Notion pages:** set `drift_policy: "preserve"` so a teammate's edits in Notion are never overwritten by a re-sync (the sync logs `drift_preserved` and moves on).
- **Keep Notion pages after a teardown:** Unsync (not a full disconnect) stops syncing but leaves every mirrored page intact — the safe "pause it" move.
- **From code, not chat:** feed the pipeline over the public Chat API — `POST /chat` with `write_outputs` enabled in the config, or a Routine that does the same on a cadence. The docs land as proposed KB versions; promotion (console) is what mirrors them.

## Tips

- **Promote, don't just upload, to publish.** With the default `version_policy: current_only`, a proposed version doesn't mirror until a human promotes it. That's the gate that keeps drafts out of Notion — use it on purpose.
- **Check the activity ledger before assuming a doc didn't sync.** A "missing" doc is usually a deliberate skip — `unchanged_hash` (nothing changed), `proposed_only` (not promoted yet), or `out_of_scope` (your include filters). The ledger names the reason.
- **A spike in failures almost always means revoked Notion access.** Reconnect the connector to re-grant; the hourly reconcile sweep backfills everything that failed while it was down.
- **Backfill is cheap and idempotent** — unchanged docs are skipped without a Notion round-trip, so the Backfill action is a safe "make sure everything's current" button.
- **Pair it with the research recipes.** The recipes that produce a saved brief — [competitor deep-dive](../competitive-intel/competitor-deep-dive.md), [deep-dive on account](../customer-research/deep-dive-on-account.md), [rebuild your value narrative](../positioning-messaging/rebuild-value-narrative-by-segment.md) — become Notion pages the moment they hit the KB. This sync is the delivery; those are the payload.

## See also

- [Notify the workspace team](../notifications/notify-the-workspace-team.md) — the other last-mile primitive: email a teammate a readout instead of (or as well as) mirroring it to Notion.
- Put "research -> save to KB" on a cadence with a **Routine** — a scheduled Chat created with the `agents` MCP tool (a name, a prompt with `write_outputs` on, a cron) — so the doc that mirrors to Notion is refreshed the same way every time. For a fully-typed recipe instead, author a Workflow in the console: [How to write an Amdahl blueprint](../blueprints/authoring-a-blueprint.md).
- The rest of the cookbook: [recipe library](../README.md) — the GTM prompts whose outputs are worth keeping in your KB.
- Product docs: <https://docs.amdahl.ai>.
