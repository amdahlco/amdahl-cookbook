# Outbound targeting by signal

**What this does**: Builds a target list of companies that look like your best closed-won deals — using the public and internal signals YOUR wins actually shared before they bought. Then surfaces 25 companies matching that profile right now, with the specific signal each one is showing and a 1-line "why they made the list."

**When to use it**: "I'm planning an outbound push and I want the list sharper than 'fintech, 50–500 employees, anywhere in North America.' I want the list to look like the companies that actually buy from us."

## Why this matters

Most outbound targeting is built on filters that feel intuitive (industry, size, geography) but don't actually correlate with closing. A B2B SaaS company that filters on "fintech, mid-market, US" often has a closed-won base that's mostly insurance, mostly enterprise, mostly Europe — and they don't notice, because the filters are downstream of reality.

The fix is to **reverse the direction**: start with the closed-won deals, identify the signals they actually shared (in the 6–12 months before they bought), and build the filter from those signals. Signals are usually a mix of public (funding stage, hiring patterns, tech stack moves, leadership changes, public commentary) and internal (a partner mention, a previous champion now at a new company). The latter is the unfair advantage — generic outbound targeting tools can't see "your champion at Mercury just joined a new company."

The recipe also explicitly surfaces what signals **didn't** correlate — the filters you can stop using. Most outbound dollars are spent filtering on attributes that don't separate winners from losers.

## Paste this into Claude

```
Build me an outbound target list grounded in our actual win patterns.

Wave 1 (run these in parallel):
- Closed-won analysis: look at our top 15–25 closed-won deals in the last 12 months (use ACV and reference-status as the filter, not "biggest contracts only"). For each: what public signals were present in the 6–12 months BEFORE they bought? Funding stage, hiring patterns (especially leadership in the function we sell into), tech stack moves, leadership changes, public commentary, partnership announcements, regulatory or market events.
- Internal signal: for each win, were there internal hooks? A previous customer who knew them, a partner who introduced them, a champion who moved from another account?
- Negative signal: what filters did NOT correlate with winning? E.g., if half of our wins were "wrong industry" by ICP, that filter is noise. Identify 1–2 filters that we currently use but the data shows don't correlate.

Wave 2 (after wave 1):
Synthesize:
1. The win-signal profile: 4–6 signals shared across our wins, ranked by how distinctive they are (a signal shared by 12 of 15 wins is sharp; one shared by 6 is moderate).
2. The "stop targeting on" list: 1–2 filters we currently use that aren't correlated with winning.
3. 25 companies matching the profile right now. For each: company name + domain, which signals they show (with sources), and a 1-line "why they made the list."
4. The top 5 of the 25, with deeper notes on each and a recommended first-touch channel (email, LinkedIn, warm intro if we have one).

Cite sources for every public signal. If a signal is internal (a customer mentioned them), say so explicitly. No fabrication — if a company doesn't have a strong signal, don't pad the list to hit 25; return 17 strong matches if that's what the data supports.
```

## What you'll see back

- A win-signal profile — 4–6 signals shared across your wins, ranked by distinctiveness.
- A "stop targeting on" list — usually 1–2 filters you're currently using that aren't correlated with winning. This is often the most valuable output.
- 25 (or fewer) target companies, each with a specific signal and a "why they made the list."
- A top-5 with deeper notes and a recommended first-touch channel per company.

## How to actually use it

1. **Define "best closed-won" by reference status, not contract size.** The biggest-contract wins are sometimes outliers (a deal that took 18 months and 3 exec sponsors); reference-status wins are the ones you can repeat. Use those as your training set.
2. **Take the "stop targeting on" list to your operations team the same day.** If you're spending money targeting on a filter that doesn't correlate, the fastest ROI is to stop spending on it.
3. **Don't fire all 25 into outbound at once.** Pilot the top 5 with personalized outreach; if 2–3 of those engage, the signal profile is calibrated. If 0 engage, the profile needs another iteration.
4. **Re-run quarterly.** Win patterns shift as the product, the market, and the segment shift; the signal profile from 12 months ago may already be stale.

## Variations

- **Smaller / sharper**: "Give me 10 companies instead of 25, with deeper notes on each — full company brief, recent signal, named contacts." Useful for a high-touch outbound motion.
- **Segment lock**: "Restrict to mid-market healthcare." Tightens the profile to a known segment.
- **Channel recommendation**: "For each of the 25, recommend the right first-touch channel (cold email, LinkedIn DM, warm intro request through {champion}, event)."
- **Tier the list**: "Tier the 25 into A (immediate outreach), B (warm watch), C (track but don't reach out yet)."
- **Account-based marketing version**: "Group the 25 by likely buying-team composition (which roles to engage) and recommend a multi-thread approach per company."

## Tips

- **Best closed-won = your reference customers, not your biggest contracts.** Biggest-contract wins are often outliers; reference customers are the repeatable pattern.
- **The "what didn't matter" list is gold.** Most outbound is built on filters that don't actually correlate with wins. Cutting them frees up budget.
- **A signal that shows up in 12 of 15 wins is sharp. One that shows up in 6 of 15 is moderate. Below half is noise.** Use the distinctiveness, not the absolute count.
- **Pair with [personalize cold outreach](personalize-cold-outreach.md)** for what to actually say to each one, and [prospect cold research](../customer-research/prospect-cold-research.md) for the deep brief on the top-5 before you reach out.
