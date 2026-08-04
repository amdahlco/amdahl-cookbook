# Amdahl skills

Agent skills Amdahl ships for the grading loop. Drop a directory into your
harness's skills path (`.claude/skills/` for Claude Code), and it works as-is.

| Skill                                           | Does                                                   | Hands back                  |
| ----------------------------------------------- | ------------------------------------------------------ | --------------------------- |
| [`ground-and-draft`](ground-and-draft/SKILL.md) | Pulls customer evidence, freezes it, drafts against it | A draft for a human to read |
| [`grade-and-report`](grade-and-report/SKILL.md) | Submits to Eval, polls, renders the report card        | The scorecard               |

They are deliberately two skills, not one. The gap between them is where a
person looks at a draft before it is graded, and where they decide whether they
agree with the verdict. See
[the grading loop](https://docs.amdahl.ai/guides/the-grading-loop).

## Setup

```bash
export AMDAHL_API_KEY='...'          # Settings → API keys in the console
```

Optional: `AMDAHL_API_BASE` (defaults to `https://app.amdahl.ai/api/platform/v1`),
`AMDAHL_POLL_ATTEMPTS`, `AMDAHL_POLL_INTERVAL`.

`AMDAHL_MCP_API_KEY` is accepted as a fallback, because an MCP client config
already sets it and keeping two copies of one secret in sync is how they go
stale.

## Scripts

```bash
# ground-and-draft
bash ground-and-draft/scripts/ground.sh semantic "their pain" evidence/$(date +%F)-x.json 25

# grade-and-report
bash grade-and-report/scripts/grade.sh  draft.md runs/2026-08-03-launch "" "VP of Marketing"
bash grade-and-report/scripts/ab.sh     v1.md v2.md runs/ab-hook "VP of Marketing"
bash grade-and-report/scripts/repeat.sh draft.md runs/noise-check 5
```

## The three things these encode

The scripts exist because each of these is easy to get wrong from the API alone,
and wrong in a direction that looks like a result.

1. **Report the card, not your summary of it.** `GET /eval-runs/{id}/report`
   returns finished markdown. The eval grades your draft _and_ a rewrite it
   produced, and the headline score mostly follows the rewrite — so a summary
   written in your own words is where those merge into a claim your numbers do
   not support.
2. **A/B on the submitted side.** `compare.score_delta` is
   rewrite-versus-rewrite. On a live pinned pair whose true draft delta was
   −0.8, it reported −0.167. `ab.sh` reads
   `report.headline.submitted.score_15` on each side.
3. **One run is not a measurement.** The same draft graded 15 times on identical
   input spanned 0.0 → 1.0 and produced all four transitions. `repeat.sh` takes
   a median of N and drops degenerate runs.
