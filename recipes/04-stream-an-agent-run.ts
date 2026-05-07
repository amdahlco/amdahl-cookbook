/**
 * Recipe 04: Stream an agent run
 *
 * Title: Stream tokens from a long agent run via Server-Sent Events
 * Description: For long-running agent calls, polling adds latency. Use the
 *   /conversations/:id/stream endpoint to receive token-by-token output as it
 *   is produced. This recipe creates a conversation, opens an SSE stream, and
 *   prints each delta to the terminal as it arrives.
 * Prerequisites: AMDAHL_API_KEY, AMDAHL_BUSINESS_ID, optional AMDAHL_API_BASE
 * Expected runtime: 15-45 seconds
 * Creates: one conversation
 * Cleans up: yes — deletes the conversation at the end
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

interface CreateConversationResponse {
  conversation: {
    id: string;
    status: string;
  };
}

/**
 * SSE events the streaming endpoint emits. The exact event taxonomy may grow
 * over time; we handle the common ones and ignore unknown event types.
 */
type StreamEvent =
  | { type: 'token'; text: string }
  | { type: 'message_start'; conversation_id: string }
  | { type: 'message_delta'; text: string }
  | { type: 'message_complete'; final_text: string }
  | { type: 'error'; error: string }
  | { type: 'done' };

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
// HTTP helper for plain JSON calls
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
// Operations
// ----------------------------------------------------------------------------

async function createConversation(config: AmdahlConfig): Promise<string> {
  // POST /api/platform/v1/conversations
  // Creates a new conversation seeded with a user message. The server starts
  // generating immediately; we then attach the SSE stream to read the output.
  const result = await apiCall<CreateConversationResponse>(
    config,
    'POST',
    '/api/platform/v1/conversations',
    {
      messages: [
        {
          role: 'user',
          content:
            'Write a short, four-sentence overview of how Server-Sent ' +
            'Events work and when to use them instead of WebSockets.',
        },
      ],
      metadata: {
        source: 'amdahl-cookbook',
        recipe: '04-stream-an-agent-run',
      },
    },
  );
  return result.conversation.id;
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
// SSE parser. The stream returns text/event-stream framed as:
//   event: token
//   data: {"text":"hello"}
//
//   event: done
//   data: {}
//
// Events are separated by a blank line. We buffer bytes, split on \n\n, and
// parse each event. This is simpler than pulling in an SSE library and keeps
// the recipe self-contained.
// ----------------------------------------------------------------------------

function parseSseFrame(frame: string): StreamEvent | null {
  const lines = frame.split('\n');
  let eventName: string | undefined;
  let dataPayload = '';

  for (const line of lines) {
    if (line.startsWith('event:')) {
      eventName = line.slice('event:'.length).trim();
    } else if (line.startsWith('data:')) {
      // Multiple data: lines are joined with newlines per the SSE spec.
      dataPayload += line.slice('data:'.length).trim();
    }
  }

  if (!eventName) return null;

  let parsed: Record<string, unknown> = {};
  if (dataPayload.length > 0) {
    try {
      parsed = JSON.parse(dataPayload) as Record<string, unknown>;
    } catch {
      // Non-JSON data; treat as raw text on a token event.
      if (eventName === 'token') return { type: 'token', text: dataPayload };
      return null;
    }
  }

  switch (eventName) {
    case 'token':
      return { type: 'token', text: String(parsed.text ?? '') };
    case 'message_start':
      return {
        type: 'message_start',
        conversation_id: String(parsed.conversation_id ?? ''),
      };
    case 'message_delta':
      return { type: 'message_delta', text: String(parsed.text ?? '') };
    case 'message_complete':
      return { type: 'message_complete', final_text: String(parsed.final_text ?? '') };
    case 'error':
      return { type: 'error', error: String(parsed.error ?? 'unknown') };
    case 'done':
      return { type: 'done' };
    default:
      // Unknown event types are ignored. The recipe is forward-compatible.
      return null;
  }
}

async function streamConversation(
  config: AmdahlConfig,
  conversationId: string,
  onEvent: (evt: StreamEvent) => void,
): Promise<void> {
  // GET /api/platform/v1/conversations/:id/stream
  // The Accept header asks for an SSE stream; the server responds with
  // text/event-stream and keeps the connection open until the run finishes.
  const url = `${config.apiBase}/api/platform/v1/conversations/${encodeURIComponent(conversationId)}/stream`;
  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'X-API-Key': config.apiKey,
      'X-Business-Id': config.businessId,
      Accept: 'text/event-stream',
    },
  });

  if (!response.ok) {
    throw new Error(
      `Stream request failed with ${response.status} ${response.statusText}`,
    );
  }
  if (!response.body) {
    throw new Error('Server did not return a streaming body');
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  while (true) {
    const { value, done } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });

    // Split on the SSE event separator (blank line).
    let separatorIndex: number;
    while ((separatorIndex = buffer.indexOf('\n\n')) !== -1) {
      const frame = buffer.slice(0, separatorIndex);
      buffer = buffer.slice(separatorIndex + 2);
      const event = parseSseFrame(frame);
      if (event) {
        onEvent(event);
        if (event.type === 'done' || event.type === 'message_complete') {
          // Server signaled end of stream. Stop reading.
          await reader.cancel();
          return;
        }
      }
    }
  }
}

// ----------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log('Recipe 04: Stream an agent run');
  const config = loadConfig();

  let conversationId: string | undefined;

  try {
    // Step 1: kick off the conversation.
    console.log('\n[1/3] Creating conversation...');
    conversationId = await createConversation(config);
    console.log(`      Conversation: ${conversationId}`);

    // Step 2: open the stream and print each token as it arrives.
    console.log('\n[2/3] Streaming output...\n');
    let receivedTokens = 0;
    let finalText = '';

    await streamConversation(config, conversationId, (evt) => {
      switch (evt.type) {
        case 'token':
        case 'message_delta':
          // Print the token without a newline so the output looks like
          // continuous text streaming into the terminal.
          process.stdout.write(evt.text);
          receivedTokens += 1;
          break;
        case 'message_complete':
          finalText = evt.final_text;
          break;
        case 'error':
          throw new Error(`Stream error: ${evt.error}`);
        case 'message_start':
        case 'done':
          // Lifecycle markers; nothing to print.
          break;
      }
    });

    // Newline after the streamed text so the next log line aligns properly.
    process.stdout.write('\n');
    console.log(`\n      Received ${receivedTokens} streamed deltas.`);
    if (finalText) {
      console.log(`      Final text length: ${finalText.length} chars.`);
    }
  } finally {
    // Step 3: cleanup.
    console.log('\n[3/3] Cleanup...');
    if (conversationId) {
      try {
        await deleteConversation(config, conversationId);
        console.log(`      Deleted conversation ${conversationId}`);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        console.error(`      Cleanup failed: ${msg}`);
      }
    }
  }

  console.log('\nSuccess. Stream completed.');
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error(`\nRecipe failed: ${message}`);
  process.exit(1);
});
