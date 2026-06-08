---
description: Audit your messaging against how customers actually talk — paste copy (or name your homepage), get line-by-line matches, divergences, jargon, and grounded rewrites.
argument-hint: [paste copy to audit, or a URL, or a draft message]
---

Run the Amdahl positioning audit. Use the connected **Amdahl** MCP tools. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

The copy to pressure-test is: **$ARGUMENTS**
(If that's empty, ask the user to paste their homepage hero / one-pager / draft message, or fetch the URL they name.)

**Wave 1 — gather in parallel:**
- Customer voice → `data` cluster_search + `context` query_substrate: how our actual customers describe us, this category, and the problem — on calls, verbatim, with roles. Pull the recurring phrases.
- Our voice on file → `context` summary + `authors` / `settings`: our stated positioning and brand voice.

**Wave 2 — audit, line by line:**
1. Where the copy **matches** customer language (quote both sides).
2. Where it **diverges** — claims customers never echo, or benefits they care about that the copy omits.
3. **Internal jargon** the copy uses that buyers never say.
4. **3 specific rewrites** — each pulling language directly from a verbatim customer quote.
5. If this is a single message (not a page): a **SHIP / REWRITE / KILL** verdict with the reason.

Ground every rewrite in a real customer phrase (anonymized). Full recipes — `prompts/positioning-messaging/audit-our-positioning.md`, `stress-test-a-message.md`, `rep-vs-buyer-language.md`.
