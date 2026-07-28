# amdahl-gtm

**Turn Claude Code into your GTM intelligence team. One install, no key.**

Generic Claude reads the public internet. Connect Amdahl, and Claude can also read *your* CRM and *your* call transcripts — what buyers actually said, which objections actually surfaced, which competitors actually showed up late in your deals. The interesting signal is the **divergence** between the public story and your internal story. That's the moat. This plugin packages that moat as a set of `/amdahl-gtm:*` plays.

It's the Claude Code companion to the [Amdahl cookbook](../../README.md): every command is wired to a recipe in [`prompts/`](../../prompts), so anything a command does, you can also do by pasting the matching recipe into claude.ai.

## Install

From your terminal:

```
claude plugin marketplace add amdahlco/amdahl-cookbook && claude plugin install amdahl-gtm@amdahl-cookbook
```

Already inside a Claude Code session? Use the slash form instead:

```
/plugin marketplace add amdahlco/amdahl-cookbook
/plugin install amdahl-gtm@amdahl-cookbook
```

Either way, that single install gives you the MCP connection **and** the slash commands below.

## Connect (automatic, OAuth, no key)

The plugin ships the `amdahl` MCP server (`https://app.amdahl.ai/mcp`) and starts it when the plugin is enabled. The first time a command calls an Amdahl tool, the standard MCP OAuth approval opens in your browser; after that it stays connected and scoped to your workspace. No token paste, no JSON to edit.

Run `/amdahl-gtm:setup` to confirm the connection and see what's on file. If you don't have an Amdahl account yet, start at <https://amdahl.ai>.

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

## The skills

The plugin ships two skills (auto-discovered from `skills/`):

- **`amdahl-gtm-routing`** — a thin routing skill so that **ambient** GTM questions — ones where you didn't type a slash command — still route through Amdahl instead of generic `web_search`. Ask "help me write a cold email to a Series B fintech CTO" and it reaches for your corpus on its own.
- **`blueprint-authoring`** — helps you author an Amdahl **workflow (blueprint)** — a reusable, typed recipe the platform validates, versions, forks, and runs. Workflow authoring is a console capability (the `blueprints` MCP tool was retired and the endpoints behind the console aren't reachable with an external key), so the skill composes + checks the DSL body with you and hands you the finished JSON for the console's Workflows surface — and routes "make this recur" asks to **Routines**: scheduled Chats created with the `agents` MCP tool. Ask "save this workflow as a reusable recipe" or "fork the draft-piece starter and lock it to LinkedIn" and it walks the DSL with you. The narrative guide is [`prompts/blueprints/authoring-a-blueprint.md`](../../prompts/blueprints/authoring-a-blueprint.md).

## How it works

Each command runs a **wave structure**: an explicit parallel gather (internal corpus via the synchronous `search` endpoint — structured, NL, and semantic lanes; entity + topic signal via `enrich`; similarity via `lookalike`) followed by a synthesis pass whose centerpiece is the **divergence** between what the market says and what your buyers said. When the job outgrows synchronous calls, a command escalates to `agents` (`start_chat`) — one server-side Master agent turn that decomposes the ask and composes a cited answer. Every claim is grounded: a verbatim call quote (speaker + date) or a dated public source. To make a deliverable durable, ask for a Chat with `write_outputs` on — it commits a knowledge-base version you promote in the console.

(Workspaces still on the pre-rollout surface see the legacy `data` / `context` / `external_search` / `knowledge_base` tools instead; the commands carry a fallback note for them.) The deep routing detail and operational defaults live server-side in the `system/amdahl_gtm_playbook` MCP prompt, so the plugin stays thin and the playbook can evolve without a plugin release.

## Troubleshooting

- **A command says it can't reach Amdahl** → run `/amdahl-gtm:setup`; approve the OAuth login. Manual fallback: `claude mcp add --transport http amdahl "https://app.amdahl.ai/mcp"`.
- **Output is thin** → usually thin grounding. Follow up with "pull 5 more verbatim quotes on <theme>" — the brief sharpens.
- **The divergence section is empty** → either the public or internal side had no signal for this entity. `/amdahl-gtm:setup` shows whether your CRM + calls have synced.

## Docs & support

- Product docs: <https://docs.amdahl.ai>
- Home: <https://amdahl.ai>
- Support: hello@amdahl.ai

MIT licensed.
