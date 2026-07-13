# Notifications

How to **email people on your workspace** from Amdahl — the last-mile delivery primitive that gets a recipe's output into a teammate's inbox instead of leaving it in the chat. Members-only by design (a non-member rejects the whole send), rate-capped, idempotent, and autonomous (no confirmation gate), so an agent can use it safely on its own.

It works the same over MCP (the `notifications` coarse tool + the `notification_recipient://` and `notification_sends://` resources) and the REST API (`/notifications/*`).

- [Notify the workspace team](notify-the-workspace-team.md) — the full loop with copy-paste call shapes for both protocols: **list_recipients -> email_member -> list_sends** (discover who you can email, send, then confirm it landed and check the rate caps), plus the unattended paths: a **Routine** (a scheduled Chat with `email_member` in its `actions_allowed`) for "every Monday, no human present," and the Workflow `tool`-step variant for typed recipes.

New here? Start with the [main README](../../README.md) for setup, then the [recipe library](../README.md) for the GTM prompts that produce the readouts worth emailing.
