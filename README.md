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
3. Name it **Amdahl** and set the URL to `https://app.amdahl.co/mcp`.
4. Click **Connect**, then **Configure**.
5. Sign in to Amdahl when prompted, then choose this workspace.

<!-- TODO: screenshot of the connector-add UI here -->
<!-- TODO: screenshot of the OAuth approval -->

If you don't have an Amdahl account yet, start at <https://amdahl.co>.

## Setup — Claude Code (1 line)

For the technical folks. Same OAuth flow, but from your terminal:

```
claude mcp add --transport http amdahl "https://app.amdahl.co/mcp"
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

24 recipes, organized by the seven jobs.

| Category | What's in it | Recipes |
|---|---|---|
| [Customer research](prompts/customer-research/) | Know an account before you walk in | 4 |
| [Competitive intel](prompts/competitive-intel/) | Public posture vs. how buyers actually describe them | 3 |
| [Positioning & messaging](prompts/positioning-messaging/) | Pressure-test copy against customer language | 4 |
| [Pre-meeting prep](prompts/pre-meeting-prep/) | Sales calls, QBRs, renewals | 3 |
| [Win/loss & deal postmortem](prompts/win-loss-deal-postmortem/) | Real reasons, not dropdown reasons | 3 |
| [Content & outbound](prompts/content-and-outbound/) | Grounded posts, targeted outreach | 4 |
| [Pipeline pulse](prompts/pipeline-pulse/) | Weekly health, risk, triage | 3 |

The full index lives at [prompts/README.md](prompts/README.md).

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

- Product docs: <https://amdahl.co/mcp>
- Home: <https://amdahl.co>
- Support: hello@amdahl.co

<details>
<summary>What's actually happening under the hood?</summary>

Amdahl exposes its customer-intelligence platform through MCP — the Model Context Protocol — which is the standard way modern AI clients (like Claude.ai and Claude Code) plug into outside data sources. When you add the connector, Claude gets a private, authenticated link to your Amdahl workspace: your CRM history, your call transcripts, your context entries. Your prompts are still prompts; Amdahl just gives Claude the *grounding* it needs to answer with your reality instead of the generic internet's. Nothing leaves your workspace unless you ask Claude to share it.

</details>

---

## License

MIT
