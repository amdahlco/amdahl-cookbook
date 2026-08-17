# Amdahl Cookbook

**Turn Claude into your GTM intelligence team. No code.**

Generic Claude reads the public internet. Connect Amdahl, and Claude can also read *your* CRM and *your* call transcripts — what buyers actually said, which objections actually surfaced, which competitors actually showed up late in your deals. The interesting signal is the **divergence** between the public story and your internal story. That's the moat. This cookbook is a copy-paste library that turns that moat into answers.

---

## What you can do with it

Six questions you'll be able to answer the minute you finish setup. Each one links to the full recipe.

- "Why did we lose Acme — what actually happened, not the dropdown reason?" → [why we lost this deal](prompts/win-loss-deal-postmortem/why-we-lost-this-deal.md)
- "What do buyers actually say about {competitor} on our calls, and is that shifting?" → [where they show up in our calls](prompts/competitive-intel/where-they-show-up-in-our-calls.md)
- "Prep me for the QBR with Mercury — recap, risks, the next thing to sell." → [QBR prep](prompts/pre-meeting-prep/qbr-prep.md)
- "Which deals look healthy on paper but are quietly dying?" → [deals at risk](prompts/pipeline-pulse/deals-at-risk.md)
- "Rewrite our value narrative in customer voice, segment by segment." → [rebuild your value narrative by segment](prompts/positioning-messaging/rebuild-value-narrative-by-segment.md)
- "Find 25 outbound targets that look like our best closed-won deals — and tell me what filters to stop using." → [outbound targeting by signal](prompts/content-and-outbound/outbound-targeting-by-signal.md)

---

## Connect in the Claude UI — no key needed

Claude signs in to your workspace over OAuth. Works in the Claude web app and Claude Desktop — both expose Settings → Connectors.

1. Open Claude and go to **Settings → Connectors** (direct link: <https://claude.ai/customize/connectors>).
2. Click **Add custom connector**.
3. Name it **Amdahl** and set the URL to `https://app.amdahl.ai/mcp`.
4. Click **Connect**, then **Configure**.
5. Sign in to Amdahl when prompted, then choose this workspace.

<!-- TODO: screenshot of the connector-add UI here -->
<!-- TODO: screenshot of the OAuth approval -->

If you don't have an Amdahl account yet, start at <https://amdahl.ai>.

## Setup — Claude Code (1 line)

For the technical folks. Same OAuth flow, but from your terminal:

```
claude mcp add --transport http amdahl "https://app.amdahl.ai/mcp"
```

The first time you call an Amdahl tool, the OAuth approval opens in your browser. After that it stays connected.

### Or install the plugin (one-click, adds slash commands)

Prefer guided plays over remembering prompts? Install the **amdahl-gtm** plugin — it auto-connects the same `amdahl` MCP server *and* adds a set of `/amdahl-gtm:*` slash commands (account deep-dive, competitor intel, meeting prep, win-loss, positioning, grounded drafts, pipeline pulse), each wired to the recipes below.

```
claude plugin marketplace add amdahlco/amdahl-cookbook && claude plugin install amdahl-gtm@amdahl-cookbook
```

(Already inside a Claude Code session? Use the slash form: `/plugin marketplace add amdahlco/amdahl-cookbook` then `/plugin install amdahl-gtm@amdahl-cookbook`.)

Then run `/amdahl-gtm:setup` to confirm the connection, or jump straight to `/amdahl-gtm:company stripe.com`. The plugin lives in [`plugins/amdahl-gtm/`](plugins/amdahl-gtm/) — the recipes in this cookbook are its source material, so anything a command does, you can also do by pasting the matching recipe.

---

## Try these now

Six prompts you can paste straight into Claude after setup. Swap the `{placeholders}` for your own values.

### 1. Deep-dive on an account before you call them

```
Pull everything we know about {company name or domain}. Combine our internal history — past deals, support history, who we've talked to, what they said on calls — with what's happening publicly right now (funding, hiring, product launches, leadership changes). Give me a 1-page brief: where they are in their buying journey, the 3 things they care about most, the 2 risks I should know about, and a recommended next step.
```

### 2. Find out who really beat us — and why

```
Look at every closed-lost deal in the last 6 months where the reason was "went with a competitor." Tell me which competitors actually won, what those buyers said on calls about why they chose them, and the 3 most common reasons we lost. Use verbatim quotes from the calls wherever possible.
```

### 3. Prep for tomorrow's meeting

```
I have a meeting with {company name} tomorrow. Pull our full history with them — who's been on the calls, what's been said, what's open, what's stalled — and combine it with anything publicly relevant. Give me a 1-page prep doc: who's attending and what they care about, the last 3 things they said that matter, any open objections, and a recommended agenda.
```

### 4. Audit your homepage against how customers actually talk

```
Here's the hero copy from our homepage:

"""
{paste your homepage hero copy here}
"""

Compare it to how our actual customers describe us on calls. Where does it match? Where does it diverge? Where are we using internal jargon that buyers never use? Give me 3 specific rewrites that pull language directly from customer quotes.
```

### 5. Spot deals that are quietly dying

```
Show me the deals in our pipeline that look healthy on paper but are at risk based on call activity, sentiment, or unanswered objections. For each one: deal name, stage, last meaningful touch, the specific signal that worries you, and what the rep should do this week.
```

### 6. Write a LinkedIn post that sounds like us

```
Draft a LinkedIn post about {topic}. Ground it in real customer language from our calls — pull at least one verbatim phrase (anonymized) that captures what buyers actually say about this. Match our brand voice. Keep it under 150 words, no emoji, no hashtags.
```

---

## How recipes are organized

The cookbook is organized around the seven GTM jobs people actually run — not by tool, channel, or team. Pick the job, find the recipe.

- **Customer research** — know an account before you walk in.
- **Competitive intel** — public posture vs. how buyers actually describe them.
- **Positioning & messaging** — pressure-test copy against the language your customers actually use.
- **Pre-meeting prep** — walk in knowing the room.
- **Win/loss & deal postmortem** — real reasons, not dropdown reasons.
- **Content & outbound** — grounded posts, smarter targeting, less generic outreach.
- **Pipeline pulse** — weekly health, risk, triage.

## Browse the cookbook

26 recipes, organized by the seven jobs.

| Category | What's in it | Recipes |
|---|---|---|
| [Customer research](prompts/customer-research/) | Know an account before you walk in | 4 |
| [Competitive intel](prompts/competitive-intel/) | Public posture vs. how buyers actually describe them | 4 |
| [Positioning & messaging](prompts/positioning-messaging/) | Pressure-test copy against customer language | 4 |
| [Pre-meeting prep](prompts/pre-meeting-prep/) | Sales calls, QBRs, renewals | 3 |
| [Win/loss & deal postmortem](prompts/win-loss-deal-postmortem/) | Real reasons, not dropdown reasons | 3 |
| [Content & outbound](prompts/content-and-outbound/) | Grounded posts, targeted outreach | 4 |
| [Pipeline pulse](prompts/pipeline-pulse/) | Weekly health, risk, triage, fast lookups | 4 |

The full index lives at [prompts/README.md](prompts/README.md).

---

## Make it recur (Routines) or build your own recipes (blueprints)

The recipes above are paste-ready prompts. When you want work to repeat *inside Amdahl* — without you pasting anything — there are two paths in:

- **Routines** — the MCP-native way to schedule work. A Routine is a cron that fires a **Chat** (one server-side Master agent turn, in a fresh Session) each occurrence. From any connected Claude session, ask for a standing refresh ("every Monday, refresh the pipeline health report") and Claude creates it with the `agents` tool's `create_routine` action — a name, a prompt, and a cron. No DSL required, and each fire shows up as its own Session you can open and read.
- **Workflows (blueprints)** — the fully-typed path: a **blueprint** is a typed recipe with declared inputs, outputs, and a validated step graph that the platform can version, fork, schedule, and run headlessly. Authoring and running Workflows is a **console capability** (the Workflows surface; the `blueprints` MCP tool was retired, and the endpoints behind the console aren't reachable with an external API key). It's a different thing from a cookbook prompt; the guide opens by untangling the two.

> **Surface note:** the agent platform (the `search` + `agents` MCP tools) is on **every** workspace — the per-workspace rollout flag it once sat behind is retired, so there is no capability check to make and no `feature_disabled` error to handle. The `blueprints` and `pages` MCP tools were retired with it; Workflows and Pages are console surfaces now.


- [How to write an Amdahl blueprint](prompts/blueprints/authoring-a-blueprint.md) — the mental model, the DSL anatomy, validating in the console, and two worked examples (one from scratch, one fork-and-customize).

If you've installed the plugin, the `blueprint-authoring` skill routes "make this recur" asks to Routines and composes the Workflow DSL with you, handing off to the console's Workflows surface for the create -> validate -> fork -> iterate loop.

---

## Grade what you write (agent skills)

Two ready-to-drop agent skills for the grading loop — write, ground, draft,
grade, fix, rerun. Copy a directory into your harness's skills path
(`.claude/skills/` for Claude Code), set `AMDAHL_API_KEY`, and it works as-is.

| Skill                                                    | Does                                                   | Hands back                  |
| -------------------------------------------------------- | ------------------------------------------------------ | --------------------------- |
| [`ground-and-draft`](skills/ground-and-draft/SKILL.md)   | Pulls customer evidence, freezes it, drafts against it | A draft for a human to read |
| [`grade-and-report`](skills/grade-and-report/SKILL.md)   | Submits to Eval, polls, renders the report card        | The scorecard               |

They are deliberately two skills, not one: the gap between them is where a
person looks at a draft before it is graded. The full walkthrough is
[the grading loop](https://docs.amdahl.ai/guides/the-grading-loop); the
directory index is [skills/](skills/).

---

## Build it into your own product (API + MCP)

Everything above runs on two "ask Amdahl" doors, and you can drive both from your own code — over the REST API and over MCP — not just by pasting prompts. The [agent-platform section](prompts/agent-platform/README.md) is the developer-facing walkthrough, with copy-paste REST + MCP request/response shapes for each door.

- **The mental model** — where Amdahl sits in a GTM agent stack: one layer on your [shared MCP belt](prompts/agent-platform/gtm-brain-architecture.md), and the [four shapes](prompts/agent-platform/four-flows.md) every play takes (your skill asks, Amdahl answers, your skill acts).

- **Fast lane (`search.query`, mode `fuzzy`)** — one synchronous call that returns the rows *and* the SQL it ran. For "get me the number." [Recipe](prompts/agent-platform/fast-lane-search.md).
- **The endpoints** — synchronous primitives beside the doors: [structured search](prompts/agent-platform/structured-search.md) (typed filters + `group_by`/`metrics` over a discoverable field catalog), and [semantic search](prompts/agent-platform/semantic-search.md) (meaning over the call corpus — also how you find "more accounts like this one").
- **Agentic Chat** — the always-async Master agent: start, get handles, poll or stream for the cited answer, respond to a pause. For "investigate this." [Recipe](prompts/agent-platform/agentic-chat.md).
- **Routines & saved agents** — put a Chat on a cron, or save a reusable agent and pin it. [Routines](prompts/agent-platform/routines.md) · [Saved agents](prompts/agent-platform/saved-agents.md).
- **Evals** — grade a drafted message against how your customers actually talk: pass in the message, poll the run, read the scorecard (verdict + per-dimension grades, the customer quotes that support or contradict it, and a grounded rewrite). Or author your own eval. [Recipe](prompts/agent-platform/evals.md). Then close the loop: report whether the recommendation was applied, and roll adoption up across runs. [Feedback loop](prompts/agent-platform/evals-feedback-loop.md).
- **Rendering the answer** — the seven content-block types and the `amdahl:q` / `amdahl:cite` link grammar, for showing a Chat result in your own UI. [Recipe](prompts/agent-platform/answer-envelope.md).
- **End-to-end use cases** — full journeys over both surfaces: [voice of customer](prompts/agent-platform/voice-of-customer-end-to-end.md) (teaches the fast -> Chat handoff), [call prep + objection handling](prompts/agent-platform/call-prep-objection-end-to-end.md), and [the expansion motion](prompts/agent-platform/expansion-motion-end-to-end.md) (read your best win's own language, then semantic-search the corpus for the accounts that sound like it).

Available on every workspace: the `search` + `agents` MCP tools, or `POST /search/query` and `POST /chat` on REST.

---

## Push results to your team (notifications)

The recipes above end in the chat. When the output should reach a teammate who isn't watching the session — the deal owner, your manager, RevOps — email it to them. Amdahl's notifications primitive is members-only (a non-member rejects the whole send), rate-capped, and idempotent, so an agent can deliver autonomously without becoming a spam cannon. You drive it through the agent: put the send in a Chat's input, or grant it on a Routine via `actions_allowed`.

- [Notify the workspace team](prompts/notifications/notify-the-workspace-team.md) — the **discover -> send -> verify** discipline (resolve recipients from the member list, send with an idempotency key, then confirm delivery), the guardrail contract, and the unattended Routine + Workflow paths.

---

## Mirror your knowledge base to Notion (knowledge sync)

Your team lives in Notion but your canonical reference library — competitive briefs, positioning memos, the research your agents keep producing — lives in Amdahl. Mirror it: connect Notion once, pick a parent page, and every document you promote in Amdahl shows up (and stays current) in a Notion database your whole team can read. One-way, current-version-only, self-healing on an hourly reconcile — it runs server-side with no open session required.

- [Mirror your knowledge base to Notion](prompts/knowledge-sync/mirror-knowledge-base-to-notion.md) — the **connect -> configure -> it-syncs-itself -> monitor** loop. Setup and monitoring live in the console (Connections); agents feed it — a doc a Chat or Routine lands in the knowledge base (`write_outputs`) mirrors to Notion the moment you promote it.

---

## By your role

**Sales leader**
- [Why we lost this deal](prompts/win-loss-deal-postmortem/why-we-lost-this-deal.md) — the honest postmortem on a deal that just closed-lost.
- [Deals at risk](prompts/pipeline-pulse/deals-at-risk.md) — pipeline that looks healthy but isn't.
- [What separates won from lost](prompts/win-loss-deal-postmortem/what-separates-won-from-lost.md) — the discriminators between deals that closed and ones that didn't.

**Marketing leader**
- [Rebuild your value narrative by segment](prompts/positioning-messaging/rebuild-value-narrative-by-segment.md) — raw customer voice per ICP segment, with anti-contamination filters.
- [Audit our positioning](prompts/positioning-messaging/audit-our-positioning.md) — your copy vs. how customers actually describe you.
- [Find content gaps](prompts/content-and-outbound/find-content-gaps.md) — questions buyers keep asking that your content doesn't answer.

**RevOps**
- [Pattern across cohort](prompts/win-loss-deal-postmortem/pattern-across-cohort.md) — common threads across a group of deals.
- [Weekly recap](prompts/pipeline-pulse/weekly-recap.md) — what moved, what stalled, what to watch.
- [Stalled pipeline triage](prompts/pipeline-pulse/stalled-pipeline-triage.md) — chase / nurture / close-lost, with the honest reasons.

**Founder**
- [Deep-dive on account](prompts/customer-research/deep-dive-on-account.md) — fused public + internal view of one company.
- [Stress-test a message](prompts/positioning-messaging/stress-test-a-message.md) — sanity-check copy before it ships.
- [Whose name comes up](prompts/customer-research/whose-name-comes-up.md) — the shadow champions, blockers, and incumbents hiding in your transcripts.

---

## Help & docs

- Product docs: <https://docs.amdahl.ai>
- Home: <https://amdahl.ai>
- Support: hello@amdahl.ai

<details>
<summary>What's actually happening under the hood?</summary>

Amdahl exposes its customer-intelligence platform through MCP — the Model Context Protocol — which is the standard way modern AI clients (like Claude.ai and Claude Code) plug into outside data sources. When you add the connector, Claude gets a private, authenticated link to your Amdahl workspace: your CRM history, your call transcripts, your context entries. Your prompts are still prompts; Amdahl just gives Claude the *grounding* it needs to answer with your reality instead of the generic internet's. Nothing leaves your workspace unless you ask Claude to share it.

</details>

---

## License

MIT
