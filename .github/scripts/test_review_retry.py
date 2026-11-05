"""Runs the workflow's "Generate review findings" step with a fake model helper.

Run: python3 -m unittest discover -s .github/scripts -p 'test_*.py' -v

The step's own bash runs in a throwaway clone of a local repository, with
every /tmp/ path moved to a temporary directory. The fake helper answers from
a queue and counts its calls; nothing leaves the machine.
"""

import json
import os
import shutil
import subprocess
import tempfile
import textwrap
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
WORKFLOW = os.path.join(HERE, "..", "workflows", "claude-code-review.yml")
STEP = "Generate review findings"
FINDING = {"path": "guide.md", "line": 2, "severity": "Link", "summary": "s", "body": "b"}

FAKE_HELPER = """import json, os, sys
tmp = %r
args = sys.argv[1:]
queue = os.path.join(tmp, 'answers.json')
answers = json.load(open(queue))
answer = answers.pop(0)
json.dump(answers, open(queue, 'w'))
open(os.path.join(tmp, 'calls.log'), 'a').write(' '.join(args[args.index('--timeout'):][:4]) + '\\n')
if answer is None:
    open(os.path.join(tmp, 'review_status.txt'), 'a').write('review: http_500 (fake)\\n')
    sys.exit(1)
open(args[args.index('--out') + 1], 'w').write(answer)
"""


def step_script():
    """The step's run: block, as GitHub hands it to bash."""
    lines = open(WORKFLOW, encoding="utf-8").read().splitlines()
    start = next(i for i, line in enumerate(lines) if line.strip() == "- name: %s" % STEP)
    run_at = next(i for i in range(start, len(lines)) if lines[i].strip() == "run: |")
    indent = len(lines[run_at]) - len(lines[run_at].lstrip()) + 2
    body = []
    for line in lines[run_at + 1:]:
        if line.strip() and len(line) - len(line.lstrip()) < indent:
            break
        body.append(line)
    return textwrap.dedent("\n".join(body)) + "\n"


def git(cwd, *args):
    subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@example.com", *args],
                   cwd=cwd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


@unittest.skipIf(shutil.which("git") is None, "needs git")
class GenerateStep(unittest.TestCase):
    def run_step(self, answers, seconds_used=0):
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp, True)
        origin, work = os.path.join(tmp, "origin.git"), os.path.join(tmp, "work")
        git(tmp, "init", "-q", "--bare", "-b", "main", origin)
        git(tmp, "clone", "-q", origin, work)
        with open(os.path.join(work, "guide.md"), "w") as page:
            page.write("# Guide\n")
        git(work, "add", "guide.md")
        git(work, "commit", "-q", "-m", "base")
        git(work, "push", "-q", "origin", "HEAD:main")
        with open(os.path.join(work, "guide.md"), "a") as page:
            page.write("See [setup](setup.md).\n")
        git(work, "commit", "-q", "-am", "change")

        scripts = os.path.join(work, ".review-tools", ".github", "scripts")
        os.makedirs(scripts)
        with open(os.path.join(scripts, "anthropic_review_call.py"), "w") as fake:
            fake.write(FAKE_HELPER % tmp)
        with open(os.path.join(tmp, "answers.json"), "w") as queue:
            json.dump(answers, queue)
        # SECONDS is bash's clock for the step; setting it stands in for time already spent.
        script = "SECONDS=%d\n" % seconds_used + step_script().replace("/tmp/", tmp + "/")
        self.assertNotIn("${{", script)
        done = subprocess.run(
            ["bash", "--noprofile", "--norc", "-e", "-c", script],
            cwd=work,
            env={"PATH": os.environ["PATH"], "HOME": tmp, "GIT_CONFIG_NOSYSTEM": "1",
                 "ANTHROPIC_API_KEY": "not-a-key", "BASE_REF": "main", "HEAD_SHA": "f" * 40},
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        )
        calls = open(os.path.join(tmp, "calls.log")).read().splitlines()
        findings_path = os.path.join(tmp, "review_findings.json")
        status_path = os.path.join(tmp, "review_status.txt")
        status = open(status_path).read() if os.path.exists(status_path) else ""
        findings = json.load(open(findings_path)) if os.path.exists(findings_path) else None
        return done, calls, findings, status

    def test_a_good_first_answer_is_one_call(self):
        done, calls, findings, _ = self.run_step([json.dumps([FINDING])])
        self.assertEqual(done.returncode, 0, done.stdout)
        self.assertEqual(len(calls), 1)
        self.assertEqual(findings, [FINDING])

    def test_an_unparseable_answer_is_asked_once_more_within_the_step_limit(self):
        done, calls, findings, status = self.run_step(["[{bad json]", json.dumps([FINDING])])
        self.assertEqual(done.returncode, 0, done.stdout)
        self.assertEqual(calls[0], "--timeout 180 --budget-seconds 420")
        self.assertEqual(len(calls), 2)
        self.assertEqual(findings, [FINDING])
        self.assertEqual(status, "")
        self.assertIn("asking once more", done.stdout)

    def test_two_unparseable_answers_fail_the_review_after_one_re_ask(self):
        done, calls, findings, status = self.run_step(["no array here", "[{bad json]", "[]"])
        self.assertEqual(done.returncode, 1, done.stdout)
        self.assertEqual(len(calls), 2)
        self.assertIsNone(findings)
        self.assertIn("review: unparseable (JSON parse error", status)

    def test_the_re_ask_gets_only_the_time_the_step_has_left(self):
        done, calls, findings, _ = self.run_step(["[{bad json]", json.dumps([FINDING])], seconds_used=400)
        self.assertEqual(done.returncode, 0, done.stdout)
        self.assertEqual(len(calls), 2)
        _, timeout, _, budget = calls[1].split()
        self.assertEqual(timeout, budget)
        self.assertTrue(90 <= int(budget) <= 100, calls[1])
        self.assertEqual(findings, [FINDING])

    def test_no_re_ask_with_under_a_minute_left(self):
        done, calls, findings, status = self.run_step(["[{bad json]", json.dumps([FINDING])], seconds_used=460)
        self.assertEqual(done.returncode, 1, done.stdout)
        self.assertEqual(len(calls), 1)
        self.assertIsNone(findings)
        self.assertIn("not asking again", done.stdout)
        self.assertIn("review: unparseable (JSON parse error", status)

    def test_an_api_failure_is_not_re_asked(self):
        done, calls, _, status = self.run_step([None, "[]"])
        self.assertEqual(done.returncode, 1, done.stdout)
        self.assertEqual(len(calls), 1)
        self.assertIn("http_500", status)


if __name__ == "__main__":
    unittest.main()
