# Amdahl Cookbook

Runnable code examples for [Amdahl](https://amdahl.co), the customer intelligence platform. Each recipe is a self-contained TypeScript file that demonstrates a single end-to-end flow against the public Platform API.

This is the companion repository to the [Amdahl docs](https://docs.amdahl.co). For conceptual material and full API reference, start there. For copy-paste-and-run examples, you are in the right place.

## What is Amdahl

Amdahl is a customer intelligence platform built around three primitives: **sessions** (a unit of work), **substrate** (the context layer that holds your data), and **artifacts** (the universal output format). Anything you can build through the dashboard you can also build through the Platform API or via the MCP server.

The platform is API-first. Recipes in this repo are written in raw TypeScript using `fetch`, so they read the same way regardless of language ecosystem. Port them to Python, Go, or anything else by translating the HTTP calls.

## What is a recipe

A recipe is a single TypeScript file that:

- Shows one focused capability (auth, session lifecycle, blueprint authoring, streaming, artifact publishing)
- Loads configuration from environment variables (no hardcoded secrets)
- Uses raw `fetch` against the Platform API at `https://app.amdahl.co/api/platform/v1/`
- Cleans up any test data it creates
- Prints a clear success or failure message
- Is verified weekly by an automated cron run against the staging API

Recipes are intentionally minimal. They favor clarity over completeness. If you want a production-grade pattern (retry, backoff, idempotency keys), see the [Amdahl docs guides section](https://docs.amdahl.co/guides).

## Recipes in this repo

| File | What it shows |
|---|---|
| [`recipes/01-hello-world.ts`](recipes/01-hello-world.ts) | Verify auth and connectivity by listing sessions |
| [`recipes/02-create-a-session.ts`](recipes/02-create-a-session.ts) | Full session lifecycle: create, list, get, delete |
| [`recipes/03-build-a-blueprint.ts`](recipes/03-build-a-blueprint.ts) | Author and run a custom agent blueprint via REST |
| [`recipes/04-stream-an-agent-run.ts`](recipes/04-stream-an-agent-run.ts) | Stream tokens from a long agent run via Server-Sent Events |
| [`recipes/05-publish-an-artifact.ts`](recipes/05-publish-an-artifact.ts) | Create an artifact, version it, share it publicly |

## How to run

You will need:

- Node.js 20 or newer
- An Amdahl API key (generate one at [app.amdahl.co/settings/api-keys](https://app.amdahl.co/settings/api-keys))
- Your Amdahl business UUID (find it in the console URL)

Setup:

```bash
git clone https://github.com/amdahlco/amdahl-cookbook.git
cd amdahl-cookbook
npm install
cp .env.example .env
# edit .env and fill in AMDAHL_API_KEY and AMDAHL_BUSINESS_ID
```

Run an individual recipe:

```bash
npx tsx recipes/01-hello-world.ts
```

Or use the named npm scripts:

```bash
npm run recipe:hello-world
npm run recipe:create-session
npm run recipe:build-blueprint
npm run recipe:stream-run
npm run recipe:publish-artifact
```

Run the type checker over every recipe:

```bash
npm run lint
```

## How recipes are kept fresh

Every Sunday at 02:00 UTC, a GitHub Actions cron job runs each recipe against the staging API. If a recipe fails, the failure is posted to a Slack webhook and an issue is opened in this repo. This is the contract that keeps recipes from rotting silently.

The runner lives at [`scripts/run-recipe.ts`](scripts/run-recipe.ts). The workflow lives at [`.github/workflows/recipe-cron.yml`](.github/workflows/recipe-cron.yml).

## How to contribute

We welcome new recipes. Good candidates are focused, self-contained flows that a developer might Google for at three in the morning.

To propose a new recipe:

1. Open an issue describing the flow you want to demonstrate
2. Fork this repo and add a new file under `recipes/` following the existing naming pattern (`NN-short-slug.ts`)
3. Include the standard frontmatter comment block (title, description, prerequisites, expected runtime, what gets created and cleaned up, `verified` date)
4. Make sure your recipe creates and cleans up its own test data; never operate destructively on customer data
5. Run `npm run lint` and the recipe itself end-to-end before opening a PR
6. Open a PR; the cron will pick up your recipe on the next Sunday run

For larger contributions or feedback on the docs themselves, open an issue at [github.com/amdahlco/amdahl-cookbook/issues](https://github.com/amdahlco/amdahl-cookbook/issues).

## Related repos

This is the first public repo under the [amdahlco GitHub organization](https://github.com/amdahlco). Other public repos and SDKs will land here over time. For now, the integration surface is the Platform API directly, documented at [docs.amdahl.co](https://docs.amdahl.co).

## License

MIT. See [LICENSE](LICENSE).
