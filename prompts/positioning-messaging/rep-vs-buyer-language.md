# Rep vs. buyer language

**What this does**: Surfaces the topics where your reps and your buyers describe the same thing in different words. Pulls the rep language and the buyer language for each topic side by side, flags the biggest translation gaps, and tells you which side's language should win.

**When to use it**: "I suspect there's a translation gap on calls — reps are pitching 'platform capabilities' and buyers are saying 'I just need to get the report out on Friday.' I want to see where they're talking past each other."

## Why this matters

Sales calls are bilingual. Reps speak product, buyers speak job-to-be-done, and the moment those two languages diverge the deal slows down. Sometimes the right move is to coach the rep down the abstraction ladder ("don't say 'workflow orchestration' — say 'the thing that runs the report on Friday'"). Sometimes the right move is the opposite — pull the buyer up the ladder on purpose, because their framing is too narrow for the actual solution. Both are coaching moves, but you can only make either move once you've seen the gap in writing.

The other thing this surfaces: when a rep IS using buyer language well. That's the model. Most enablement programs spend years writing scripts. The faster path is to find the rep who's already in buyer language and propagate their phrasing across the team.

## Paste this into Claude

```
On our sales calls in the last 90 days, pull the language reps use to describe what we do/solve, and the language buyers use to describe the same thing. I want to see where they're talking past each other.

Wave 1 (run these in parallel):
- Topic clustering: identify 5–8 recurring topics across recent calls (e.g., "implementation effort," "reporting," "security," "pricing," "ROI timing"). Cluster around the underlying job-to-be-done, not the surface keyword.
- Rep utterances per topic: for each topic, pull 2–3 verbatim quotes from REPS describing it. Include rep name (or initials) and date.
- Buyer utterances per topic: same — 2–3 verbatim quotes from BUYERS describing it. Include speaker role + date.

Wave 2 (after wave 1):
Produce a side-by-side per topic:
- Topic heading
- Rep language (2–3 verbatim quotes)
- Buyer language (2–3 verbatim quotes)
- Gap classification: "in sync" / "small gap" / "talking past each other"
- Which side should win on this topic, and why (one sentence)

End with:
1. The 3 topics with the BIGGEST translation gap — these are the coaching priorities.
2. The 1–2 reps whose language is consistently closest to buyer language — these are the models to learn from.
3. The 1 topic where the REP language should win (buyer framing is too narrow). One sentence on why.
```

## What you'll see back

- 5–8 topics, side by side, with rep and buyer quotes for each.
- A gap classification per topic — in sync, small gap, or talking past each other.
- The 3 biggest gaps called out as coaching priorities.
- The 1–2 reps whose language is already buyer-aligned (the model).
- One contrarian topic where rep language should actually win, with the reason.

## How to actually use it

1. **Read the "talking past each other" topics first.** Those are the calls slowing down right now. Coaching can fix them this week.
2. **Find the model rep.** Listen to one of their calls. Borrow their phrasing for the next team sales meeting.
3. **For each big gap, write a one-line phrase swap** — "instead of X, say Y" — and post it in the sales channel. Don't write a doc; write a swap.
4. **Re-run quarterly.** Language drifts. The gap that's open today closes, and a new one opens. Cadence beats one-shots.

## Variations

- **One rep**: "Only calls from {rep name}." Useful for 1:1 coaching prep.
- **One product line**: "Only calls discussing {product or feature}." Tightens the topic clusters.
- **New hire mode**: "Compare a specific new rep's language to the most buyer-aligned rep on the team." Fast way to find where ramp gaps exist.
- **Closed-won vs. closed-lost**: "Compare rep language on won deals vs. lost deals." Often surfaces a phrasing pattern that correlates with winning — that's the script.

## Tips

- **Buyer language almost always wins.** The exception is when reps are pulling buyers up the abstraction ladder on purpose (e.g., reframing a feature ask as a strategic outcome). That's the one topic where rep language should win — flag it.
- **A rep whose language is suspiciously close to the buyers' is a coaching asset, not a quirk.** They're listening. Propagate their phrasing.
- **Don't fix every gap.** Pick the top 3 by deal impact, fix those, then run it again next quarter.
- **Pair with [stress-test a message](stress-test-a-message.md)** for new copy — same buyer-language standard.
