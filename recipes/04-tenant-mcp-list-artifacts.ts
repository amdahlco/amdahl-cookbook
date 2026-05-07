/**
 * Recipe 04 — Connect to the tenant MCP and list your artifacts
 *
 * What it shows:
 *   How to connect to the AUTHENTICATED tenant MCP at
 *   https://app.amdahl.co/mcp using an API key. Lists your business's
 *   artifacts via the MCP `read_resource` meta-tool addressing
 *   `artifact://list`. This is the entry point for any tenant-scoped
 *   workflow — every other tool call uses the same auth pattern.
 *
 * Prerequisites:
 *   - Node 20+
 *   - `npm install` at the repo root
 *   - AMDAHL_API_KEY in your environment (an MCP key with at least
 *     `mcp_read_only` scope bundle). Generate one in the Amdahl Console
 *     under Team Settings → MCP Keys.
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

const TENANT_MCP_URL = process.env.AMDAHL_MCP_URL ?? 'https://app.amdahl.co/mcp'
const API_KEY = process.env.AMDAHL_API_KEY

if (!API_KEY) {
  console.error('AMDAHL_API_KEY env var is required for this recipe.')
  console.error('Generate one in the Amdahl Console under Team Settings → MCP Keys.')
  process.exit(1)
}

async function main(): Promise<void> {
  console.log(`Connecting to tenant MCP at ${TENANT_MCP_URL}...`)

  const transport = new StreamableHTTPClientTransport(new URL(TENANT_MCP_URL), {
    requestInit: {
      headers: {
        'X-API-Key': API_KEY!,
      },
    },
  })

  const client = new Client({
    name: 'amdahl-cookbook-04',
    version: '1.0.0',
  })

  try {
    await client.connect(transport)
    console.log('Connected.\n')

    // Read the artifact list resource. The tenant MCP routes resources
    // through a single `read_resource` meta-tool that takes a URI.
    const resource = await client.readResource({
      uri: 'artifact://list?limit=10',
    })

    const textContent = resource.contents.find((c) => 'text' in c) as
      | { text: string }
      | undefined

    if (!textContent) {
      console.error('Unexpected response from artifact://list:', resource)
      process.exit(1)
    }

    const artifacts = JSON.parse(textContent.text) as Array<{
      id: string
      artifact_type: string
      name?: string
      created_at: string
    }>

    if (artifacts.length === 0) {
      console.log('No artifacts found in this business yet.')
      return
    }

    console.log(`Found ${artifacts.length} artifact${artifacts.length === 1 ? '' : 's'}:\n`)
    for (const a of artifacts) {
      console.log(`  ${a.artifact_type.padEnd(24)} ${a.id}`)
      if (a.name) console.log(`    ${a.name}`)
      console.log(`    created: ${a.created_at}`)
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
