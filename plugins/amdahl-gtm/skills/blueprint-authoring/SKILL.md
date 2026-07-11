---
name: blueprint-authoring
description: Author, validate, and fork Amdahl workflow recipes (blueprints) over the Amdahl REST API — and route "make this recur" asks to Routines. Use when the user wants to create / edit / fork / validate a workflow (blueprint), save a multi-step GTM workflow as a reusable recipe, customize a starter, schedule recurring work, or learn the blueprint DSL. The `blueprints` MCP tool was retired — workflow authoring is console + REST; over MCP, recurring work is a Routine (`agents` tool, a cron that fires a Search) and one-shot deep work is a `search`.
---

# Amdahl blueprint authoring

When the user wants to **save a repeatable multi-step workflow as a reusable recipe**, or to **create / edit / fork / validate** an Amdahl blueprint (the console calls them **Workflows**), drive the authoring loop over the Amdahl **REST API** (`/api/platform/v1/agent-blueprints*`, platform API key with `versioning:write`; `artifacts:read` for the reads). The `blueprints` MCP tool was **retired** — nothing blueprint-shaped is authored, read, or run over MCP anymore.

**Route the ask first — Routine or Workflow?**

- The user wants a **standing, scheduled refresh** in plain language ("every Monday, refresh the pipeline report") → don't author a blueprint. Create a **Routine** with the connected Amdahl MCP `agents` tool (`create_routine` with `name` + `prompt` + `cron`): a Routine is a cron that fires a Search — one server-side Master agent turn in a fresh Session — each occurrence. `run_routine_now` fires one immediately.
- The user wants **one-shot deep work run server-side** → the MCP `search` tool (start → poll status → respond).
- The user wants the **fully-typed, step-by-step contract** — declared inputs/outputs, a validated step graph, forkable starters → author a **Workflow (blueprint)** over REST, per this skill. If no API key is available, compose + explain the body and point the user at the console's Workflows surface.

If an MCP call fails on auth, tell the user to run `/amdahl-gtm:setup`.

Hold this mental model and keep the user on it:

- A blueprint is a **structured recipe (a typed DSL artifact) with two ways to run.** The platform runs Workflows **headlessly** (`POST /agent-blueprints/:id/run`, and cron schedules fired server-side); an agent reading the recipe over the console or REST can also **walk it interactively**, making the primitive calls itself (`data.query`, `external_search.execute`, `artifacts.create`, ...).
- **Blueprints are off MCP.** Never tell the user to author or run a blueprint from an MCP session; from MCP the automation surfaces are Routines (`agents`) and Search (`search`).
- `policy.tool_allowlist` is **load-bearing on headless runs** — the platform derives the run's scopes from it (least-privilege) — and guidance for an interactive walker. `timeout_seconds` and `cost_cap_usd` are advisory authoring metadata. The API key's scope grammar remains the outer safety boundary.
- A cookbook *recipe/prompt* (paste-into-Claude text) is a DIFFERENT thing from an in-app *blueprint* (the DSL artifact). If the user conflates them, clarify once.

## The REST endpoints

| Method + path | Purpose | Key body/query params |
|---|---|---|
| `GET /agent-blueprints` | Every blueprint the workspace sees (Amdahl starters + tenant rows). | `status`, `limit`, `offset` |
| `GET /agent-blueprints/:id` | Full v1 DSL body for one blueprint. | `:id` (UUID always; slug resolves for Amdahl starters) |
| `GET /step-kinds` | The 8 step kinds with fields + example bodies. | — |
| `GET /prompt-fragments` | Registered `prompt://` fragments (lean list, no body). | `scheme` |
| `POST /agent-blueprints/validate` | Dry-run the moat on a draft body. Returns `{ valid, errors[] }`. | `content` |
| `POST /agent-blueprints` | Persist a new tenant blueprint. | `content`, `status` |
| `PATCH /agent-blueprints/:id` | Patch a tenant blueprint (content is REPLACE-semantic). | `content`, `change_summary`, `status` |
| `DELETE /agent-blueprints/:id` / `POST /agent-blueprints/:id/unarchive` | Soft-archive / restore. | `:id` |
| `POST /agent-blueprints/fork` | Copy a starter or tenant blueprint into a fresh draft. | `source`, `new_slug`, `new_name` |
| `POST /agent-blueprints/:id/run` | Fire one headless run of a published workflow. | `inputs` |

## The loop you drive

Always: **orient -> draft -> validate -> create/fork -> iterate.** Never write before validating.

1. **Orient.** Pull the grammar so the body is right the first time: `GET /step-kinds`, and `GET /prompt-fragments` (filter with `?scheme=content_writer` or `?scheme=researcher`; the list is lean — fetch `GET /prompt-fragments/:id` to read a fragment's text). If the user's ask is close to an existing recipe, `GET /agent-blueprints` then `GET /agent-blueprints/:id` for that starter and copy from it — forking beats authoring from scratch.
2. **Draft.** Compose the v1 DSL body in your reasoning loop (see the anatomy below). Show it to the user before writing.
3. **Validate.** `POST /agent-blueprints/validate` with `{ "content": <body> }`. Read `errors[]` and fix by `code` (see the error table). Re-validate until `valid: true`.
4. **Create or fork.** `POST /agent-blueprints` with `{ "content": <body>, "status": "draft" }` for net-new; or `POST /agent-blueprints/fork` with `{ "source": "<slug>" }` to start from a starter, then `PATCH` the fork. Save the returned blueprint id.
5. **Iterate.** Read (`GET /agent-blueprints/:id`), edit, re-validate, `PATCH /agent-blueprints/:id` with the full body. Bump `identity.version` on a real change. Promote with `PATCH /agent-blueprints/:id` `{ "status": "published" }` when the user is happy.

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
- `prompt://<scheme>/<id>` in an `llm` step's `prompt_resources` inlines a shared fragment. Two schemes: `content_writer/*` (grounding_rules, audience_scoping, channel_budget, cta_synthesis, hook_patterns, ...) and `researcher/*` (topic_decomposition, evidence_synthesis, confidence_scoring, metric_grounding, document_render, ...). DON'T guess ids — `GET /prompt-fragments` first.
- `policy.tool_allowlist` (>=1 op id) is required — headless runs derive their scopes from it, so keep it honest. `trigger`: `{ "manual": { "enabled": true } }`; `schedule` (cron) also ships, though for a plain-language cadence a Routine is usually the better fit.
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
- `unknown_fragment` — a `prompt://` id isn't registered (e.g. `grounded_rules` vs `grounding_rules`). Re-run `GET /prompt-fragments`.
- `duplicate_step_id` — two steps share an `id` (common after copy-paste). Rename one.
- `invalid_tool_id` — a `tool_allowlist` entry isn't a real operation id.

## Operating rules

- Validate before every write. Surface the `errors[]` to the user with the fix, don't just retry blindly.
- `PATCH`'s `content` is REPLACE-semantic: always send the WHOLE body, never a partial patch — omitted top-level keys are dropped.
- Prefer forking a starter (`POST /agent-blueprints/fork` with `source: "draft-piece" | "research-report" | ...`) over authoring from scratch when the ask is close to an existing recipe. Starters are read-only; fork first, then edit the fork.
- Never put a literal secret in the body — reference `$secret.NAME`. A literal key is stored in plaintext on the artifact.
- When the user says "run" the blueprint: publish it, then fire `POST /agent-blueprints/:id/run` (headless) — or, if what they really want is "run this on a cadence," offer a Routine instead (`agents create_routine` over MCP).
- When the user asks to do any of this from an MCP-connected chat: the `blueprints` MCP tool was retired — route them to the console/REST, or to Routines + Search for the MCP-native equivalents.
- The full narrative guide (mental model, anatomy, two worked examples) lives at `prompts/blueprints/authoring-a-blueprint.md` — point the user there for depth.

This skill drives a live authoring loop; it stays thin and defers DSL depth to the guide so it remains correct as the platform's starters + fragments evolve.
