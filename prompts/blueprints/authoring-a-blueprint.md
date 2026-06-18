# How to write an Amdahl blueprint

**What this is**: A practical guide to authoring an Amdahl *agent blueprint* — a structured, typed recipe that an LLM reads and walks step-by-step using primitive Amdahl tools. You author, validate, and fork blueprints through the Amdahl MCP `blueprints` coarse tool. By the end you'll have written a one-step blueprint from scratch and forked a shipped starter into your own customized copy.

**When to use it**: "I keep running the same multi-step GTM workflow by hand and I want to save it as a reusable recipe my team (or an agent) can run the same way every time."

---

## First, untangle two things that share a name

This cookbook has two different things people call "recipes," and they are NOT the same:

- **Cookbook recipes / prompts** (everything else in [`prompts/`](../README.md)) are *Claude prompts* — text you paste into Claude that calls the Amdahl MCP tools. They live in this repo as markdown. Claude reads them as instructions for the current conversation.
- **Amdahl blueprints** (this guide) are a *typed DSL artifact* that lives inside your Amdahl workspace as an `agent_blueprint`. A blueprint is data — a strict JSON document with declared inputs, outputs, steps, and policy — that any connected LLM can read and walk later. You author it once and it persists in your workspace.

A cookbook prompt is "do this now, in this chat." A blueprint is "here is a reusable, structured procedure saved in Amdahl that anyone (or any agent) can pull up and run." This guide is about the second one.

## The mental model (read this twice)

A blueprint is **a recipe, not a program the platform runs.** There is no server-side blueprint runner in the product today. The platform's job is to let you *author*, *validate*, *version*, and *fork* blueprints — not execute them.

So who runs a blueprint? **The connected LLM is the runner.** When you (or a teammate) are in a Claude session connected to Amdahl, Claude reads the blueprint's step graph and *performs the steps itself*, calling the same primitive tools it always has (`data.query`, `external_search.execute`, `artifacts.create`, and so on). The blueprint is the script; Claude is the actor reading it.

Three consequences fall out of this, and they're worth internalizing before you write anything:

1. **You don't "run" a blueprint from MCP.** The `blueprints` tool is for authoring + discovery only. There is no `run` action on it. To execute, an agent reads the recipe (`blueprints get`) and makes the primitive calls directly, step by step.
2. **`policy.tool_allowlist` is guidance, not a fence.** It tells the reading LLM which operations the recipe *intends* to use. It is not enforced server-side. The real safety boundary is the **scope grammar of the API key** the session is using — the key's scopes decide what any tool call is actually allowed to do.
3. **`estimated_cost_cents`, `timeout_seconds`, and the allowlist are authoring metadata.** They set expectations and document intent. Treat them as labels and hints for the human and the reading LLM, not as runtime controls the platform enforces.

The easiest way to get a real blueprint in front of you is to **fork a starter** — an Amdahl-shipped recipe that's already valid. We'll do that in worked example 2. First, the anatomy.

## Anatomy of a blueprint

A blueprint's body is a strict JSON object (the `content_json` of an `agent_blueprint` artifact). "Strict" means you cannot add unknown top-level keys — every field is part of the v1 schema. The top-level shape:

| Field | Required | What it is |
|---|---|---|
| `schema_version` | yes | Pinned to `"1.0.0"` for v1. |
| `identity` | yes | Name, slug, description, version — the recipe's metadata. |
| `inputs` | yes (may be `[]`) | The parameters someone fills in to run it. |
| `outputs` | yes (may be `[]`) | What the recipe produces. Empty = a pure side-effect recipe. |
| `policy` | yes | Tool allowlist (guidance) + advisory caps. |
| `trigger` | yes | How it can be invoked. v1 ships `manual` only. |
| `steps` | yes (non-empty) | The body — the ordered step graph the LLM walks. |
| `outputs_mapping` | yes (may be `{}`) | Maps each declared output name to the step result that fills it. |
| `metadata` | optional | Provenance + free-form extras. |

### identity

```json
"identity": {
  "slug": "weekly-competitor-pulse",
  "name": "Weekly competitor pulse",
  "description": "Pulls fresh public signal on a named competitor and writes a short internal note. Use for a recurring battle-card refresh.",
  "version": "1.0.0",
  "category": "competitive",
  "tags": ["competitive", "weekly"]
}
```

- `slug` — lowercase handle, `[a-z0-9-]`, 3-60 chars. Unique within your workspace.
- `name` — up to 80 chars.
- `description` — **30 to 500 chars** (the schema rejects shorter or longer). Make it a real sentence.
- `version` — semver (`MAJOR.MINOR.PATCH`) for the *blueprint logic*, separate from `schema_version`. Bump it when you change the recipe.
- `category`, `tags`, `icon` — optional UI hints.

### inputs

Each input is a typed declaration. The 10 input types: `string`, `integer`, `number`, `boolean`, `date`, `datetime`, `enum`, `json`, `artifact_ref`, `artifact_ref_list`. Every input has a `name` (lowercase `snake_case`, starts with a letter), an optional `required`, an optional `description`, and an optional `ui` hint block. Per-type validation lives in a `validate` block:

```json
"inputs": [
  {
    "name": "competitor",
    "type": "string",
    "required": true,
    "description": "Competitor name or domain to pulse.",
    "validate": { "min_length": 2, "max_length": 120 }
  },
  {
    "name": "depth",
    "type": "enum",
    "required": false,
    "default": "standard",
    "validate": { "values": ["quick", "standard", "deep"] }
  }
]
```

- `string` validates with `regex` / `min_length` / `max_length`.
- `integer` / `number` validate with `min` / `max`.
- `enum` requires `validate.values` (at least one).
- `artifact_ref` requires `validate.artifact_type` (e.g. `content_piece`); `artifact_ref_list` adds optional `min` / `max`.

### outputs

Outputs declare what the recipe produces. Three kinds, mixable:

- `artifact` — produces an artifact of a given `artifact_type` with `cardinality: "one" | "many"`.
- `data` — returns structured JSON matching a small JSON-Schema subset.
- `side_effect` — performs a side effect; `category` is one of `slack_message`, `email_sent`, `webhook_call`, `external_api_call`, `notification`, `audit_log_entry`.

```json
"outputs": [
  { "kind": "artifact", "name": "note", "artifact_type": "knowledge_doc", "cardinality": "one" }
]
```

If `outputs` is `[]`, the recipe is a pure side-effect (or pure-write) blueprint and `outputs_mapping` is just `{}`.

### steps — the 8 step kinds

`steps` is the body. It must be non-empty. Every step is one of 8 kinds, discriminated by a `kind` field. Every step also has a unique `id` (lowercase, starts with a letter) and an optional `output_alias` (a `$name` you bind the step's result to so later steps can reference it cleanly).

| Kind | What it does | Key fields |
|---|---|---|
| `tool` | Call one Amdahl operation by id. The workhorse. | `tool` (op id), `args` (record of refs / literals) |
| `llm` | Run a structured prompt with an output schema. | `effort` (`fast`/`medium`/`deep`/`research`), `prompt`, `output_schema`, optional `prompt_resources`, `input_data`, `temperature` |
| `loop` | Iterate a collection, run a nested step per item. | `over` (ref), `as` (loop var), optional `parallel`, `step` |
| `branch` | Conditional dispatch. | `condition`, `if_true` (step), optional `if_false` (step) |
| `parallel` | Fan out N child steps concurrently. | `steps` (>= 1), optional `merge` (`object`/`array`) |
| `blueprint` | Compose another blueprint as a sub-step. | `blueprint` (ref/literal), `args` |
| `transform` | Pure data transform via a JSONata expression. | `input` (ref), `expression` |
| `assert` | Halt the run if a condition is false. | `condition`, `halt_message` |

A `tool` step is the one you'll use most:

```json
{
  "id": "pulse",
  "kind": "tool",
  "tool": "external_search.execute",
  "args": { "action": "enrich_topic", "topic": "$inputs.competitor" },
  "output_alias": "signal"
}
```

An `llm` step always declares an `output_schema` (a JSON-Schema-subset object) so the result is structured:

```json
{
  "id": "write_note",
  "kind": "llm",
  "effort": "medium",
  "prompt": "Summarize the competitor signal into a 5-bullet internal note. Cite each bullet.",
  "prompt_resources": ["prompt://researcher/evidence_synthesis"],
  "input_data": { "signal": "$signal" },
  "output_schema": {
    "type": "object",
    "properties": { "title": { "type": "string" }, "body_markdown": { "type": "string" } },
    "required": ["title", "body_markdown"]
  },
  "output_alias": "note"
}
```

The `effort` field names a *capability tier*, not a model — `fast` (cheap, quick), `medium` (the default, full reasoning), `deep` (heaviest reasoning / long context), `research` (web-grounded). The platform maps the tier to a concrete model per workspace, so your blueprint stays valid as models change.

### references — the `$` syntax

Anywhere the schema accepts a reference, write a `$`-prefixed expression. References resolve at run time; the LLM substitutes the resolved value as it walks the steps.

| Reference | Resolves to |
|---|---|
| `$inputs.NAME` | The supplied value of input `NAME`. |
| `$STEP_ID` or `$alias` | The output of an earlier step (by its `id` or its `output_alias`). |
| `$alias.path.to.field` | A nested field on that step's output. |
| `$now` | An ISO-8601 timestamp at resolve time. |
| `$today` | A `YYYY-MM-DD` date. |
| `$random_uuid` | A fresh UUID. |
| `$secret.NAME` | An encrypted secret-store entry. Never substituted into prompts; resolved only at the tool that needs it. |
| `$builtin.X` | A platform-managed reference. |

Reference the *alias* you bound (`output_alias`) rather than the step id where you can — it stays stable if you rename the step later.

### prompt fragments — `prompt://`

`llm` steps can pull in shared, Amdahl-maintained prompt snippets via `prompt_resources` using the `prompt://<scheme>/<id>` URI. The renderer inlines the fragment body into the step prompt. This lets your recipe reuse battle-tested instructions (grounding discipline, audience scoping, synthesis rules) instead of re-writing them.

Two schemes ship today: **`content_writer/*`** (16 fragments — including `grounding_rules`, `audience_scoping`, `channel_budget`, `cta_synthesis`, `hook_patterns`, `pillar_selection`, `cadence_rhythm`, `variant_drafting`) and **`researcher/*`** (8 fragments — including `topic_decomposition`, `evidence_synthesis`, `cross_pattern_synthesis`, `confidence_scoring`, `metric_grounding`, `document_render`, `eval_rubric`, `intent_routing`). Don't guess fragment ids — list them live with `blueprints list_prompt_fragments` (optionally `scheme="content_writer"`, `include_body=true`). A typo'd `prompt://` id is one of the most common validation errors.

`prompt_resources` also accepts `artifact://<id>` and `knowledge_base://<id>` URIs; those stay as "read this resource first" hints rather than being inlined.

### policy

```json
"policy": {
  "tool_allowlist": ["external_search.execute", "artifacts.create"],
  "artifact_write_allowlist": ["knowledge_doc"],
  "timeout_seconds": 600,
  "parallelism_max": 4
}
```

- `tool_allowlist` (required, at least one) — the operation ids the recipe's `tool` steps intend to call. **Guidance for the reading LLM, not server-enforced.** The API key's scopes are the real boundary.
- `artifact_write_allowlist` (optional) — artifact types the recipe intends to write. Same guidance status.
- `timeout_seconds`, `parallelism_max`, `retry_policy`, `cost_cap_usd` — advisory hints. Document intent; not runtime-enforced on the recipe path.

### trigger

v1 ships `manual` only:

```json
"trigger": { "manual": { "enabled": true } }
```

(`schedule`, `event`, and `webhook` trigger shapes exist in the schema as forward-compatible placeholders, but manual is the one that works today.)

### outputs_mapping

When `outputs` is non-empty, map each declared output name to the step result that fills it (by reference):

```json
"outputs_mapping": { "note": "$note" }
```

## How to discover the grammar live

You don't have to hold all of this in your head. The `blueprints` tool is self-documenting — ask it before you author:

- `blueprints describe_step_kinds` — the 8 step kinds with field tables and complete example bodies.
- `blueprints list_prompt_fragments` — every registered `prompt://` fragment (add `scheme=` to filter, `include_body=true` to see the text).
- `blueprints list` — every blueprint your workspace can see (Amdahl starters + your own).
- `blueprints get id="research-report"` — the full validated DSL of a shipped starter, to copy from.

## How to validate

Before you save anything, dry-run the body through the moat:

```
blueprints validate content=<the full DSL body>
```

It returns `{ valid: boolean, errors: [...] }`. Each error carries a stable `code`. The ones you'll hit most:

- `schema_error` — the body failed the strict v1 schema (wrong field name, missing required field, bad enum). Re-read the anatomy above.
- `unknown_reference` — a `$alias.field` points at something that doesn't exist (usually a typo, e.g. `$singal` for `$signal`).
- `unknown_fragment` — a `prompt://` id isn't registered (e.g. `grounded_rules` instead of `grounding_rules`). Re-list fragments.
- `duplicate_step_id` — two steps share an `id` (easy to hit when you copy-paste a step block).
- `invalid_tool_id` — a `tool_allowlist` entry isn't a real operation id.

The moat catches these *before* the write, and returns the full list in one shot. `create` and `update` run the same checks, but validate-first gives you everything to fix at once.

---

## Worked example 1 — a trivial blueprint from scratch

Goal: the smallest useful, valid recipe — one tool step that enriches a topic and returns the brief. This is the "hello world" of blueprints.

```json
{
  "schema_version": "1.0.0",
  "identity": {
    "slug": "topic-pulse",
    "name": "Topic pulse",
    "description": "Runs a fused internal + external search on a topic and returns the brief. The smallest reusable research recipe; a good base to extend.",
    "version": "1.0.0",
    "category": "research",
    "tags": ["research", "starter"]
  },
  "inputs": [
    {
      "name": "topic",
      "type": "string",
      "required": true,
      "description": "The topic or question to pulse.",
      "validate": { "min_length": 3, "max_length": 300 }
    }
  ],
  "outputs": [
    { "kind": "data", "name": "brief", "schema": { "type": "object" } }
  ],
  "policy": {
    "tool_allowlist": ["external_search.execute"]
  },
  "trigger": { "manual": { "enabled": true } },
  "steps": [
    {
      "id": "pulse",
      "kind": "tool",
      "tool": "external_search.execute",
      "args": { "action": "enrich_topic", "topic": "$inputs.topic" },
      "output_alias": "pulse_result"
    }
  ],
  "outputs_mapping": { "brief": "$pulse_result" }
}
```

Author it in three calls:

```
blueprints validate content=<the body above>
blueprints create  content=<the body above> status="draft"
# returns { success: true, blueprint: { header: { id, slug, ... }, content: {...} } }
# save header.id
```

Then flip it live once you're happy:

```
blueprints update id="<the id>" status="published" change_summary="Promote topic-pulse"
```

That's a complete, valid, persisted blueprint. To "run" it, an agent connected to your workspace reads it (`blueprints get id="topic-pulse"`) and makes the `external_search.execute` call itself — there's no `run` action, by design.

## Worked example 2 — fork a starter and customize it

Most real work starts from a starter. Amdahl ships several (`bootstrap-workspace`, `draft-piece`, `plan-and-draft-window`, `multi-persona-social-launch`, `research-report`, and a Substack newsletter recipe). Forking copies one into your workspace as a fresh, editable draft.

Say your team only ever writes LinkedIn posts and you want a LinkedIn-locked drafter. Start from `draft-piece`.

**1. Read what you're starting from.**

```
blueprints get id="draft-piece"
```

You'll see its inputs (`piece_id`, `variant_key`), its steps (`load_piece`, `load_author`, `load_voice`, `gather_evidence`, `assert_evidence`, `write_draft`, `attach_citations`, `update_piece`), and which `prompt://content_writer/*` fragments it composes.

**2. Fork it.**

```
blueprints fork source="draft-piece" new_slug="linkedin-drafter" new_name="LinkedIn drafter"
```

The fork lands as a brand-new tenant blueprint: a fresh id, `version` reset to `1.0.0`, `authored_by: "tenant"`, `status: "draft"`, `visibility: "private"`. The original starter is untouched, and the fork records where it came from (`metadata.forked_from`) so its lineage stays traceable.

**3. Customize via update (replace-semantic).**

Read the fork (`blueprints get id="<fork-id>"`), edit the body in your reasoning loop, then write the **whole** body back. `update` is replace-semantic: the `content` you send becomes the entire new `content_json`, so omitted keys are dropped — always send the full body, not a partial patch. For the LinkedIn lock, the typical edits are: tighten the `write_draft` prompt to LinkedIn norms (under ~150 words, no hashtags), and optionally add `prompt://content_writer/channel_budget` if it isn't already there.

```
blueprints validate content=<the full edited body>
blueprints update   id="<fork-id>" content=<the full edited body> change_summary="Lock to LinkedIn; tighten hook + budget"
```

**4. Iterate.** Bump `identity.version` to `1.1.0` when you change the recipe meaningfully. Re-validate, re-update. When it's right, `blueprints update id="<fork-id>" status="published"`.

That's the whole loop: **fork -> read -> edit -> validate -> update -> publish.** You never start from a blank file unless you want to (worked example 1); for anything close to an existing pipeline, fork and trim.

---

## Common mistakes (and the rule that prevents each)

- **Trying to run a blueprint from the `blueprints` tool.** There is no `run` action. If you want to execute, read the recipe and make the primitive calls yourself — you (the LLM) are the runner.
- **Skipping `validate`.** `create` / `update` will reject a bad body anyway, but `validate` hands you the *full* error list in one round-trip. Always dry-run first.
- **Guessing `prompt://` fragment ids or operation ids.** List them (`list_prompt_fragments`, and consult the tool catalog for op ids). A typo is an `unknown_fragment` / `invalid_tool_id` reject.
- **Sending a partial body on `update`.** It's replace-semantic — omitted top-level keys are dropped. Send the whole body.
- **Putting a literal secret in the body.** Reference it as `$secret.NAME`. A literal key in the body is stored in plain text on the artifact and visible to every agent in the workspace.
- **Treating the `tool_allowlist` as a security control.** It's guidance for the reading LLM. The API key's scopes are the real boundary.

## See also

- [Blueprint authoring skill](../../plugins/amdahl-gtm/skills/blueprint-authoring/SKILL.md) — drives this whole loop live against the Amdahl `blueprints` tool, with `/amdahl-gtm:*` plays.
- The rest of the cookbook: [recipe library](../README.md) — paste-ready GTM prompts (the *other* meaning of "recipe").
- Product docs: <https://amdahl.co/mcp>.
