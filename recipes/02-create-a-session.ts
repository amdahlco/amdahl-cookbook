/**
 * Recipe 02: Create and use a session
 *
 * Title: Full session lifecycle
 * Description: Walk through the four core session endpoints. Create a new
 *   session, list sessions to confirm it appears, fetch the session by id,
 *   then delete it. This is the canonical "session lifecycle" pattern that
 *   every Amdahl integration eventually needs.
 * Prerequisites: AMDAHL_API_KEY, AMDAHL_BUSINESS_ID, optional AMDAHL_API_BASE
 * Expected runtime: under 10 seconds
 * Creates: one session named "cookbook-recipe-02-<timestamp>"
 * Cleans up: yes — deletes the session it created at the end
 *
 * verified: 2026-05-06
 */

import 'dotenv/config';

// ----------------------------------------------------------------------------
// Config + types
// ----------------------------------------------------------------------------

interface AmdahlConfig {
  apiKey: string;
  apiBase: string;
  businessId: string;
}

interface Session {
  id: string;
  name?: string;
  status?: string;
  created_at: string;
  metadata?: Record<string, unknown>;
}

interface CreateSessionResponse {
  session: Session;
}

interface GetSessionResponse {
  session: Session;
}

interface ListSessionsResponse {
  sessions: Session[];
  total?: number;
}

function loadConfig(): AmdahlConfig {
  const apiKey = process.env.AMDAHL_API_KEY;
  const apiBase = process.env.AMDAHL_API_BASE ?? 'https://app.amdahl.co';
  const businessId = process.env.AMDAHL_BUSINESS_ID;

  if (!apiKey || !businessId) {
    throw new Error(
      'Missing AMDAHL_API_KEY and/or AMDAHL_BUSINESS_ID. Copy .env.example to .env first.',
    );
  }
  return { apiKey, apiBase: apiBase.replace(/\/$/, ''), businessId };
}

// ----------------------------------------------------------------------------
// HTTP helper. Wraps fetch with auth headers and JSON error parsing. We use
// generics so each call site gets the right response shape.
// ----------------------------------------------------------------------------

async function apiCall<T>(
  config: AmdahlConfig,
  method: 'GET' | 'POST' | 'DELETE',
  path: string,
  body?: unknown,
): Promise<T> {
  const url = `${config.apiBase}${path}`;
  const headers: Record<string, string> = {
    'X-API-Key': config.apiKey,
    'X-Business-Id': config.businessId,
    Accept: 'application/json',
  };
  if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }

  const response = await fetch(url, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  if (!response.ok) {
    let detail = response.statusText;
    try {
      const errBody = (await response.json()) as { error?: string; message?: string };
      detail = errBody.error ?? errBody.message ?? detail;
    } catch {
      // ignore
    }
    throw new Error(`${method} ${path} failed with ${response.status}: ${detail}`);
  }

  // 204 No Content is valid for DELETE.
  if (response.status === 204) {
    return undefined as T;
  }
  return (await response.json()) as T;
}

// ----------------------------------------------------------------------------
// Operations. Each function is one endpoint, named for what it does.
// ----------------------------------------------------------------------------

async function createSession(
  config: AmdahlConfig,
  name: string,
): Promise<Session> {
  // POST /api/platform/v1/sessions
  // The session body is small: a name, optional metadata, optional initial
  // context. Most fields are optional; the server fills sensible defaults.
  const result = await apiCall<CreateSessionResponse>(
    config,
    'POST',
    '/api/platform/v1/sessions',
    {
      name,
      metadata: {
        source: 'amdahl-cookbook',
        recipe: '02-create-a-session',
      },
    },
  );
  return result.session;
}

async function listSessions(config: AmdahlConfig): Promise<Session[]> {
  // GET /api/platform/v1/sessions
  // Returns recent sessions. By default the API caps at 50 most recent. Pass
  // ?limit=N&cursor=... for pagination if you need more.
  const result = await apiCall<ListSessionsResponse>(
    config,
    'GET',
    '/api/platform/v1/sessions',
  );
  return result.sessions;
}

async function getSession(config: AmdahlConfig, id: string): Promise<Session> {
  // GET /api/platform/v1/sessions/:id
  // Returns the full session record including metadata, status, and any
  // context attachments.
  const result = await apiCall<GetSessionResponse>(
    config,
    'GET',
    `/api/platform/v1/sessions/${encodeURIComponent(id)}`,
  );
  return result.session;
}

async function deleteSession(config: AmdahlConfig, id: string): Promise<void> {
  // DELETE /api/platform/v1/sessions/:id
  // Soft-deletes the session. Idempotent: deleting a session that's already
  // gone returns 204 (or 404 — depends on server config; we treat 404 as ok).
  await apiCall<void>(
    config,
    'DELETE',
    `/api/platform/v1/sessions/${encodeURIComponent(id)}`,
  );
}

// ----------------------------------------------------------------------------
// Main. Each step is logged so the user sees the lifecycle play out.
// ----------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log('Recipe 02: Create and use a session');
  const config = loadConfig();

  // Use a timestamp suffix so re-runs don't collide on a unique-name index.
  const sessionName = `cookbook-recipe-02-${Date.now()}`;

  // We declare createdId outside the try so the finally block can clean up
  // even if a later step throws.
  let createdId: string | undefined;

  try {
    // Step 1: create.
    console.log(`\n[1/4] Creating session "${sessionName}"...`);
    const created = await createSession(config, sessionName);
    createdId = created.id;
    console.log(`      Created session ${created.id}`);

    // Step 2: list and verify our new session is in the result.
    console.log('\n[2/4] Listing sessions to confirm it appears...');
    const all = await listSessions(config);
    const found = all.find((s) => s.id === createdId);
    if (!found) {
      throw new Error(
        `Just-created session ${createdId} did not appear in the list response.`,
      );
    }
    console.log(`      Confirmed: ${all.length} sessions returned, ours is in the list.`);

    // Step 3: get the session by id.
    console.log(`\n[3/4] Fetching session ${createdId} by id...`);
    const fetched = await getSession(config, createdId);
    console.log(`      Fetched: name="${fetched.name}", status="${fetched.status ?? 'n/a'}"`);
    if (fetched.metadata) {
      console.log(`      Metadata: ${JSON.stringify(fetched.metadata)}`);
    }

    // Step 4 (cleanup) lives in the finally block below.
  } finally {
    // Always attempt cleanup, even if an earlier step threw. This is the
    // "recipes must clean up after themselves" rule in action.
    if (createdId) {
      console.log(`\n[4/4] Deleting session ${createdId} (cleanup)...`);
      try {
        await deleteSession(config, createdId);
        console.log('      Deleted.');
      } catch (err) {
        // Log but don't re-throw. The original error (if any) is more useful.
        const msg = err instanceof Error ? err.message : String(err);
        console.error(`      Cleanup failed: ${msg}`);
      }
    }
  }

  console.log('\nSuccess. Session lifecycle complete.');
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error(`\nRecipe failed: ${message}`);
  process.exit(1);
});
