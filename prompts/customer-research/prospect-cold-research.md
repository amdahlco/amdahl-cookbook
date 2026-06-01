# Prospect cold research

**What this does**: First read on a company you've never sold to — what they do, how they make money, who their buyers are, what's happening publicly, and where any of YOUR existing customers have mentioned them in passing on calls. Builds a brief sharp enough that you walk into the first call already smarter than the last rep in their inbox.

**When to use it**: "A new logo just hit my queue — I have 10 minutes before the call and I don't want to open with 'so, tell me a bit about what you do.'"

## Why this matters

Cold research has a default failure mode: it becomes a recap of their About page. Three rounds of funding, a product list, a CEO name — facts the prospect already knows, can tell from your tone you just looked up, and zero of which actually help you ask a sharper second question. The thing that flips a cold call into a warm one is **a specific, recent, non-obvious signal** that ties to your offering. This recipe goes for that signal in three places at once: their public posture, their leadership's stated priorities, and the long tail of mentions from your own corpus where they've come up adjacent to deals you've already worked. That last one is the unfair advantage.

## Paste this into Claude

```
We have no internal sales history with {company name or domain}. Build me a 1-page cold-research brief.

Wave 1 (run these in parallel):
- What they do + how they make money: business model, target customers, pricing/packaging if public, recent product moves, scale (employees, revenue if known).
- Public signal in the last 90 days: funding, hiring patterns (especially leadership and the function I sell into), product launches, public commentary by their CEO / CRO / CMO / CTO, partnership announcements, regulatory or earnings news.
- Adjacent mentions in OUR corpus: any time this company has come up on a call or in a note from a different account — a customer who mentioned them as a peer, a prospect who namechecked them, a partner who mentioned an integration. Even passing mentions count.

Wave 2 (after wave 1):
Synthesize a 1-page brief with this structure:
1. What they do, who they sell to, how they make money (3 sentences).
2. The 3 things they're publicly prioritizing right now — each tied to a specific source (a hire, a quote, a launch).
3. Why they might care about what we sell — one paragraph, grounded in #2.
4. Hooks from our own corpus — anyone we know who has mentioned them, what was said, and why it matters.
5. A first-call opening line that uses the strongest hook from #2 or #4.

Keep it under 400 words. Cite every public claim with a source. No "may have" / "could possibly" — if you don't have the signal, say so.
```

## What you'll see back

- A 1-page brief organized around the 5 sections above.
- A specific opening line you can actually use — not "I'd love to learn more about you."
- An "adjacent mentions" section that's often the differentiator — even a one-line mention from a customer's call is gold.
- Public claims cited with a source and date. Nothing fabricated.

## How to actually use it

1. **Use a domain.** Many companies share names. `apex.com` resolves to one entity; "Apex" resolves to four.
2. **Add HQ city or country if the name is generic** — "Pulse, Berlin" beats "Pulse."
3. **Skim sections 4 and 5 first.** The opening line is what you'll actually use; the corpus hooks are what you'll actually say.
4. **If they're stealth or pre-launch**, follow up with "infer priorities from the team's backgrounds and the job descriptions they've posted."

## Variations

- **SDR mode**: replace section 5 with "3 cold-email opening lines, each tied to a different hook from #2 or #4."
- **Investor / partnerships mode**: end with "key strategic risks and a SWOT" instead of an opening line.
- **Technical buyer**: add "tech stack inferred from job postings and engineering blog content" to wave 1.
- **Account team handoff**: end with "5 discovery questions tailored to what's still genuinely unknown" — useful when you're handing the account off after first contact.

## Tips

- **Public-only briefs go stale in days.** Pair this with [deep-dive on account](deep-dive-on-account.md) once you've had a call or two.
- **"Skip if no signal" is the rule.** If wave 1 #2 is thin (a quiet, private, no-press company), say so and ask Claude to "infer priorities from the team's public bios and recent hires."
- **The corpus hook is the moat.** Generic web research can't tell you "your customer at Mercury mentioned them as a competitor last quarter." That's the line that gets a meeting.
- **Don't paste the brief into the cold email verbatim** — pick one specific signal and write the email yourself. The brief is the input; the email is on you.
