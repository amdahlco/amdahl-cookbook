/**
 * Recipe runner.
 *
 * Runs a single recipe by filename with a hard timeout, captures stdout +
 * stderr, and exits with the recipe's exit code. Used by the weekly cron in
 * .github/workflows/recipe-cron.yml. Can also be invoked locally:
 *
 *   npm run run -- recipes/01-hello-world.ts
 *   npx tsx scripts/run-recipe.ts recipes/01-hello-world.ts --timeout 90
 *
 * Behavior on failure: the runner posts a Slack message via SLACK_WEBHOOK_URL
 * if that env var is set. Failures still exit non-zero so the GitHub Actions
 * job is marked failed and the cron's matrix surface shows red.
 */

import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

interface RunnerArgs {
  recipePath: string;
  timeoutSeconds: number;
}

function parseArgs(argv: string[]): RunnerArgs {
  // argv shape: [node, script, recipePath, ...flags]
  // We accept --timeout <seconds> as the only flag.
  const positional: string[] = [];
  let timeoutSeconds = 60;

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--timeout') {
      const next = argv[i + 1];
      if (!next) throw new Error('--timeout requires a value (seconds)');
      const parsed = Number(next);
      if (!Number.isFinite(parsed) || parsed <= 0) {
        throw new Error(`--timeout must be a positive number, got "${next}"`);
      }
      timeoutSeconds = parsed;
      i += 1;
    } else if (arg !== undefined) {
      positional.push(arg);
    }
  }

  const recipePath = positional[0];
  if (!recipePath) {
    throw new Error(
      'Usage: tsx scripts/run-recipe.ts <recipes/NN-name.ts> [--timeout <seconds>]',
    );
  }
  return { recipePath, timeoutSeconds };
}

interface RecipeResult {
  exitCode: number;
  durationMs: number;
  timedOut: boolean;
  stderrTail: string;
}

async function runRecipe(args: RunnerArgs): Promise<RecipeResult> {
  const absPath = resolve(args.recipePath);
  if (!existsSync(absPath)) {
    throw new Error(`Recipe file not found: ${absPath}`);
  }

  const start = Date.now();
  // Buffer the last ~64KB of stderr so we have something to surface on
  // failure without flooding the Slack message.
  const stderrChunks: string[] = [];
  const stderrCap = 64 * 1024;
  let stderrSize = 0;

  const child = spawn('npx', ['tsx', absPath], {
    stdio: ['ignore', 'inherit', 'pipe'],
    env: process.env,
  });

  child.stderr.on('data', (chunk: Buffer) => {
    const text = chunk.toString('utf8');
    process.stderr.write(text);
    stderrChunks.push(text);
    stderrSize += text.length;
    while (stderrSize > stderrCap && stderrChunks.length > 1) {
      const removed = stderrChunks.shift();
      if (removed) stderrSize -= removed.length;
    }
  });

  // Hard timeout. We send SIGTERM, then SIGKILL after a 5s grace.
  let timedOut = false;
  const killTimer = setTimeout(() => {
    timedOut = true;
    child.kill('SIGTERM');
    setTimeout(() => {
      if (!child.killed) child.kill('SIGKILL');
    }, 5_000);
  }, args.timeoutSeconds * 1_000);

  const exitCode = await new Promise<number>((resolvePromise) => {
    child.on('close', (code) => resolvePromise(code ?? -1));
  });
  clearTimeout(killTimer);

  return {
    exitCode,
    durationMs: Date.now() - start,
    timedOut,
    stderrTail: stderrChunks.join('').slice(-stderrCap),
  };
}

async function postToSlack(args: {
  recipePath: string;
  result: RecipeResult;
}): Promise<void> {
  const webhook = process.env.SLACK_WEBHOOK_URL;
  if (!webhook) return;

  const summary = args.result.timedOut
    ? `Recipe timed out: ${args.recipePath} (${args.result.durationMs}ms)`
    : `Recipe failed: ${args.recipePath} (exit ${args.result.exitCode})`;

  const tail = args.result.stderrTail.slice(-1500);
  const text = `:rotating_light: amdahl-cookbook ${summary}\n\n\`\`\`${tail}\`\`\``;

  try {
    await fetch(webhook, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text }),
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`Failed to post to Slack: ${msg}`);
  }
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  console.log(`[runner] Running ${args.recipePath} (timeout ${args.timeoutSeconds}s)`);
  const result = await runRecipe(args);
  console.log(
    `[runner] Done: exit=${result.exitCode} duration=${result.durationMs}ms timedOut=${result.timedOut}`,
  );

  if (result.exitCode !== 0 || result.timedOut) {
    await postToSlack({ recipePath: args.recipePath, result });
    process.exit(result.exitCode === 0 ? 124 : result.exitCode);
  }
}

main().catch((err: unknown) => {
  const msg = err instanceof Error ? err.message : String(err);
  console.error(`[runner] ${msg}`);
  process.exit(1);
});
