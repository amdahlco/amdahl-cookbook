# Blueprints

How to author your own **Amdahl blueprints** — reusable, typed recipes (the console calls them **Workflows**) that live in your workspace and that the platform can validate, version, fork, schedule, and run.

A heads-up on the word "recipe": everything else in this cookbook is a *paste-ready Claude prompt*. A blueprint is a different thing — a structured DSL artifact saved inside Amdahl, authored in the **console** (the Workflows surface). It is a console capability: the MCP `blueprints` tool was retired, and the endpoints behind the console aren't reachable with an external API key. From a connected Claude session, deep work is a **Chat** (`start_chat`). The guide below opens by untangling the two so you don't conflate them.


- [How to write an Amdahl blueprint](authoring-a-blueprint.md) — the mental model (a typed recipe the platform validates, forks, schedules, and runs), the DSL anatomy (identity, inputs, outputs, the 8 step kinds, `$`-references, `prompt://` fragments, policy, trigger), how to validate in the console, and two worked examples: a one-step blueprint from scratch and a fork-and-customize of the `draft-piece` starter.

Want help composing one? The Claude Code plugin ships a [blueprint-authoring skill](../../plugins/amdahl-gtm/skills/blueprint-authoring/SKILL.md) that walks the DSL with you — drafting and checking the body, then handing you the finished JSON for the console's Workflows surface.

New here? Start with the [main README](../../README.md) for setup, then the [recipe library](../README.md) for the paste-ready GTM prompts.
