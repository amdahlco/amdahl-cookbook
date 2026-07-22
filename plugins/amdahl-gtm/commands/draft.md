---
description: Draft content grounded in real customer language — a post/email/blog anchored to an anonymized verbatim buyer phrase, in your brand voice.
argument-hint: <topic> [linkedin | email | blog]
---

Run the Amdahl grounded-draft play. Use the connected **Amdahl** MCP tools. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

Topic + channel: **$ARGUMENTS** (default channel: LinkedIn post.)

**Wave 1 — gather:**
- Customer language → `search` { action: query, semantic } (and `lookalike` { action: themes } for the theme this topic lands on): how buyers actually talk about this topic on our calls. Pull at least one verbatim phrase (anonymized) that captures it.
- Voice → the brand voice profile lives server-side. For a quick draft, write from the customer language you gathered and say so. For an on-voice draft, run it as `agents` { action: start_chat } — the Master drafts with the workspace's voice profile applied.

*Pre-rollout fallback:* on a legacy session (`data` / `context` tools), gather with `data` cluster_search + `context` query_substrate and read the voice from `context` summary.

**Wave 2 — draft:**
- Write the piece anchored on the verbatim buyer phrase (anonymized), ending in a real question — not a CTA cliché.
- LinkedIn: under 150 words, no emoji, no hashtags. Email: subject + 2–3 tight sentences. Blog: outline + opening.
- Show the verbatim phrase you anchored on, separately, so the user can verify it's real.
- Stop there — the draft lives in this conversation. To keep it, re-run it as a Chat with `write_outputs` on (it lands a knowledge-base version the user promotes in the console); suggest that if they ask where it goes.

Full recipe + variations — `prompts/content-and-outbound/draft-linkedin-post-grounded.md`.
