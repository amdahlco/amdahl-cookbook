#!/usr/bin/env bash
# repeat.sh - grade one draft N times and report the MEDIAN, not one reading.
#
# Usage: repeat.sh <draft-file> <run-dir> [N] [audience] [account]
#   N   number of fresh grades to take (default 5)
#
# ## Why this exists
#
# One run is not a measurement. A single fingerprinted draft graded 15 times on
# BYTE-IDENTICAL input spanned `overall_score` 0.0 to 1.0 (sd 0.244) and produced
# all four transitions. That was measured BEFORE 2.14.0, so the field it spans is
# the pre-repoint blend rather than the submitted side - the noise is real and is
# why this script exists, but it is not a spread on your own draft's grade.
# Across 18 repeat groups the submitted draft's pass/fail flipped 22% of the time
# and the transition changed 33% of the time.
#
# The mechanism is not sloppiness, it is quantization: five binary rubric lines
# put `score_15` on six positions {1.0, 1.8, 2.6, 3.4, 4.2, 5.0} with the bar at
# 4.2, so ONE dimension flipping flips the whole verdict. Greedy decoding does
# not remove it - a two-arm measurement at temperature 0 versus 1.0 found the
# noise floor identical - because the variance lives in rubric lines that are
# vacuously true or false of the same draft, not in sampling.
#
# Vintage: these figures were measured on the superseded 4.x-series judge and
# before #2291 made evidence draws deterministic, so they describe the historical
# instrument, not the current one.
#
# So: take the median of N, drop degenerate runs, and read the pass RATE rather
# than a pass/fail. Anything you would act on should survive that.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

DRAFT="${1:?draft file required}"
RUNDIR="${2:?run-dir required}"
N="${3:-5}"
AUDIENCE="${4:-}"
ACCOUNT="${5:-}"
SLUG="${AMDAHL_EVAL_SLUG:-prompt-and-message-eval}"

mkdir -p "$RUNDIR"
INPUTS=$(inputs_from_file "$DRAFT" "$AUDIENCE" "$ACCOUNT")
SAMPLES="$RUNDIR/samples.jsonl"
: > "$SAMPLES"

echo "sampling $(basename "$DRAFT") x$N ..."
for i in $(seq 1 "$N"); do
  echo "== sample $i/$N =="
  # Every attempt appends EXACTLY ONE line, so the tally below counts what
  # happened instead of inferring it from how many lines are missing. The three
  # ways a sample can fail to yield a grade are different facts: an
  # infrastructure fault is not the same as a run that completed and produced no
  # gradable comparison, and neither is a low score. None of them may be scored
  # as a zero - that would drag the median down with a non-measurement.
  if ! RID=$(submit_run "$INPUTS" "$SLUG"); then
    echo '{"_drop":"submit_failed"}' >> "$SAMPLES"
    continue
  fi
  if ! STATUS=$(poll_run "$RID"); then
    echo '{"_drop":"never_settled"}' >> "$SAMPLES"
    continue
  fi
  if [ "$STATUS" != "complete" ]; then
    echo "{\"_drop\":\"finished_$STATUS\"}" >> "$SAMPLES"
    continue
  fi
  # Fetched separately from the parse because `api_get` now RETURNS NON-ZERO on a
  # hard failure (circuit open, or retries exhausted), and under `set -e` an
  # inline `api_get | jsonpath` would abort the whole N-sample loop instead of
  # costing this one sample.
  if ! REPORT=$(api_get "eval-runs/$RID/report"); then
    echo '{"_drop":"report_fetch_failed"}' >> "$SAMPLES"
    continue
  fi
  # A null headline means the run completed but produced no before/after (an
  # abstain, or a grader mix with no improvement report). `jsonpath` prints
  # nothing for a null, so the fallback keeps the one-line-per-sample invariant.
  HEADLINE=$(printf '%s' "$REPORT" | jsonpath data.report.headline)
  if [ -z "$HEADLINE" ]; then HEADLINE='{"_drop":"no_comparison"}'; fi
  echo "$HEADLINE" >> "$SAMPLES"
done

echo
python3 - "$SAMPLES" "$N" <<'PY'
import json, statistics as st, sys
from collections import Counter

graded, dropped = [], Counter()
for line in open(sys.argv[1]):
    line = line.strip()
    if not line:
        continue
    try:
        h = json.loads(line)
    except json.JSONDecodeError:
        dropped['unparseable'] += 1
        continue
    if not isinstance(h, dict) or h.get('_drop'):
        dropped[(h or {}).get('_drop', 'unparseable')] += 1
    elif (h.get('submitted') or {}).get('score_15') is None:
        dropped['no_comparison'] += 1
    else:
        graded.append(h)

requested = int(sys.argv[2])
detail = ', '.join(f'{k}={v}' for k, v in sorted(dropped.items()))
if not graded:
    print(f"0 of {requested} samples produced a grade ({detail or 'no samples'}) - nothing to report")
    raise SystemExit(1)

def med(vals):
    return round(st.median(vals), 2) if vals else None

sub = [g['submitted']['score_15'] for g in graded]
imp = [g['improved']['score_15'] for g in graded if (g.get('improved') or {}).get('score_15') is not None]
checks = [c for c in ((g['submitted'].get('checks') or {}).get('passed') for g in graded) if c is not None]
# The submitted side's verdict is RECORDED on the transition (`pass_to_*` means
# the submitted draft cleared the bar). Read it rather than re-deriving it from
# score-versus-threshold: the recorded verdict is what every other surface
# reports, and a second derivation is a second thing that can disagree.
verdicts = [g['transition'] for g in graded if g.get('transition')]
passed = sum(1 for t in verdicts if t.startswith('pass_'))

print(f"n_graded={len(graded)}  n_dropped={sum(dropped.values())}  (of {requested} requested)"
      + (f"  [{detail}]" if detail else ""))
print(f"  submitted score_15 : median {med(sub)}  range {min(sub)}-{max(sub)}"
      + (f"  sd {round(st.pstdev(sub), 3)}" if len(sub) > 1 else ""))
if checks:
    # A check count is an integer; "median 2.0 checks" reads as a fractional
    # check, which is not a thing this instrument can produce.
    m = med(checks)
    print(f"  submitted checks   : median {int(m) if m == int(m) else m}  "
          f"range {min(checks)}-{max(checks)}")
if imp:
    print(f"  improved score_15  : median {med(imp)}  range {min(imp)}-{max(imp)}")
if verdicts:
    print(f"  submitted pass RATE: {round(passed / len(verdicts), 2)} ({passed}/{len(verdicts)})")
if len(set(sub)) > 1 or len(set(verdicts)) > 1:
    print("  NOTE: the same draft did not grade the same way twice. Report the median"
          " and the range - a single reading from this set would have been misleading.")
PY

echo
echo "Saved: $SAMPLES (one line per attempt - a headline, or why it was dropped)"
