#!/usr/bin/env bash
# The cards a person reads, rendered as markdown from a saved response.
#
# There is no server-rendered report any more, so these build the card from the
# response's own fields and nothing else. They hold the rules a reader relies
# on: the score is printed with the fraction it is (passed of total) beside it,
# a line that abstained says so and is never shown as a fail, a null score is
# "not graded" and never 0, only notes for the `sender` are shown, and every
# card says the grade does not predict replies.
#
# Sourced by _lib.sh. Needs only python3.

# render_grade_card <response-file> - the card a person reads, as markdown.
#
# Built only from the response's own fields. The score is printed with the
# fraction it is (passed of total) beside it, and a line that abstained says
# so: it is out of both sides of the fraction, never a fail.
render_grade_card() {
  python3 - "$1" <<'PY'
import json, sys
d = (json.load(open(sys.argv[1])) or {}).get('data') or {}
g = d.get('grade') or {}

def cell(s):
    return ' '.join(str(s or '').split()).replace('|', '\\|')

def num(x):
    return f'{round(x, 2):g}'

out = []
score, passed, total = g.get('score'), g.get('passed'), g.get('total')
if score is None:
    why = g.get('not_applicable_reason') or 'no line could be graded'
    out.append(f'## Grade: not graded ({cell(why)})')
    out.append('')
    out.append('No line could be graded, so there is no score. This is not a score of zero.')
else:
    out.append(f'## Grade: {num(score)} / 5 ({passed} of {total} lines passed)')
    out.append('')
    bar = g.get('bar')
    verdict = 'passes the bar' if g.get('passes_bar') else 'below the bar'
    out.append(f'Bar {num(bar)}: {verdict}. The score is 1 + 4 x {passed}/{total}.')
    abstained = sum(1 for ln in (g.get('lines') or []) if not ln.get('applicable'))
    if abstained:
        out.append(f'{abstained} line(s) could not be graded. They are out of both sides '
                   'of the fraction: not graded is not a fail.')

ev = d.get('evidence') or {}
if ev.get('requested') == 'workspace':
    if ev.get('used'):
        out.append('Evidence: graded against this workspace\'s conversations.')
    else:
        out.append(f'Evidence: not read ({cell(ev.get("reason") or "no reason given")}). '
                   'The four evidence lines abstained.')
elif ev:
    out.append('Evidence: off, so only `cta_clarity` was graded.')
j = g.get('judge') or {}
if j:
    out.append(f'Judge: {cell(j.get("model"))}, version {cell(j.get("judge_version"))} '
               f'({cell(j.get("role"))}).')
out.append('')

lines = g.get('lines') or []
if lines:
    out.append('| Line | Verdict | Reason |')
    out.append('| --- | --- | --- |')
    for ln in lines:
        if not ln.get('applicable'):
            v = f'not graded ({cell(ln.get("not_applicable_reason") or "abstained")})'
        else:
            v = 'pass' if ln.get('pass') else 'fail'
        out.append(f'| `{cell(ln.get("id"))}` | {v} | {cell(ln.get("reason"))} |')
    out.append('')

claims = d.get('unsupported_claims')
if claims:
    out.append('### Claims nothing in your conversations backs')
    out.append('')
    for c in claims:
        out.append(f'- "{cell(c.get("span"))}" (`{cell(c.get("dimension"))}`): {cell(c.get("why"))}')
    out.append('')

notes = [n for n in (d.get('notes') or []) if n.get('audience') == 'sender' and n.get('says')]
if notes:
    out.append('### Notes')
    out.append('')
    for n in notes:
        out.append(f'- {cell(n.get("says"))}')
    out.append('')

disc = d.get('disclosures') or {}
spread = disc.get('repeat_spread')
if spread and isinstance(spread.get('share'), (int, float)):
    out.append(f'This is one grading of one text. In Amdahl\'s measurement, this judge '
               f'({cell(spread.get("model"))}) moved its score by more than '
               f'{num(spread.get("moved_past"))} on {round(spread["share"] * 100)}% of texts '
               f'when it graded them again.')
else:
    out.append('This is one grading of one text.')
out.append('')
out.append('The grade measures the message against your evidence and this rubric; '
           'it does not predict replies.')
out.append('')
out.append(f'optimize_id: `{cell(d.get("optimize_id"))}` · run_id: `{cell(d.get("run_id"))}`')
print('\n'.join(out))
PY
}

# render_prompt_card <response-file> - the prompt run's card, as markdown.
#
# `lift` is printed only when `lift_reportable` is true. The train scores are
# the in-loop judge's, never lift, and the card says so.
render_prompt_card() {
  python3 - "$1" <<'PY'
import json, sys
d = (json.load(open(sys.argv[1])) or {}).get('data') or {}

def cell(s):
    return ' '.join(str(s or '').split()).replace('|', '\\|')

def num(x):
    return f'{round(x, 2):g}' if isinstance(x, (int, float)) else 'not graded'

out = []
err = d.get('error') or {}
if err:
    out.append(f'## Prompt run: no result ({cell(err.get("code"))})')
    out.append('')
    out.append(cell(err.get('message')))
    print('\n'.join(out)); sys.exit(0)
if d.get('status') != 'complete':
    out.append(f'## Prompt run: {cell(d.get("status"))}')
    print('\n'.join(out)); sys.exit(0)

mode, outcome = d.get('prompt_mode'), d.get('outcome')
out.append(f'## Prompt run: {cell(outcome)} ({cell(mode)})')
out.append('')
grade = d.get('grade') or {}
sides = [('Original' if mode == 'improve' else 'Prompt', grade.get('original'))]
if grade.get('revised'):
    sides.append(('Revised', grade['revised']))
scope = 'held-out emails' if mode == 'improve' else 'emails'
out.append(f'| Prompt | Mean of its {scope} | Emails graded | Passing the bar |')
out.append('| --- | --- | --- | --- |')
for name, s in sides:
    out.append(f'| {name} | {num(s.get("mean"))} | {s.get("n")} | '
               f'{s.get("emails_passing_bar")} of {s.get("n")} (bar {num(s.get("bar"))}) |')
out.append('')

ids = []
for _, s in sides:
    for k in (s.get('lines') or {}):
        if k not in ids: ids.append(k)
if ids:
    out.append('| Line | ' + ' | '.join(n for n, _ in sides) + ' |')
    out.append('| --- |' + ' --- |' * len(sides))
    for k in ids:
        row = []
        for _, s in sides:
            r = (s.get('lines') or {}).get(k)
            if not r or not r.get('total'):
                row.append('not graded')
            else:
                row.append(f'{r.get("passed")} of {r.get("total")}')
        out.append(f'| `{k}` | ' + ' | '.join(row) + ' |')
    out.append('')

if mode == 'improve':
    if d.get('lift_reportable'):
        out.append(f'Held-out lift: {d.get("lift"):+g}.')
    else:
        out.append(f'Held-out lift: not reportable ({cell(d.get("lift_not_reportable_reason"))}).')
    out.append('The train scores are the in-loop judge\'s and are never lift.')
    out.append('')

notes = [n for n in (d.get('notes') or []) if n.get('audience') == 'sender' and n.get('says')]
if notes:
    out.append('### Notes')
    out.append('')
    for n in notes:
        out.append(f'- {cell(n.get("says"))}')
    out.append('')

disc = d.get('disclosures') or {}
spread = disc.get('repeat_spread')
if spread and isinstance(spread.get('share'), (int, float)):
    out.append(f'Each email has one grading. In Amdahl\'s measurement, this judge '
               f'({cell(spread.get("model"))}) moved its score by more than '
               f'{num(spread.get("moved_past"))} on {round(spread["share"] * 100)}% of texts '
               f'when it graded them again.')
else:
    out.append('Each email has one grading.')
out.append('')
out.append('The grade measures the message against your evidence and this rubric; '
           'it does not predict replies.')
out.append('')
out.append(f'run_id: `{cell(d.get("run_id"))}`')
print('\n'.join(out))
PY
}
