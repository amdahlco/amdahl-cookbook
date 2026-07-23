---
description: Pipeline pulse — surface deals that look healthy on paper but are quietly dying in the call content, sorted by ACV × severity. Also does weekly recap and stalled-deal triage.
argument-hint: [at-risk | weekly-recap | stalled]  (default: at-risk)
---

Run the Amdahl pipeline-pulse play. Use the connected **Amdahl** MCP tools. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

Scope: **$ARGUMENTS** (default: deals at risk.)

**Gather** over `search`: the structured lane (`query` with typed filters + `group_by`) for open pipeline with stage / ACV / last-touch, the semantic lane for the call-content signals on each (sentiment, unanswered objections, attendee drop-off, go-quiet gaps), and `run` for anything easier to ask in plain language. If the triage needs real decomposition across the whole book, escalate to `agents` { action: start_chat }. *Pre-rollout fallback:* on a legacy session, gather over `data` query + cluster_search + `context` query_substrate.

**Produce:**
- **at-risk** (default): deals that look healthy on paper but are at risk in the call content. For each: deal name, stage, last meaningful touch, the specific signal that worries you, what the rep should do this week. Sort by ACV × severity.
- **weekly-recap**: what moved, what slipped, what's new, what went quiet — plus the one question to ask in standup.
- **stalled**: chase / nurture / close-lost on each stalled deal, with the honest verbatim "why it's dying" on each.

Every flag must cite a specific call signal (quote + date), not a hunch. Full recipes — `prompts/pipeline-pulse/deals-at-risk.md`, `weekly-recap.md`, `stalled-pipeline-triage.md`.
