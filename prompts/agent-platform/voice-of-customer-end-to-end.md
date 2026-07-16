# Use case: voice of customer, end to end

**What this does**: Walks one real question — "what are customers actually saying, and which themes are growing?" — across **both doors**, and shows the exact moment you hand off from the [fast lane](fast-lane-search.md) to [agentic Chat](agentic-chat.md). It's the recipe that teaches the `escalate_to_chat` seam in a real narrative, over REST and MCP.

**When to use it**: You're wiring a voice-of-customer view into your own tool or agent and you want the cheapest path that still answers the hard version of the question. Start fast; escalate only when the ask outgrows a lookup.

## Why this matters

Most VoC questions have two halves. The first half is a **count** — "how many calls raised pricing objections in the last 90 days?" — and that's a fast-lane lookup: one synchronous call, rows plus SQL, done. The second half is a **why** — "…and which themes are growing, and what's driving it?" — and no single SQL query answers that; it needs theme clustering, trend, and synthesis. The mistake is forcing the whole thing through one door. The right shape is: **fire the fast lane, and when it tells you the ask outgrew a lookup (`escalate_to_chat: true`), re-fire the same question as a Chat.** The fast lane is built to hand off — it returns `internal.status: "unsupported"` and `escalate_to_chat: true` rather than guessing at bad SQL.

## Step 1 — the countable half (fast lane)

Ask the concrete version first. It's a lookup, so it comes back in one blocking call with the SQL as the receipt.

**REST:**

```
POST /search
Authorization: Bearer <api-key with data:read>
Content-Type: application/json

{ "query": "How many calls in the last 90 days raised a pricing objection? Break it down by month.", "mode": "internal" }
```

**MCP:**

```
search run
  query = "How many calls in the last 90 days raised a pricing objection? Break it down by month."
```

**What comes back** — `internal.status: "ok"`, the rows, and the query:

```json
{
  "success": true,
  "internal": {
    "status": "ok",
    "sql": "SELECT FORMAT_DATE('%Y-%m', occurred_at) AS month, COUNT(DISTINCT interaction_id) ... WHERE sentiment_primary = 'objection' ...",
    "rows": [ { "month": "2026-05", "calls": 41 }, { "month": "2026-06", "calls": 58 } ],
    "row_count": 3
  },
  "escalate_to_chat": false
}
```

You have the number and the SQL. If that's all you needed, you're done — one call.

## Step 2 — the "why / which are growing" half triggers the handoff

Now ask the hard version. The fast lane recognizes this isn't a single-query lookup and hands off instead of forcing it:

**REST:**

```
POST /search
{ "query": "Which customer objection themes are growing over the last two quarters, and what's driving each one?" }
```

**What comes back** — the escalation signal:

```json
{
  "success": true,
  "internal": { "status": "unsupported", "sql": null, "note": "This needs theme clustering and trend synthesis, not a single query." },
  "escalate_to_chat": true,
  "message": "This is a multi-step investigation — ask it as a Chat."
}
```

`escalate_to_chat: true` is your branch. Don't retry the fast lane — switch doors.

## Step 3 — re-fire the same question as a Chat

Hand the identical question to the agentic lane. It decomposes the ask, runs theme clustering + trend itself, and composes a cited answer.

**REST:**

```
POST /chat
Authorization: Bearer <api-key with conversations:write>
{ "input": "Which customer objection themes are growing over the last two quarters, and what's driving each one?", "config": { "depth": "standard" } }
```

**MCP:**

```
agents start_chat
  input  = "Which customer objection themes are growing over the last two quarters, and what's driving each one?"
  config = { "depth": "standard" }
```

You get handles back immediately (`chat_id`, `run_id`, `read_url`, `stream_url`). Poll `read_url?wait_ms=30000` until `status: "complete"` and read `run.answer`. The answer arrives as [content blocks](answer-envelope.md) — expect `cluster_finding` cards (one per growing theme, each with a `member_count` and a `narrative_hook`) plus `follow_ups`.

```
GET /chats/{chat_id}/runs/{run_id}?wait_ms=30000   ->   { "run": { "status": "complete", "answer": { ... } } }
```

## The whole journey, in pseudocode

```
r = POST /search { query }
if r.escalate_to_chat or r.internal.status != "ok":
    start = POST /chat { input: query, config: { depth: "standard" } }
    poll  start.read_url + "?wait_ms=30000"  until complete
    render run.answer     # cluster_finding cards + follow_ups
else:
    render r.internal.rows + r.internal.sql   # the lookup answered it
```

That branch — one `if` on `escalate_to_chat` — is the entire fast-lane-plus-Chat integration.

## Step 4 (optional) — make it a standing digest

Once the Chat version answers well, wrap it in a [Routine](routines.md) so a weekly VoC digest runs itself and emails the team:

```
POST /routines
{
  "name": "Weekly voice-of-customer digest",
  "prompt": "Which customer objection and praise themes are growing this week vs last, and what's driving each? Email the top 3 to the GTM team.",
  "cron": "0 9 * * 1",
  "config": { "depth": "standard", "actions_allowed": ["email_member"] }
}
```

## Paste this into Claude

The MCP-native version — Claude picks the door and escalates for you:

```
Voice-of-customer read on our calls.

First, the quick number: how many calls in the last 90 days raised a pricing
objection, by month? Use the fast synchronous search and show me the SQL.

Then the harder part: which objection themes are growing over the last two
quarters and what's driving each? If that needs a real investigation rather
than a lookup, run it as a full Chat over our call corpus and give me the top
growing themes with a verbatim quote each, plus 3 follow-ups.
```

## Tips

- **Branch on `escalate_to_chat`, not on a guess.** The fast lane tells you when to switch doors. Trust the field.
- **Same question, both doors.** You don't rewrite the ask on escalation — you hand the identical string to `POST /chat`.
- **Themes come back as `cluster_finding` blocks.** A count like "58 calls raised pricing" that comes from a theme is a `cluster_finding`, not a table row — render it as a card and cite it. See the [answer envelope](answer-envelope.md).

## See also

- [Fast lane — `search.run`](fast-lane-search.md) — the door step 1 uses and the `escalate_to_chat` contract.
- [Agentic Chat](agentic-chat.md) — the door step 3 uses.
- [Call prep + objection handling](call-prep-objection-end-to-end.md) — the other flagship end-to-end journey.
- The GTM prompt version: [Where they show up in our calls](../competitive-intel/where-they-show-up-in-our-calls.md).
