# Operation reference — where the contracts live

**What this does**: Points you at the authoritative reference for the public operations — the **tool catalog** and the **OpenAPI-driven API reference** on <https://docs.amdahl.co> — and maps every recipe in this section to its operation ids so you know exactly which contract to look up.

**When to use it**: You want the exact input schema, response shape, or required scope for an operation, or you're checking why a call was refused. Read the published reference rather than trusting a doc that can drift.

## The reference surfaces

- **The API reference** — <https://docs.amdahl.co/api-reference> — the interactive, OpenAPI-driven console: every public REST operation with its full request/response schema, required scopes, and a browser-side "Try it" runner against `https://app.amdahl.co`.
- **The tool catalog** — on <https://docs.amdahl.co> — the generated per-operation catalog (the same descriptions the agent sees), grouped by family.

Both are generated from the platform's operation registry, so they track the deployed contract.

> **Don't build a discovery loop on `GET /operations`.** The registry's self-introspection surface (`GET /operations` / the `operation://list` resource) is console-internal: an external API key gets a `403` (`not_on_public_api`), and it isn't on the v2 MCP resource surface either. The published docs above are the discovery path for integrations.

## The public surface, recipe by recipe

The agent-platform recipes map to these operation ids — look any of them up in the API reference for the exact current schema:

| Recipe | Operation ids |
|---|---|
| [Fast lane](fast-lane-search.md) | `search.run` |
| [Structured search](structured-search.md) | `search.query`, `search.fields` |
| [Semantic search](semantic-search.md) | `search.query` (semantic lane), `search.fields` |
| [Tiered enrichment](tiered-enrichment.md) | `enrich.company`, `enrich.person`, `enrich.topic` |
| [Lookalikes](lookalikes.md) | `lookalike.find`, `lookalike.similar_themes` |
| [Agentic Chat](agentic-chat.md) | `chat.start`, `chat.get_run`, `chat.get`, `chat.list`, `chat.rename`, `agents.resume`, `agents.cancel` |
| [Routines](routines.md) | `routines.create`, `routines.list`, `routines.get`, `routines.update`, `routines.delete`, `routines.run_now` |
| [Saved agents](saved-agents.md) | `agents.create_agent`, `agents.list_agents`, `agents.get_agent`, `agents.update_agent`, `agents.delete_agent` |
| [Evals](evals.md) | `evals.run`, `evals.create`, `evals.update`, `evals.validate`, `eval.list`, `eval.get`, `eval_run.list`, `eval_run.get`, `grader_kind.list`, `grader_kind.get` |

These families — `search`, `enrich`, `lookalike`, the `chat` / `routines` / agent-library surface, and `evals` — are the whole public API. An external key calling anything outside it gets a `403` with `error.code: "not_on_public_api"`; those operations serve the console only.

## Tips

- **The published reference is the source of truth.** If a recipe's field list and the API reference ever disagree, the reference wins — it's generated from what the server enforces.
- **Check the operation's scopes before you call.** The reference lists `required_scopes` per operation — the fastest way to see why a `403` happened is to compare them to what your key holds.
- **A `403 not_on_public_api` means the wrong surface, not the wrong scope.** You called a console-internal operation with an external key; the fix is to use the public equivalents above (or do the job in the console), not to request more scopes.

## See also

- [Agent platform overview](README.md) — the two doors, the flag prerequisite, and the scope table.
- Product docs: <https://docs.amdahl.co>.
