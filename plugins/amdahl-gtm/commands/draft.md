---
description: Draft content grounded in real customer language — a post/email/blog anchored to an anonymized verbatim buyer phrase, in your brand voice. Offers to save it to your Amdahl library.
argument-hint: <topic> [linkedin | email | blog]
---

Run the Amdahl grounded-draft play. Use the connected **Amdahl** MCP tools. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

Topic + channel: **$ARGUMENTS** (default channel: LinkedIn post.)

**Wave 1 — gather in parallel:**
- Customer language → `data` cluster_search + `context` query_substrate: how buyers actually talk about this topic on our calls. Pull at least one verbatim phrase (anonymized) that captures it.
- Voice → `context` summary + `authors`: our brand voice and, if an author voice profile exists, that author's word choice and personality. If none exists, say the draft uses generic voice and note that `/amdahl-gtm:setup` shows whether a voice profile is on file.

**Wave 2 — draft:**
- Write the piece in our voice, anchored on the verbatim buyer phrase (anonymized), ending in a real question — not a CTA cliché.
- LinkedIn: under 150 words, no emoji, no hashtags. Email: subject + 2–3 tight sentences. Blog: outline + opening.
- Show the verbatim phrase you anchored on, separately, so the user can verify it's real.
- Then offer to save it to the Amdahl library as a `content_piece` via `artifacts` create (grounded). That runs the fact-check gate and returns a shareable console link. **Ask before saving** — don't save unprompted.

Full recipe + variations — `prompts/content-and-outbound/draft-linkedin-post-grounded.md`.
