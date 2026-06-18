# Blueprints

How to author your own **Amdahl blueprints** — reusable, typed recipes that live in your workspace and that any connected LLM (or agent) can read and walk step-by-step.

A heads-up on the word "recipe": everything else in this cookbook is a *paste-ready Claude prompt*. A blueprint is a different thing — a structured DSL artifact saved inside Amdahl, authored through the MCP `blueprints` tool. The guide below opens by untangling the two so you don't conflate them.

- [How to write an Amdahl blueprint](authoring-a-blueprint.md) — the mental model (a recipe the LLM walks, NOT a thing the platform runs), the DSL anatomy (identity, inputs, outputs, the 8 step kinds, `$`-references, `prompt://` fragments, policy, trigger), how to validate via the `blueprints` tool, and two worked examples: a one-step blueprint from scratch and a fork-and-customize of the `draft-piece` starter.

Want to do it live, hands-on, against your own workspace? The Claude Code plugin ships a [blueprint-authoring skill](../../plugins/amdahl-gtm/skills/blueprint-authoring/SKILL.md) that drives the whole create -> validate -> fork -> iterate loop for you.

New here? Start with the [main README](../../README.md) for setup, then the [recipe library](../README.md) for the paste-ready GTM prompts.
