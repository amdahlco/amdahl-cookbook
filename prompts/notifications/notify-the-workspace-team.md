# Notify the workspace team

**What this does**: Sends an email to people on your Amdahl workspace — straight from a Claude session or from your own code — and lets you confirm it landed without double-sending. It's the "tell my team" primitive: discover who you can email, send the email, then verify delivery and check you're under the rate caps. Works the same over MCP (the `notifications` coarse tool) and the REST API (`/notifications/*`).

**When to use it**: "Claude just finished the win-loss postmortem (or the weekly pipeline recap, or a competitor brief) — now email the two-line takeaway to the deal owner and my manager." Anything where the output of a GTM play should land in a teammate's inbox, not just the chat.

## Why this matters

Most cookbook recipes end in the chat: a brief, a draft, a target list. The last mile is getting that result to a human who isn't watching the session. `notifications.email_member` is that last mile — and it's deliberately narrow so an agent can use it autonomously without becoming a spam cannon:

- **Members only.** Every recipient must be a current member of the workspace. Hand it an outside address and the *whole* call fails with `error.code: "invalid_argument"` and a `non_members[]` list telling you exactly which addresses were rejected — nothing is sent. This is the anti-spam guarantee: a leaked key or a confused agent can email your teammates, never your customers.
- **Capped.** A per-business hourly cap (default 100) and a per-blueprint-run cap (default 20) bound the blast radius. Exceed either and the call returns `error.code: "rate_limited"` and sends nothing.
- **Idempotent.** Pass an `idempotency_key` and a repeat of the same call returns `skipped_duplicate: true` with no second email. Safe to retry; safe to re-walk a recipe.
- **Autonomous + per-recipient resilient.** No confirmation gate — the agent can send without pausing — and one bad address doesn't sink the rest: the result splits into `sent[]` and `failed[]` so a partial send is legible.

The loop has three steps, and the first and last are what make it safe to automate: **discover recipients, send, then verify + check caps.** Skipping discovery is how you end up guessing at addresses; skipping verification is how you re-send because you weren't sure the first one went.

## The three operations

| Job | Operation | MCP | REST | Scope |
|---|---|---|---|---|
| Who can I email? | `notifications.list_recipients` | resource `notification_recipient://list` | `GET /notifications/recipients` | `notifications:read` |
| Send the email | `notifications.email_member` | `notifications` tool, action `email_member` | `POST /notifications/email-member` | `notifications:write` |
| Did it land? Am I under the cap? | `notifications.list_sends` | resource `notification_sends://list` | `GET /notifications/sends` | `notifications:read` |

`email_member` is a write (`notifications:write`); the two list calls are reads (`notifications:read`). If your key has only read scope you can discover and verify but not send.

---

## Step 1 — discover who you can email

Never guess at addresses — a non-member rejects the whole send. List the workspace's addressable members first.

**MCP** (read it as a resource):

```
notifications list_recipients
# → resource notification_recipient://list
```

**REST:**

```
GET /notifications/recipients
Authorization: Bearer <api-key with notifications:read>
```

**What comes back** — the members you're allowed to email:

```json
{
  "recipients": [
    { "user_id": "9c1e…", "email": "teammate@yourworkspace.com", "display_name": "Sam Rivera" },
    { "user_id": "4a77…", "email": "manager@yourworkspace.com", "display_name": "Jordan Lee" }
  ]
}
```

Pick the `email` values you want from this list. Anything not in it will be rejected at send time.

## Step 2 — send the email

One call, to one or more members. `subject` is 1-200 chars; `recipient_emails` is a list and each entry must be a member from step 1. `cc_emails` and `idempotency_key` are optional — but pass an `idempotency_key` whenever you might retry or re-walk the recipe.

**MCP** (the `notifications` coarse tool, `email_member` action):

```
notifications email_member
  recipient_emails = ["teammate@yourworkspace.com", "manager@yourworkspace.com"]
  subject          = "Win-loss readout: Mercury (closed-lost)"
  body             = "Quick readout from the Mercury postmortem.\n\nTurning point: security review stalled in week 3; the competitor had a SOC 2 bridge letter we couldn't match in time.\n\nThree do-overs in the full brief — link in the workspace. Want to walk through it before the forecast call?"
  cc_emails        = ["revops@yourworkspace.com"]
  idempotency_key  = "mercury-winloss-2026-06-19"
```

**REST equivalent:**

```
POST /notifications/email-member
Authorization: Bearer <api-key with notifications:write>
Content-Type: application/json

{
  "recipient_emails": ["teammate@yourworkspace.com", "manager@yourworkspace.com"],
  "subject": "Win-loss readout: Mercury (closed-lost)",
  "body": "Quick readout from the Mercury postmortem.\n\nTurning point: security review stalled in week 3; the competitor had a SOC 2 bridge letter we couldn't match in time.\n\nThree do-overs in the full brief — link in the workspace. Want to walk through it before the forecast call?",
  "cc_emails": ["revops@yourworkspace.com"],
  "idempotency_key": "mercury-winloss-2026-06-19"
}
```

**What comes back on success** — a per-recipient split:

```json
{
  "sent": [
    { "email": "teammate@yourworkspace.com" },
    { "email": "manager@yourworkspace.com" }
  ],
  "failed": [],
  "skipped_duplicate": false
}
```

**The three responses you must handle:**

- **A non-member in the list** — the *entire* call fails, nothing is sent:

  ```json
  { "error": { "code": "invalid_argument" }, "non_members": ["prospect@acme.com"] }
  ```

  Drop the flagged addresses (or add the person to the workspace first) and re-send.

- **Over a cap** — nothing is sent:

  ```json
  { "error": { "code": "rate_limited" } }
  ```

  Wait out the hour, or split the recipients across runs. Check the cap *before* you send with step 3's `summary`.

- **A repeat of the same `idempotency_key`** — no second email goes out:

  ```json
  { "sent": [], "failed": [], "skipped_duplicate": true }
  ```

  This is the safety net for retries and re-walked recipes: the prior outcome rides back, no resend.

## Step 3 — verify it landed and check the cap

After sending, confirm delivery and see how much hourly headroom you have left. `list_sends` returns recent sends newest-first, plus a cap-aware `summary`. Filters: `limit`, `recipient_email`, `blueprint_run_id`, `since`.

**MCP:**

```
notifications list_sends limit=5
# → resource notification_sends://list
```

**REST:**

```
GET /notifications/sends?limit=5&recipient_email=teammate@yourworkspace.com
Authorization: Bearer <api-key with notifications:read>
```

**What comes back:**

```json
{
  "sends": [
    {
      "recipient_email": "manager@yourworkspace.com",
      "subject": "Win-loss readout: Mercury (closed-lost)",
      "status": "sent",
      "sent_at": "2026-06-19T15:04:22Z",
      "idempotency_key": "mercury-winloss-2026-06-19"
    },
    {
      "recipient_email": "teammate@yourworkspace.com",
      "subject": "Win-loss readout: Mercury (closed-lost)",
      "status": "sent",
      "sent_at": "2026-06-19T15:04:22Z",
      "idempotency_key": "mercury-winloss-2026-06-19"
    }
  ],
  "summary": {
    "sent_last_hour": 2,
    "cap_per_hour": 100,
    "cap_per_run": 20
  }
}
```

Use `summary.sent_last_hour` vs `summary.cap_per_hour` to decide whether a bigger batch will fit before you fire it — checking the cap here is cheaper than catching a `rate_limited` on the send.

---

## Paste this into Claude

Drop this in after any recipe whose output should reach a teammate. It runs the full loop — discover, send, verify — and refuses to invent addresses.

```
Email a short readout to my team using the Amdahl notifications tools.

Step 1 — recipients: list the workspace members I'm allowed to email
(notifications list_recipients). Match the people I name below to addresses
from THAT list. If someone I name isn't a member, tell me — do not guess
an address, and do not send to anyone off the list.

Send to: {teammate name + manager name}. CC: {optional}.

Step 2 — send: call notifications email_member with a subject under 200
chars and a tight body (3-5 sentences, the takeaway + one next step).
Pass an idempotency_key like "{short-slug}-{today}" so a retry won't
double-send.

Body should be: {the takeaway you want sent — e.g. "the 2-line Mercury
win-loss readout above, plus a one-line ask to review before the forecast call"}.

Step 3 — verify: call notifications list_sends (limit 5) and confirm both
recipients show status "sent". Report the cap headroom (sent_last_hour vs
cap_per_hour). If the send returned invalid_argument with non_members,
tell me who was rejected and stop. If it returned rate_limited, tell me
and don't retry.
```

## What you'll see back

- A short list of the members Claude resolved your names to (and a flag for anyone who wasn't a member).
- A confirmation that the email was sent, with the per-recipient `sent` / `failed` split.
- The verification read showing both rows at `status: "sent"`, plus the cap headroom.
- If anything was rejected (`invalid_argument` + `non_members`) or capped (`rate_limited`), a plain statement of what happened and no silent retry.

## Sending from a blueprint

Inside an [Amdahl blueprint](../blueprints/authoring-a-blueprint.md), emailing the team is a normal `tool` step calling `notifications.email_member` — there's no special "notification" step kind. It looks like any other tool step:

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

Add `notifications.email_member` to the blueprint's `policy.tool_allowlist` so the recipe documents that it intends to send mail. (Per the [authoring guide](../blueprints/authoring-a-blueprint.md), the allowlist is guidance for the reading LLM — the API key's `notifications:write` scope is the real boundary.)

**The honest caveat — when does the email actually fire?** Amdahl has no server-side blueprint runner. A blueprint is a recipe an LLM reads and walks; the `notify_team` step's email goes out at the moment a connected agent (in a Claude session) or your own code *reaches that step while walking the recipe* — the render-and-walk / LLM-in-the-loop path. There is **no** fully unattended, scheduled blueprint email today: nothing on the platform wakes up at 9am, walks the recipe by itself, and sends. If you need "every Monday, no human present," wire `POST /notifications/email-member` into your own scheduler/cron and call the REST endpoint directly — that's the supported unattended path until a platform-side runner ships. (This mirrors the blueprint mental model: the platform authors, validates, versions, and forks recipes; it doesn't run them.)

## Variations

- **Single recipient, no CC:** drop `cc_emails` and pass a one-element `recipient_emails`. The shape is identical.
- **Digest to the whole team:** call `list_recipients`, then pass every returned `email` into one `email_member` call — but check step 3's `summary.sent_last_hour` against `cap_per_hour` first so a big team doesn't trip the hourly cap mid-batch.
- **Just-the-failures audit:** `list_sends` with `recipient_email=<one person>` to see whether a specific teammate has been getting your sends, or `since=<iso>` to scope to today.
- **Confirm-before-send (human in the loop):** the tool is autonomous by design (no confirmation gate). If you *want* a gate, instruct Claude to draft the subject + body and show them to you for approval before it calls `email_member` — the gate lives in your prompt, not the API.
- **From code, not chat:** skip the prompt entirely and call the three REST endpoints in sequence (`GET /notifications/recipients` → `POST /notifications/email-member` → `GET /notifications/sends`). Same contracts, same `idempotency_key` semantics.

## Tips

- **Always pass an `idempotency_key`.** It's the difference between a safe retry and a double-send. A stable slug plus the date (`weekly-recap-2026-06-19`) is plenty.
- **Resolve names to addresses via `list_recipients`, never from memory.** One non-member address fails the whole send; the list is the allowlist.
- **Check the cap with `list_sends` before a big batch, not after a failure.** `summary.sent_last_hour` vs `cap_per_hour` tells you if the batch fits; catching `rate_limited` after the fact means re-planning the send.
- **Keep the body short.** This is an inbox nudge, not the deliverable. Put the takeaway and one next step in the email; leave the full brief in the workspace and link to it.
- **Pair with a recipe that produces something worth sending** — [why we lost this deal](../win-loss-deal-postmortem/why-we-lost-this-deal.md), [weekly recap](../pipeline-pulse/weekly-recap.md), or [deals at risk](../pipeline-pulse/deals-at-risk.md). This recipe is the delivery step; those are the payload.

## See also

- [How to write an Amdahl blueprint](../blueprints/authoring-a-blueprint.md) — the `tool`-step model the blueprint variant above builds on, and why a blueprint is walked, not run.
- The rest of the cookbook: [recipe library](../README.md) — paste-ready GTM prompts that produce the readouts worth emailing.
- Product docs: <https://amdahl.co/mcp>.
