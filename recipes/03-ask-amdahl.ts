/**
 * Recipe 03 — Ask Amdahl a natural-language question
 *
 * What it shows:
 *   How to call the public MCP server's `ask` action. Unlike `search`
 *   (which returns ranked excerpts), `ask` runs a Claude-grounded RAG
 *   pipeline against the docs corpus and returns a synthesized answer
 *   with citations. This is what powers the Cmd+K Ask AI tab on
 *   docs.amdahl.co.
 *
 * Prerequisites:
 *   - Node 20+
 *   - `npm install` at the repo root
 *
 * Expected runtime: ~5-15 seconds (LLM synthesis).
 *
 * What gets created / cleaned up: nothing. Read-only.
 *
 * verified: 2026-05-06
 */

import 'dotenv/config'
import { Client } from '@modelcontextprotocol/sdk/client/index.js'
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js'

const PUBLIC_MCP_URL =
  process.env.AMDAHL_MCP_PUBLIC_URL ?? 'https://app.amdahl.co/mcp/public'

const QUESTION =
  process.argv[2] ?? 'What scopes does an MCP customer-agent key need to publish artifacts?'

async function main(): Promise<void> {
  console.log(`Question: ${QUESTION}\n`)

  const transport = new StreamableHTTPClientTransport(new URL(PUBLIC_MCP_URL))
  const client = new Client({
    name: 'amdahl-cookbook-03',
    version: '1.0.0',
  })

  try {
    await client.connect(transport)

    console.log('Asking...\n')
    const result = await client.callTool({
      name: 'ask',
      arguments: { query: QUESTION },
    })

    const textBlock = result.content?.find((c) => c.type === 'text')
    if (!textBlock || textBlock.type !== 'text') {
      console.error('Unexpected response shape from ask:', result)
      process.exit(1)
    }

    const response = JSON.parse(textBlock.text) as {
      answer: string
      citations: Array<{ title: string; url: string }>
    }

    console.log('Answer:\n')
    console.log(response.answer)

    if (response.citations.length > 0) {
      console.log('\nCitations:')
      for (const c of response.citations) {
        console.log(`  - ${c.title}: ${c.url}`)
      }
    }

    console.log('\nDone.')
  } finally {
    await client.close()
  }
}

main().catch((err) => {
  console.error('Recipe failed:', err)
  process.exit(1)
})
