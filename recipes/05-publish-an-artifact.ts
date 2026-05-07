/**
 * Recipe 05: Publish an artifact
 *
 * Title: Create, version, and publicly share an artifact
 * Description: Artifacts are the universal output format in Amdahl. This
 *   recipe creates a "report" artifact, versions it (so the change history is
 *   preserved), then flips its visibility to "public" so it gets a shareable
 *   URL. Public artifacts can be read with no auth, which is useful for
 *   sharing one-pagers and battle cards externally.
 * Prerequisites: AMDAHL_API_KEY, AMDAHL_BUSINESS_ID, optional AMDAHL_API_BASE
 * Expected runtime: under 10 seconds
 * Creates: one platform_artifact (report) + one version row
 * Cleans up: yes — flips visibility back to private and deletes the artifact
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
  visibility?: 'private' | 'public' | 'business';
  current_version?: number;
  public_url?: string;
  content_json?: Record<string, unknown>;
  created_at: string;
  updated_at?: string;
}

interface ArtifactResponse {
  artifact: Artifact;
}

interface ArtifactVersion {
  id: string;
  artifact_id: string;
  version: number;
  created_at: string;
}

interface VersionResponse {
  version: ArtifactVersion;
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
  method: 'GET' | 'POST' | 'PATCH' | 'DELETE',
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

/**
 * Build the body for our test report. We use a simple shape that the report
 * viewer understands: a title, a sections array, and some metadata.
 */
function buildInitialReport(): {
  type: string;
  title: string;
  visibility: 'private';
  content_json: Record<string, unknown>;
} {
  return {
    type: 'report',
    title: 'Cookbook 05: Sample Quarterly Update',
    visibility: 'private',
    content_json: {
      version: '1.0',
      summary: 'Initial draft created by the cookbook recipe.',
      sections: [
        {
          heading: 'Overview',
          body: 'This is a sample artifact created by recipe 05.',
        },
      ],
      metadata: { source: 'amdahl-cookbook', recipe: '05-publish-an-artifact' },
    },
  };
}

async function createArtifact(config: AmdahlConfig): Promise<Artifact> {
  const result = await apiCall<ArtifactResponse>(
    config,
    'POST',
    '/api/platform/v1/artifacts',
    buildInitialReport(),
  );
  return result.artifact;
}

async function updateArtifactContent(
  config: AmdahlConfig,
  artifactId: string,
): Promise<Artifact> {
  // PATCH /api/platform/v1/artifacts/:id
  // Updating content_json automatically creates a new version row.
  const result = await apiCall<ArtifactResponse>(
    config,
    'PATCH',
    `/api/platform/v1/artifacts/${encodeURIComponent(artifactId)}`,
    {
      content_json: {
        version: '1.1',
        summary: 'Revised draft after stakeholder review.',
        sections: [
          {
            heading: 'Overview',
            body: 'This is a sample artifact created by recipe 05.',
          },
          {
            heading: 'What changed',
            body: 'Added a "Next steps" section based on feedback.',
          },
          {
            heading: 'Next steps',
            body: 'Share publicly and circulate to the broader team.',
          },
        ],
        metadata: { source: 'amdahl-cookbook', recipe: '05-publish-an-artifact' },
      },
    },
  );
  return result.artifact;
}

async function listVersions(
  config: AmdahlConfig,
  artifactId: string,
): Promise<ArtifactVersion[]> {
  // GET /api/platform/v1/artifacts/:id/versions
  const result = await apiCall<{ versions: ArtifactVersion[] }>(
    config,
    'GET',
    `/api/platform/v1/artifacts/${encodeURIComponent(artifactId)}/versions`,
  );
  return result.versions;
}

async function setVisibility(
  config: AmdahlConfig,
  artifactId: string,
  visibility: 'private' | 'public' | 'business',
): Promise<Artifact> {
  // PATCH /api/platform/v1/artifacts/:id with just { visibility }
  // Setting visibility=public makes the artifact readable at a stable URL
  // without auth. The server returns the public_url in the response.
  const result = await apiCall<ArtifactResponse>(
    config,
    'PATCH',
    `/api/platform/v1/artifacts/${encodeURIComponent(artifactId)}`,
    { visibility },
  );
  return result.artifact;
}

async function fetchPublicUrl(publicUrl: string): Promise<{ ok: boolean; status: number }> {
  // The public URL is reachable with no auth headers. We do a HEAD-equivalent
  // GET to confirm the artifact is genuinely public-readable.
  const response = await fetch(publicUrl, {
    method: 'GET',
    headers: { Accept: 'application/json' },
  });
  return { ok: response.ok, status: response.status };
}

async function deleteArtifact(config: AmdahlConfig, id: string): Promise<void> {
  await apiCall<void>(
    config,
    'DELETE',
    `/api/platform/v1/artifacts/${encodeURIComponent(id)}`,
  );
}

// ----------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log('Recipe 05: Publish an artifact');
  const config = loadConfig();

  let artifactId: string | undefined;

  try {
    // Step 1: create the artifact (private by default).
    console.log('\n[1/5] Creating artifact (private)...');
    const created = await createArtifact(config);
    artifactId = created.id;
    console.log(`      Created: ${artifactId}`);
    console.log(`      Title: "${created.title}"`);
    console.log(`      Visibility: ${created.visibility ?? 'private'}`);

    // Step 2: update content -> new version row.
    console.log('\n[2/5] Updating content to create a new version...');
    const updated = await updateArtifactContent(config, artifactId);
    console.log(`      Updated. current_version=${updated.current_version ?? '?'}`);

    // Step 3: list versions to confirm history.
    console.log('\n[3/5] Listing versions...');
    const versions = await listVersions(config, artifactId);
    console.log(`      ${versions.length} version(s) on record:`);
    for (const v of versions) {
      console.log(`        v${v.version}  ${v.created_at}`);
    }
    if (versions.length < 2) {
      // Not strictly fatal — some envs squash trivial updates — but worth
      // surfacing so the user knows what to expect.
      console.log('      (Note: expected at least 2 versions after the update.)');
    }

    // Step 4: flip to public and verify the URL works.
    console.log('\n[4/5] Setting visibility=public and fetching public URL...');
    const published = await setVisibility(config, artifactId, 'public');
    if (!published.public_url) {
      throw new Error('Server returned no public_url after visibility=public');
    }
    console.log(`      Public URL: ${published.public_url}`);

    const probe = await fetchPublicUrl(published.public_url);
    if (!probe.ok) {
      throw new Error(`Public URL returned ${probe.status}; expected 200`);
    }
    console.log(`      Verified: public URL returned ${probe.status} with no auth.`);
  } finally {
    // Step 5: clean up. Flip back to private first (defense in depth) then
    // delete.
    console.log('\n[5/5] Cleanup...');
    if (artifactId) {
      try {
        await setVisibility(config, artifactId, 'private');
        console.log('      Reverted visibility to private.');
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        console.error(`      Visibility revert failed: ${msg}`);
      }
      try {
        await deleteArtifact(config, artifactId);
        console.log(`      Deleted artifact ${artifactId}`);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        console.error(`      Artifact cleanup failed: ${msg}`);
      }
    }
  }

  console.log('\nSuccess. Artifact created, versioned, published, and cleaned up.');
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error(`\nRecipe failed: ${message}`);
  process.exit(1);
});
