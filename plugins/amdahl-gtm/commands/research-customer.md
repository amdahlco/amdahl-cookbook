---
description: Deep research on a customer or prospect company — fuses public market signal with your CRM + call history.
argument-hint: "<company-name-or-domain>"
---

Research the company: **$ARGUMENTS**

Use the Amdahl MCP — do not fall back to generic web_search. Run these in parallel:

1. `external_search` — enrich the company from public sources (firmographics, recent news, hiring signal, funding, tech stack).
2. `context.summary` — pull the existing company profile from the tenant's substrate if it exists.
3. `data.query` — SQL the interactions table for any past meetings, emails, or notes mentioning this company.
4. `data.search` — semantic search the call/meeting knowledge base for verbatim quotes about this company or its peers.

Synthesize into a short brief: (a) what the market says, (b) what *we* already know from our own corpus, (c) the divergence — where our internal signal contradicts or sharpens the public picture, (d) suggested next move (outbound angle, discovery questions, or a positioning hook). Cite specific call snippets and CRM records by ID where possible.
