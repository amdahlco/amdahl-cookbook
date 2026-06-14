---
description: Connect Claude Code to your Amdahl workspace and verify it's working — checks auth, tenant binding, and what data is on file.
argument-hint: (no arguments)
---

Run the Amdahl connection health check. Be concise — report status as a short checklist, not an essay.

1. **Connection + auth.** Make one cheap Amdahl call: `context` summary.
   - If it fails because the server isn't connected or isn't authorized: tell the user the `amdahl` MCP server ships with this plugin and authorizes over OAuth on first use. Ask them to approve the browser login that opens (or re-run this command after approving). If no login appears, they can add the server manually: `claude mcp add --transport http amdahl "https://app.amdahl.co/mcp"`.
   - If it returns a profile: you're connected. Report the workspace / company name back to them.

2. **Tenant readiness.** From the `context` summary, report what's on file and what's thin:
   - Company profile / ICP present?
   - CRM + call data synced — is there interaction volume to query? If it's empty, say so plainly: the divergence map will be light until data syncs.
   - Brand voice on file? If it's thin, note that `/amdahl-gtm:draft` will lean on generic voice until the profile fills in.

3. **No Amdahl account?** If auth lands with no tenant / workspace, the user isn't an Amdahl customer yet. Point them to https://amdahl.co to get an account, then re-run `/amdahl-gtm:setup`.

4. **Show them the menu.** List the available plays with one example each:
   - `/amdahl-gtm:company <name|domain>` — 1-page account deep-dive
   - `/amdahl-gtm:competitor <name>` — public posture vs. how buyers describe them on our calls
   - `/amdahl-gtm:meeting-prep <company>` — walk in knowing the room
   - `/amdahl-gtm:win-loss <company>` — honest closed-lost postmortem
   - `/amdahl-gtm:positioning` — your copy vs. how customers actually talk
   - `/amdahl-gtm:draft <topic>` — content grounded in real customer language, in your voice
   - `/amdahl-gtm:pipeline` — deals that look healthy but are quietly dying

End by reminding them: everything here is grounding from their own workspace; nothing leaves it unless they ask Claude to share it.
