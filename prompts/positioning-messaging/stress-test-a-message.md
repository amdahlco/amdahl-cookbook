# Stress-test a message

**What this does**: Takes a draft — subject line, ad headline, tagline, hero copy, CTA — and stress-tests it phrase by phrase against how your customers actually talk on calls. Flags jargon, overclaim, and generic-sounding lines, then returns 2 sharper rewrites grounded in real customer quotes plus a "ship it / rewrite it / kill it" verdict.

**When to use it**: "I have a draft I'm about to ship — paid ad, email subject, tagline — and I can't tell if it's actually clever or just inside-baseball. I want a sanity check before it goes live."

## Why this matters

The single most common reason copy underperforms is that the writer didn't notice they'd written something only people inside the company would parse. "Modern platform for unified buyer signal" reads as crisp to the marketer who wrote it (they've heard the conversation behind every word) and as nothing to the buyer scrolling past it. The phrase is full of meaning to insiders and full of static to outsiders. There's no way to feel this gap from inside the team — you have to test against external language.

The fix isn't a focus group. It's a fast comparison to the verbatim language your customers already use on calls. If your draft uses words that show up nowhere in your call corpus, that's a signal it's drifting toward jargon. If your draft makes a claim buyers never make about you, that's a signal it's overclaiming. The recipe surfaces both, phrase by phrase, before the copy ships.

## Paste this into Claude

```
Here's a draft message I'm about to ship:

"""
{paste the draft — subject line, ad headline, tagline, hero copy, CTA, whatever}
"""

Channel / context: {paid LinkedIn ad / cold email subject / homepage hero / event banner / etc.}

Stress-test it against how our customers actually talk on calls. For each distinct phrase or claim in the draft:

1. Would a real buyer in our segment say this? (Y / partial / N)
2. Would they understand it without context? (Y / partial / N)
3. Would they care — i.e., does it map to a pain or value moment they've actually voiced? (Y / partial / N)
4. Is it jargon, overclaim, or generic? Flag each:
   - JARGON: the phrase has no analog in customer language (cite the absence — "we have zero call mentions of this phrase or its close cousins").
   - OVERCLAIM: the phrase claims something stronger than what customers actually say about us (cite the actual customer language for contrast).
   - GENERIC: the phrase could be said by any competitor; it's not distinguishable.

Then produce:
- 2 sharper rewrites, each grounded in a verbatim customer quote (cite the quote, speaker role, date).
- A 1-line verdict on the original: SHIP IT / REWRITE IT / KILL IT.
- One sentence on WHY a buyer would or wouldn't stop their scroll on this in the chosen channel.
```

## What you'll see back

- A phrase-by-phrase verdict on the draft, with Y/partial/N on the three filter questions.
- Specific flags: jargon (with the absence cited), overclaim (with the contrast), generic (with the differentiator that's missing).
- 2 rewrites grounded in real customer quotes, with sources.
- A clear 1-line verdict — ship, rewrite, kill — and a 1-sentence scroll-stopping rationale.

## How to actually use it

1. **Paste the draft in triple quotes.** Otherwise Claude may interpret your draft as instructions to itself.
2. **Name the channel.** A line that's perfect for a cold email subject is terrible for a paid LinkedIn ad — context changes the test.
3. **Trust the "would a real buyer say this" question over the others.** It's the cleanest filter. If a buyer wouldn't say it, the copy is leaking jargon — even if it scores well on the other two.
4. **Use the rewrites as a forcing function, not as final copy.** The point isn't to ship the rewrite verbatim; it's to see what direction the customer language is pulling you.

## Variations

- **Paid scroll-stop**: "Treat this as a paid LinkedIn ad — would it stop the scroll for our ICP? Be brutal."
- **Audience slice**: "Stress-test against just our economic buyers, not end users." Useful for exec-targeted ads.
- **A/B helper**: "Also give me a more conservative version and a more aggressive version, then tell me which would test better and why."
- **Long-form audit**: for landing pages or longer copy, paste paragraph by paragraph instead of whole-doc; the audit gets sharper.

## Alternatives

If you want a deeper job done than just stress-testing a draft:

- For full-copy audits (homepage, one-pager), use [audit our positioning](audit-our-positioning.md) — same mechanic, more structured output.
- For finding new copy directions from raw customer voice, use [rebuild your value narrative by segment](rebuild-value-narrative-by-segment.md) — generates the raw material the rewrites here are grounded in.
- For LinkedIn posts specifically, jump to [draft a LinkedIn post (grounded)](../content-and-outbound/draft-linkedin-post-grounded.md).

## Tips

- **"Would a real buyer say this?" is the single best filter.** Keep asking it.
- **A SHIP IT verdict is rare and worth trusting.** If the draft scores high on all three filters and isn't flagged, ship it without further tweaking — overediting copy that's already grounded is how you drift back into jargon.
- **A KILL IT verdict isn't a failure — it's saved cycles.** Better to kill a line in stress-test than to A/B test it for two weeks.
- **For long copy, paragraph by paragraph beats whole-doc.** Whole-doc audits average across strong and weak lines and miss the specific problem phrase.
