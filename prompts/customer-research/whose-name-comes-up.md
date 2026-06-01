# Whose name comes up

**What this does**: Surfaces the people, vendors, tools, and competitors that get mentioned around an account — even briefly, even in passing — that AREN'T already on the deal's contact list or flagged as a competitor in the CRM. The hidden context.

**When to use it**: "I suspect there's a quiet decision-maker I've never met, a tool in their stack I've never been told about, or a competitor that's been in the background. The CRM says everything's clean, but the calls don't feel that way."

## Why this matters

The CRM only knows what someone bothered to log. The interesting context — the name dropped in passing in call minute 47, the procurement person the champion alluded to without naming, the legacy tool nobody wants to admit is still in the stack — lives in the **margins of the transcripts**, not in the structured fields. That's where shadow champions, shadow blockers, and shadow incumbents hide. The deals that surprise you (good and bad) almost always lose to or win because of someone or something that was mentioned three times in passing and never made it into a contact record.

This recipe goes after that long tail explicitly. It compares the cast of characters that shows up in the transcripts against the cast that's in the CRM, and flags every delta.

## Paste this into Claude

```
For {company name or domain}, scan every call, email thread, and CRM note we have. I want to find the people, vendors, tools, and competitors that get mentioned but are NOT already in the structured record.

Wave 1 (run these in parallel):
- People: pull every human name mentioned in any call or note from their side that is NOT already on the deal's contact list or in our CRM as a known contact. For each: how often they came up, who on their team brought them up, and the actual context (was it "my VP," "our procurement team," "the previous CTO," etc.).
- Vendors / tools: pull every third-party product, tool, or service mentioned — incumbents, point solutions, in-house builds, infrastructure. Exclude tools that are obviously not in our category (e.g., their Slack, their Notion).
- Competitors / alternatives: pull every other company in our space mentioned — even if not flagged as a competitor in our CRM. Include "we built it in-house" as a competitor.

Wave 2 (after wave 1):
Synthesize one combined ranked list, sorted by frequency. For each entry:
- Name + type (person / vendor / competitor)
- Count of mentions + which calls (with dates)
- Who from their side brought them up
- 1–2 verbatim quotes with the surrounding context
- "Why this matters" — one sentence on whether this is a shadow champion, shadow blocker, incumbent, or just noise

End with a "worth chasing this week" callout — the top 1–2 names I should ask about by name on the next call.
```

## What you'll see back

- A ranked list of names — people, vendors, competitors — that are NOT in the structured CRM.
- Frequency, attribution, verbatim quote, and surrounding context for each.
- A "why this matters" classification per entry: shadow champion, shadow blocker, incumbent, noise.
- Top 1–2 names to chase by name on the next call.

## How to actually use it

1. **Run this BEFORE every multi-stakeholder meeting** on a deal that's been open more than 60 days. The longer a deal runs, the more shadow names accumulate.
2. **Take the "worth chasing" list and add them as questions to your next-call agenda.** Not "who else is involved" — specifically "you mentioned someone named David from procurement on the last call, who is he and where does he sit?"
3. **For every shadow vendor, ask the champion directly on the next call whether you'd be replacing it or coexisting with it.** That answer changes the deal.
4. **Treat shadow competitors as live.** If a competitor name came up three times in passing and isn't on the CRM, your champion is doing more comparison shopping than they've told you.

## Variations

- **People only**: "Just human names — internal champions, skeptics, procurement, legal. Skip tools and competitors."
- **Vendor stack only**: "Just the tools and software they mentioned. Group by category (CRM, data, security, etc.)."
- **Late-stage focus**: "Only mentions from the last 30 days, or after the demo." This is where the late-deal shadow blockers hide.
- **Cross-deal pattern**: "Across our last 10 deals in {segment}, which shadow names came up repeatedly?" Catches the systemic incumbent or systemic blocker.

## Tips

- **Shadow champions and shadow blockers are the biggest deal-shapers nobody flags.** Take the top 2 seriously.
- **A name mentioned 3+ times that's not on the CRM is a follow-up.** Don't speculate; just ask.
- **Watch for "the previous" + role.** "The previous head of data" usually means there's an org change you didn't know about — and a new buyer to meet.
- **Pair with [deep-dive on account](deep-dive-on-account.md)** — this recipe fills in the cast that the deep-dive's structured sections miss.
