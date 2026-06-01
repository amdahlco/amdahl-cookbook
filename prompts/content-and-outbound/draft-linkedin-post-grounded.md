# Draft a LinkedIn post (grounded)

**What this does**: Drafts a LinkedIn post in your brand voice with at least one anonymized verbatim customer phrase pulled from your own call corpus — so the post is genuinely yours, not interchangeable with every other LinkedIn post on the topic. Under 150 words, no emoji, no hashtags, ends with a question that invites a comment (not a "DM me" close).

**When to use it**: "I owe LinkedIn a post on {topic} and I don't want it to sound like everyone else's LinkedIn post on the same topic."

## Why this matters

LinkedIn posts are crowded because they're cheap to write. The marginal cost of a competent-sounding post on "the future of B2B sales" is near zero — every CEO, AE, and founder is shipping one. The thing that makes a post stop the scroll isn't structure or voice; it's a **specific concrete detail that nobody else has access to**. A verbatim customer phrase — anonymized, but real — is exactly that detail. It signals "this person isn't reciting an article, they've actually talked to buyers" within the first 50 words, which is the only signal that matters in the scroll.

The recipe enforces three things: (1) the anonymized customer phrase, (2) brand voice (if you've configured one), and (3) a question close that genuinely invites a response, not a CTA disguised as a question. Most LinkedIn posts fail the third — they end with "DM me to learn more" and lose the engagement that would have come if they'd asked a real question.

This is a single-job recipe — drafting one post — so waves don't add value. The Alternatives section below covers adjacent jobs.

## Paste this into Claude

```
Draft a LinkedIn post about {topic — e.g. "why mid-market sales teams underestimate procurement cycles," "the thing nobody mentions about implementation," "what buyers actually say about category X"}.

Constraints:
- Under 150 words.
- Ground it in real customer language from our calls. Pull at least one verbatim phrase that captures what buyers actually say about this topic. Anonymize it — no company names, no person names, no identifying details. ("A VP at a mid-market SaaS company told us…" is fine; "Sarah at Acme told us…" is not.)
- Match our brand voice. If you have a configured tone of voice for our workspace, use it. Otherwise, default to: direct, specific, no hype, no jargon.
- No emoji. No hashtags. No "this 1 trick" / "controversial take" style hooks.
- Open with a specific observation, not a generalization. ("Most LinkedIn posts about X start with…" is a generalization; "On the last 12 sales calls I sat in on, every buyer mentioned…" is specific.)
- End with a real question that invites a comment — NOT "DM me," NOT "What do you think?" (too vague). The question should reference the specific observation in the post.

Return the post. Below the post, list the anonymized quote(s) you used and the role of the original speaker (without identifying details).
```

## What you'll see back

- A LinkedIn post under 150 words.
- One (or more) anonymized verbatim buyer phrase woven in.
- A close that's a real question, not a CTA.
- An attribution line at the bottom showing the anonymized source quote(s) used.

## How to actually use it

1. **Pick a topic you've actually had on a call recently.** Topics with no internal call signal will produce thin output — the recipe leans heavily on having something to anchor in.
2. **Read the post out loud once before posting.** Brand voice is a written quality, but it's also rhythm — say it out loud and you'll catch the awkward phrasings.
3. **Don't auto-post the first draft.** Use the recipe as a draft, edit for your own voice, then ship. The customer phrase and the question close are the load-bearing pieces; the rest is yours to rewrite.
4. **Save the anonymized quotes from each post into a "buyer phrase bank" doc.** The phrases that work in one post often work in others — and you'll stop relying on the same one.

## Alternatives

If you want a deeper job than a single post:

- **Content roadmap from buyer voice**: [find content gaps](find-content-gaps.md) — surfaces the topics buyers keep asking about that your content doesn't cover.
- **Founder voice specifically**: replace the brand-voice line with "Write it in {founder name}'s voice based on their past LinkedIn posts." Pulls from their public posting history.
- **Blog-length, not post-length**: "Write a 400-word version for our blog instead, with the same anonymized buyer phrase as the anchor."
- **Contrarian framing**: "Take a contrarian angle on the topic — what's the conventional wisdom, and what does our call corpus suggest is actually true?" Useful when you want to stake a position, not just observe.
- **Series**: "Draft 5 posts on this topic, each anchored in a DIFFERENT anonymized customer phrase from our calls." Useful for a weekly cadence.

## Tips

- **The anonymized quote is the unlock.** It's the thing that makes the post land; the anonymization is what makes it legal. Don't skip either.
- **If the first draft sounds generic, ask Claude to "make it more specific — what's the one detail nobody else writing on this topic would have?"** The customer phrase usually IS that detail; ask for a sharper one if the first pick is too tame.
- **Question closes beat CTA closes by a wide margin on LinkedIn.** A real question gets responses; "DM me" gets ignored.
- **Pair with [find content gaps](find-content-gaps.md)** for what to post about next, and [stress-test a message](../positioning-messaging/stress-test-a-message.md) if you want to pressure-test the hook before shipping.
