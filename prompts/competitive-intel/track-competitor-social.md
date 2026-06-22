# Track a competitor's social presence

**What this does**: Puts a competitor's *public* social signal — what they post on X / LinkedIn, how often, how it lands, which way their following is trending — next to what your buyers *actually say* about them on your calls, and ends on the gap between the two. Their social feed is the story they want told; your call corpus is the story buyers live. The gap is the lever.

**When to use it**: "I want an always-on read on what {competitor} is broadcasting and whether it's working — campaign launches, hiring posts, founder thought-leadership — without living in their feed. And I want it cross-checked against my own deals, not taken at face value."

## Why this matters

A competitor's social feed is the most polished, least honest view of them that exists — every post is chosen. Tracked alone it just makes you anxious. The value shows up when you lay it against your own ground truth: their feed says "category leader, shipping fast, hiring 40 people," and your call corpus says four buyers in the last quarter described their onboarding as a six-week slog. That gap is a positioning lever, a battle-card line, and a content angle all at once.

This is the public-signal half of competitive intel. The [competitor deep-dive](competitor-deep-dive.md) and [where they show up in our calls](where-they-show-up-in-our-calls.md) are the private-truth half. This recipe is best run *with* them, not instead.

## Set it up first (one time)

Social tracking reads accounts you point it at. Track the competitor before you analyze them:

- **In the console** (recommended for grouping): Connections -> **People** -> track them as an **external subject**, then link their X and LinkedIn handles so both roll up under one identity. External tracking is **on by default** for every workspace and bounded by a per-tenant cap (the cost guard) — the People view shows your usage. Internal (your own / your team's) accounts are never gated or capped.
- **Or just ask Claude** to connect a handle via the `social` tool (`connect_account`), then read it back.

A freshly tracked account reads as **empty until its first sync lands** — give it a sync cycle before expecting numbers. This is the public-signal layer; it does not replace your CRM + call corpus, it complements it.

## Paste this into Claude

```
Give me a competitive social read on {competitor name or domain}, cross-checked against our own data.

1. Their public social signal (last 90 days): pull their tracked X / LinkedIn — follower trend (growing / flat / declining), posting cadence, and their best-performing recent posts. What THEMES are they leaning into right now (product, hiring, founder POV, customer proof, category education)? What are they conspicuously NOT posting about?

2. Our call reality: every mention of this competitor in our call corpus over the same window. What do buyers actually say about the things they're broadcasting? Verbatim quotes, each tagged with speaker role + deal stage + date.

3. The divergence: 3 specific gaps between what they're broadcasting and what buyers report. (e.g., "their feed is all 'enterprise security,' but two security-review losses in our data cite their SOC2 gaps.")

4. So what: for each divergence, one move for us — a battle-card line, a content angle that occupies the gap, or a talk-track for reps when this competitor surfaces.

Cite post dates on the social side and call dates on the corpus side. If the social account hasn't synced yet or the corpus is thin, say so plainly rather than filling the gap.
```

## What you'll see back

- A short read of their public posture *as they're broadcasting it right now* — themes, cadence, follower direction.
- The same themes checked against verbatim buyer quotes from your calls.
- 3 divergences with specifics on both sides (the part you act on).
- One concrete move per divergence — a battle-card line, a content angle, or a rep talk-track.

## How to actually use it

1. **Track them before you run it.** No tracked account = empty social half. Set the external subject up once; the read stays current after that.
2. **Read the divergence section first** — sections 1 and 2 exist to feed section 3.
3. **Turn a divergence into content the same week.** The strongest divergences (their loud claim + your buyers' lived contradiction) are the posts that write themselves — pair with [draft a grounded LinkedIn post](../content-and-outbound/draft-linkedin-post-grounded.md).
4. **Re-run monthly per top competitor.** Social posture shifts fast; the divergences shift with it.

## Variations

- **Prospect, not competitor**: track a target account's execs as external subjects and run section 1 only — what is this buyer's leadership broadcasting right now? Useful pre-outreach. Pair with [personalize cold outreach](../content-and-outbound/personalize-cold-outreach.md).
- **Our own portfolio**: drop the competitor and ask "summarize OUR tracked accounts' social performance this month" for an owned-channel pulse (internal subjects, no cap).
- **Launch watch**: "Only the last 14 days" right after they ship — does the launch show up in buyer conversations yet, or only in their feed?

## Tips

- **The social half is signal, not proof.** A spike in their hiring posts is a hypothesis ("are they moving upmarket?"); your call corpus is where you confirm or kill it.
- **Empty is information.** A competitor who's gone quiet on social, or whose following is sliding, is a real read — don't discard the null result.
- **Keep the cap for who matters.** External tracking is capped on purpose; track your few real competitors + active target accounts, not everyone.
