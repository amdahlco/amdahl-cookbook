---
description: Analyze a closed deal (won or lost) — or a cohort — using call transcripts and CRM history. Find the real reason, not the CRM dropdown reason.
argument-hint: "<deal-id-or-account-name-or-cohort-description>"
---

Run a win/loss analysis on: **$ARGUMENTS**

CRM "loss reason" fields are almost always wrong or shallow. Use the Amdahl MCP to get the real story from the corpus.

1. `data.query` — pull the deal record(s), stage history, owner, ACV, sales cycle length, and the stated CRM outcome reason.
2. `data.search` — semantic search every meeting and email tied to this deal/cohort. Look for the moments the deal turned: objections that went unaddressed, competitors that surfaced late, champions who went quiet, pricing pushback.
3. `context.query_substrate` — ask for any patterns we've already persisted about similar deals.
4. For a cohort: `data.cluster_search` to find recurring themes across multiple losses (or wins).

Output: (a) stated CRM reason, (b) actual reason(s) supported by quoted moments with source IDs, (c) the inflection point — when the deal was decided, (d) 1-2 process or messaging changes that would have changed the outcome, (e) which of those generalize to the pipeline.
