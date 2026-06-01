# Rebuild your value narrative — by segment, in customer voice

**What this does**: Pulls raw customer voice for one ICP segment at a time — pain in their words, what they want next, the language they already use to describe value, and where the gaps are — with two specific filters that stop the result getting contaminated by your own sales pitch.

**When to use it**: You're pivoting positioning, building a new value narrative, or moving past an old product framing. You don't want a polished narrative — you want the raw quotes that will *feed* the narrative. Run once per ICP segment.

## Why two filters (and why it matters)

Most "voice of customer" queries quietly poison the result two ways:

1. **Your own reps' voices.** Sales and CS reps repeat the pitch back on calls. If you don't exclude them, the query returns *your pitch* back as if it were customer language.
2. **Customers parroting your old product framing.** A buyer who learned about you through an old positioning lens ("our AI thing," "our automation product," whatever you're moving past) will use that framing back at you. That's not their pain — it's your old framing reflected.

This recipe excludes both. What's left is real customer pain in real customer words.

## Paste this into Claude (run once per segment)

```
Using only customer interactions from our call corpus:

- EXCLUDE every utterance from one of our own team members (external customer voices only — anyone with an @{our-company-domain} email, anyone on our sales / CS / founding team, gets dropped).
- EXCLUDE every utterance where the customer is repeating back our OLD product framing — specifically the language around {list the legacy product names or positioning phrases you're moving past, e.g. "AI SDR", "outbound automation", "<your old product name>"}. If a customer is using those words, they learned them from us; that's not their voice.

Filter to this ICP segment ONLY: {paste the segment — e.g. "RevOps leaders at Series B–D vertical SaaS, 50–500 employees". Be specific. "Mid-market" is not a segment.}

Surface, with verbatim quotes attributed to company name + role + deal stage:

1. The pain that brought them to us. (≥5 quotes)
2. What they want the product to do beyond what we already do. (verbatim, every angle)
3. The language THEY use to describe the value they already get from us. (exact words, no paraphrasing)
4. Objections, complaints, or "I wish it did X" gaps. (verbatim)

Output as quotes grouped by question. Do NOT summarize. Do NOT paraphrase. Do NOT add transition prose. The customer voice IS the output.
```

## What you'll see back

- Four blocks of quotes — pain, future-wants, value-they-already-get, gaps — each with 5–15 verbatim utterances.
- Every quote attributed: `"<quote>" — VP Sales, Acme Corp, in eval stage`.
- No editorial wrapper. The output IS the raw material; the synthesis is on you (or a follow-up prompt).
- Different segments produce different language. That's the whole point.

## How to actually use it

1. **List your ICP segments first.** Usually 3–5. e.g., "enterprise SaaS sales orgs, 500+ reps", "Series B–D RevOps", "PLG growth leaders", "vertical SaaS CROs." Be specific.
2. **Run the prompt once per segment.** Same prompt, swap the segment line.
3. **Pre-load the EXCLUDE list with every old framing phrase** you're trying to move past — product names, positioning lines, category names. The more specific you are about what to filter out, the cleaner the output.
4. **Read the quotes raw before doing anything else.** If you immediately ask Claude to "synthesize" it, you collapse the voice back into a narrative — the move that erased the original voice the first time. Read the quotes first, in your own head.

## Variations

- **One segment, deeper**: drop the segmentation and pump quote count to 25+ per question.
- **Pain only, fast**: just ask for question #1. Useful for landing-page hero rewrites.
- **Compare two segments side-by-side**: run it twice, then ask Claude to surface where the two segments use DIFFERENT language for the same pain — that's the divergence worth knowing.
- **Time-bounded**: add a date filter ("only conversations in the last 90 days") if you want the post-pivot voice rather than the pre-pivot voice.

## Tips

- **Don't skip the EXCLUDE list.** It's the difference between getting your own pitch echoed back vs. real customer voice.
- **The first run will surprise you** — usually because the buyer pain is meaningfully different from what your decks say.
- **Save the output to a doc, not just chat history.** This is the raw material for the next 6 months of positioning work.
- **Thin output?** The segment definition might be too narrow for your corpus volume. Broaden the segment first, then narrow once you have signal.
