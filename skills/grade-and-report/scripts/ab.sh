#!/usr/bin/env bash
# ab.sh - grade two drafts and compare the two grades line by line.
#
# Usage: ab.sh <v1-draft> <v2-draft> <run-dir> [context.json]
#   v1-draft, v2-draft  draft files or request.json files, as grade.sh takes
#   context.json        optional {"facts": [...], "rules": [...]}, sent with BOTH
#
# ## Read this before you trust the delta
#
# These are TWO INDEPENDENT GRADES. Each call reads its own evidence: the
# Optimizer retrieves from the workspace's conversations for that call, and
# nothing pins the second grade to the first one's quotes. So a difference
# between v1 and v2 can come from your edit, from different evidence, or from
# the judge itself, which does not give the same score every time
# (`disclosures.repeat_spread` states how often it moved on a repeat in
# Amdahl's measurement). Send both drafts the same context, so at least that
# input is held fixed.
#
# The score is 1 + 4 x passed/total, so it moves only when a whole line flips.
# That is why this prints which lines changed their verdict, not only the two
# numbers.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

V1="${1:?v1 draft file required}"
V2="${2:?v2 draft file required}"
RUNDIR="${3:?run-dir required}"
CONTEXT="${4:-}"

mkdir -p "$RUNDIR"

for side in v1 v2; do
  if [ "$side" = v1 ]; then SRC="$V1"; else SRC="$V2"; fi
  echo "== $side =="
  REQUEST=$(grade_request_from_file "$SRC" "$CONTEXT")
  printf '%s\n' "$REQUEST" > "$RUNDIR/${side}_request.json"
  if ! grade_draft "$REQUEST" > "$RUNDIR/${side}_grade.json"; then
    echo "$side was not graded - see $RUNDIR/${side}_grade.json" >&2
    exit 1
  fi
  render_grade_card "$RUNDIR/${side}_grade.json" > "$RUNDIR/${side}_report.md"
  echo "  optimize_id=$(jsonpath data.optimize_id < "$RUNDIR/${side}_grade.json")"
done

echo
echo "== A/B: two independent grades =="
python3 - "$RUNDIR/v1_grade.json" "$RUNDIR/v2_grade.json" <<'PY'
import json, sys
g1, g2 = ((json.load(open(p)).get('data') or {}).get('grade') or {} for p in sys.argv[1:3])

def show(g):
    if g.get('score') is None:
        return 'not graded'
    return f'{round(g["score"], 2):g} / 5 ({g.get("passed")} of {g.get("total")} lines)'

print(f'  v1: {show(g1)}')
print(f'  v2: {show(g2)}')

def verdicts(g):
    out = {}
    for ln in g.get('lines') or []:
        out[ln.get('id')] = ('pass' if ln.get('pass') else 'fail') if ln.get('applicable') else 'not graded'
    return out

v1, v2 = verdicts(g1), verdicts(g2)
changed = [(k, v1.get(k, '-'), v2.get(k, '-')) for k in list(dict.fromkeys([*v1, *v2]))
           if v1.get(k) != v2.get(k)]
if changed:
    print('  lines that changed:')
    for k, a, b in changed:
        print(f'    {k}: {a} -> {b}')
else:
    print('  no line changed its verdict, so the two grades are the same fraction.')
if g1.get('total') != g2.get('total'):
    print('  NOTE: the two grades graded a different number of lines, so their'
          ' scores are fractions of different totals.')
print('  Each grade read its own evidence; nothing pinned v2 to v1\'s quotes.')
PY
echo
echo "Saved: $RUNDIR/{v1,v2}_report.md · {v1,v2}_grade.json"
