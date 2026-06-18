---
name: blueprint-authoring
description: Author, validate, and fork Amdahl agent blueprints live against the connected Amdahl MCP `blueprints` tool. Use when the user wants to create / edit / fork / validate a blueprint, save a multi-step GTM workflow as a reusable recipe, customize a starter, or learn the blueprint DSL. A blueprint is a typed recipe an LLM walks step-by-step — NOT a thing the platform runs; the `blueprints` tool does authoring + discovery only (no run action).
---

# Amdahl blueprint authoring

When the user wants to **save a repeatable multi-step workflow as a reusable recipe**, or to **create / edit / fork / validate** an Amdahl blueprint, drive the authoring loop through the connected **Amdahl** MCP `blueprints` coarse tool. If the server isn't connected or a call fails on auth, tell the user to run `/amdahl-gtm:setup`.

Hold this mental model and keep the user on it:

- A blueprint is a **structured recipe (a typed DSL artifact), not a program the platform runs.** There is no server-side runner. When an agent is connected, **the agent IS the runner** — it reads the recipe and performs the steps itself with primitive tools (`data.query`, `external_search.execute`, `artifacts.create`, ...).
- The `blueprints` tool is **authoring + discovery only**. There is **no `run` action**. Never tell the user to "run" a blueprint from MCP; to execute, read it (`get`) and make the primitive calls directly.
- `policy.tool_allowlist`, `timeout_seconds`, and `cost_cap_usd` are **authoring metadata / guidance**, not enforced runtime controls. The API key's scope grammar is the real safety boundary.
- A cookbook *recipe/prompt* (paste-into-Claude text) is a DIFFERENT thing from an in-app *blueprint* (the DSL artifact). If the user conflates them, clarify once.

## The `blueprints` tool actions

| Action | Purpose | Key params |
|---|---|---|
| `list` | Every blueprint the workspace sees (Amdahl starters + tenant rows). | `search`, `source_filter`, `include_archived` |
| `get` | Full v1 DSL body for one blueprint. | `id` (UUID or slug) |
| `describe_step_kinds` | The 8 step kinds with fields + example bodies. | — |
| `list_prompt_fragments` | Registered `prompt://` fragments. | `scheme`, `include_body` |
| `validate` | Dry-run the moat on a draft body. Returns `{ valid, errors[] }`. | `content` |
| `create` | Persist a new tenant blueprint. | `content`, `status` |
| `update` | Patch a tenant blueprint (content is REPLACE-semantic). | `id`, `content`, `change_summary`, `status` |
| `delete` / `unarchive` | Soft-archive / restore. | `id` |
| `fork` | Copy a starter or tenant blueprint into a fresh draft. | `source`, `new_slug`, `new_name` |

## The loop you drive

Always: **orient -> draft -> validate -> create/fork -> iterate.** Never write before validating.

1. **Orient.** Pull the grammar so the body is right the first time: `describe_step_kinds`, and `list_prompt_fragments` (filter with `scheme="content_writer"` or `scheme="researcher"`; `include_body=true` to read the text). If the user's ask is close to an existing recipe, `list` then `get` that starter and copy from it — forking beats authoring from scratch.
2. **Draft.** Compose the v1 DSL body in your reasoning loop (see the anatomy below). Show it to the user before writing.
3. **Validate.** `validate content=<body>`. Read `errors[]` and fix by `code` (see the error table). Re-validate until `valid: true`.
4. **Create or fork.** `create content=<body> status="draft"` for net-new; or `fork source="<slug>"` to start from a starter, then `update` the fork. Save the returned blueprint id.
5. **Iterate.** Read (`get`), edit, re-`validate`, `update id=<id> content=<full body>`. Bump `identity.version` on a real change. Promote with `update id=<id> status="published"` when the user is happy.

## DSL anatomy (what a valid body needs)

Top-level (strict — no extra keys): `schema_version` (`"1.0.0"`), `identity`, `inputs`, `outputs`, `policy`, `trigger`, `steps`, `outputs_mapping`, optional `metadata`.

- `identity`: `slug` (`[a-z0-9-]`, 3-60), `name` (<=80), `description` (**30-500 chars**), `version` (semver). Optional `category`, `tags`, `icon`.
- `inputs`: typed declarations (`string` / `integer` / `number` / `boolean` / `date` / `datetime` / `enum` / `json` / `artifact_ref` / `artifact_ref_list`), each with `name` (snake_case), optional `required`, optional `validate` (e.g. `enum` needs `validate.values`; `artifact_ref` needs `validate.artifact_type`).
- `outputs`: `kind` = `artifact` (with `artifact_type` + `cardinality`) | `data` (with `schema`) | `side_effect` (with `category`). May be `[]` (pure side-effect recipe).
- `steps` (non-empty): each has `kind`, unique `id`, optional `output_alias`. The 8 kinds:
  - `tool` — call one op: `tool` (op id) + `args`. The workhorse.
  - `llm` — `effort` (`fast`/`medium`/`deep`/`research`) + `prompt` + `output_schema` (required); optional `prompt_resources`, `input_data`, `temperature`.
  - `loop` — `over` + `as` + `step`, optional `parallel`.
  - `branch` — `condition` + `if_true`, optional `if_false`.
  - `parallel` — `steps` (>=1), optional `merge`.
  - `blueprint` — compose a sub-blueprint: `blueprint` + `args`.
  - `transform` — `input` + JSONata `expression`.
  - `assert` — `condition` + `halt_message`.
- References (`$`): `$inputs.NAME`, `$STEP_ID` / `$alias`, `$alias.field`, `$now`, `$today`, `$random_uuid`, `$secret.NAME` (never goes into prompts), `$builtin.X`. Prefer referencing `output_alias` over the raw step id.
- `prompt://<scheme>/<id>` in an `llm` step's `prompt_resources` inlines a shared fragment. Two schemes: `content_writer/*` (grounding_rules, audience_scoping, channel_budget, cta_synthesis, hook_patterns, ...) and `researcher/*` (topic_decomposition, evidence_synthesis, confidence_scoring, metric_grounding, document_render, ...). DON'T guess ids — `list_prompt_fragments` first.
- `policy.tool_allowlist` (>=1 op id) is required but GUIDANCE only. `trigger`: `{ "manual": { "enabled": true } }` (v1 ships manual only).
- `outputs_mapping`: map each declared output name to a `$`-reference (e.g. `{ "report": "$report_id" }`); `{}` when `outputs` is `[]`.

A minimal valid body:

```json
{
  "schema_version": "1.0.0",
  "identity": { "slug": "topic-pulse", "name": "Topic pulse", "description": "Runs a fused internal + external search on a topic and returns the brief. The smallest reusable research recipe.", "version": "1.0.0" },
  "inputs": [{ "name": "topic", "type": "string", "required": true, "validate": { "min_length": 3, "max_length": 300 } }],
  "outputs": [{ "kind": "data", "name": "brief", "schema": { "type": "object" } }],
  "policy": { "tool_allowlist": ["external_search.execute"] },
  "trigger": { "manual": { "enabled": true } },
  "steps": [{ "id": "pulse", "kind": "tool", "tool": "external_search.execute", "args": { "action": "enrich_topic", "topic": "$inputs.topic" }, "output_alias": "pulse_result" }],
  "outputs_mapping": { "brief": "$pulse_result" }
}
```

## Validation errors and how to fix them

`validate` (and `create` / `update`) return errors keyed by a stable `code`:

- `schema_error` — body failed the strict v1 schema (wrong field, missing required, bad enum). Re-check the anatomy.
- `unknown_reference` — a `$alias.field` points at nothing (usually a typo). Check the step that bound the alias.
- `unknown_fragment` — a `prompt://` id isn't registered (e.g. `grounded_rules` vs `grounding_rules`). Re-run `list_prompt_fragments`.
- `duplicate_step_id` — two steps share an `id` (common after copy-paste). Rename one.
- `invalid_tool_id` — a `tool_allowlist` entry isn't a real operation id.

## Operating rules

- Validate before every write. Surface the `errors[]` to the user with the fix, don't just retry blindly.
- `update` is REPLACE-semantic: always send the WHOLE body, never a partial patch — omitted top-level keys are dropped.
- Prefer forking a starter (`fork source="draft-piece" | "research-report" | ...`) over authoring from scratch when the ask is close to an existing recipe. Starters are read-only; fork first, then edit the fork.
- Never put a literal secret in the body — reference `$secret.NAME`. A literal key is stored in plaintext on the artifact.
- When the user says "run" the blueprint: gently correct — there's no run action. Offer to read it (`get`) and walk the steps with primitives, or to publish it so an agent can.
- The full narrative guide (mental model, anatomy, two worked examples) lives at `prompts/blueprints/authoring-a-blueprint.md` — point the user there for depth.

This skill drives a live authoring loop; it stays thin and defers DSL depth to the guide so it remains correct as the platform's starters + fragments evolve.
