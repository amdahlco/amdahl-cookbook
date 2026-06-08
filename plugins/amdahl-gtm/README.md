# amdahl-gtm

**Turn Claude Code into your GTM intelligence team. One install, no key.**

Generic Claude reads the public internet. Connect Amdahl, and Claude can also read *your* CRM and *your* call transcripts — what buyers actually said, which objections actually surfaced, which competitors actually showed up late in your deals. The interesting signal is the **divergence** between the public story and your internal story. That's the moat. This plugin packages that moat as a set of `/amdahl-gtm:*` plays.

It's the Claude Code companion to the [Amdahl cookbook](../../README.md): every command is wired to a recipe in [`prompts/`](../../prompts), so anything a command does, you can also do by pasting the matching recipe into claude.ai.

## Install

```
/plugin marketplace add amdahlco/amdahl-cookbook
/plugin install amdahl-gtm@amdahl-cookbook
```

That single install gives you the MCP connection **and** the slash commands below.

## Connect (automatic, OAuth, no key)

The plugin ships the `amdahl` MCP server (`https://app.amdahl.co/mcp`) and starts it when the plugin is enabled. The first time a command calls an Amdahl tool, the standard MCP OAuth approval opens in your browser; after that it stays connected and scoped to your workspace. No token paste, no JSON to edit.

Run `/amdahl-gtm:setup` to confirm the connection and see what's on file. If you don't have an Amdahl account yet, start at <https://amdahl.co>.

## Commands

| Command | What it does |
|---|---|
| `/amdahl-gtm:setup` | Connect + health check — auth, tenant binding, and what data is on file. |
| `/amdahl-gtm:company <name\|domain>` | 1-page account deep-dive: internal history fused with public signal, ending on the divergence + a next step. |
| `/amdahl-gtm:competitor <name>` | Their public posture vs. how buyers describe them on your calls, with attack angles. |
| `/amdahl-gtm:meeting-prep <company> [type]` | 1-page prep for tomorrow's discovery / demo / QBR / renewal. |
| `/amdahl-gtm:win-loss <company>` | Honest closed-lost postmortem: timeline, turning point, verbatim "why we lost", 3 do-overs. |
| `/amdahl-gtm:positioning [copy\|url]` | Your messaging vs. how customers actually talk, with grounded rewrites. |
| `/amdahl-gtm:draft <topic> [channel]` | Content grounded in real customer language, in your voice. Offers to save to your library. |
| `/amdahl-gtm:pipeline [scope]` | Deals that look healthy on paper but are quietly dying — sorted by ACV × severity. |

## The skill

The plugin also ships a thin routing skill (`amdahl-gtm-routing`) so that **ambient** GTM questions — ones where you didn't type a slash command — still route through Amdahl instead of generic `web_search`. Ask "help me write a cold email to a Series B fintech CTO" and it reaches for your corpus on its own.

## How it works

Each command runs a **wave structure**: an explicit parallel gather (internal corpus via `data` + `context`, public signal via `external_search`) followed by a synthesis pass whose centerpiece is the **divergence** between the two. Every claim is grounded — a verbatim call quote (speaker + date) or a dated public source. When a command writes a deliverable back to Amdahl (e.g. `/amdahl-gtm:draft`), the platform's fact-check gate runs on the write and hands back a shareable console link.

The deep routing detail and operational defaults live server-side in the `system/amdahl_gtm_playbook` MCP prompt, so the plugin stays thin and the playbook can evolve without a plugin release.

## Troubleshooting

- **A command says it can't reach Amdahl** → run `/amdahl-gtm:setup`; approve the OAuth login. Manual fallback: `claude mcp add --transport http amdahl "https://app.amdahl.co/mcp"`.
- **Output is thin** → usually thin grounding. Follow up with "pull 5 more verbatim quotes on <theme>" — the brief sharpens.
- **The divergence section is empty** → either the public or internal side had no signal for this entity. `/amdahl-gtm:setup` shows whether your CRM + calls have synced.

## Docs & support

- Product docs: <https://amdahl.co/mcp>
- Home: <https://amdahl.co>
- Support: hello@amdahl.co

MIT licensed.
