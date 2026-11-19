# Improve a sequence: one email at a time, in order

**What this does**: Improves a multi-email sequence with the Message Optimizer, one call per email, in order. Each call carries the improved earlier emails as `context.prior_touches`, so email 2 is written as the next message to someone who read email 1, not as a first touch. This is the developer view (REST + MCP payloads) of what the console's Optimizer does with a sequence.

**When to use it**: You have two or more drafted emails (a cadence from your sequencer, or one your own agent wrote) and you want each email improved so that the set reads as one conversation. If you have no drafts yet, see [Write a sequence from a goal and a plan](write-a-sequence.md).

## Why this matters

One optimize call improves one message. Send email 3 on its own and it reads as a first touch: it introduces the sender again and repeats points that email 1 already made. Send the earlier emails as `prior_touches` and the server writes the message "as a follow-up, not a first touch". The message may refer to those touches.

Amdahl returns text. It sends no email and starts no campaign. Your code or your agent puts the result where it belongs.

## The operation

| | |
|---|---|
| Operation | `messages.optimize` |
| REST | `POST https://app.amdahl.ai/api/platform/v1/messages/optimize` |
| MCP | `optimize_message` |
| Scope | `messages:execute`, and the key's member needs the editor role or above |

Authenticate with a Customer agent key, sent as `Authorization: Bearer $AMDAHL_KEY`. Make one with the CLI: `amdahl keys create --preset agent`.

## Request

For each email, send the draft as `message` and the earlier emails in `context.prior_touches`.

| Field | Type | Notes |
|---|---|---|
| `message` | string | the draft, up to 10,000 characters |
| `channel` | `email` \| `linkedin` | send `email` |
| `context.prior_touches` | array, up to 10 | the earlier touches, oldest first. Leave the field out for email 1 |
| `context.prior_touches[].on` | string, required | a day, written `YYYY-MM-DD` |
| `context.prior_touches[].channel` | `email` \| `linkedin` \| `call` \| `meeting` \| `other` | optional |
| `context.prior_touches[].summary` | string, 1 to 500 characters | what happened. For an earlier email, the email text |

Three rules about `context`:

- **It is strict.** A key the schema does not list, such as a misspelled `prior_touch`, is refused. The server does not drop it and carry on.
- **A summary over 500 characters is refused, not cut.** Cut it yourself.
- **At most 10 touches.** For an email past the eleventh, send the 10 most recent.

There is no `subject` field. A subject is the first line of the text, written `Subject: ...`, then a blank line, then the body. The same format comes back in `message`, so your code splits it off the result. For a reply in the same thread, send no `Subject:` line.

## The loop

```
touches = []
for k, draft in drafts:                      # in order, one call at a time
    body = { message: draft, channel: "email" }
    if touches: body.context = { prior_touches: touches }
    result = POST /messages/optimize body
    stop if result.ok is false
    text = result.message                    # the version to use
    final[k] = text
    touches.append({ on: <day>, channel: "email", summary: text[0:500] })
    touches = touches[-10:]
```

Build each touch from the improved email, never from the draft. Email 3 then follows the version of email 2 you will actually use.

The console sends today's date as `on` for each touch. Do the same unless you know the real send days.

## Worked example

Email 1. No `context`, because nothing came before it.

```bash
curl -sS -X POST "https://app.amdahl.ai/api/platform/v1/messages/optimize" \
  -H "Authorization: Bearer $AMDAHL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "email",
    "message": "Subject: Quick question\n\nHi Dana, we help engineering teams ship faster with rollout tooling. Worth 15 minutes next week?"
  }'
```

The response below is cut to the fields this recipe reads.

```json
{
  "ok": true,
  "outcome": "rewritten",
  "rewrite": "Subject: Rollouts at Northwind\n\nHi Dana, ...",
  "message": "Subject: Rollouts at Northwind\n\nHi Dana, ...",
  "what_changed": "Opened on the rollout problem and cut the claim about shipping faster.",
  "unchanged": false,
  "omitted": [],
  "placeholders": []
}
```

Email 2. The `summary` is email 1 as returned: the `Subject:` line, a blank line, the body, cut to 500 characters.

```bash
curl -sS -X POST "https://app.amdahl.ai/api/platform/v1/messages/optimize" \
  -H "Authorization: Bearer $AMDAHL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "email",
    "message": "Hi Dana, following up on my note. Do you have 15 minutes next week?",
    "context": {
      "prior_touches": [
        {
          "on": "2026-11-18",
          "channel": "email",
          "summary": "Subject: Rollouts at Northwind\n\nHi Dana, ..."
        }
      ]
    }
  }'
```

Email 2 has no `Subject:` line because it is a reply in the same thread. The result is written as the next message to Dana, and it may refer to email 1.

## Read each result before the next call

- **`ok: false`.** No message was produced. Read `reason` and `detail`, stop, and fix that email. Later emails need this one.
- **`outcome`.** `rewritten`: use `message`. `kept`: no rewrite beat your draft, so `message` is your own text, and `unchanged` is `true`. Use it as it is. `needs_input`: Amdahl wrote nothing and `message` is absent. Read `ask`.
- **`omitted`.** Each row is `{what, why}`: something the message could not do with your input. One check applies to a sequence. When your input records earlier contact and the first sentence after the greeting does not refer to it, or the message repeats that contact's points, a row named "Building on what came before" says so. Show the `why` to the sender.
- **`placeholders`.** A non-empty list means a fill-in slot is still in `message`. See [Reasons on each change](optimize-reasons.md#open-slots).
- **`ignored_params`.** Names a parameter that changed nothing. Where the optimizer does not read `prior_touches` yet, the response names them here.
- **`changes`.** The reason for each edit. See [Reasons on each change](optimize-reasons.md).

## Paste this into Claude

The MCP-native version, with the Amdahl connector on:

```
Improve this email sequence with Amdahl, in order. Call optimize_message once per email, with channel "email".

For email 1, send the draft only. For email k, send its draft and context.prior_touches built from my improved emails 1 to k-1. Each touch is { "on": today as YYYY-MM-DD, "channel": "email", "summary": the improved email text, cut to 500 characters }. Keep the most recent 10.

A subject is a first line "Subject: ..." in message. A reply in the same thread has no subject line. Stop if a call returns ok false, and tell me why.

Show me each email as returned, with its what_changed line and any omitted or placeholders rows. Do not send anything.

Email 1: {paste}
Email 2: {paste}
Email 3: {paste}
```

## Variations

- **Say who it is for.** Add `context.facts`: what you know first-hand about the recipient, one fact per entry. A fact is graded as your own claim, never as a customer quote.
- **Hold a length.** Add `context.max_words` (10 to 1,000). It is checked exactly on each rewrite.
- **Write instead of improve.** To build the emails from a goal, see [Write a sequence from a goal and a plan](write-a-sequence.md).

## Tips

- **One call at a time.** Email k needs the improved email k-1, so the calls cannot run in parallel.
- **Put the improved text in the touch.** A touch built from the draft teaches the server a conversation that never happens.
- **Evidence defaults to your workspace.** With `evidence: "workspace"` and no connected source, the result carries `setup_needed` with a message and a link for the user.
- **Show `what_changed` and the `omitted` rows with the message.** They carry Amdahl's reasons.

## See also

- [Write a sequence from a goal and a plan](write-a-sequence.md): the same loop with no drafts.
- [Reasons on each change](optimize-reasons.md): `changes`, `added_claims` and `placeholders`.
- [Send to your sequencer](https://docs.amdahl.ai/cookbooks/send-to-your-sequencer): put the finished emails in your sequencer. Amdahl sends no email and starts no campaign.
- [Grade and report](../../skills/grade-and-report/SKILL.md): grade a finished email against your evidence.
- [Agent platform overview](README.md): the doors, the scopes, the surface.
