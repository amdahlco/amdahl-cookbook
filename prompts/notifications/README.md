# Notifications

How to **email people on your workspace** from Amdahl — the last-mile delivery primitive that gets a recipe's output into a teammate's inbox instead of leaving it in the chat. Members-only by design (a non-member rejects the whole send), rate-capped, idempotent, and autonomous (no confirmation gate), so an agent can use it safely on its own.

You drive it through your agent: put the send in a **Chat**'s input, or grant it on a **Routine** via `actions_allowed` — the run performs the send server-side with the guardrails intact. (There is no standalone notifications tool on the current MCP surface, and the send endpoint isn't reachable with an external API key; the agent run is the path.)

- [Notify the workspace team](notify-the-workspace-team.md) — the **discover -> send -> verify** discipline the run should follow (resolve recipients from the member list, send with an idempotency key, confirm it landed), the guardrail contract, plus the unattended paths: a **Routine** (a scheduled Chat with `email_member` in its `actions_allowed`) for "every Monday, no human present," and the Workflow `tool`-step variant for typed recipes.

New here? Start with the [main README](../../README.md) for setup, then the [recipe library](../README.md) for the GTM prompts that produce the readouts worth emailing.
