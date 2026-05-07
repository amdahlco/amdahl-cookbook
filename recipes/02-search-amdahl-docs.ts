/**
 * Recipe 02 — Search Amdahl docs via MCP
 *
 * What it shows:
 *   How to call the public Amdahl MCP server's `search` action to find
 *   relevant documentation pages. No auth required. Useful for AI agents
 *   that need to ground answers about Amdahl in real docs content.
 *
 * Prerequisites:
 *   - Node 20+
 *   - `npm install` at the repo root
 *
 * Expected runtime: ~3 seconds.
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

const QUERY = process.argv[2] ?? 'how do I create a session in Amdahl'
const TOP_K = 5

async function main(): Promise<void> {
  console.log(`Query: "${QUERY}"\n`)

  const transport = new StreamableHTTPClientTransport(new URL(PUBLIC_MCP_URL))
  const client = new Client({
    name: 'amdahl-cookbook-02',
    version: '1.0.0',
  })

  try {
    await client.connect(transport)

    const result = await client.callTool({
      name: 'search',
      arguments: { query: QUERY, top_k: TOP_K },
    })

    // The MCP server returns the search hits in result.content as a single
    // text block with JSON. Parse and pretty-print.
    const textBlock = result.content?.find((c) => c.type === 'text')
    if (!textBlock || textBlock.type !== 'text') {
      console.error('Unexpected response shape from search:', result)
      process.exit(1)
    }

    const hits = JSON.parse(textBlock.text) as Array<{
      title: string
      url: string
      excerpt: string
      score: number
    }>

    console.log(`Top ${hits.length} hit${hits.length === 1 ? '' : 's'}:\n`)
    for (const [i, hit] of hits.entries()) {
      console.log(`${i + 1}. ${hit.title}`)
      console.log(`   ${hit.url}`)
      console.log(`   score: ${hit.score.toFixed(3)}`)
      console.log(`   ${hit.excerpt.slice(0, 160)}${hit.excerpt.length > 160 ? '...' : ''}`)
      console.log()
    }

    console.log('Done.')
  } finally {
    await client.close()
  }
}

main().catch((err) => {
  console.error('Recipe failed:', err)
  process.exit(1)
})
