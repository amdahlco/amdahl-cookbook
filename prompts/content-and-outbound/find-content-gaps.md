# Find content gaps

**What this does**: Surfaces the questions, objections, and topics buyers keep raising on sales calls that your published content doesn't answer well — or at all. Cross-references your call corpus against your blog, docs, landing pages, and sales collateral, then ranks the gaps by how often they come up. Ends with 5 specific content ideas, each with a working title and an angle.

**When to use it**: "I need a content roadmap, and I'd like it grounded in something other than vibes. What are buyers actually asking that we're not answering?"

## Why this matters

Content roadmaps written from inside the marketing team tend to optimize for what marketing thinks the audience should care about. They produce well-meaning posts about "the future of {category}" that no buyer actually searches for, and zero posts answering the question that has come up on every fifth sales call for six months. The fix is to build the roadmap from the demand side — start with what buyers actually ask on calls, and work backward to what content would have answered the question before the call ever happened.

The recipe forces three buckets — covered well, covered poorly, not covered at all — because the right action depends on which bucket the gap falls into. "Not covered" is a green-field content brief. "Covered poorly" is a rewrite job. "Covered but un-findable" is an SEO / distribution problem (often the most common one, and the easiest to fix).

## Paste this into Claude

```
Surface our content gaps grounded in what buyers actually ask on calls.

Wave 1 (run these in parallel):
- Buyer questions, objections, and topics on our sales calls in the last 6 months: cluster by theme. For each theme, count how many distinct deals raised it (frequency by deal, not by utterance). Pull 2–3 verbatim quotes per theme.
- Existing content inventory: our blog posts, landing pages, docs, sales one-pagers, FAQ, customer stories. For each, note the topic / angle / publish date.
- Coverage match: for each buyer theme, check whether our existing content covers it. Classify each match as: COVERED WELL (a published piece directly addresses it), COVERED POORLY (we touch it but the angle or depth misses the actual question), or NOT COVERED (no published piece addresses it).

Wave 2 (after wave 1):
Produce a structured gap report:
1. COVERED WELL — themes where buyers ask and we have strong content. List the theme + the existing piece. (Short section.)
2. COVERED POORLY — themes where we have something but it doesn't answer the actual buyer question. For each: theme, existing piece, what's missing, what the buyers actually want. (This is the rewrite list.)
3. NOT COVERED — themes that come up repeatedly on calls but have zero published content. Ranked by frequency. (This is the content roadmap.)
4. COVERED BUT UN-FINDABLE — themes where we DO have a piece, but the SEO / distribution is so weak buyers wouldn't find it. (This is the easy-win list.)

End with:
- 5 specific content ideas with working titles and a 1-sentence angle each. For each, cite the buyer themes (with frequency) that justify it.
- The 1 content idea most worth shipping first, with the reason.
```

## What you'll see back

- Four buckets: covered well / covered poorly / not covered / covered but un-findable.
- Ranked gap list (in the "not covered" bucket) with frequency counts.
- 5 content ideas with titles and angles, each tied to specific buyer themes.
- A single "ship this first" recommendation with the reason.
- Usually 1–2 "you already wrote about this but nobody can find it" findings — the easy wins.

## How to actually use it

1. **Take the "covered but un-findable" list to whoever owns distribution.** These are the easy wins — content already exists, you just need to surface it via SEO, sales enablement, or a campaign.
2. **Use the "covered poorly" list as the rewrite queue, not the new-content queue.** Rewriting an existing piece to answer the actual question is faster than starting from scratch.
3. **Take the 5 content ideas to the content calendar and ship the #1 first.** Don't try to ship five; ship one well, then re-run the recipe and see if the gap closed.
4. **Pair this with sales enablement.** A gap that's also a frequent objection in calls is a content piece AND a one-pager — ship both.

## Variations

- **Channel-specific**: "Only the topics that would work as LinkedIn posts" — turns the roadmap into a posting calendar.
- **Sales enablement angle**: "What's missing from our one-pagers / battle cards / objection-handling docs, based on the buyer themes?"
- **SDR-specific**: "Which of these gaps would also help our SDRs in cold outreach — i.e., topics they could lead with that buyers are already thinking about?"
- **Segment slice**: "Cut the gaps by segment — what's missing for mid-market vs. enterprise buyers specifically?"
- **Competitive content**: "Of the not-covered themes, which ones do our top competitors have strong content on?" Tells you where to compete on content.

## Tips

- **Frequency matters more than recency.** A question asked 30 times last year beats one asked once last week.
- **If two gaps overlap, consolidate before commissioning three blog posts.** Ask Claude to "merge overlapping themes into single content briefs."
- **The "covered but un-findable" bucket is usually the highest-ROI fix.** You don't need to write anything — you just need to make existing content findable.
- **Pair with [draft a LinkedIn post (grounded)](draft-linkedin-post-grounded.md)** to ship the top idea fast, and [audit our positioning](../positioning-messaging/audit-our-positioning.md) if the gaps are revealing a positioning drift, not a content drift.
