# Recipe library

26 copy-paste recipes for go-to-market work. Each recipe is a self-contained markdown file with one paste-ready prompt, a "why this matters" explainer, what comes back, variations, and tips. The deeper recipes use a wave structure — explicit parallel sub-tasks the model can fan out on, then a synthesis pass — so a single paste does the work of three rounds of back-and-forth.

New here? Start with the [main README](../README.md) for setup and the six headliner prompts.

---

## Customer research (4)

Walk into any account already smarter than the rep before you — fusing your internal history with what's happening in their world right now.

- [Deep-dive on account](customer-research/deep-dive-on-account.md) — 1-page brief fusing full internal history (deals, calls, support, contacts) with public signal, ending with the divergence between the two.
- [Prospect cold research](customer-research/prospect-cold-research.md) — first read on a company you've never sold to, including the long-tail hooks from your own corpus.
- [What they care about](customer-research/what-they-care-about.md) — the 3 themes one account keeps coming back to, in their words, with seriousness scored.
- [Whose name comes up](customer-research/whose-name-comes-up.md) — shadow champions, blockers, incumbents, and people who aren't in the CRM but are in the calls.

## Competitive intel (4)

The gap between a competitor's marketing site and how buyers actually describe them on your calls — usually the most useful 200 words you'll read this quarter.

- [Competitor deep-dive](competitive-intel/competitor-deep-dive.md) — public posture vs. call reality, with the divergences and the attack angles they imply.
- [Where they show up in our calls](competitive-intel/where-they-show-up-in-our-calls.md) — the volume + trend view: are they showing up earlier, later, more, less, in which segments?
- [How buyers compare us](competitive-intel/how-buyers-compare-us.md) — verbatim head-to-head trade-offs in three buckets, including the tie bucket nobody else looks at.
- [Track a competitor's social presence](competitive-intel/track-competitor-social.md) — their public X / LinkedIn signal (cadence, engagement, follower trend) laid against what buyers actually say on your calls; the divergence is the lever.

## Positioning & messaging (4)

Pressure-test the words you use against the words your customers actually use — and surface the new headlines hiding in their language.

- [Audit our positioning](positioning-messaging/audit-our-positioning.md) — your homepage / one-pager vs. real customer voice, line by line, with grounded rewrites.
- [Rep vs. buyer language](positioning-messaging/rep-vs-buyer-language.md) — where reps and buyers describe the same thing in different words, and which side should win on each topic.
- [Stress-test a message](positioning-messaging/stress-test-a-message.md) — paste a draft, get the parts that won't land and why — with a SHIP / REWRITE / KILL verdict.
- [Rebuild your value narrative by segment](positioning-messaging/rebuild-value-narrative-by-segment.md) — raw customer voice per ICP segment with two anti-contamination filters; the raw material for a positioning pivot.

## Pre-meeting prep (3)

Walk in knowing the room — including the things the CRM forgot.

- [Sales call prep](pre-meeting-prep/sales-call-prep.md) — 1-page brief for tomorrow's discovery, demo, or negotiation, with attendee-specific context.
- [QBR prep](pre-meeting-prep/qbr-prep.md) — recap, risks, expansion angles (grounded in their quotes), and the 3 quotes to reference verbatim in the room.
- [Renewal prep](pre-meeting-prep/renewal-prep.md) — a year-long trajectory view ending in a FLAT / EXPAND / DEFEND posture recommendation.

## Win/loss & deal postmortem (3)

The honest reasons — turning points, unresolved objections, the moments deals actually shifted — not the dropdown reasons.

- [Why we lost this deal](win-loss-deal-postmortem/why-we-lost-this-deal.md) — single-deal postmortem with the turning point named and 3 specific do-overs.
- [Pattern across cohort](win-loss-deal-postmortem/pattern-across-cohort.md) — common threads across many deals, with the single biggest pattern phrased specifically enough to act on.
- [What separates won from lost](win-loss-deal-postmortem/what-separates-won-from-lost.md) — the diff, not two profiles: the 3 sharpest discriminators between deals that closed and ones that didn't.

## Content & outbound (4)

Grounded posts, smarter targeting, openers that aren't Mad Libs.

- [Draft a LinkedIn post (grounded)](content-and-outbound/draft-linkedin-post-grounded.md) — your voice, anchored in an anonymized verbatim buyer phrase, ending in a real question.
- [Find content gaps](content-and-outbound/find-content-gaps.md) — buyer questions your published content doesn't answer, with a ranked content roadmap.
- [Outbound targeting by signal](content-and-outbound/outbound-targeting-by-signal.md) — a target list built from the signals your wins actually shared, with a "stop targeting on" list of filters that don't correlate.
- [Personalize cold outreach](content-and-outbound/personalize-cold-outreach.md) — a non-generic 2-sentence opener per prospect, with skips when the hook isn't real.

## Pipeline pulse (3)

Weekly health, risk surfacing, and zombie cleanup — all on a cadence.

- [Weekly recap](pipeline-pulse/weekly-recap.md) — what moved, what slipped, what's new, what went quiet, plus the one question to ask in standup.
- [Deals at risk](pipeline-pulse/deals-at-risk.md) — deals that look healthy on paper but are at risk in the call content, sorted by ACV × severity.
- [Stalled pipeline triage](pipeline-pulse/stalled-pipeline-triage.md) — chase / nurture / close-lost, with the honest verbatim "why it died" on each loss.

## Pages & dashboards (2)

Turn an answer into a real, designed Page in your console — a workspace data UI over your live tenant data, not a chat transcript — and embed it live anywhere. See the [section README](pages-and-dashboards/README.md) for the three page layouts (dashboard / single / document) and the [create-a-page command](../plugins/amdahl-gtm/commands/create-page.md) for the full contract.

- [Build a markdown report page](pages-and-dashboards/markdown-report-page.md) — publish a written deliverable (competitive brief, account one-pager, positioning memo) as a `document`-layout Page: a centered prose column built from `Markdown` blocks, no SQL required.
- [Embed a live page](pages-and-dashboards/embed-a-page.md) — build a Page, then mint a self-scoped, signed, short-lived embed link to drop it live into another site. Fails closed by design; public/workspace embeds are admin-gated; rotating the per-tenant secret revokes every embed at once.
