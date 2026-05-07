/**
 * Recipe 05 — Give Claude access to Amdahl via MCP
 *
 * What it shows:
 *   How to wire the Anthropic Messages API to the Amdahl MCP server so
 *   Claude can call Amdahl tools as it reasons. This is the canonical
 *   pattern for "build an agent on top of Amdahl" — your code orchestrates
 *   the message loop, Claude picks tools, the MCP client dispatches them.
 *
 *   Uses the public docs MCP (no auth) to keep the recipe self-contained.
 *   Swap the URL + add the X-API-Key header to use the tenant MCP for
 *   real workflows.
 *
 * Prerequisites:
 *   - Node 20+
 *   - `npm install` at the repo root
 *   - ANTHROPIC_API_KEY in your environment
 *
 * Expected runtime: ~10-30 seconds (multi-turn loop).
 *
 * What gets created / cleaned up: nothing. Read-only.
 *
 * verified: 2026-05-06
 */

import 'dotenv/config'
import Anthropic from '@anthropic-ai/sdk'
import { Client } from '@modelcontextprotocol/sdk/client/index.js'
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js'

const PUBLIC_MCP_URL =
  process.env.AMDAHL_MCP_PUBLIC_URL ?? 'https://app.amdahl.co/mcp/public'
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY
const MODEL = process.env.ANTHROPIC_MODEL ?? 'claude-sonnet-4-6'

if (!ANTHROPIC_API_KEY) {
  console.error('ANTHROPIC_API_KEY env var is required for this recipe.')
  process.exit(1)
}

const USER_QUESTION =
  process.argv[2] ??
  'I am building an agent on top of Amdahl. What MCP tools are available and what would I use each for?'

async function main(): Promise<void> {
  // 1. Connect to the Amdahl MCP server
  const transport = new StreamableHTTPClientTransport(new URL(PUBLIC_MCP_URL))
  const mcpClient = new Client({
    name: 'amdahl-cookbook-05',
    version: '1.0.0',
  })
  await mcpClient.connect(transport)

  // 2. Discover the tools the server exposes and translate them into the
  //    Anthropic tool-use schema. This is a one-time mapping per session.
  const { tools: mcpTools } = await mcpClient.listTools()
  const anthropicTools = mcpTools.map((t) => ({
    name: t.name,
    description: t.description ?? '',
    input_schema: t.inputSchema as Anthropic.Tool.InputSchema,
  }))

  console.log(`Discovered ${anthropicTools.length} MCP tool(s) on ${PUBLIC_MCP_URL}.\n`)

  const anthropic = new Anthropic({ apiKey: ANTHROPIC_API_KEY })

  // 3. Run the message loop. Claude picks tools, we dispatch them via the
  //    MCP client, feed the results back, repeat until Claude is done.
  const messages: Anthropic.MessageParam[] = [
    { role: 'user', content: USER_QUESTION },
  ]

  for (let turn = 0; turn < 6; turn++) {
    console.log(`Turn ${turn + 1}: asking Claude...`)
    const response = await anthropic.messages.create({
      model: MODEL,
      max_tokens: 2048,
      tools: anthropicTools,
      messages,
    })

    // Add Claude's response to the conversation.
    messages.push({ role: 'assistant', content: response.content })

    if (response.stop_reason === 'end_turn') {
      // Print final answer.
      const text = response.content
        .filter((b): b is Anthropic.TextBlock => b.type === 'text')
        .map((b) => b.text)
        .join('\n')
      console.log('\nFinal answer:\n')
      console.log(text)
      break
    }

    if (response.stop_reason === 'tool_use') {
      // Dispatch each tool_use block to the MCP server.
      const toolResults: Anthropic.ToolResultBlockParam[] = []
      for (const block of response.content) {
        if (block.type !== 'tool_use') continue
        console.log(`  → calling ${block.name}(${JSON.stringify(block.input).slice(0, 80)}...)`)
        try {
          const result = await mcpClient.callTool({
            name: block.name,
            arguments: block.input as Record<string, unknown>,
          })
          const text = result.content
            ?.filter((c) => c.type === 'text')
            .map((c) => (c as { text: string }).text)
            .join('\n')
          toolResults.push({
            type: 'tool_result',
            tool_use_id: block.id,
            content: text ?? '',
          })
        } catch (err) {
          toolResults.push({
            type: 'tool_result',
            tool_use_id: block.id,
            content: `Tool error: ${err instanceof Error ? err.message : String(err)}`,
            is_error: true,
          })
        }
      }
      messages.push({ role: 'user', content: toolResults })
      continue
    }

    console.log(`Unexpected stop_reason: ${response.stop_reason}. Bailing.`)
    break
  }

  await mcpClient.close()
  console.log('\nDone.')
}

main().catch((err) => {
  console.error('Recipe failed:', err)
  process.exit(1)
})
