# Operation reference — the live catalog

**What this does**: Points you at the **self-describing** operation catalog instead of a hand-maintained list. Every Amdahl operation — its id, description, kind, sensitivity, required scopes, and input schema — is queryable at runtime, so the authoritative reference is the API itself, always current with your workspace.

**When to use it**: You want the exact input schema or required scope for an operation, you're building a tool picker, or you want to confirm which operations your key can actually reach. Read the catalog rather than trusting a doc that can drift.

## Why the reference is live

The cookbook recipes describe the operations you'll use most, but the *complete, current* contract lives in the registry. Reading it back means you never integrate against a stale field list — the catalog reflects exactly what's registered on the server you're calling.

## Read the catalog

| Job | REST | MCP | Scope |
|---|---|---|---|
| List all operations | `GET /operations` | resource `operation://list` | `artifacts:read` |
| One operation's full contract | `GET /operations/:id` | resource `operation://<id>` | `artifacts:read` |

**REST:**

```
GET /operations?kind=compute
Authorization: Bearer <api-key with artifacts:read>
```

Filters: `?namespace=` (e.g. `chat`, `search`, `routines`), `?kind=read|write|compute|workflow`, `?include_admin=false` (default).

**What comes back** — one lean entry per operation:

```json
{
  "operations": [
    {
      "id": "search.run",
      "namespace": "search",
      "name": "Fast Search",
      "description": "Use when you want one concrete question answered in a single synchronous call ...",
      "kind": "compute",
      "sensitivity": "safe",
      "required_scopes": ["data:read"],
      "input_schema": { "type": "object", "properties": { "query": { "type": "string" }, "mode": { "enum": ["internal", "blended"] } } },
      "expected_latency_ms": 6000
    }
  ],
  "namespaces": { "search": 1, "chat": 5, "routines": 6, "agents": 5 },
  "count": 167
}
```

**One operation:**

```
GET /operations/chat.start   ->   { "operation": { "id": "chat.start", "required_scopes": ["conversations:write"], "input_schema": { ... } } }
```

## The operations behind this section

The agent-platform recipes map to these registry ids — read any of them with `GET /operations/<id>` for the exact current schema:

| Recipe | Operation ids |
|---|---|
| [Fast lane](fast-lane-search.md) | `search.run` |
| [Agentic Chat](agentic-chat.md) | `chat.start`, `chat.get_run`, `chat.get`, `chat.list`, `chat.rename`, `agents.cancel` |
| [Routines](routines.md) | `routines.create`, `routines.list`, `routines.get`, `routines.update`, `routines.delete`, `routines.run_now` |
| [Saved agents](saved-agents.md) | `agents.create_agent`, `agents.list_agents`, `agents.get_agent`, `agents.update_agent`, `agents.delete_agent` |

## Tips

- **The catalog is the source of truth.** If a recipe's field list and `GET /operations/:id` ever disagree, the live schema wins — it's what the server enforces.
- **Filter by namespace to scope your read.** `?namespace=chat` returns just the Chat door's operations.
- **Check `required_scopes` before you call.** It's the fastest way to see why a `403` happened — compare the operation's scopes to what your key holds.

## See also

- [Agent platform overview](README.md) — the two doors, the flag prerequisite, and the scope table.
- Product docs: <https://amdahl.co/mcp>.
