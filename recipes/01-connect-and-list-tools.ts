/**
 * Recipe 01 — Connect and list tools
 *
 * What it shows:
 *   The minimal MCP client setup. Connects to the public Amdahl MCP server
 *   (no auth) and prints every tool the server exposes. This is the
 *   "hello world" of the MCP client SDK — verifies your environment can
 *   reach Amdahl over Streamable HTTP and speak the protocol.
 *
 * Prerequisites:
 *   - Node 20+
 *   - `npm install` at the repo root (pulls @modelcontextprotocol/sdk)
 *   - No env vars required for the public server. Optionally set
 *     AMDAHL_MCP_PUBLIC_URL to override the default endpoint.
 *
 * Expected runtime: ~2 seconds.
 *
 * What gets created / cleaned up: nothing. Read-only smoke test.
 *
 * verified: 2026-05-06
 */

import 'dotenv/config'
import { Client } from '@modelcontextprotocol/sdk/client/index.js'
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js'

const PUBLIC_MCP_URL =
  process.env.AMDAHL_MCP_PUBLIC_URL ?? 'https://app.amdahl.co/mcp/public'

async function main(): Promise<void> {
  console.log(`Connecting to ${PUBLIC_MCP_URL}...`)

  const transport = new StreamableHTTPClientTransport(new URL(PUBLIC_MCP_URL))
  const client = new Client({
    name: 'amdahl-cookbook-01',
    version: '1.0.0',
  })

  try {
    await client.connect(transport)
    console.log('Connected.\n')

    const { tools } = await client.listTools()

    console.log(`Server exposes ${tools.length} tool${tools.length === 1 ? '' : 's'}:\n`)
    for (const tool of tools) {
      console.log(`  ${tool.name}`)
      if (tool.description) {
        console.log(`    ${tool.description.split('\n')[0]}`)
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
