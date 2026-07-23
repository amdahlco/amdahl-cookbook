# Blueprints

How to author your own **Amdahl blueprints** — reusable, typed recipes (the console calls them **Workflows**) that live in your workspace and that the platform can validate, version, fork, schedule, and run.

A heads-up on the word "recipe": everything else in this cookbook is a *paste-ready Claude prompt*. A blueprint is a different thing — a structured DSL artifact saved inside Amdahl, authored in the **console** (the Workflows surface). It is a console capability: the MCP `blueprints` tool was retired, and the endpoints behind the console aren't reachable with an external API key. From a connected Claude session, recurring work is a **Routine** — a scheduled Chat created with the `agents` tool — and one-shot deep work is a **Chat** (`agents` `start_chat`). The guide below opens by untangling the two so you don't conflate them.

> **Rollout note:** the v2 agent platform (the `search` + `agents` MCP tools, with the `blueprints` and `pages` tools retired) is enabled **per workspace**. If your connected session still lists a `blueprints` or `pages` tool and no `search`/`agents`, your workspace is on the pre-rollout surface — keep using those tools as before, and ask your Amdahl admin about Agent Platform v2.


- [How to write an Amdahl blueprint](authoring-a-blueprint.md) — the mental model (a typed recipe the platform validates, forks, schedules, and runs), the DSL anatomy (identity, inputs, outputs, the 8 step kinds, `$`-references, `prompt://` fragments, policy, trigger), how to validate in the console, and two worked examples: a one-step blueprint from scratch and a fork-and-customize of the `draft-piece` starter.

Want help composing one? The Claude Code plugin ships a [blueprint-authoring skill](../../plugins/amdahl-gtm/skills/blueprint-authoring/SKILL.md) that walks the DSL with you — drafting and checking the body, then handing you the finished JSON for the console's Workflows surface (and routing "make this recur" asks to Routines).

New here? Start with the [main README](../../README.md) for setup, then the [recipe library](../README.md) for the paste-ready GTM prompts.
