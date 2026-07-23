# Embed a live page

**What this does**: Has Claude draft a **Page** spec over your live tenant data, which you create in the console — then mint a **self-scoped embed link** for it there: a signed, short-lived URL you can drop into an iframe so the page renders live (refreshing on every load) inside another site or app, not just in the console.

**When to use it**: "I built a pipeline-health page (or a win-rate gauge, or a voice-of-customer dashboard) and I want it living on our internal wiki / a Notion page / an ops portal — live, not a screenshot." Anything where the dashboard needs to be seen outside the Amdahl console without copy-pasting a stale image.

## Why this matters

A Page in your console is great for the team that logs into Amdahl. But the people who most need to see "how's pipeline this week" are often somewhere else — a wiki, an internal portal, a Slack-linked doc. A screenshot goes stale the moment you take it; a link into the console asks them to log in.

A **live embed** solves both. The page renders in an iframe over your real data, refreshing every time the host page loads, and it carries a **signed, short-lived token** that scopes it to exactly one page and one data slice. Crucially, it **fails closed**: a missing, invalid, expired, or empty-scope token shows **nothing** — never a fallback to your full tenant data. There's no "open it up and lock it down later" hole; the safe state is the default state.

The mint is also **clamped to whoever asks**. When Claude (or you) mints a `self` embed, it can only ever be scoped to what that principal already sees. So you can let the agent hand you back an embed link with confidence — it cannot widen the audience or the data slice past your own access. Going **public** (anyone with the link) or **workspace-wide** is a deliberate, admin-gated step — the same trust decision as publishing — so it never happens by accident.

## Paste this into Claude

Page authoring + embed minting are **console capabilities** (the `pages` MCP tool was retired, and the endpoints behind the console aren't reachable with an external API key). Claude drafts the spec; you create the page and mint the embed in the console.

```
First, draft me an Amdahl Page spec for {what the page should show — e.g.
"pipeline health by stage" or "win rate as a gauge"}. The console's Pages
surface ships vetted templates (pipeline health, voice of customer, win-rate
gauge, funnel, and more) — if one obviously fits, base the spec on that shape;
otherwise author the catalog spec + declared queries from scratch. Hand me the
finished spec JSON in one block.

Then walk me through publishing and embedding it in the console:

1. Pages -> New page: paste the spec, run Validate, fix anything it flags with
   me, then Create.
2. From the created page, mint a LIVE embed with audience "self" — a link
   scoped to what *I* can already see. Tell me NOT to mint a "public" or
   "workspace" embed; those tiers are admin-gated and I don't want to widen
   access by accident.
3. A sensible ttl (an hour is fine for a test), data scope inherited from my
   own access (no custom rules).
4. Show me the ready-to-paste iframe shape for the embed_url the console
   returns:
   <iframe src="{embed_url}" style="width:100%;border:0" loading="lazy"></iframe>

Remind me of two things in your reply: (1) the embed fails closed — if the token
is missing/expired/invalid it shows nothing, never my full data — and (2) if I
later want this visible to external viewers (a public link) or to the whole
workspace, an admin has to mint that tier.
```

## What you'll see back

- The drafted spec: the component tree (or the template shape it adapted) plus the declared queries, ready to paste into the console.
- The console walkthrough: create the page (Validate, then Create), then mint the embed from the created page — the console hands back `{ token, expires_at, embed_url }`, where the `embed_url` already carries the signed token.
- A **paste-ready iframe shape** to wrap that `embed_url` in.
- A short reminder that the embed is `self`-scoped, fails closed, and that public/workspace embeds are admin-gated.

## How to actually use it

1. **Build and verify the page first, embed second.** The embed is a wrapper around a page that already works — open the console URL once to confirm it renders right before you put it on your wiki.
2. **Paste the iframe where you want it live.** Drop the `<iframe>` snippet into your wiki, portal, or any HTML host. It renders over your live data and refreshes on each load — no screenshot to maintain.
3. **Watch the expiry.** A `self` test embed is short-lived by design. When it stops rendering, re-mint to get a fresh `embed_url` (same page, new token).
4. **Lock the embed to your host site.** For anything beyond a quick test, set an `origins` allowlist when minting (the site that's allowed to frame it) so the link only works where you intend.
5. **To kill every live embed at once, rotate the secret.** The per-tenant **embedding secret** (Settings) signs all your embed tokens; rotating it **immediately revokes every outstanding embed** for the workspace. It's the one-click "pull everything down" lever — re-mint afterward to bring the ones you still want back.

## Variations

- **Public / external embed (admin).** To put the page on a customer-facing site or a public status page, an **admin** mints with `audience: "public"` (and almost always an `origins` allowlist). Same mint flow, admin-gated tier — if you're not an admin, an admin has to do it in the console.
- **Workspace embed.** For a page every teammate should see embedded in an internal tool, an admin mints `audience: "workspace"` — visible to any member, still scoped to the data slice on the token.
- **Tighter data scope than your own.** Set explicit `rules` at mint time to scope the embed to a narrower slice than the principal sees (e.g. one region's pipeline) — the render never widens past it.
- **Embed a single-viz page.** Pages with `layout: "single"` (a gauge, a funnel, a treemap) embed beautifully as a compact widget — build one, then embed it the same way. See the [create-a-page command](../../plugins/amdahl-gtm/commands/create-page.md) for the single layout.

## Tips

- **Fail-closed is the whole point — don't fight it.** If an embed shows nothing, the token is missing, expired, or scoped to an empty slice. That's the safe behavior, not a bug; re-mint or widen the (admin-gated) audience deliberately.
- **`self` for tests, admin tiers for sharing.** A self-scoped embed is the right first move — it can't over-share. Promote to `workspace` / `public` only when you actually mean to, through an admin.
- **A mint can't out-scope the minter.** The mint is clamped to the principal, so a `self` embed is only ever scoped to what you can already see. Audience-widening to public stays admin-gated regardless of who asks.
- **Rotate the secret = revoke everything.** Keep that in your back pocket: one secret rotation in Settings invalidates every live embed across the workspace at once.
- **Pair it with a page recipe.** This recipe is the embed step; the page itself comes from [build a markdown report page](markdown-report-page.md) (for a document) or the dashboard/single-viz flows in the [create-a-page command](../../plugins/amdahl-gtm/commands/create-page.md).

## See also

- [Create a page (command)](../../plugins/amdahl-gtm/commands/create-page.md) — the full Pages contract: the catalog, the three layouts, data bindings, the validate → create loop, and the **Embedding a live page** section (the authoritative reference for the mint flow, the audience gate, and secret rotation).
- [Build a markdown report page](markdown-report-page.md) — publish a written deliverable as a `document`-layout Page; embed it the same way.
- Product docs: <https://docs.amdahl.co>.
