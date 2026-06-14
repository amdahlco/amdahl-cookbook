---
description: Draft content grounded in real customer language — a post/email/blog anchored to an anonymized verbatim buyer phrase, in your brand voice.
argument-hint: <topic> [linkedin | email | blog]
---

Run the Amdahl grounded-draft play. Use the connected **Amdahl** MCP tools. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

Topic + channel: **$ARGUMENTS** (default channel: LinkedIn post.)

**Wave 1 — gather in parallel:**
- Customer language → `data` cluster_search + `context` query_substrate: how buyers actually talk about this topic on our calls. Pull at least one verbatim phrase (anonymized) that captures it.
- Voice → `context` summary: our brand voice and word choice. If the profile is thin, say the draft uses generic voice and note that `/amdahl-gtm:setup` shows what's on file.

**Wave 2 — draft:**
- Write the piece in our voice, anchored on the verbatim buyer phrase (anonymized), ending in a real question — not a CTA cliché.
- LinkedIn: under 150 words, no emoji, no hashtags. Email: subject + 2–3 tight sentences. Blog: outline + opening.
- Show the verbatim phrase you anchored on, separately, so the user can verify it's real.
- Stop there — the draft lives in this conversation. To keep it, the user saves it from the Amdahl app; suggest that if they ask where it goes.

Full recipe + variations — `prompts/content-and-outbound/draft-linkedin-post-grounded.md`.
