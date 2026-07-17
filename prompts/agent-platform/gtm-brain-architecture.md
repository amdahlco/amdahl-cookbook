# Amdahl is one layer of your GTM brain

**What this does**: Gives you the mental model for where Amdahl sits in a GTM agent stack — so you wire it once, as a layer, instead of bolting it onto each agent. It's the "how to think about it" doc that the [door recipes](README.md) plug into.

**When to use it**: Before you build. If you already have a folder of skills, something like Clay firing triggers, and MCP servers pointed at Gong and the CRM, this explains which layer Amdahl is and why that shape holds as you add agents.

## You're already building the brain

A GTM "brain" isn't one agent. It's three things:

- **Skills** — files in a folder (`skills/outbound.md`, `call-prep.md`, `win-loss.md`, `monday-digest.md`). One per play, plain markdown, reviewed like code. **You own these.**
- **Agents** — a skill plus a trigger. The outbound agent is `outbound.md` woken by Clay; call-prep is `call-prep.md` woken by the calendar; the digest is `monday-digest.md` woken by cron. **You own these too.**
- **A shared tool belt** — the MCP servers every agent can call. ZoomInfo to enrich, Instantly to send, your CRM to write back, and **Amdahl** to score / ground / tell you what changed.

Amdahl is one server on the third layer. You wire it once, and every agent on the belt has it — `score` and `ground` aren't the outbound agent's tools, they're the belt's, so call-prep and win/loss already have them. The fifth agent you write next month inherits the belt on day one. **That's the whole reason it's a layer and not an integration.**

## Why the hand-rolled version breaks

Most teams first build the context themselves — RAG over transcripts, keyword search, some ETL + SQL, manual review. It works until it doesn't, and where it breaks is structural, not a skill issue:

- **Retrieval isn't aggregation.** Top-k hands back ten chunks. "What do buyers keep objecting to?" needs all 4,000 calls, grouped. That's a different operation.
- **Chunks are context-free.** A slice of transcript doesn't carry the account, the stage, or whether the rep or the buyer was talking.
- **You can quote a deal you lost — but nothing knows you lost it.** The vector store has the words; the CRM has the outcome; nothing joined them.
- **Ask twice, get two answers.** Change k, the chunker, or the day, and retrieval shifts. Every agent walks its own path to its own conclusion.
- **Re-embedding is nobody's job.** It's accurate the week you build it. Nothing in the diagram owns keeping it that way.

None of that is fixable with a better prompt. It's the shape: the agent is improvising a data platform at request time.

## What Amdahl moves

Same shape, moved: the data platform now runs **upstream, on a schedule**, instead of inside a context window at request time. Ingest → store → compute → serve:

- **Embed and cluster the whole corpus** (compute). All your calls, grouped by what was actually discussed. The aggregate is precomputed, so asking for it is a read.
- **Every utterance keeps its context** (store). Account, deal, stage, and who was speaking travel with the words; entity resolution stitches them across sources.
- **Joined to won and lost** (store). Ask for what got said in the deals that closed, and that's what comes back. This join is the product.
- **Computed once, upstream** (serve). The answer is already made when the agent asks. Five agents asking the same question get the same answer.
- **Re-runs as calls land** (ingest). Freshness is the platform's job — nobody on your side owns a re-embed script, and nothing silently rots.

## The reference architecture

Top to bottom, where each layer lives:

| Layer | What it is | Who owns it |
|---|---|---|
| **Execution** | Send it, write it back, publish it | Your vendors (HeyReach, Instantly, Outreach, your CRM) |
| **Orchestration** | Which play runs, when, for whom | You build (subagents, Clay, n8n, cron) |
| **Skills** | Your repeatable plays, written down | You build (`skills/`, prompt files) |
| **Context** | What your customers said, what closed, and where the two disagree | **Amdahl** — themes, verbatim quotes, close-likelihood, divergence |
| **Unification** | One account, stitched across every system | **Amdahl** — entity resolution, normalization |
| **Sources** | The raw material, already flowing | You already have (Gong, Fireflies, Salesforce, HubSpot, Slack, email) |

Amdahl is the **Context + Unification** layers — one MCP server — reading your sources **read-only** (it never writes to your systems of record). And the loop closes upward: outcomes return to the context layer, not to your skills — so what closed last quarter changes what gets said next quarter without anyone editing a prompt.

## What this means for the recipes

Every recipe in this section is you calling that context layer from your own agent. The [fast lane](fast-lane-search.md) and [Chat](agentic-chat.md) are the two ways to ask it; [routines](routines.md) and [saved agents](saved-agents.md) are how a play repeats. The [four flows](four-flows.md) show the four shapes those plays take. In all of them the agent stays yours — Amdahl answers; your skill decides what to do with the answer.

## See also

- [The four shapes of an Amdahl play](four-flows.md) — automated / interactive / scheduled / ad hoc, and the one contract they share.
- [Agent platform overview](README.md) — the two doors, the flag prerequisite, the scope table.
- The nothing-new-to-buy point: your sources are already flowing, and replies land back in them, so the loop closes without a new pipe.
