# Personalize cold outreach

**What this does**: Writes a non-generic 2-sentence opener for each prospect on a list — grounded in something real and specific to THAT person or company (a recent post, a funding event, a hire, a public quote from their CEO, a product launch). Skips prospects with no real hook rather than padding with "I see you're at {company}" filler.

**When to use it**: "I'm about to send cold outreach to a list of 15 prospects, and 'Hi {first_name}, I noticed you're at {company}' makes me wince. I want each opener to be specific enough that the recipient can tell I actually looked them up."

## Why this matters

The reason cold outreach fails at scale is that personalization is treated as a checkbox — "did I include their first name and company?" — rather than as the actual unlock. The real unlock is **a specific, recent, non-obvious hook** that proves you spent time on them, not on a Mad Libs template. Most cold outreach openers read identical because they're built from the same five fields the SDR's tool exposes. The opener that lands references something that requires actual research: a phrase from a public post, a hire that suggests where they're heading, a regulatory event that creates urgency, something their CEO said on an earnings call. Any of those, executed in two specific sentences, beats a polished generic email every time.

The other rule the recipe enforces: **skip if you can't find a hook**. Padding a list with weak openers is worse than sending fewer emails — it trains the recipient to ignore future ones. Quality is asymmetric in outbound; one great email outperforms ten generic ones.

This is a list-based job where parallel research per prospect is genuinely useful, so it's structured with waves.

## Paste this into Claude

```
For each prospect on the list below, write a 2-sentence cold-outreach opener that I'd actually send. Ground each opener in something specific and real about that prospect or their company — NOT a Mad Libs template.

Wave 1 (per prospect, in parallel):
- Public signal: recent LinkedIn posts, public commentary, podcast appearances, conference talks, quotes in press.
- Company signal: recent funding, hiring (especially in the function I sell into), product launches, leadership changes, regulatory events, public initiatives.
- Adjacent signal in our own corpus: has this company or person come up on a call or in notes from another account? Even a passing mention counts.

Wave 2 (after wave 1, per prospect):
Pick the strongest single hook from the signals above and write the opener:
- 2 sentences max.
- Sentence 1 references the specific hook (with enough detail that the recipient can tell it's not template). Cite the source (e.g., "from their CEO's LinkedIn post on {date}").
- Sentence 2 ties the hook to something we could plausibly help with — soft, not a pitch.
- No "I noticed you're at {company}" filler. No "hope you're well." No "I'll keep it short." No emoji.
- If you can't find a real hook for someone — i.e., the signal is thin or generic — SAY SO and skip them. Don't pad.

List:
{paste prospect list — name, role, company, domain — one per line. 10–20 prospects per run is the sweet spot.}

For each prospect that gets an opener, also draft:
- A 1-sentence subject line tied to the same hook.
- A 1-line "what hook I used and why" (so I can tell at a glance whether the opener is grounded).
```

## What you'll see back

- A 2-sentence opener per prospect (for the ones with real hooks).
- A 1-sentence subject line tied to the same hook.
- A 1-line attribution of what hook was used, so you can sanity-check at a glance.
- A "couldn't find a hook" call-out for anyone where the signal was thin — usually 1–3 in a list of 15.
- Often: 2–3 surprising hooks you wouldn't have spotted yourself (a corpus mention, an obscure podcast quote).

## How to actually use it

1. **Keep the list to 10–20 prospects per run.** Bigger lists get sloppy; the model spreads its attention too thin and the hooks start to feel generic.
2. **Read the "what hook I used" line BEFORE the opener.** If the hook is something soft like "they're in fintech," the opener is going to be generic too — re-prompt with "give me a more specific hook from their public posts or recent hires."
3. **Trust the "skip if no hook" rule.** Sending 12 great emails beats sending 18 mediocre ones; the bottom 6 weren't worth sending.
4. **Send the openers verbatim to the SDR / rep ONLY if you've sanity-checked the hook is real.** Hooks based on hallucinated facts are worse than no email. Spot-check 2–3 hooks per run before sending.

## Variations

- **LinkedIn DM tone**: "Make these LinkedIn DMs, not emails — softer, no subject line, no signature, 1 sentence not 2."
- **One-to-many**: "Write a single email that works for everyone on the list — and then for each prospect, tell me why an individualized opener would beat it."
- **Account-based**: "Group prospects by company and write one email that goes to the buying team, with a per-person tweak on the opening line."
- **Re-engagement**: "These prospects went silent 60+ days ago. Write re-engagement openers grounded in what's happened on their side SINCE the last touch."
- **Event follow-up**: "These prospects attended {event}. Reference something specific from the event in each opener."

## Tips

- **10–20 per run is the sweet spot.** Bigger and the hooks degrade; smaller and you're wasting the setup overhead.
- **"Skip if no hook" is the rule that keeps quality high.** Don't force it. A list of 15 returning 11 great openers and 4 skips is the right output.
- **The corpus hook (a mention from another account's call) is the moat.** Generic outbound tools can't surface that. Watch for it.
- **Sanity-check 2–3 hooks per run before sending.** Hallucinated specifics are worse than no specifics; spot-check the dates and quotes.
- **Pair with [outbound targeting by signal](outbound-targeting-by-signal.md)** to build the list first, and [prospect cold research](../customer-research/prospect-cold-research.md) for a deep brief on the top 5 before you send.
