# Stress-test a message

**What this does**: Take a draft — an email subject line, a paid ad headline, a tagline — and get back the parts that won't land, grounded in real customer language.

**When to use it**: Before you ship copy. Especially when something feels clever but you can't tell if it's clever or just inside-baseball.

## Paste this into Claude

```
Here's a draft message:

"""
{paste the draft — subject line, ad headline, tagline, CTA, whatever}
"""

Stress-test it against how our customers actually talk on calls. For each phrase or claim, tell me: would a real buyer say this? Would they understand it? Would they care? Flag anything that sounds like internal jargon, anything that overclaims, and anything that's just generic. End with 2 sharper rewrites grounded in real customer quotes.
```

## What you'll see back

- A phrase-by-phrase verdict on the draft.
- Specific callouts: jargon, overclaim, generic, on-the-nose.
- 2 sharper rewrites with the customer quotes that ground them.
- A 1-line "ship it / rewrite it / kill it" verdict.

## Variations

- Channel: `Treat this as a paid LinkedIn ad — would it stop the scroll?`
- Audience: `Stress-test against just our economic buyers, not end users.`
- Add: `Also give me a more conservative version and a more aggressive version.`

## Tips

- Paste in triple-quotes — otherwise Claude may treat your draft as instructions to itself.
- "Would a real buyer say this?" is the single best filter — keep asking it.
- For long copy, run this paragraph by paragraph instead of whole-doc.
