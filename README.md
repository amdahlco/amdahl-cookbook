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

Docs: <https://amdahl.co/mcp>

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

## Publishing & releases

### Community marketplace (Anthropic-hosted)

The Anthropic community marketplace at `anthropics/claude-plugins-community` does **not** accept direct PRs (they are auto-closed). Submit via the official form: <https://clau.de/plugin-directory-submission>. After Anthropic's automated security scan + internal review, the marketplace's `marketplace.json` is updated nightly. Once listed, users install with:

```
/plugin marketplace add anthropics/claude-plugins-community
/plugin install amdahl-gtm@claude-community
```

### Official curated marketplace

The Anthropic **official marketplace** is curated and inclusion is at Anthropic's discretion — reach out directly to be considered alongside the canonical plugins (`github`, `linear`, `notion`, etc.).

### Cutting a release

After merging, tag and push `v1.0.0` so installs pin to a release SHA instead of `main`:

```
git checkout main && git pull
git tag -a v1.0.0 -m "amdahl-gtm v1.0.0 — initial release"
git push origin v1.0.0
```

For each subsequent release, bump `version` in BOTH `plugins/amdahl-gtm/.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` in the same commit before tagging. Without a bump, users follow the latest commit on `main`.

## License

MIT
