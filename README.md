# amdahl-cookbook

Plugins and runnable examples for [Amdahl](https://amdahl.co), the customer intelligence platform.

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

## License

MIT
