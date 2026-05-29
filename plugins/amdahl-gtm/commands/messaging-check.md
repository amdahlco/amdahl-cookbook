---
description: Pressure-test a piece of messaging (tagline, email, landing copy, LinkedIn post) against how customers actually talk in your call corpus.
argument-hint: "<message-or-paste-of-copy>"
---

Pressure-test this messaging against the customer corpus: **$ARGUMENTS**

Generic copy reviews are cheap. The value here is checking whether the claim, vocabulary, and emotional register match how *real prospects in our pipeline* actually talk.

1. `data.search` — for each major claim or keyword in the message, search the call corpus for prospect language on the same topic. Note where their words differ from ours (jargon mismatch, claim too strong, wrong pain framing).
2. `context.summary` — pull the current brand voice and ICP profile so we're checking against the right audience.
3. `settings.warm` (only if no brand voice is loaded) — prime the workspace voice once, then re-check.
4. `external_search` — quickly confirm no competitor is already running near-identical language.

Output: (a) claims that resonate with corpus language (keep), (b) claims our customers never actually say (rewrite — suggest the verbatim phrase from the corpus instead), (c) any tone mismatch vs. the workspace voice, (d) a revised version of the message. Cite the call snippets that justify each rewrite.
