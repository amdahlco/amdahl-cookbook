# Notify the workspace team

**What this does**: Gets an email to people on your Amdahl workspace — by asking your agent. A Chat (or a scheduled Routine) performs the send through the platform's notifications primitive, and the run can confirm it landed without double-sending. It's the "tell my team" last mile: the run discovers who it can email, sends, then verifies delivery and checks the rate caps.

**When to use it**: "Claude just finished the win-loss postmortem (or the weekly pipeline recap, or a competitor brief) — now email the two-line takeaway to the deal owner and my manager." Anything where the output of a GTM play should land in a teammate's inbox, not just the chat.

## Why this matters

Most cookbook recipes end in the chat: a brief, a draft, a target list. The last mile is getting that result to a human who isn't watching the session. The member-email primitive (`email_member`) is that last mile — and it's deliberately narrow so an agent can use it autonomously without becoming a spam cannon:

- **Members only.** Every recipient must be a current member of the workspace. Hand it an outside address and the *whole* send fails with `invalid_argument` and a `non_members[]` list naming exactly which addresses were rejected — nothing is sent. This is the anti-spam guarantee: a confused agent can email your teammates, never your customers.
- **Capped.** A per-business hourly cap (default 100) and a per-run cap (default 20) bound the blast radius. Exceed either and the send returns `rate_limited` and sends nothing.
- **Idempotent.** A send carries an `idempotency_key`; a repeat of the same key returns `skipped_duplicate: true` with no second email. Safe to retry; safe to re-fire a run.
- **Autonomous + per-recipient resilient.** No confirmation gate — the run can send without pausing — and one bad address doesn't sink the rest: the result splits into `sent[]` and `failed[]` so a partial send is legible.

The loop has three moves, and the first and last are what make it safe to automate: **discover recipients, send, then verify + check caps.** Skipping discovery is how a run ends up guessing at addresses; skipping verification is how you re-send because you weren't sure the first one went.

## How you reach it

On the current (v2) agent platform the send is driven **through the agent run**, not as a tool you call directly:

| Path | How |
|---|---|
| Interactive (a human watching) | Put the send in a [Chat](../agent-platform/agentic-chat.md)'s input — "…and email the takeaway to {names}." The run performs the discover -> send -> verify loop server-side. |
| Unattended (no human present) | A [Routine](../agent-platform/routines.md) whose config grants the action: `actions_allowed: ["email_member"]`. Each fired Chat may then send, with every guardrail above intact. |
| Typed recipe | A Workflow (blueprint) `tool` step calling `notifications.email_member` — see the variant below. Workflows are authored in the console. |

There's no standalone `notifications` tool on the MCP surface and the send endpoint isn't on the public API — the run is the door, and the guardrails live server-side either way.

## The loop the run performs

You don't make these calls yourself, but knowing the contract lets you instruct the run precisely and read its trace.

**Move 1 — discover who it can email.** The run lists the workspace's addressable members (email + display name per member) and resolves the names you gave it against THAT list. Anything not on it will be rejected at send time — so a good prompt tells the run to flag a non-member rather than guess.

**Move 2 — send.** One send, to one or more members, with a subject (1-200 chars), a tight body, optional CCs, and an idempotency key. Three outcomes to know about:

- **Success** — a per-recipient split:

  ```json
  { "sent": [ { "email": "teammate@yourworkspace.com" }, { "email": "manager@yourworkspace.com" } ], "failed": [], "skipped_duplicate": false }
  ```

- **A non-member in the list** — the *entire* send fails, nothing goes out:

  ```json
  { "error": { "code": "invalid_argument" }, "non_members": ["prospect@acme.com"] }
  ```

- **Over a cap** — nothing is sent:

  ```json
  { "error": { "code": "rate_limited" } }
  ```

- **A repeat of the same `idempotency_key`** — no second email; the prior outcome rides back with `skipped_duplicate: true`. This is the safety net for retries and re-fired runs.

**Move 3 — verify + check the cap.** The send ledger returns recent sends newest-first plus a cap-aware summary (`sent_last_hour` vs `cap_per_hour` / `cap_per_run`), so the run can confirm each recipient shows `status: "sent"` and report the headroom left — checking the cap before a big batch is cheaper than catching `rate_limited` after it.

---

## Paste this into Claude

Drop this in after any recipe whose output should reach a teammate. It asks Amdahl to run the full loop — discover, send, verify — and refuses to invent addresses.

```
Email a short readout to my team through Amdahl.

Step 1 — recipients: list the workspace members you're allowed to email and
match the people I name below to addresses from THAT list. If someone I name
isn't a member, tell me — do not guess an address, and do not send to anyone
off the list.

Send to: {teammate name + manager name}. CC: {optional}.

Step 2 — send: subject under 200 chars and a tight body (3-5 sentences, the
takeaway + one next step). Use an idempotency key like "{short-slug}-{today}"
so a retry won't double-send.

Body should be: {the takeaway you want sent — e.g. "the 2-line Mercury
win-loss readout above, plus a one-line ask to review before the forecast call"}.

Step 3 — verify: confirm every recipient shows as sent, and report the cap
headroom (sends in the last hour vs the hourly cap). If the send was rejected
for a non-member, tell me who was rejected and stop. If it was rate-limited,
tell me and don't retry.
```

## What you'll see back

- A short list of the members the run resolved your names to (and a flag for anyone who wasn't a member).
- A confirmation that the email was sent, with the per-recipient `sent` / `failed` split.
- The verification read showing every recipient at `status: "sent"`, plus the cap headroom.
- If anything was rejected (`invalid_argument` + `non_members`) or capped (`rate_limited`), a plain statement of what happened and no silent retry.

## Sending unattended — Routines and Workflows

**The "every Monday, no human present" path is a Routine.** A Routine is a cron that fires a Chat — one server-side Master agent turn in a fresh Session — each occurrence, and its config carries an `actions_allowed` list that scopes what the fired run may do. **Mind the default: leaving `actions_allowed` off means ALL cataloged actions are allowed** — so a routine can send email autonomously out of the box. Best practice for a sending routine is to name the grant explicitly — `actions_allowed: ["email_member"]` — which narrows the run to exactly that action; `[]` disables outbound actions entirely, and a run whose effective list lacks the action surfaces the send as a proposal with a structured `action_not_allowed` instead of firing it. Every guardrail above (member-only, capped, idempotent) applies unchanged. Create one from any connected Claude session with the `agents` tool (`create_routine` with a name, a prompt like "compile the weekly pipeline recap and email it to {names}", and a cron).

**Workflows (blueprints) can send too.** Inside an [Amdahl blueprint](../blueprints/authoring-a-blueprint.md) — a typed Workflow recipe, authored in the console — emailing the team is a normal `tool` step calling `notifications.email_member`; there's no special "notification" step kind. It looks like any other tool step:

```json
{
  "id": "notify_team",
  "kind": "tool",
  "tool": "notifications.email_member",
  "args": {
    "recipient_emails": ["$inputs.deal_owner_email", "$inputs.manager_email"],
    "subject": "Win-loss readout: $inputs.account_name",
    "body": "$write_readout.body_markdown",
    "idempotency_key": "winloss-$inputs.account_name-$today"
  },
  "output_alias": "notify_result"
}
```

Add `notifications.email_member` to the blueprint's `policy.tool_allowlist` so the recipe documents that it intends to send mail (per the [authoring guide](../blueprints/authoring-a-blueprint.md), headless runs derive their scopes from the allowlist).

**When does the email actually fire?** On a headless Workflow run (fired from the console, or by a Workflow schedule), the platform walks the recipe server-side and the `notify_team` step sends the moment the runner reaches it. On the interactive path, it sends when the agent walking the recipe reaches that step. Either is fully unattended once scheduled — but for most standing "email the team a digest" jobs, the Routine above is the simpler build: a prompt and a cron instead of a typed step graph.

## Variations

- **Single recipient, no CC:** name one person; the loop is identical.
- **Digest to the whole team:** ask the run to send to every addressable member — and to check the cap headroom first so a big team doesn't trip the hourly cap mid-batch.
- **Just-the-failures audit:** ask "has {person} been getting my sends this week?" — the run reads the ledger filtered to that recipient.
- **Confirm-before-send (human in the loop):** the primitive is autonomous by design (no confirmation gate). If you *want* a gate, instruct Claude to draft the subject + body and show them to you for approval before sending — the gate lives in your prompt, not the API.
- **From code, not chat:** drive the same thing over the public Chat API — `POST /chat` with the send in the `input` (and poll the run to completion). For a standing job, create the Routine over `POST /routines` with `actions_allowed: ["email_member"]` in its config.

## Tips

- **Always have the run use an `idempotency_key`.** It's the difference between a safe retry and a double-send. A stable slug plus the date (`weekly-recap-2026-06-19`) is plenty.
- **Resolve names to addresses via the member list, never from memory.** One non-member address fails the whole send; the list is the allowlist.
- **Check the cap before a big batch, not after a failure.** `sent_last_hour` vs `cap_per_hour` tells you if the batch fits; catching `rate_limited` after the fact means re-planning the send.
- **Keep the body short.** This is an inbox nudge, not the deliverable. Put the takeaway and one next step in the email; leave the full brief in the workspace and link to it.
- **Pair with a recipe that produces something worth sending** — [why we lost this deal](../win-loss-deal-postmortem/why-we-lost-this-deal.md), [weekly recap](../pipeline-pulse/weekly-recap.md), or [deals at risk](../pipeline-pulse/deals-at-risk.md). This recipe is the delivery step; those are the payload.

## See also

- [Routines](../agent-platform/routines.md) — the scheduled Chat that carries the unattended send, and the `actions_allowed` contract in full.
- [How to write an Amdahl blueprint](../blueprints/authoring-a-blueprint.md) — the `tool`-step model the Workflow variant above builds on, and when a Routine is the better fit.
- The rest of the cookbook: [recipe library](../README.md) — paste-ready GTM prompts that produce the readouts worth emailing.
- Product docs: <https://docs.amdahl.ai>.
