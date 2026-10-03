---
description: Connect Claude Code to your Amdahl workspace and verify it's working — checks sign-in, the workspace, connection health, and what data is on file.
argument-hint: (no arguments)
---

Run the Amdahl connection health check. Be concise — report status as a short checklist, not an essay.

1. **Connection + auth.** Make one cheap Amdahl call: `connections` { action: "setup_status" }. It takes no other parameters and changes nothing.
   - If it fails because the server isn't connected or isn't authorized: tell the user the `amdahl` MCP server ships with this plugin and signs in over OAuth on first use. Ask them to approve the browser sign-in that opens (or re-run this command after approving). If no sign-in appears, they can add the server manually: `claude mcp add --transport http amdahl "https://app.amdahl.ai/mcp"`, then run `/mcp`.
   - If the session lists no `connections` tool at all, the server is not connected; there is no alternate surface to fall back to.
   - If it returns: report the workspace (`workspace.name`), who is signed in (`caller.email`) and their role (`caller.role`). That confirms the connection and the workspace binding.
   - If `optimize.allowed` is `false`, report `optimize.blocker` in plain words: `missing_scope` means the connector was authorized before a capability existed (disconnect and reconnect Amdahl to re-authorize), `role_too_low` means they are a Viewer (ask a workspace admin for Editor or above), and `quota_exhausted` means this month's optimizations are used up (they reset at `optimize.quota.resets_at`). The read-only plays below still work.

2. **Tenant readiness.** Report what's connected and what's on file:
   - From the same result: `connections.total` sources, `connections.healthy` of them healthy, and each entry in `connections.needs_attention` by `name` and `status`. A source that needs attention is the usual reason data looks thin.
   - Then one read for volume: `search` { action: query, mode: "fuzzy", query: "how many customer interactions do we have on file, and how many in the last 30 days" }. If it's empty or thin, say so plainly: the divergence map will be light until data syncs.
   - Note that brand voice / ICP live server-side and are picked up automatically by deep runs (`agents` start_chat); if `/amdahl-gtm:draft` output reads generic, the voice profile is still filling in.

3. **No workspace yet?** If sign-in ends on a page that says **Join the beta** (or **Create a workspace first**), the user has no Amdahl workspace yet. Point them to https://console.amdahl.ai/new to join the beta waitlist (or create the workspace, if they are approved), then re-run `/amdahl-gtm:setup`. If their company already uses Amdahl, an admin there can add them instead.

4. **Show them the menu.** List the available plays with one example each:
   - `/amdahl-gtm:company <name|domain>` — 1-page account deep-dive
   - `/amdahl-gtm:competitor <name>` — public posture vs. how buyers describe them on our calls
   - `/amdahl-gtm:meeting-prep <company>` — walk in knowing the room
   - `/amdahl-gtm:win-loss <company>` — honest closed-lost postmortem
   - `/amdahl-gtm:positioning` — your copy vs. how customers actually talk
   - `/amdahl-gtm:draft <topic>` — content grounded in real customer language, in your voice
   - `/amdahl-gtm:pipeline` — deals that look healthy but are quietly dying

End by reminding them: everything here is grounding from their own workspace; nothing leaves it unless they ask Claude to share it.
