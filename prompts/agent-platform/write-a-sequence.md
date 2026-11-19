# Write a sequence from a goal and a plan

**What this does**: Writes a multi-email sequence with no drafts. You give the goal and a plan (what each email is for). Your code calls the Message Optimizer once per email, in order. Each call carries the goal and that email's job as `context.rules`, and the emails already written as `context.prior_touches`.

**When to use it**: You know what the sequence is for and how many emails it needs, but you have no copy yet. If you already have the emails, see [Improve a sequence](improve-a-sequence.md).

## Why this matters

The optimizer writes from `context`. A draft is optional: with no `message`, it writes from the facts and rules you send. Rules say what a message must do, so a rule that names the goal and the email's job tells the writer why this email exists. `prior_touches` tell it what the reader has already seen.

Amdahl returns text. It sends no email and starts no campaign.

## The operation

| | |
|---|---|
| Operation | `messages.optimize` |
| REST | `POST https://app.amdahl.ai/api/platform/v1/messages/optimize` |
| MCP | `optimize_message` |
| Scope | `messages:execute`, and the key's member needs the editor role or above |

## What a call with no draft needs

- **Something to write from.** The server accepts a call with no `message` when `context` holds at least one of `facts`, `rules`, `voice_examples` or `prior_touches` (or you send `recipient`). A call with only `max_words`, `keep_cta`, `banned_phrases` or `banned_punctuation` is refused: those say what a message may not do, not what to write.
- **A channel.** Send `"channel": "email"`. With no draft, nothing else says it, and the channel sets the length and format.
- **Facts about the recipient and the offer.** Put what is true about the recipient or the offer in `context.facts`. Put what the message must or must not do in `context.rules`. Up to 10 facts, each up to 1,000 characters.

## Request

| Field | Notes |
|---|---|
| `channel` | `email` |
| `context.rules` | up to 20, each up to 500 characters once trimmed. A rule is a string, or `{ "text": "...", "strict": false }` for a style preference. Rules steer the rewrite. They are not quoted in the message |
| `context.facts` | what you know first-hand, one fact per entry |
| `context.prior_touches` | the emails already written, as in [Improve a sequence](improve-a-sequence.md#request) |
| `message` | leave out |

`context` is strict: a key the schema does not list is refused.

## The plan as rules

Send two rules for each email. One states the goal. One states which email this is and its job. This is the wording the console uses for its sequence plan:

```
This sequence: <goal>
This is email 2 of 4: Follow-up. Its job: a new reason to reply, not a bump.
```

The console names its steps and gives each a job. Use your own, or start from these:

| Step name | Its job |
|---|---|
| Opener | Why now, and one easy question |
| Follow-up | A new reason to reply, not a bump |
| Proof | One result from a team like theirs |
| Another angle | A different reason to talk, in one line |
| Last try | Close politely and leave a way back in |
| Thanks | Thank them and pick up where you left off |
| What changed | Say what is new since you last spoke |

For four emails, the console's plan is Opener, Follow-up, Proof, Last try. When the goal names an event, the plan starts with Thanks. When it names a lost or quiet deal, the plan starts with What changed. Keep each rule under 500 characters.

## The loop

```
touches = []
for i, step in plan:                         # in order, one call at a time
    body = {
      channel: "email",
      context: {
        rules: [ "This sequence: " + goal,
                 "This is email " + (i+1) + " of " + n + ": " + step.name + ". Its job: " + step.job + "." ],
        facts: facts
      }
    }
    if touches: body.context.prior_touches = touches
    result = POST /messages/optimize body
    stop if result.ok is false
    final[i] = result.message
    touches.append({ on: <day>, channel: "email", summary: result.message[0:500] })
    touches = touches[-10:]
```

## Worked example

Email 2 of 4. Email 1 is already written, so it goes in as a touch.

```bash
curl -sS -X POST "https://app.amdahl.ai/api/platform/v1/messages/optimize" \
  -H "Authorization: Bearer $AMDAHL_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "email",
    "context": {
      "rules": [
        "This sequence: Book a first meeting with prospects who have never heard from us.",
        "This is email 2 of 4: Follow-up. Its job: a new reason to reply, not a bump."
      ],
      "facts": [
        "Dana Reyes is VP Engineering at Northwind.",
        "Northwind posted two platform engineering roles this month."
      ],
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

The response below is cut to the fields this recipe reads.

```json
{
  "ok": true,
  "outcome": "rewritten",
  "rewrite": "Hi Dana, ...",
  "message": "Hi Dana, ...",
  "what_changed": "Wrote this message from the context.",
  "unchanged": false,
  "omitted": [],
  "placeholders": []
}
```

With no draft, `message` is the message Amdahl wrote, and `rewrite` holds the same text. Use `message`.

## Read each result

The same checks apply as for [Improve a sequence](improve-a-sequence.md#read-each-result-before-the-next-call): stop on `ok: false`, read `outcome`, show the `omitted` rows, and check `placeholders` before you use the text. A subject, when the result has one, is a first line `Subject: ...`. Your code splits it off.

## Paste this into Claude

```
Write a {n}-email sequence with Amdahl. Goal: {goal}.
Plan: {email 1 name and job}, {email 2 name and job}, and so on.
Facts about the recipient and the offer: {facts}.

Call optimize_message once per email, in order, with channel "email" and no message. For email k, send context.rules with "This sequence: <goal>" and "This is email k of n: <name>. Its job: <job>.", context.facts, and context.prior_touches built from the emails already written. Each touch is { "on": today as YYYY-MM-DD, "channel": "email", "summary": the email text, cut to 500 characters }.

Stop if a call returns ok false, and tell me why. Show me each email with its what_changed line and any omitted or placeholders rows. Do not send anything.
```

## Tips

- **Put the goal in every call.** Each call is separate. Email 3 knows the goal only if its own rules say it.
- **Facts are not rules.** A request sent whole as a fact can outweigh the length, tone and exclusions it carries. Split it: the ask and the limits go in `rules`, what is true goes in `facts`.
- **Never put a customer quote in a fact.** A fact is graded as your own claim.
- **Keep the voice.** Add `context.voice_examples` (up to 5 of your own messages) to match the sender's voice. Amdahl matches it and does not copy the words.

## See also

- [Improve a sequence](improve-a-sequence.md): the same loop with drafts.
- [Reasons on each change](optimize-reasons.md): `changes`, `added_claims` and `placeholders`.
- [Ground and draft](../../skills/ground-and-draft/SKILL.md): ground an email in your customers' words, then let Amdahl write it.
- [Agent platform overview](README.md): the doors, the scopes, the surface.
