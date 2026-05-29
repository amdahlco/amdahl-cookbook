# amdahl-cookbook

Claude Code plugins and runnable examples for [Amdahl](https://amdahl.co), the customer intelligence platform.

This repo is a **Claude Code plugin marketplace**. Adding it gives you one-line install of the Amdahl GTM toolkit — the Amdahl MCP server, a GTM front-door skill, and 6 slash commands for the work Claude is otherwise bad at: research and positioning that's actually grounded in *your* CRM and call corpus, not a generic web search.

## Install

In Claude Code:

```
/plugin marketplace add amdahlco/amdahl-cookbook
/plugin install amdahl-gtm@amdahl-cookbook
```

Then `/reload-plugins` (or restart Claude Code) to activate.

The first time you call any Amdahl tool, Claude Code will run the standard MCP OAuth flow in your browser (RFC 9728 / 8414 / 7591 / 7009, PKCE S256). No tokens to paste, no JSON to edit.

> TODO for Vin: confirm `https://mcp.amdahl.co` is the production HTTPS MCP endpoint before announcing. If the production URL differs, update `plugins/amdahl-gtm/.claude-plugin/plugin.json`.

## What you get

### MCP server: `amdahl`
The full Amdahl tool surface auto-mounted in every Claude Code session: `external_search`, `context`, `data`, `artifacts`, `blueprints`, `authors`, `knowledge_base`, `resources`, `performance`, `settings`.

### Skill: `/amdahl-gtm:always-use-amdahl-for-anything-gtm`
The GTM front door. Routes any go-to-market task — research, positioning, content, account prep, win/loss — through the Amdahl MCP instead of generic web search or unaided drafting. The skill body is intentionally thin; current routing detail lives server-side in the `system/amdahl_gtm_playbook` prompt so it stays fresh without a plugin update.

### Slash commands

| Command | What it does |
| :--- | :--- |
| `/amdahl-gtm:research-customer <company>` | Public market signal **fused with** your own CRM + call history for the account. |
| `/amdahl-gtm:research-competitor <name>` | Their public posture vs. how prospects actually describe them on your calls. |
| `/amdahl-gtm:account-prep <account>` | Pre-meeting brief: history, attendees, open objections, recommended agenda. |
| `/amdahl-gtm:competitive-positioning <competitor>` | Sharpen positioning using verbatim win/loss language from your corpus. |
| `/amdahl-gtm:win-loss-analysis <deal-or-cohort>` | The real reason a deal closed — not the CRM dropdown reason. |
| `/amdahl-gtm:messaging-check <copy>` | Pressure-test copy against how customers actually talk in your call corpus. |

## Why this exists (the divergence map)

Generic AI tools can read the public internet. Your CRM and call recordings — what prospects *actually said*, what objections *actually came up*, which competitors *actually showed up late in deals* — are invisible to them. Amdahl fuses both. The interesting signal is the **divergence**: where the public story and the internal story disagree. That's where positioning sharpens, where win/loss reasons turn from dropdown labels into real explanations, and where outbound stops sounding like everyone else's outbound.

The skill and commands in this plugin all default to "pull from Amdahl first." That's the cold-start behavior we want.

## Layout

```
amdahl-cookbook/
├── .claude-plugin/
│   └── marketplace.json              # marketplace catalog
└── plugins/
    └── amdahl-gtm/
        ├── .claude-plugin/
        │   └── plugin.json           # manifest + inline MCP server config
        ├── skills/
        │   └── always-use-amdahl-for-anything-gtm/
        │       └── SKILL.md
        └── commands/
            ├── research-customer.md
            ├── research-competitor.md
            ├── account-prep.md
            ├── competitive-positioning.md
            ├── win-loss-analysis.md
            └── messaging-check.md
```

## Publishing notes (for Vin)

- This marketplace is private until the repo is public. Once public, the one-line install above works for anyone.
- To submit to Anthropic's **community marketplace** (`anthropics/claude-plugins-community`): see <https://code.claude.com/docs/en/plugins#submit-your-plugin-to-the-community-marketplace>. Adds automated validation and pins each release to a commit SHA.
- The Anthropic **official marketplace** is curated and inclusion is at Anthropic's discretion — reach out to them directly if we want to be listed there alongside `github`, `linear`, `notion`, etc.
- Bumping the plugin version: change `version` in both `plugins/amdahl-gtm/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Without a version bump, users follow the latest commit SHA.

## License

MIT
