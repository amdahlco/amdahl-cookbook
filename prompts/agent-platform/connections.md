# Connections — connector CRUD over REST + MCP

**What this does**: Manages a workspace's data sources end to end from your own code or an agent turn — browse the connector catalog, connect a source (API key, public handle, or OAuth), watch its sync runs and health, and repair it in place when it breaks. Every read is self-describing (display name, logo, and the exact fields the connect flow needs ride on the wire), so a client renders the whole surface from the API with no hardcoded connector list.

**When to use it**: You're building onboarding or a settings surface outside the console, an agent should check why a source looks stale before anyone blames the data, or a script should confirm what's connected and healthy before it runs a play that depends on fresh data.

## The operations

| | Operation | REST | MCP (`connections` tool) | Scope |
|---|---|---|---|---|
| The catalog | `connections.list_catalog` | `GET /connections/catalog` | action `catalog` | `connections:read` |
| Connected instances | `connections.list` | `GET /connections` | action `list` | `connections:read` |
| One connection | `connections.get` | `GET /connections/:id` | action `get` | `connections:read` |
| Status (polling) | `connections.get_status` | `GET /connections/:id/status` | action `status` | `connections:read` |
| Sync-run history | `connections.list_runs` | `GET /connections/:id/runs` | action `runs` | `connections:read` |
| Data summary | `connections.get_summary` | `GET /connections/:id/summary` | action `summary` | `connections:read` |
| Connect | `connections.connect` | `POST /connections` | action `connect` | `connections:write` |
| Disconnect | `connections.disconnect` | `DELETE /connections/:id` | action `disconnect` | `connections:delete` |
| Set the owner | `connections.update` | `PATCH /connections/:id` | action `update` | `connections:write` |
| Repair in place | `connections.reconnect` | `POST /connections/:id/reconnect` | action `reconnect` | `connections:write` |
| Call filters | `connections.set_call_filters` | `PUT /connections/:id/call-filters` | — (REST only) | `connections:write` |
| CRM recency | `connections.set_crm_recency` | `PUT /connections/:id/crm-recency` | — (REST only) | `connections:write` |
| Comms filter | `connections.set_comms_filter` | `PUT /connections/:id/comms-filter` | — (REST only) | `connections:write` |

**Which credential can do what is the part to get right up front.** The six reads work on every credential, including a read-only API key. The writes (`connect` / `disconnect` / `update` / `reconnect` and the three config endpoints) ride only on an **OAuth session** — a signed-in member's delegated token, the thing a Claude.ai / Claude Code MCP connection holds. A headless API key gets a `403` on them by design: connector lifecycle stays with a person, while keys watch. So: OAuth-connected agents manage connectors; API-key scripts monitor them.

## Browse: the catalog is self-describing

`GET /connections/catalog` returns one entry per connector. The fields that make it render-without-a-hardcoded-list:

- `logo` — `{ key, url, monogram }`. `url` is an absolute asset URL or `null` when no mark ships (then render the two-letter `monogram`; never guess a path).
- `connect` — `{ method, fields }`, the connect-flow spec. `api_key` connectors declare one secret `api_key` field with the vendor's key-shape `placeholder` and scope `help` when known; `handle` connectors declare a public `account_handle` field; `oauth` connectors declare `fields: []` (the flow is a redirect).
- `connectable` + `unavailableReason` — whether `connect` will accept this type right now.
- `single_instance` — the effective connect rule (read this, not the raw `instancing` capability, when deciding whether to offer a second connect).

Every connected-instance read carries a matching `connector` block (`{ type, name, category, logo }`), so a list of connections renders names and logos straight off the wire.

## Connect

`POST /connections` (or the MCP `connect` action) takes `connector_type` plus the fields the catalog's `connect` spec declared, and routes on the connector's auth method. Branch on `mode` in the response:

- **`connected`** — an `api_key` or `handle` connect landed: the credential stored (or the handle resolved) and the first sync was triggered.
- **`oauth_redirect`** — you got an `authorize_url`. Send the human there; the provider callback completes the connection server-side. Poll `GET /connections/:id/status` until `health` leaves `syncing`.
- **`already_connected`** — the existing connection, unchanged (workspace data sources are single-instance; the same handle dedupes).

For a call recorder, pass `call_filters` **on the connect itself** — the decision rides atomically, so the source never lands connected-but-paused waiting for a filter nobody configured. On MCP, the `connect` action forwards `call_filters` for exactly this reason.

```jsonc
// MCP
connections { "action": "connect", "connector_type": "askelephant", "api_key": "sk-apik_..." }
// handle connector
connections { "action": "connect", "connector_type": "twitter", "account_handle": "acme" }
```

## Watch

- `list` rows carry derived `health` — `healthy` / `syncing` / `stale` / `degraded` / `needs_reauth` / `rate_limited` / `error` / `disconnected` — computed server-side from the lifecycle status plus the most recent run. A connection can be `status: "connected"` and still `health: "stale"`; trust `health`.
- `status` is the lean polling read (`status` + `health` + `is_syncing`, nothing heavy).
- `runs` is the sync-run history, newest first, with a bucketed `error_reason` (`auth` / `rate_limit` / `transient` / `config` / `unknown`) — raw provider error text is never surfaced.
- `summary` is a glanceable snapshot of the connection's own synced data (deals and contacts for a CRM, calls for a recorder). Not-yet-synced degrades to `partial` with `null` stats — and `null` never means `0`.

**The stale-data investigation an agent should run**: `list` → find the source whose `health` is not `healthy` → `runs` for it → read `error_reason`. An `auth` reason means reconnect (below); `rate_limit` means it will retry on its own; blaming cadence is almost never the answer.

## Fix

`POST /connections/:id/reconnect` repairs **in place** — never a second row, so history and warehouse data stay attached. `oauth` re-mints the authorize URL, `api_key` takes a fresh key, `handle` re-triggers the sync. A healthy connection is refused (`invalid_argument`) — nothing to restore. `DELETE /connections/:id` disconnects but retains the row, so a later reconnect restores it.

## Traps

- **Don't offer a second connect off `instancing`.** Workspace data-source connectors are single-instance for connect even where the capability says `multi`; the served `single_instance` field is the rule.
- **`health: "stale"` on a `connected` row is real.** The lifecycle status alone cannot express "connected but nothing synced lately"; render `health`, not `status`.
- **A `403` on `connect` from an API key is the contract, not a missing scope.** Requesting more scopes will not fix it — the write surface is OAuth-only. Do the connect from an OAuth-connected client (or the console).
- **Sync cadence is not on this surface.** How often a connector type syncs is a platform-level setting; there is no per-connection cadence field to look for.

## See also

- Product docs: <https://docs.amdahl.ai/endpoints/connections> — the full endpoint guide, request shapes, and the connect-flow contract.
- [Operation reference](reference.md) — where the authoritative contracts live.
