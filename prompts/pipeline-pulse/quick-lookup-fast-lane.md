# Quick lookup (fast lane)

**What this does**: Answers a single, concrete question about your data in ONE synchronous call — "how many open deals over $50K?", "which accounts went quiet in the last 14 days?", "what's our win rate this quarter?" — and hands back the rows plus the exact SQL it ran. No waiting, no multi-step investigation.

**When to use it**: You want a number or a short list right now, not a report. If the ask is "just get me the rows / the figure / a fast fact," this is the fast lane. If it's "investigate why X is happening across the whole pipeline," that's a deeper multi-step Chat instead — reach for [deals at risk](deals-at-risk.md) or [weekly recap](weekly-recap.md).

## Why this matters

Not every question deserves a full investigation. "How many deals are in stage 3?" is a lookup, and routing it through a heavy multi-step agent turn is slow and overkill. Amdahl's fast lane is the synchronous `search` tool: it turns your question into a SQL query over your tenant's data, runs it, and returns the rows **and the query it ran** in a single call — so you get the answer immediately and can see exactly how it was computed. It's the right tool for "get me the number"; save the multi-step Chat for "figure out what's going on."

The fast lane reads **your own data only**. It has no public-web mode — for a market or competitor number, ask it as a [Chat](../agent-platform/agentic-chat.md), which fans out to the web and reports the divergence between what the market says and what your customers say.

## Paste this into Claude

```
Fast lookup, not a deep investigation — use the quick synchronous search over our data and return the answer in one pass.

Question: {e.g. "How many open opportunities over $50K ACV have had no meaningful touch in the last 14 days? List deal name, ACV, owner, and last-touch date, newest activity first."}

Return the matching rows AND the SQL you ran so I can see how it was computed. If the result hits the row cap, say so and tell me the filter to narrow it. If any part of my question went unanswered, name that part rather than presenting the rest as complete. Don't launch a multi-step investigation — this is a lookup.
```

## What you'll see back

- The matching rows (capped — the fast lane returns up to a set row limit per call).
- The exact SQL the tool ran, so you can verify the logic or reuse it.
- A one-line note if the result was truncated at the row cap, with the suggested narrowing filter.
- A note naming any part of a multi-part question that produced no answer — the lane reports partial coverage rather than presenting a partial answer as the whole one.

## Need an outside number too?

The fast lane is your data only. For "how many of our deals mention {competitor}, and what's their latest public funding" — one internal half, one public half — ask it as a [Chat](../agent-platform/agentic-chat.md) instead of a lookup. The Chat runs the web fan-out itself and answers both halves in context, which a synchronous lookup cannot do. For a real competitive write-up, use [competitor deep-dive](../competitive-intel/competitor-deep-dive.md).

## How to actually use it

1. **Ask one concrete question.** The fast lane is at its best on a single, answerable question — a count, a filtered list, a rate. Compound "and also…" questions belong in a multi-step Chat.
2. **Read the SQL it returns.** It's the receipt. If the number looks off, the query tells you why (wrong stage filter, wrong date window) faster than re-asking.
3. **Escalate when the answer raises a bigger question.** "Why are 12 deals quiet?" is the moment to hand off to [deals at risk](deals-at-risk.md) or a full investigation — the lookup found the thread; the Chat pulls it.

## Variations

- **Just the number**: end the prompt with "return only the single figure and the SQL — no table." Good for a metric you're dropping into a doc.
- **Reuse the query**: "save that SQL — I'll want to run it again next week." The returned query is copy-pasteable.
- **Widen the row cap**: for a longer list, say "return up to the full row limit." The fast lane caps rows per call; a genuinely large export is a job for a page or a report, not a lookup.
- **A broader question**: say "split this into up to 5 sub-questions." The lane fans a multi-part ask out in parallel, and raising that breadth is what stops it reporting only the part it had room for.

## Tips

- **Name the lane.** Saying "fast lookup, not an investigation" keeps Claude on the synchronous `search` tool instead of opening a multi-step Chat — faster and cheaper for a simple ask.
- **A partial answer is still a real answer — but say which part.** If the lookup covered two of your three questions, the two numbers are sound; presenting them as the whole answer is the failure mode. Ask it to name what it missed.
- **The SQL is the trust.** Every lookup returns the query it ran; skim it before you quote the number in a forecast.
