/**
 * Recipe 01: Hello World
 *
 * Title: Verify your Amdahl API key works
 * Description: The minimal "is everything wired up correctly?" recipe. Loads
 *   credentials from .env, calls the Platform API to list sessions, and prints
 *   the result. If this works, your environment is ready for every other recipe.
 * Prerequisites: AMDAHL_API_KEY, AMDAHL_BUSINESS_ID, optional AMDAHL_API_BASE
 * Expected runtime: under 5 seconds
 * Creates: nothing
 * Cleans up: nothing (this recipe is read-only)
 *
 * verified: 2026-05-06
 */

import 'dotenv/config';

// ----------------------------------------------------------------------------
// Step 1: load and validate environment configuration.
// We fail fast and loud if anything is missing, because every recipe in this
// cookbook needs the same three values and a partial config produces confusing
// 401s deep inside an HTTP call.
// ----------------------------------------------------------------------------

interface AmdahlConfig {
  apiKey: string;
  apiBase: string;
  businessId: string;
}

function loadConfig(): AmdahlConfig {
  const apiKey = process.env.AMDAHL_API_KEY;
  const apiBase = process.env.AMDAHL_API_BASE ?? 'https://app.amdahl.co';
  const businessId = process.env.AMDAHL_BUSINESS_ID;

  const missing: string[] = [];
  if (!apiKey) missing.push('AMDAHL_API_KEY');
  if (!businessId) missing.push('AMDAHL_BUSINESS_ID');

  if (missing.length > 0) {
    throw new Error(
      `Missing required env vars: ${missing.join(', ')}.\n` +
        `Copy .env.example to .env and fill in your values.`,
    );
  }

  // Strip any trailing slash so we can safely concat path segments later.
  return {
    apiKey: apiKey!,
    apiBase: apiBase.replace(/\/$/, ''),
    businessId: businessId!,
  };
}

// ----------------------------------------------------------------------------
// Step 2: define a tiny HTTP helper that wraps fetch with sane defaults.
// Every recipe re-implements this inline so the file stays standalone, but the
// shape is identical: set auth headers, parse JSON, surface clear errors.
// ----------------------------------------------------------------------------

interface SessionsListResponse {
  sessions: Array<{
    id: string;
    name?: string;
    created_at: string;
    status?: string;
  }>;
  total?: number;
}

async function listSessions(config: AmdahlConfig): Promise<SessionsListResponse> {
  const url = `${config.apiBase}/api/platform/v1/sessions`;

  const response = await fetch(url, {
    method: 'GET',
    headers: {
      // X-API-Key is the canonical Platform API auth header. OAuth Bearer
      // tokens are also accepted but require a separate flow.
      'X-API-Key': config.apiKey,
      // X-Business-Id scopes every request to a single business namespace.
      'X-Business-Id': config.businessId,
      Accept: 'application/json',
    },
  });

  if (!response.ok) {
    // Try to read the JSON error body for context. If the server returned HTML
    // (e.g. a Cloudflare error page), fall back to status text.
    let detail = response.statusText;
    try {
      const body = (await response.json()) as { error?: string; message?: string };
      detail = body.error ?? body.message ?? detail;
    } catch {
      // Body wasn't JSON; ignore.
    }
    throw new Error(
      `GET /sessions failed with ${response.status} ${response.statusText}: ${detail}`,
    );
  }

  return (await response.json()) as SessionsListResponse;
}

// ----------------------------------------------------------------------------
// Step 3: orchestrate the recipe. Top-level await would work in NodeNext but
// we wrap in main() so test harnesses and the runner script can import this
// file without immediately executing.
// ----------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log('Recipe 01: Hello World');
  console.log('Loading config...');
  const config = loadConfig();
  console.log(`API base: ${config.apiBase}`);
  console.log(`Business: ${config.businessId}`);

  console.log('Calling GET /api/platform/v1/sessions...');
  const result = await listSessions(config);

  const count = result.sessions.length;
  console.log(`Auth verified. Found ${count} session(s) in this business.`);

  // Print the first few sessions so users see real data flowing back.
  if (count > 0) {
    console.log('\nMost recent sessions:');
    for (const session of result.sessions.slice(0, 3)) {
      const label = session.name ?? '(unnamed)';
      console.log(`  - ${session.id}  ${label}  [${session.status ?? 'unknown'}]`);
    }
  }

  console.log('\nSuccess. Your environment is ready.');
}

// Run when invoked directly. The runner script imports this module without
// triggering main() because it watches for an explicit invocation.
main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error(`\nRecipe failed: ${message}`);
  process.exit(1);
});
