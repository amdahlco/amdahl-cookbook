# Use case: call prep + objection handling, end to end

**What this does**: The flagship end-to-end journey — walk into a call already knowing which of *your* customers look like this prospect, what worked and what didn't in those deals, and the exact rebuttal to the objection you'll get. One agentic [Chat](agentic-chat.md), grounded entirely in your own CRM + call corpus, over REST and MCP. Optionally delivered to the rep's inbox or run on a schedule.

**When to use it**: You have a call booked with a prospect who resembles accounts you've already won or lost, and you want the brief that generic web research can't produce — because the useful part is *your* deal history and *your* buyers' words, not the public internet.

## Why this matters

This is the single best showcase of the moat, and it's worth understanding why it's *one Chat*, not a pipeline you assemble. The ask — "prep me for this call, and give me the rebuttal" — is an investigation: the Master agent internally runs theme clustering over similar accounts, pulls the won/lost deals that match, reads the specific objection threads, and composes the brief. You don't orchestrate those steps; you ask the question and poll for the answer. The output is defensible precisely because a note-taker or a raw MCP connector can't produce it: they move data; this reads *what the data means* across every conversation you've had.

Worked example (illustrative names): prepping for **Spotify**, a large and technically sophisticated prospect already building on MCP internally. The journey finds **Airbnb** — a close twin you closed — and surfaces the framing that won it ("Amdahl is the intelligence layer their agents query, not a competing tool"), finds **Uber**'s near-identical MCP-gateway objection and how it was answered, and hands back the exact rebuttal for "why can't we just use our Zoom MCP?" — plus the 349 lost SMB deals that show the failure mode to avoid.

## The journey — one Chat, then deliver

### Step 1 — start the Chat

Put the whole job in one input: who they look like, what worked/didn't, and the rebuttal. The Master decomposes it.

**REST:**

```
POST /chat
Authorization: Bearer <api-key with conversations:write>
Content-Type: application/json

{
  "input": "Prep me for a call with Spotify (a large, technically sophisticated prospect already building on MCP internally). Which of our customers look most like them, and in those deals what worked and what didn't? Then give me the exact rebuttal for when they ask 'why can't we just use our own Zoom MCP / build this ourselves?' Ground every claim in real call quotes from our corpus.",
  "config": { "depth": "standard" }
}
```

**MCP:**

```
agents start_chat
  input  = "Prep me for a call with Spotify (a large, technically sophisticated prospect already building on MCP internally). Which of our customers look most like them, and in those deals what worked and what didn't? Then give me the exact rebuttal for 'why can't we just use our own Zoom MCP?' Ground every claim in real call quotes."
  config = { "depth": "standard" }
```

Both return handles immediately:

```json
{ "chat_id": "c_a1...", "run_id": "r_b2...", "status": "queued", "read_url": "...", "stream_url": "...", "resume_url": "..." }
```

### Step 2 — watch it work (optional but instructive)

Stream `stream_url` (or poll `read_url?include=events`) to see the trace — each step carries a plain-language label. On a prep like this you'll see the agent find themes across your conversations, drill into the closest-matching one, and run a couple of targeted queries. That trace is the same thing the Amdahl console renders as collapsed tool cards; you can surface it or ignore it.

### Step 3 — read the answer

Poll to completion and read `run.answer`. The deliverable is the brief plus follow-ups:

```
GET /chats/c_a1.../runs/r_b2...?wait_ms=30000
```

```json
{
  "run": {
    "status": "complete",
    "answer": {
      "answer_text": "Spotify is a close twin of Airbnb, which we closed. The frame that worked: Amdahl is the intelligence layer their agents query, not a competing tool ...",
      "content_blocks": [
        { "type": "text", "markdown": "**The Zoom/MCP rebuttal:** \"Zoom captures the conversation. We turn it into intelligence ... Those are pipes. We're the brain that decides what flows through them.\"" },
        { "type": "cluster_finding", "cluster_id": "…_62", "label": "Reverse-Engineering Own Customer Data Mid-Call", "member_count": 367, "narrative_hook": "Internet-native teams hijack discovery to interrogate their own data ..." }
      ],
      "follow_ups": [
        "What did Airbnb's winning conversation look like in detail?",
        "How did Uber's MCP-gateway objection get resolved — show the thread?",
        "Which technically sophisticated accounts are open right now and at what stage?"
      ]
    }
  }
}
```

Render `content_blocks` (the rebuttal text + the theme card), not just `answer_text` — see the [answer envelope](answer-envelope.md). The `follow_ups` are the natural next asks; wire them as chips that seed the next turn.

### Step 4 — deliver it (optional)

Two ways to get the brief off the screen:

- **Email the rep** — put the delivery in the ask: end the Chat input with "…and email the takeaway to the deal owner." The run sends through the platform's member-email primitive — members-only, capped, idempotent (see [notifications](../notifications/notify-the-workspace-team.md)).
- **Make it standing** — a rep with recurring calls can wrap this as a [saved agent](saved-agents.md) pinned into a [Routine](routines.md): `create_agent` a "call-prep brief" agent, then a Routine that fires it each morning for every account with a meeting on the calendar. Scope its config with `actions_allowed: ["email_member"]` so the fired runs can send exactly that and nothing else.

## Paste this into Claude

```
Prep me for my call with {company} ({one line on who they are}).

Investigate over our own CRM + call corpus — a full Chat, not a lookup:
1. Which of our customers look most like {company}? Name the closest closed-won
   and closed-lost matches and what actually happened in each.
2. What worked and what didn't in those deals — the specific framing, in quotes.
3. The exact rebuttal for when they say "{the objection you expect, e.g. why
   can't we just use our own Zoom MCP / build this ourselves}".

Ground every claim in real call quotes (anonymized). End with 3 follow-ups.
```

## Variations

- **Deeper dig**: `config.depth: "deep"` for a high-stakes strategic account (Opus + web + the divergence map). Costs more; reserve it for the deals that matter.
- **Objection-only**: drop the prep and ask just for the rebuttal to one objection, grounded in how it was actually answered in past deals — a fast, focused Chat.
- **Whole-team enablement**: run the same prompt with `write_outputs: true` to land a reusable objection-handling doc in the knowledge base, then mirror it to the team.

## Tips

- **One Chat, not a pipeline.** Don't try to orchestrate cluster_search + queries yourself — the Master does that internally. Ask the whole question; poll for the whole answer.
- **The rebuttal is the payload; the theme card is the proof.** Render both — the `text` block carries the words to say, the `cluster_finding` block is the evidence it's grounded in real conversations.
- **`depth: "standard"` is usually enough.** This shape produces a strong brief without `deep`. Escalate depth only for the accounts that justify it.

## See also

- [Agentic Chat](agentic-chat.md) — the door this journey runs on, in full.
- [The answer envelope](answer-envelope.md) — rendering the rebuttal + theme card.
- [Voice of customer, end to end](voice-of-customer-end-to-end.md) — the other flagship journey (teaches the fast→Chat handoff).
- The GTM prompt version: [Sales call prep](../pre-meeting-prep/sales-call-prep.md).
