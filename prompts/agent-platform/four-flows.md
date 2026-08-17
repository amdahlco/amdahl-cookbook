# The four shapes of an Amdahl play

**What this does**: Shows the four shapes every Amdahl play takes — automated, interactive, scheduled, ad hoc — and the one contract they all share. Once you see the shape, wiring a new play is picking a trigger and an action around the same middle.

**When to use it**: You're deciding how a GTM job should run, or you're mapping one of your existing plays onto Amdahl. Start here, then drop into the [door recipes](README.md) for the exact calls.

## The one contract

Every flow is the same four beats:

> **TRIGGER → your skill asks → Amdahl answers → your skill does.**

In every one, **your skill asks the question and decides what to do — Amdahl only answers.** The trigger is yours, the instructions are yours, the action is yours. Amdahl sits in the middle and answers the one thing your own tools can't: what your customers actually said, measured against what actually closed. Nothing here is a black box you hand the work to — the agent stays yours.

## The four shapes

| Shape | Trigger | Your skill asks | Amdahl answers | Your skill does |
|---|---|---|---|---|
| **Automated** — Outbound | Clay pushes a new lead | "Worth reaching out to? And what do we say?" | How likely it is to close and what's blocking it; the themes closest to their situation; the customer's exact words | Drafts and sends via HeyReach. Off-persona leads never get drafted |
| **Interactive** — Call prep | A rep opens the account 10 min before the call | "What do we already know about buyers like this one?" | The objections that recur in this segment, what their economic buyer said last time, what unblocked the deals that closed | Writes a one-page brief into Slack |
| **Scheduled** — Monday digest | Cron. Nobody asked for it | "What changed since last week?" | Themes that are new or growing, accounts that moved band and why, where positioning has drifted from what buyers say | Posts the digest |
| **Ad hoc** — Someone asks | In Slack: "why do we keep losing to them?" | "Compare the deals we won against the ones we lost, on what was actually discussed" | Win rate against that rival, and what was covered in the won deals but missing from the lost — over **every** closed deal, not a sample | Answers in the thread, with the calls cited so anyone can check |

Which door each uses: **Automated / Ad hoc** short lookups are the [fast lane](fast-lane-search.md); an **Interactive** investigation is a [Chat](agentic-chat.md); the **Scheduled** one is a [Routine](routines.md) that fires a Chat on cron.

---

## Worked in full: the outbound motion

Outbound is the clearest version of the contract, so it's worth drawing out. **Your tools find the leads and send the emails. Amdahl decides which leads are worth it and what to say to them.** Five steps; Amdahl owns the two in the middle — the two that decide whether the campaign works.

| Step | What it is | Who does it |
|---|---|---|
| 1 | **Find a reason to reach out** | Your lead gen — Trigify, Clay, Common Room. Your competitor buys the same rows. |
| 2 | **Find out who they are** | Enrichment — Clearbit, Apollo, ZoomInfo. Anyone can buy this. |
| 3 | **Decide if they're worth it** | **Amdahl** — scores the account on how likely it is to close and what's blocking it, measured against the deals you've actually won and lost, not a rules list someone typed into a form. |
| 4 | **Write the message** | **Amdahl** — finds the accounts whose conversations were closest to this one, and returns what those buyers asked, which objections came up, and their exact words. |
| 5 | **Send it and track replies** | Your sender — HeyReach, Instantly, Smartlead. It just delivers what Amdahl grounded. |

**Amdahl reads every sales call you've recorded against every deal you've won or lost** — so it knows what actually gets said in the deals that close, and what's missing from the ones that don't. That's steps 3 and 4.

### The agent that runs it

The outbound agent is a skill plus a trigger, calling the shared belt:

- **Trigger** — Clay drops a new row: a person, a company, a reason you noticed them.
- **Instructions** (the skill file you own) — "For every lead: enrich it, then score it. If it doesn't clear the bar, stop — don't draft, don't send. If it does, open with the reason we noticed them, and ground every claim in what our customers actually said. Quote them exactly. Never invent a number."
- **Tool belt** — enrich (ZoomInfo) · **score (Amdahl)** · **ground (Amdahl)** · send (Instantly).
- **The run** — `new row → enrich → score → ground → draft → approve (a human) → send → reply lands back to Amdahl`.

**The gate is the point:** below the bar at `score`, the run stops there. No draft, no send, no tokens spent on an account that was never going to close. Off-persona leads never get drafted at all.

### Why this shape holds

- **Nothing gets replaced.** Keep your lead source. Keep your sender. Amdahl answers the two questions those tools can't, over one API.
- **What it needs.** Call recordings and a CRM connection. Most teams already have both — the recordings are sitting in Gong or Fireflies, unread after the deal closes.
- **Why no vendor sells this.** Steps 1, 2, and 5 run on data anyone can buy, so any vendor can sell them. Steps 3 and 4 run on **your** calls and **your** deals, so the answer is different for every company — there's nothing to package and resell.
- **It gets sharper on its own.** Replies come back in, so reply rate by segment tells Amdahl which accounts were actually worth it and which messages landed. Steps 3 and 4 improve without anyone editing a prompt.

**The same shape works for renewals, expansion, ABM, and lifecycle** — only the vendors in the outer boxes change. The middle two steps — decide, and ground in customer voice — are always Amdahl.

## How each flow maps to the tools

- **Score / "worth it" / "what's blocking it"** — the deal close-likelihood + binding-constraint read: ask the [fast lane](fast-lane-search.md) (`search.run` writes and runs the deal-qualification query for you — the warehouse reads are internal machinery behind the door, not tools you call).
- **Ground / "closest conversations" / "exact words"** — theme + verbatim retrieval: [semantic search](semantic-search.md) for the nearest accounts and the exact words, or a [Chat](agentic-chat.md) when it needs synthesis (the Master runs the clustering + who-said-what reads internally).
- **"What changed"** — new/growing themes + accounts that moved band + positioning drift (a [Routine](routines.md) whose fired Chat runs the trend + divergence reads).
- **"Won vs lost, over every closed deal, not a sample"** — an aggregate over the full corpus, not top-k retrieval. This is the join that makes the answer trustworthy; see [why hand-rolled context breaks](gtm-brain-architecture.md#why-the-hand-rolled-version-breaks).

## See also

- [Amdahl is one layer of your GTM brain](gtm-brain-architecture.md) — the shared-belt mental model these flows sit on.
- [Call prep + objection handling, end to end](call-prep-objection-end-to-end.md) — the Interactive flow, fully worked over REST + MCP.
- [Voice of customer, end to end](voice-of-customer-end-to-end.md) — the Ad hoc / Scheduled shape and the fast → Chat handoff.
- The GTM prompt versions: [outbound targeting by signal](../content-and-outbound/outbound-targeting-by-signal.md), [sales call prep](../pre-meeting-prep/sales-call-prep.md), [weekly recap](../pipeline-pulse/weekly-recap.md), [why we lost this deal](../win-loss-deal-postmortem/why-we-lost-this-deal.md).
