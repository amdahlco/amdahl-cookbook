#!/usr/bin/env bash
# ground.sh - run a Search query over your corpus and FREEZE the result.
#
# Usage: ground.sh <mode> <query> <out.json> [limit] [filters-json]
#   mode         semantic | fuzzy | filter | auto
#                semantic = vector similarity. Fast, and the right default for
#                grounding. The fuzzy/NL lane has a ~15s ceiling and returns
#                status=failed on broad asks - narrow the question or use semantic.
#   query        the plain-language question
#   out.json     where to write the frozen evidence. Pick a DATED name; never
#                overwrite an existing one.
#   limit        default 25 (ceiling 1000)
#   filters-json a JSON array of {"field","op","value"} predicates, scoping the
#                pull the same way you will scope the grade.
#
# SCOPE THE PULL THE WAY THE GRADE WILL BE SCOPED. `grade-and-report` passes
# `audience` / `account` to evals.run, which scopes what the judge retrieves. If
# the pull you drafted from was corpus-wide, you drafted against one population
# and are graded against another.
#
#   # buyer-side only - the default worth having on every pull
#   ground.sh semantic "release approval friction" evidence/2026-08-03.json 25 \
#     '[{"field":"speaker_type","op":"eq","value":"external"}]'
#
#   # a WARM account: their own words
#   ground.sh semantic "..." evidence/x.json 25 \
#     '[{"field":"company_id","op":"eq","value":"<company_id>"}]'
#
# The SEMANTIC lane admits only `company_id` (eq|in), `occurred_at`
# (gte|gt|lte|lt|between) and `speaker_type` (eq); it refuses anything else with
# `invalid_argument` and names what it supports. Audience predicates
# (`role_level`, `speaker_title`, `inferred_persona`, `industry`, ...) need
# `mode filter`, which returns rows by predicate rather than by similarity - a
# complementary second pull, not a replacement. `GET /search/fields` lists the
# full vocabulary per surface.
#
# Freezing is the point. A second search returns different quotes, so any change
# you measure later could be your edit or could be retrieval. Pull once, write it
# to a file, feed that same file to every attempt.
set -euo pipefail

MODE="${1:?mode required}"
QUERY="${2:?query required}"
OUT="${3:?out.json required}"
LIMIT="${4:-25}"
FILTERS="${5:-}"

AMDAHL_API_BASE="${AMDAHL_API_BASE:-https://app.amdahl.ai/api/platform/v1}"
AMDAHL_KEY="${AMDAHL_API_KEY:-${AMDAHL_MCP_API_KEY:-}}"
if [ -z "$AMDAHL_KEY" ]; then
  echo "ERROR: set AMDAHL_API_KEY to your workspace API key." >&2
  echo "  export AMDAHL_API_KEY='...'   # Settings -> API keys in the console" >&2
  exit 1
fi

if [ -e "$OUT" ]; then
  echo "ERROR: $OUT already exists. Evidence files are frozen - use a new dated name." >&2
  exit 1
fi

# Build the body in python so a query containing quotes cannot break out of the
# shell string. A malformed filters argument fails HERE, before a request is
# spent, and says so.
BODY=$(python3 -c "
import json,sys
b={'mode':sys.argv[1],'query':sys.argv[2],'limit':int(sys.argv[3])}
raw=sys.argv[4]
if raw:
    try: f=json.loads(raw)
    except Exception as e: sys.exit(f'ERROR: filters is not valid JSON ({e})')
    if not isinstance(f,list): sys.exit('ERROR: filters must be a JSON ARRAY of {field,op,value}')
    b['filters']=f
print(json.dumps(b))
" "$MODE" "$QUERY" "$LIMIT" "$FILTERS")

for attempt in 1 2 3 4; do
  RESP=$(curl -s --max-time 40 -X POST "$AMDAHL_API_BASE/search/query" \
    -H "Authorization: Bearer $AMDAHL_KEY" -H "Content-Type: application/json" \
    -d "$BODY" || true)
  # REST nests the payload under {"data":{...}}; MCP returns it at top level.
  OK=$(printf '%s' "$RESP" | python3 -c "
import sys,json
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
print(bool((d.get('data') or d).get('success')))
" 2>/dev/null || echo "")
  [ "$OK" = "True" ] && break
  # A rejected request is deterministic - retrying it four times only spends 18
  # seconds arriving at the same answer. Surface it now, with the server's own
  # message, which for a filter the semantic lane does not admit names the ones
  # it does.
  CODE=$(printf '%s' "$RESP" | python3 -c "
import sys,json
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
print(((d.get('data') or d).get('error') or d.get('error') or {}).get('code',''))
" 2>/dev/null || echo "")
  if [ "$CODE" = "invalid_argument" ] || [ "$CODE" = "forbidden" ] || [ "$CODE" = "unauthorized" ] || [ "$CODE" = "feature_disabled" ]; then
    echo "ERROR: search refused ($CODE): $RESP" >&2
    exit 1
  fi
  echo "search attempt $attempt failed, retrying..." >&2
  sleep $((attempt * 3))
done

if [ "${OK:-}" != "True" ]; then
  echo "ERROR: search failed. Last response: ${RESP:-<none>}" >&2
  exit 1
fi

# Write the UNWRAPPED payload, so an evidence file has one shape whether it came
# from REST or MCP.
printf '%s' "$RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
json.dump(d.get('data',d), open(sys.argv[1],'w'), indent=1)
" "$OUT"

python3 - "$OUT" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
results = d.get('results', [])
detail = d.get('detail') or {}
print(f"mode_ran={d.get('mode_ran')} rows={len(results)}")
internal = detail.get('internal') or {}
if internal.get('status'):
    print(f"  internal status: {internal['status']} | {internal.get('note','')}")
# speaker_type matters: corpus retrieval does not filter on speaker, so a chunk
# of any pull is your own team talking, not a customer. Grounding a claim about
# what buyers want in your own rep's words is the quiet failure here.
sides = {}
for r in results:
    sides[r.get('speaker_type', 'unknown')] = sides.get(r.get('speaker_type', 'unknown'), 0) + 1
if sides:
    print(f"  speakers: {sides}")
for r in results[:8]:
    text = r.get('content_preview') or r.get('content') or ''
    print(f"  [{r.get('speaker_type','?')}] {text[:120]}")
print(f"(froze evidence -> {sys.argv[1]})")
PY
