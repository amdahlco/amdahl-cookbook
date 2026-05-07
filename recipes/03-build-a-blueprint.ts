/**
 * Recipe 03: Build a custom agent blueprint
 *
 * Title: Author and run a custom agent_blueprint via REST
 * Description: Blueprints are reusable agent specs. This recipe authors a
 *   simple "summarize a topic" blueprint as an artifact, runs it once via the
 *   blueprint runner endpoint, polls for completion, prints the result, and
 *   then cleans up the blueprint artifact.
 * Prerequisites: AMDAHL_API_KEY, AMDAHL_BUSINESS_ID, optional AMDAHL_API_BASE
 * Expected runtime: 30-60 seconds (depends on blueprint complexity)
 * Creates: one platform_artifact of type "agent_blueprint" + one conversation
 *   from the blueprint run
 * Cleans up: yes — deletes the blueprint artifact and the conversation
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

interface Artifact {
  id: string;
  type: string;
  title: string;
  status?: string;
  content_json?: Record<string, unknown>;
  created_at: string;
}

interface CreateArtifactResponse {
  artifact: Artifact;
}

interface RunBlueprintResponse {
  conversation_id: string;
  status: string;
}

interface ConversationStatus {
  id: string;
  status: 'pending' | 'running' | 'completed' | 'failed' | string;
  output?: {
    text?: string;
    artifact_id?: string;
  };
  error?: string;
}

interface GetConversationResponse {
  conversation: ConversationStatus;
}

function loadConfig(): AmdahlConfig {
  const apiKey = process.env.AMDAHL_API_KEY;
  const apiBase = process.env.AMDAHL_API_BASE ?? 'https://app.amdahl.co';
  const businessId = process.env.AMDAHL_BUSINESS_ID;

  if (!apiKey || !businessId) {
    throw new Error('Missing AMDAHL_API_KEY and/or AMDAHL_BUSINESS_ID.');
  }
  return { apiKey, apiBase: apiBase.replace(/\/$/, ''), businessId };
}

// ----------------------------------------------------------------------------
// HTTP helper
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
  if (body !== undefined) headers['Content-Type'] = 'application/json';

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
  if (response.status === 204) return undefined as T;
  return (await response.json()) as T;
}

// ----------------------------------------------------------------------------
// Blueprint operations
// ----------------------------------------------------------------------------

/**
 * A blueprint is just a platform_artifact with type='agent_blueprint' and a
 * specific content_json shape. The runner endpoint reads this artifact at
 * execution time to know what model, prompt, and tools to use.
 */
function buildBlueprintBody(): {
  type: string;
  title: string;
  content_json: Record<string, unknown>;
} {
  return {
    type: 'agent_blueprint',
    title: 'Cookbook 03: Topic Summarizer',
    content_json: {
      // The blueprint schema is intentionally flexible. These are the fields
      // the runner expects; refer to the docs for the canonical schema.
      version: '1.0',
      description: 'Summarize a given topic in three bullet points.',
      model: 'claude-sonnet-4-5',
      system_prompt:
        'You are a concise expert. Summarize the user-provided topic in ' +
        'exactly three bullet points. No preamble, no closing remark.',
      input_schema: {
        type: 'object',
        properties: {
          topic: { type: 'string', description: 'The topic to summarize' },
        },
        required: ['topic'],
      },
      // Tools list left empty for the simplest possible blueprint.
      tools: [],
    },
  };
}

async function createBlueprint(config: AmdahlConfig): Promise<Artifact> {
  // POST /api/platform/v1/artifacts
  // Creates an artifact. Type is set in the body.
  const result = await apiCall<CreateArtifactResponse>(
    config,
    'POST',
    '/api/platform/v1/artifacts',
    buildBlueprintBody(),
  );
  return result.artifact;
}

async function runBlueprint(
  config: AmdahlConfig,
  blueprintId: string,
  topic: string,
): Promise<RunBlueprintResponse> {
  // POST /api/platform/v1/agents/run_blueprint
  // The runner kicks off a conversation, returns immediately with the new
  // conversation id, and runs in the background. We poll for completion.
  return await apiCall<RunBlueprintResponse>(
    config,
    'POST',
    '/api/platform/v1/agents/run_blueprint',
    {
      blueprint_id: blueprintId,
      input_params: { topic },
    },
  );
}

async function getConversation(
  config: AmdahlConfig,
  id: string,
): Promise<ConversationStatus> {
  const result = await apiCall<GetConversationResponse>(
    config,
    'GET',
    `/api/platform/v1/conversations/${encodeURIComponent(id)}`,
  );
  return result.conversation;
}

async function deleteArtifact(config: AmdahlConfig, id: string): Promise<void> {
  await apiCall<void>(
    config,
    'DELETE',
    `/api/platform/v1/artifacts/${encodeURIComponent(id)}`,
  );
}

async function deleteConversation(
  config: AmdahlConfig,
  id: string,
): Promise<void> {
  await apiCall<void>(
    config,
    'DELETE',
    `/api/platform/v1/conversations/${encodeURIComponent(id)}`,
  );
}

// ----------------------------------------------------------------------------
// Polling helper. We poll the conversation status with a small backoff up to a
// hard cap. Real production code would probably use a webhook subscription
// instead, but polling is simpler for a cookbook example.
// ----------------------------------------------------------------------------

async function waitForCompletion(
  config: AmdahlConfig,
  conversationId: string,
  options: { maxWaitMs?: number; pollIntervalMs?: number } = {},
): Promise<ConversationStatus> {
  const maxWaitMs = options.maxWaitMs ?? 90_000;
  const pollIntervalMs = options.pollIntervalMs ?? 2_000;
  const start = Date.now();

  while (true) {
    const status = await getConversation(config, conversationId);
    if (status.status === 'completed') return status;
    if (status.status === 'failed') {
      throw new Error(`Conversation failed: ${status.error ?? 'unknown error'}`);
    }
    if (Date.now() - start > maxWaitMs) {
      throw new Error(
        `Conversation did not complete within ${maxWaitMs}ms (last status: ${status.status})`,
      );
    }
    await new Promise<void>((resolve) => setTimeout(resolve, pollIntervalMs));
  }
}

// ----------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log('Recipe 03: Build a custom agent blueprint');
  const config = loadConfig();

  let blueprintId: string | undefined;
  let conversationId: string | undefined;

  try {
    // Step 1: author the blueprint as an artifact.
    console.log('\n[1/4] Authoring blueprint artifact...');
    const blueprint = await createBlueprint(config);
    blueprintId = blueprint.id;
    console.log(`      Blueprint created: ${blueprintId}`);
    console.log(`      Title: "${blueprint.title}"`);

    // Step 2: kick off a run.
    console.log('\n[2/4] Running blueprint with topic="prompt caching"...');
    const run = await runBlueprint(config, blueprintId, 'prompt caching');
    conversationId = run.conversation_id;
    console.log(`      Run started: conversation ${conversationId}`);

    // Step 3: poll for completion.
    console.log('\n[3/4] Polling for completion (this may take 30-60s)...');
    const final = await waitForCompletion(config, conversationId);
    console.log(`      Status: ${final.status}`);
    if (final.output?.text) {
      console.log('\n      Output:\n');
      // Indent the model output so it visually nests under the step.
      const lines = final.output.text.split('\n');
      for (const line of lines) console.log(`      ${line}`);
    }
  } finally {
    // Step 4: clean up everything we created. We try each independently so
    // one failure doesn't leave the other dangling.
    console.log('\n[4/4] Cleanup...');
    if (conversationId) {
      try {
        await deleteConversation(config, conversationId);
        console.log(`      Deleted conversation ${conversationId}`);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        console.error(`      Conversation cleanup failed: ${msg}`);
      }
    }
    if (blueprintId) {
      try {
        await deleteArtifact(config, blueprintId);
        console.log(`      Deleted blueprint ${blueprintId}`);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        console.error(`      Blueprint cleanup failed: ${msg}`);
      }
    }
  }

  console.log('\nSuccess. Blueprint authored, run, and cleaned up.');
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error(`\nRecipe failed: ${message}`);
  process.exit(1);
});
