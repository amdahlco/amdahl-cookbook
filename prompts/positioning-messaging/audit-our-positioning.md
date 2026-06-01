# Audit our positioning

**What this does**: Takes a piece of your own copy — homepage hero, one-pager, deck slide, ad — and compares it line by line against how customers ACTUALLY describe you on calls. Flags the jargon you use that buyers never use, the buyer language you never use, and ends with 3 grounded rewrites tied to specific customer quotes.

**When to use it**: "I'm rewriting the homepage / refreshing the category narrative / about to ship a one-pager, and I have the sinking feeling our copy doesn't match how customers actually talk about us."

## Why this matters

The fastest way to write copy that doesn't land is to write it from inside the team. Internal language drifts from buyer language the same way colleagues' inside jokes drift from public English — slowly, gradually, until one day you're describing your product as "the unified customer intelligence layer" while every customer on every call calls it "the thing that tells me which deals to chase." Same product, two languages.

The audit recipe forces a side-by-side: your copy on one side, the verbatim customer descriptions on the other. The interesting output isn't the matches — it's the **language buyers use that you don't**. That's where the next headline lives. It's also where your competitor will eat you alive if they get there first.

## Paste this into Claude

```
Here's a piece of our positioning copy:

"""
{paste the copy — hero, one-pager, deck slide, paid ad, whatever}
"""

Audit it against how our actual customers describe us on calls.

Wave 1 (run these in parallel):
- Pull the verbatim language customers use to describe (a) what we do, (b) the value they get, (c) the pain we solve. EXCLUDE rep utterances — customer voice only. EXCLUDE quotes where the customer is parroting our own pitch language back to us.
- For each phrase or claim in our copy above, identify whether it matches, partially matches, or has no analog in customer language.

Wave 2 (after wave 1):
Produce a structured audit:
1. Line-by-line match readout (or paragraph by paragraph if the copy is long).
2. "Jargon we use that buyers don't" — the words / phrases in our copy that have ZERO matching utterances in customer language. List each, with 2–3 customer phrases that would actually sit in that slot.
3. "Language buyers use that we don't" — verbatim customer phrases describing us / our value / their pain that DO NOT appear in our copy. Rank by frequency. THIS IS USUALLY THE GOLD.
4. 3 specific rewrites that pull language directly from customer quotes. For each rewrite: the original copy, the rewrite, and the verbatim quote it's grounded in (with speaker role + date).
5. A grounded-ness score, 0–10, for the original copy as-is.

Cite every customer quote with speaker role + rough date. Do not paraphrase.
```

## What you'll see back

- A line-by-line or paragraph-by-paragraph match readout.
- A "jargon list" with replacement phrases in customer voice.
- A "language buyers use that we don't" list, ranked by frequency.
- 3 grounded rewrites — original + new + the quote that grounds it.
- A 0–10 grounded-ness score on the original.

## How to actually use it

1. **Paste the original copy in triple quotes.** Otherwise Claude can treat your draft as instructions and the audit collapses.
2. **Read the "buyer language we don't use" list first.** That's where the next headline is hiding — sometimes literally a verbatim phrase you can lift.
3. **Don't ship the rewrites verbatim** — use them as a forcing function. The audit's job is to show you the language; the writing is still on you (or your copywriter).
4. **Score below a 5/10? Don't tweak — rewrite from the customer quotes up.** A low grounded-ness score means the copy is fundamentally drifting from buyer language; small edits won't fix it.

## Variations

- **Segment-specific**: "Only compare against how mid-market buyers describe us." Different segments use different words; positioning for one segment shouldn't be audited against another.
- **Role-specific**: "Only how technical buyers describe us." Useful for technical landing pages or developer docs.
- **Competitive audit**: paste a competitor's hero copy instead — see how their copy scores against YOUR customers' voice. Tells you whether their positioning could steal mindshare in your segment.
- **Email audit**: paste your most-used outbound email template — same audit, same gold.

## Tips

- **Paste copy in triple quotes** every time. The single most common failure mode is Claude treating the copy as instructions.
- **The grounded-ness score is a useful trend metric.** Re-audit quarterly and watch whether your copy is drifting toward or away from buyer language over time.
- **The most useful rewrite is usually #3** — the one with the quote that genuinely surprised you. Save that quote; it's also a LinkedIn post.
- **Pair with [rep vs. buyer language](rep-vs-buyer-language.md)** — same mechanic, different surface. If reps and copy both drift from buyers in the same direction, you have a top-down language problem, not a writing problem.
- **For the deepest version, run [rebuild your value narrative by segment](rebuild-value-narrative-by-segment.md)** first to refresh the raw customer voice, then audit your copy against it.
