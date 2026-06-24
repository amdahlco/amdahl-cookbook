# Knowledge sync

How to **mirror your Amdahl knowledge base into Notion** — a configurable, one-way sync that keeps a Notion database in your own workspace up to date with your Amdahl KB. Set it up once (connect Notion, designate a parent page); after that every document you promote in Amdahl mirrors itself into Notion automatically, with no human in the loop.

Unlike a paste-and-go recipe, this is a standing capability: the sync runs server-side (instant on every KB promotion, plus an hourly reconcile sweep that self-heals drift and backfills anything missed). Agents and your own code just write to the knowledge base; the mirror keeps itself current.

- [Mirror your knowledge base to Notion](mirror-knowledge-base-to-notion.md) — the full **connect -> configure -> it-syncs-itself -> monitor** loop with copy-paste REST and MCP shapes: connect Notion over OAuth, designate a parent page (provisions an "Amdahl Knowledge Base" database + backfills), then watch it mirror every promoted doc. Reads (`notion_sync://` config / status / ledger) are on MCP + REST; the setup writes (configure / backfill / unsync) are REST + console only.

New here? Start with the [main README](../../README.md) for setup, then the [recipe library](../README.md) for the GTM prompts whose outputs are worth saving to the KB in the first place.
