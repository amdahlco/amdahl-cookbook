# Amdahl skills

Agent skills Amdahl ships for the grading loop. Drop a directory into your
harness's skills path (`.claude/skills/` for Claude Code), and it works as-is.

| Skill                                           | Does                                                        | Hands back                  |
| ----------------------------------------------- | ----------------------------------------------------------- | --------------------------- |
| [`ground-and-draft`](ground-and-draft/SKILL.md) | Pulls customer evidence, freezes it, drafts against it      | A draft for a human to read |
| [`grade-and-report`](grade-and-report/SKILL.md) | Grades a draft with the Message Optimizer, renders the card | The card                    |

They are deliberately two skills, not one. The gap between them is where a
person looks at a draft before it is graded, and where they decide whether they
agree with the verdict. See
[the grading loop](https://docs.amdahl.ai/guides/the-grading-loop).

## Setup

```bash
export AMDAHL_KEY='...'              # Settings, then Developer, Create key
```

Optional: `AMDAHL_API_BASE` (defaults to `https://app.amdahl.ai/api/platform/v1`),
`AMDAHL_EVIDENCE` (defaults to `workspace`), `AMDAHL_POLL_ATTEMPTS`,
`AMDAHL_POLL_INTERVAL`.

`AMDAHL_KEY` is the canonical name. `AMDAHL_API_KEY` and `AMDAHL_MCP_API_KEY`
are accepted as fallbacks, because older setups and MCP client configs already
set them, and keeping two copies of one secret in sync is how they go stale.

Create the key in the console under Settings, then Developer, **Create key**.
Set **Access** to **Customer agent** (the default): grading needs
`messages:execute`, which a Read only key lacks.

## Scripts

```bash
# ground-and-draft
bash ground-and-draft/scripts/ground.sh semantic "their pain" evidence/$(date +%F)-x.json 25

# grade-and-report
bash grade-and-report/scripts/grade.sh  draft.md runs/2026-10-22-launch context.json
bash grade-and-report/scripts/ab.sh     v1.md v2.md runs/ab-hook context.json
bash grade-and-report/scripts/batch.sh  launch-q3.tsv runs/q3 3
bash grade-and-report/scripts/prompt.sh prompt.md runs/prompt-v3 improve extras.json
```

## The three things these encode

The scripts exist because each of these is easy to get wrong from the API alone,
and wrong in a direction that looks like a result.

1. **Report the card, not your summary of it.** The card puts the fraction
   (`passed` of `total` lines) beside the score, says which lines abstained and
   why, and states what one grade can and cannot tell you. A summary in your own
   words is where those drop out. The grade measures the message against your
   evidence and this rubric; it does not predict replies.
2. **An A/B is two independent grades.** Each grade reads its own evidence from
   the workspace's conversations, and nothing pins one grade to the other's
   quotes. `ab.sh` prints the lines that changed their verdict, so you can read
   why the fraction moved before you credit the edit.
3. **One grade is one reading.** An identical request returns the same stored
   grading, so grading a draft again measures nothing. Every grade states in
   `disclosures.repeat_spread` how often this judge's score moved on a repeat in
   Amdahl's measurement, and the card prints it.
