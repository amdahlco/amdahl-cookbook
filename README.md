# Amdahl Cookbook

Runnable MCP recipes for [Amdahl](https://amdahl.co), the customer intelligence platform. Each recipe is a self-contained TypeScript file that demonstrates a single end-to-end flow against the Amdahl Model Context Protocol surface.

This is the companion repository to the [Amdahl docs](https://docs.amdahl.co). For conceptual material and full reference, start there. For copy-paste-and-run examples, you are in the right place.

## What is Amdahl

Amdahl is a customer intelligence platform built around three primitives: **sessions** (a unit of work), **substrate** (the context layer that holds your data), and **artifacts** (the universal output format). The integration surface is the Model Context Protocol, served at two endpoints:

- **Public docs MCP** at `https://app.amdahl.co/mcp/public` — no auth, two read-only tools (`search`, `ask`) for querying Amdahl's docs corpus. Connect from Claude Desktop, Cursor, or any MCP client without an account.
- **Tenant MCP** at `https://app.amdahl.co/mcp` — full surface (data, context, artifacts, knowledge_base, settings, authors, resources, external_search), API key required. This is the integration target for agents that work inside your business.

> A REST surface is on the roadmap but not part of the public release yet. When it ships, REST recipes will land here too.

## What is a recipe

A recipe is a single TypeScript file that:

- Shows one focused capability (connect, search, ask, list artifacts, build an agent loop)
- Loads configuration from environment variables (no hardcoded secrets)
- Uses the official [`@modelcontextprotocol/sdk`](https://www.npmjs.com/package/@modelcontextprotocol/sdk) client
- Operates read-only or cleans up any test data it creates
- Prints a clear success or failure message

Recipes are intentionally minimal. They favor clarity over completeness. If you want a production-grade pattern (retry, backoff, observability), see the [Amdahl docs guides section](https://docs.amdahl.co/guides).

## Recipes in this repo

| File | What it shows | Auth |
|---|---|---|
| [`recipes/01-connect-and-list-tools.ts`](recipes/01-connect-and-list-tools.ts) | Connect to the public MCP, list every exposed tool | none |
| [`recipes/02-search-amdahl-docs.ts`](recipes/02-search-amdahl-docs.ts) | Call the `search` tool against the docs corpus | none |
| [`recipes/03-ask-amdahl.ts`](recipes/03-ask-amdahl.ts) | Call the `ask` tool for a Claude-grounded answer with citations | none |
| [`recipes/04-tenant-mcp-list-artifacts.ts`](recipes/04-tenant-mcp-list-artifacts.ts) | Connect to the tenant MCP with an API key, list your artifacts via the `read_resource` meta-tool | API key |
| [`recipes/05-claude-with-amdahl-mcp.ts`](recipes/05-claude-with-amdahl-mcp.ts) | Wire the Anthropic Messages API to the Amdahl MCP so Claude can call Amdahl tools | Anthropic key |

## How to run

You will need:

- Node.js 20 or newer
- For recipes 04+: an Amdahl MCP API key (generate one in the [Amdahl Console](https://app.amdahl.co) under Team Settings → MCP Keys)
- For recipe 05: an Anthropic API key

Setup:

```bash
git clone https://github.com/amdahlco/amdahl-cookbook.git
cd amdahl-cookbook
npm install
cp .env.example .env
# edit .env and fill in keys for whichever recipes you want to run
```

Run an individual recipe:

```bash
npx tsx recipes/01-connect-and-list-tools.ts
```

Or use the named npm scripts:

```bash
npm run recipe:01
npm run recipe:02
npm run recipe:03
npm run recipe:04
npm run recipe:05
```

Recipes 02, 03, and 05 accept an optional CLI argument to override the default query:

```bash
npx tsx recipes/03-ask-amdahl.ts "What scopes does mcp_customer_agent grant?"
```

Type-check every recipe:

```bash
npm run lint
```

## How to contribute

Good recipe candidates are focused, self-contained flows that a developer might search for at three in the morning.

To propose a new recipe:

1. Open an issue describing the flow you want to demonstrate
2. Fork this repo and add a new file under `recipes/` following the existing naming pattern (`NN-short-slug.ts`)
3. Include the standard frontmatter comment block (title, description, prerequisites, expected runtime, what gets created and cleaned up, `verified` date)
4. Make sure your recipe creates and cleans up its own test data; never operate destructively on real customer data
5. Run `npm run lint` and the recipe itself end-to-end before opening a PR

For larger contributions or feedback on the docs themselves, open an issue at [github.com/amdahlco/amdahl-cookbook/issues](https://github.com/amdahlco/amdahl-cookbook/issues).

## Related

This is the first public repo under the [amdahlco GitHub organization](https://github.com/amdahlco). For the underlying spec, see the [Amdahl docs](https://docs.amdahl.co). For the Model Context Protocol itself, see [modelcontextprotocol.io](https://modelcontextprotocol.io).

## License

MIT. See [LICENSE](LICENSE).
