---
description: Draft content grounded in real customer language — a post/email/blog anchored to an anonymized verbatim buyer phrase, in your brand voice.
argument-hint: <topic> [linkedin | email | blog]
---

Run the Amdahl grounded-draft play. Use the connected **Amdahl** MCP tools. If the server isn't connected, tell the user to run `/amdahl-gtm:setup`.

Topic + channel: **$ARGUMENTS** (default channel: LinkedIn post.)

**Wave 1 — gather:**
- Customer language → `search_customers` { mode: "semantic" }: how buyers actually talk about this topic on our calls. Pull at least one verbatim phrase (anonymized) that captures it.
- Voice and offer → `get_story`: the workspace's approved story (value lines, offers, differentiation, audience and proof).

**Wave 2 — draft:**
- An outbound email or LinkedIn message to a person → Amdahl writes it. Send the buyer phrase and the story lines as `facts` in `context`, and the ask in `rules`. One recipient: `optimize_message`. A list of recipients: one `optimize_message_batch` call (up to 500 items), then `get_message_batch`. Do not loop `optimize_message` over a list. The bundled `amdahl` skill says how to send the context and relay the result.
- A LinkedIn post or a blog → write the piece anchored on the verbatim buyer phrase (anonymized), ending in a real question, not a CTA cliché. LinkedIn: under 150 words, no emoji, no hashtags. Blog: outline + opening.
- Show the verbatim phrase you anchored on, separately, so the user can verify it's real.
- Stop there: the draft lives in this conversation.

Full recipe + variations — `prompts/content-and-outbound/draft-linkedin-post-grounded.md`.
