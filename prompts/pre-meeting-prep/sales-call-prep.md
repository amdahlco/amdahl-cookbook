# Sales call prep

**What this does**: Builds a 1-page prep brief for tomorrow's sales call — who's in the room and what each one cares about, your full history with them, the last 3 things they said that matter, any open objections, the deal stage, and a recommended agenda — plus 3–5 verbatim quotes from previous calls you should keep in mind.

**When to use it**: "I have a {discovery / demo / negotiation / follow-up} with Acme tomorrow at 10 — what do I need to know walking in that I don't already remember from the last call?"

## Why this matters

Sales call prep almost always defaults to one of two failure modes: too thin ("I scanned the CRM, they're in stage 3, we're good") or too thick (a 6-page document the rep didn't actually read). Both fail for the same reason — they don't surface the **specific 3 things that should shape the next 30 minutes**.

The interesting prep isn't a recap; it's a **forward-looking weighting**. What's the open objection that's been quietly sitting on the table for two calls? Who in the room hasn't said anything yet and is therefore the unknown? What did the buyer say verbatim in call #2 that you want to reference in call #3 to show you were listening? That's what flips a call from "checking in" to "advancing."

The recipe enforces 1 page because anything longer doesn't get read in the 5 minutes before the call.

## Paste this into Claude

```
I have a {discovery / demo / pricing / negotiation / follow-up} call with {company name or domain} on {date or "tomorrow"} at {time, optional}. Attendees on their side: {names + roles if known; otherwise say "names will be confirmed"}.

Build me a 1-page prep brief.

Wave 1 (run these in parallel):
- Full internal history: every prior call, email, and CRM note with this account. Surface deal stage, ACV if known, last meaningful touch, who has joined / left the conversation, sentiment trajectory.
- Verbatim signal: the last 3 things buyers said on calls that matter — quotes only, with speaker role + date. Plus any open objections that have been raised and NOT resolved.
- Attendee-specific context: for each named attendee on their side, what they've said on prior calls (verbatim), what they seem to care about, what they've pushed back on. For new attendees with no prior call history, pull any public signal (recent LinkedIn post, public commentary, role context).

Wave 2 (after wave 1):
Produce a 1-page brief with this structure:
1. Snapshot (3 lines) — what stage, what's the goal of THIS call, what's the open question.
2. Attendees + what each one cares about — bullet per person, grounded in a quote or signal.
3. The last 3 things they said that matter — verbatim quotes, with speaker + date.
4. Open objections — what's been raised that hasn't been resolved.
5. Recommended agenda — 4–5 items with rough timing.
6. 5 discovery / advancement questions tailored to what's still unknown going into this call.

Keep the whole thing under 400 words. If the call is in less than an hour, also produce a 100-word "if I only have 5 minutes to read this" version at the top.
```

## What you'll see back

- A 1-page brief with 6 named sections.
- An attendee-by-attendee breakdown with grounded context per person.
- Verbatim quotes (not paraphrases) on the "what they said" section.
- An open-objections list — usually 1–3 items.
- A recommended agenda with timing.
- 5 questions tailored to what's still genuinely unknown.
- A 100-word emergency version at the top if the call is imminent.

## How to actually use it

1. **Name the call type.** Discovery, demo, pricing, and renewal calls need wildly different prep. Don't say "meeting"; say what stage.
2. **List the attendees by name if you know them.** Attendee-specific context is the difference between a generic prep doc and a useful one.
3. **Read sections 3 and 4 first.** The recent quotes and the open objections set the tone for the call — they're what should change your approach versus last time.
4. **Take the recommended questions to the call as your back-pocket list.** Don't read them off; use them when the conversation goes vague.

## Variations

- **20 minutes before the call**: append "Keep it to 200 words total. I have 5 minutes." Saves you the long version when you don't have time.
- **New attendee dropped in**: "Include a mini-profile on {new person's name} — role, public signal, what they're likely to care about based on others in that role at peer companies."
- **Demo prep**: "Recommend which 3 demo flows to prioritize for this specific call, grounded in what THIS account has actually asked about."
- **Negotiation prep**: "Add a section on every commercial conversation we've had — discounts mentioned, pricing pushback, contract terms raised — and a recommended commercial posture."
- **First-call cold prospect** (no internal history): swap wave 1 #1 for "first-principles cold research on the company" using the [prospect cold research](../customer-research/prospect-cold-research.md) approach.

## Tips

- **If the call is in 20 minutes, ask for the 200-word version.** A brief you don't read is worse than no brief — keep it short enough to actually scan.
- **The "open objections" section is the most useful 30 seconds of your prep.** If you walk in having forgotten an objection that surfaced last call, you'll lose trust faster than any other failure mode.
- **Save the brief in the deal note after the call.** Use it as the running account memory; re-run before every meaningful touch.
- **For downstream stages, use [QBR prep](qbr-prep.md) or [renewal prep](renewal-prep.md)** — same mechanic, different end-game.
