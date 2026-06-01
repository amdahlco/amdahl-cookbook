# Deep-dive on an account

**What this does**: Builds a single 1-page brief on one company — fusing your full internal history (deals, calls, support, contacts) with everything happening publicly right now (funding, hiring, product, leadership) — and ends with a recommended next step.

**When to use it**: "I'm about to spend real time on Acme — board mention tomorrow, big pitch next week, or a save play this Friday — and a 5-minute Google isn't enough."

## Why this matters

Most account research breaks one of two ways. Either it's all public (LinkedIn, press releases, latest funding round) — generic stuff your competitor's rep also pulled — or it's all internal (deal notes, support tickets) and you walk in blind to what's happened in their world this quarter. The interesting answer is the **fusion**: where your internal story and the public story line up, where they contradict, and what that contradiction tells you. If they raised a Series C last month and your champion has gone quiet, that's not two facts — it's one story.

The brief is also explicitly 1 page. Long briefs don't get read before the call.

## Paste this into Claude

```
Build me a 1-page deep-dive on {company name or domain}. If they have multiple business units or product lines, focus on: {division or BU; otherwise say "the whole company"}.

Wave 1 (run these in parallel):
- Internal history: pull every deal, call, support ticket, email, and CRM note we have. Surface deal stage, ACV, who we've talked to (with roles), the last 3 meaningful things said on calls (verbatim, with speaker + date), open objections, sentiment trajectory.
- Public signal (last 90 days first, last 12 months if thin): funding, hiring patterns, product launches, leadership changes, M&A, regulatory or earnings news, public commentary from their execs.
- Adjacent mentions: any time this company has come up on calls or notes from OTHER accounts — partners, customers, prospects mentioning them.

Wave 2 (after wave 1):
Synthesize into ONE page with this structure:
1. Snapshot — what they do, where they are in the buying journey with us, deal stage / status (3 lines).
2. The 3 things they care about most — grounded in either a verbatim call quote OR a specific public signal (cite which).
3. The 2 risks I should know about — internal (champion drift, unresolved objection, sentiment shift) or external (funding pressure, leadership change, public roadmap shift).
4. Where public and internal stories DIVERGE — anything they've told us that contradicts what they're doing publicly, or vice versa. This is the most valuable section.
5. Recommended next step — one move, this week, with a reason.

Keep the whole thing under 400 words. No filler. Cite sources inline (call date, news headline, etc.).
```

## What you'll see back

- A 1-page brief, not an essay. Five sections, all named.
- Every claim either tied to a verbatim quote (with speaker + date) or a public source (with date).
- A divergence section — usually the most useful 50 words on the page.
- One concrete next-step recommendation, not three options.

## How to actually use it

1. **Use a domain, not a nickname.** "Stripe" is fine; "the payments deal" is not. If the company is huge (e.g. Microsoft), name the division or BU on the second line.
2. **Run it the night before the meeting, not 5 minutes before.** Give yourself time to push back on a thin section ("more verbatim quotes on the security objection?").
3. **Read the divergence section first.** It's where the meeting actually starts.
4. **Save the brief to a doc and paste in any new signal you find.** Make it the living account page, not a one-shot.

## Variations

- **Pure prospect mode** (no internal history): swap "internal history" for "first-principles read on what they do, who they sell to, how they make money" — then keep wave 1 #2 and #3 as-is.
- **Multi-division account**: run it once per BU, then ask Claude to surface where the BU stories contradict each other.
- **Save play**: replace step 5 with "Recommended save play, with the exact ask and the exec sponsor required."
- **Board mention**: ask for a 60-second verbal version on top of the 1-pager — what you'd say if a board member asked "how's Acme?"

## Tips

- **Disambiguate aggressively.** If the company name is generic ("Apex," "Pulse"), add the country, HQ city, or domain — otherwise you'll get a brief about the wrong company.
- **Thin output usually means thin grounding.** Follow up with "pull 5 more verbatim quotes from our calls on the security theme" and the brief sharpens.
- **The divergence section is the moat.** Generic Claude (no Amdahl) cannot write that section.
- **Pair with [whose name comes up](whose-name-comes-up.md)** to find the people and tools the brief missed.
