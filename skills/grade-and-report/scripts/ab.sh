#!/usr/bin/env bash
# ab.sh - fair A/B of two drafts against the SAME frozen evidence.
#
# Usage: ab.sh <v1-draft> <v2-draft> <run-dir> [audience] [account]
#
# Grades v1 fresh, then grades v2 PINNED to v1's evidence, then reports the
# delta between the two SUBMITTED drafts.
#
# ## Read this before changing which number it prints
#
# The obvious number to A/B on is `compare.score_delta`, and it is the wrong
# one. It differences `overall_score`, whose meaning changed at `eval_version`
# 2.13.0. Before that it was a mean over graders judging TWO DIFFERENT artifacts
# - a hygiene check on your text, and the blinded judge's read of the REWRITE -
# so a delta between two of them was mostly rewrite-versus-rewrite: on a live
# pinned pair whose true draft delta was -0.8 (2.6 -> 1.8), it reported -0.167.
# From 2.13.0 the field reports the submitted side, so a delta between two NEW
# runs is right - but a pair that SPANS the version differences two different
# quantities, and the compare endpoint does not check versions.
#
# The submitted draft's own grade is `report.headline.submitted.score_15`, which
# is what this compares. `evidence_overlap` from the compare endpoint is still
# worth reading and still correct - it tells you whether the pin held - so it is
# reported too, just never as the score delta.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

V1="${1:?v1 draft file required}"
V2="${2:?v2 draft file required}"
RUNDIR="${3:?run-dir required}"
AUDIENCE="${4:-}"
ACCOUNT="${5:-}"
SLUG="${AMDAHL_EVAL_SLUG:-prompt-and-message-eval}"

mkdir -p "$RUNDIR"

echo "== v1 (fresh - this run's evidence becomes the pin) =="
ID1=$(submit_run "$(inputs_from_file "$V1" "$AUDIENCE" "$ACCOUNT")" "$SLUG")
echo "v1 run_id=$ID1"
poll_run "$ID1" > /dev/null
api_get "eval-runs/$ID1" > "$RUNDIR/v1_scorecard.json"
report_markdown "$ID1" > "$RUNDIR/v1_report.md"

echo "== v2 (pinned to v1's evidence) =="
ID2=$(submit_run "$(inputs_from_file "$V2" "$AUDIENCE" "$ACCOUNT")" "$SLUG" "$ID1")
echo "v2 run_id=$ID2"
poll_run "$ID2" > /dev/null
api_get "eval-runs/$ID2" > "$RUNDIR/v2_scorecard.json"
report_markdown "$ID2" > "$RUNDIR/v2_report.md"

api_get "eval-runs/$ID1/compare/$ID2" > "$RUNDIR/compare.json"
printf '%s %s\n' "$ID1" "$ID2" > "$RUNDIR/run_ids.txt"

B1=$(report_field "$ID1" submitted.score_15)
B2=$(report_field "$ID2" submitted.score_15)
C1=$(report_field "$ID1" submitted.checks.passed)
C2=$(report_field "$ID2" submitted.checks.passed)
TOTAL=$(report_field "$ID1" submitted.checks.total)
OVERLAP=$(jsonpath data.comparison.evidence_overlap < "$RUNDIR/compare.json")

echo
echo "== A/B on the SUBMITTED drafts =="
python3 - "$B1" "$B2" "$C1" "$C2" "$TOTAL" <<'PY'
import sys
b1,b2,c1,c2,total = sys.argv[1:6]
def num(x):
    try: return float(x)
    except (TypeError, ValueError): return None
n1,n2 = num(b1),num(b2)
print(f"  v1 draft: {b1 or 'not graded'} / 5" + (f"  ({c1} of {total} checks)" if c1 else ""))
print(f"  v2 draft: {b2 or 'not graded'} / 5" + (f"  ({c2} of {total} checks)" if c2 else ""))
if n1 is None or n2 is None:
    print("  delta: unavailable - one side was not graded")
else:
    print(f"  delta: {round(n2-n1,3):+}")
# The fraction is the measurement; the 1-5 figure is its rendering. With five
# binary checks the dial has six positions, so an edit that does not flip a
# whole check is invisible in the number even when it genuinely improved things.
if c1 and c2 and c1 == c2:
    print(f"  NOTE: both drafts passed the same {c1} checks - this delta reflects no"
          " flipped check, so treat it as noise, not a measured improvement.")
PY
echo "  evidence_overlap: ${OVERLAP:-unavailable}"
echo
echo "Saved: $RUNDIR/{v1,v2}_report.md · {v1,v2}_scorecard.json · compare.json"
