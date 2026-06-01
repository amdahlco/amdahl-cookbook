# What they care about

**What they actually care about — in their words**

**What this does**: Surfaces the 3 themes one account keeps coming back to — across every call, email, and CRM note — in their own language, with verbatim quotes attached. Tells you what THEY think the project is about, which is often different from what you've been pitching.

**When to use it**: "We've had 6 calls with Acme over the last quarter, the threads feel scattered, and I have a creeping feeling I'm pitching what *I* think they care about, not what they actually care about."

## Why this matters

Sales reps and AEs unconsciously back-fit account priorities to the deck they're presenting. The customer says "rollout speed matters because we promised the board Q1," you hear "speed is a priority," and a month later you're pitching speed-of-implementation when what they actually need is **a story they can tell the board**. Same word, totally different job-to-be-done.

The fix is to read the priorities the way they're actually said — in the customer's own words, with the verbatim context — and to weight by **frequency and recency**. A phrase repeated by 3 stakeholders across 4 calls in the last 6 weeks is a theme. A phrase mentioned once on a discovery call 8 months ago is noise. This recipe enforces both — and lets you check the seriousness signal separately, because not every repeated phrase is board-level urgent.

## Paste this into Claude

```
For {company name or domain}, look across every call, email, and CRM note we have in the last {6 / 12} months. I want to know what THEY care about — not what we've been pitching.

Surface the top 3 themes/priorities they keep coming back to, ranked by a combination of frequency (how often it comes up) AND recency (how recently). For each theme:

1. State the theme in THEIR words, not ours. (e.g., not "scalability" — "the report has to run before the Monday standup, every week, even on month-end.")
2. Give 2–3 verbatim quotes, each with: speaker name + role + rough date.
3. Score seriousness on a 1–5 scale, where 1 = passing comment, 5 = board-level priority. Justify the score with a specific signal (a deadline, a budget mention, a named exec).
4. One sentence on how THIS theme connects (or doesn't) to what we currently sell them.

Also call out an honorable-mention 4th theme if there's a clear runner-up.

EXCLUDE quotes from our own reps. EXCLUDE anything they're parroting back from our pitch deck (if the language is suspiciously close to our own copy, drop it).

Output as: theme heading → quotes → seriousness score → connection to our offering. No prose summary at the top.
```

## What you'll see back

- 3 (sometimes 4) themes, ranked by combined frequency + recency.
- Each theme stated in customer words, not category words.
- Verbatim quotes with speaker, role, and date attached.
- A 1–5 seriousness score per theme with the signal that justifies it.
- A "does our pitch address this?" connection line per theme — usually surfaces 1 theme you've been quietly ignoring.

## How to actually use it

1. **Compare the themes to your last 3 emails to this account.** If your emails are mostly about theme #2 but the account cares most about theme #1, that's the rewrite.
2. **Use the verbatim phrasing in your next message back to them.** Customers respond faster when their own language is reflected back.
3. **Re-run quarterly.** Themes shift — especially after leadership changes, funding events, or org restructures.
4. **If theme #1 has a 5/5 seriousness score and you've never addressed it directly on a call, that's the next meeting agenda.**

## Variations

- **Narrow to one role**: "Only quotes from their VP of Engineering or above." Useful when the deal is exec-sponsored and end-user noise is drowning out the signal.
- **Time-bounded**: "Only the last 90 days." Useful right after a new exec joins on their side.
- **Coverage check**: append "Then tell me which of these themes our messaging directly addresses, and where we're silent."
- **Multi-account compare**: run it on 3 accounts in the same segment and ask Claude to cluster — the cross-account themes are your ICP message.

## Tips

- **A vague theme is a sign of vague quotes.** If a theme reads as "scalability," ask Claude "what do they specifically mean when they say this — pull 3 more quotes" and the theme will sharpen into something concrete.
- **The seriousness score is more useful than the rank.** A 3rd-ranked 5/5 theme beats a 1st-ranked 2/5.
- **Watch for executive sponsor language.** When the economic buyer's exact phrasing shows up in your output, that's the phrase to use in the renewal deck.
- **Pair with [audit our positioning](../positioning-messaging/audit-our-positioning.md)** — paste your one-pager and see if the themes you just surfaced are even mentioned.
