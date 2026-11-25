# Notifications

How to **email people on your workspace** from Amdahl — the last-mile delivery primitive that gets a recipe's output into a teammate's inbox instead of leaving it in the chat. Members-only by design (a non-member rejects the whole send), rate-capped, idempotent, and autonomous (no confirmation gate), so an agent can use it safely on its own.

Chat and Routines, the agent runs that used to carry the send, are retired. A Workflow `tool` step, authored in the console, still performs the send server-side with the guardrails intact. There is no notifications tool on the MCP server, and the send endpoint isn't reachable with an external API key.

- [Notify the workspace team](notify-the-workspace-team.md) — the **discover -> send -> verify** discipline the run should follow (resolve recipients from the member list, send with an idempotency key, confirm it landed), the guardrail contract, plus the Workflow `tool`-step variant for unattended sends.

New here? Start with the [main README](../../README.md) for setup, then the [recipe library](../README.md) for the GTM prompts that produce the readouts worth emailing.
