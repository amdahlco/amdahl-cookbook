"""Tests for review_job_died.py.

Run: python3 -m unittest discover -s .github/scripts -p 'test_*.py' -v

No network: a fake GitHub API answers from canned data and records writes.
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import review_job_died as died  # noqa: E402

REPO = "amdahlco/amdahl-pipelines"
HEAD = "a" * 40
RUN_ID = "41875873998"

# The Code Review job of amdahl-pipelines run 41875873998 (#1556), whose
# self-hosted runner was lost 12 min in.
LOST_RUNNER_JOB = {
    "name": "Code Review",
    "status": "completed",
    "conclusion": "failure",
    "runner_name": "i-0ceeb1b1d0866a476",
    "started_at": "2026-11-04T17:17:46Z",
    "completed_at": "2026-11-04T17:29:46Z",
    "steps": [
        {"name": "Set up job", "status": "completed", "conclusion": "success"},
        {"name": "Choose what to review", "status": "completed", "conclusion": "success"},
        {"name": "Generate review findings", "status": "in_progress", "conclusion": None},
        {"name": "Verify findings and post verified comments", "status": "pending", "conclusion": None},
        {"name": "Report that the review did not run", "status": "pending", "conclusion": None},
        {"name": "Delete the Bedrock token", "status": "pending", "conclusion": None},
    ],
}


def step_failed_and_reported(report_conclusion):
    return {
        "name": "Code Review",
        "status": "completed",
        "conclusion": "failure",
        "started_at": "2026-11-04T17:17:46Z",
        "completed_at": "2026-11-04T17:20:46Z",
        "steps": [
            {"name": "Generate review findings", "status": "completed", "conclusion": "failure"},
            {"name": "Report that the review did not run", "status": "completed", "conclusion": report_conclusion},
        ],
    }


class FakeApi:
    def __init__(self, pr=None, job=LOST_RUNNER_JOB, newer_runs=(), comments=()):
        self.pr = pr or {"state": "open", "draft": False, "head": {"sha": HEAD}}
        self.job = job
        self.newer_runs = list(newer_runs)
        self.comments = list(comments)
        self.writes = []

    def get(self, path):
        if path == "/repos/%s/pulls/7" % REPO:
            return self.pr
        if path == "/repos/%s/actions/runs/%s" % (REPO, RUN_ID):
            return {"workflow_id": 55, "head_branch": "shahin/composer", "run_number": 100}
        if path.startswith("/repos/%s/actions/workflows/55/runs?" % REPO):
            assert "branch=shahin%2Fcomposer" in path, path
            older = {"id": 1, "run_number": 99, "pull_requests": [{"number": 7}]}
            this = {"id": int(RUN_ID), "run_number": 100, "pull_requests": [{"number": 7}]}
            return {"workflow_runs": [r for r, _ in self.newer_runs] + [this, older]}
        if path.startswith("/repos/%s/actions/runs/%s/attempts/" % (REPO, RUN_ID)):
            return {"jobs": [] if self.job is None else [self.job]}
        for run, pr_state in self.newer_runs:
            if path.startswith("/repos/%s/actions/runs/%s/jobs" % (REPO, run["id"])):
                return {"jobs": [{"name": "Read PR state", "conclusion": pr_state}]}
        if path.startswith("/repos/%s/issues/7/comments?" % REPO):
            return self.comments if "page=1" in path else []
        raise AssertionError("unexpected GET " + path)

    def request(self, method, path, body=None):
        if method == "GET":
            return self.get(path)
        self.writes.append((method, path, body))
        return {}


ENV = {
    "GITHUB_REPOSITORY": REPO,
    "GITHUB_RUN_ID": RUN_ID,
    "GITHUB_RUN_ATTEMPT": "1",
    "GITHUB_SERVER_URL": "https://github.com",
    "PR_NUMBER": "7",
    "HEAD_SHA": HEAD,
    "REVIEW_RESULT": "failure",
}


def run(api, **env):
    return died.run(dict(ENV, **env), api, log=lambda *_: None)


class LostRunner(unittest.TestCase):
    def test_posts_one_notice_with_the_reason_the_run_and_the_re_run_command(self):
        api = FakeApi()
        self.assertEqual(run(api), "posted")
        [(method, path, body)] = api.writes
        self.assertEqual((method, path), ("POST", "/repos/%s/issues/7/comments" % REPO))
        text = body["body"]
        self.assertTrue(text.startswith("<!-- amdahl-review-job-died run=%s -->" % RUN_ID))
        self.assertIn("**Automated review did not run** for commit aaaaaaaaaaaa.", text)
        self.assertIn('stopped responding during the step "Generate review findings", 12 min after', text)
        self.assertIn("i-0ceeb1b1d0866a476", text)
        self.assertIn("gh run rerun %s --failed --repo %s" % (RUN_ID, REPO), text)
        self.assertIn("https://github.com/%s/actions/runs/%s (attempt 1)" % (REPO, RUN_ID), text)

    def test_a_later_attempt_of_the_same_run_updates_its_notice(self):
        mine = {"id": 900, "user": {"login": "github-actions[bot]"}, "body": died.marker(RUN_ID) + "\nold"}
        api = FakeApi(comments=[mine])
        self.assertEqual(run(api, GITHUB_RUN_ATTEMPT="2"), "updated")
        [(method, path, body)] = api.writes
        self.assertEqual((method, path), ("PATCH", "/repos/%s/issues/comments/900" % REPO))
        self.assertIn("(attempt 2)", body["body"])

    def test_a_marker_written_by_someone_else_is_not_edited(self):
        quoted = {"id": 901, "user": {"login": "shahin"}, "body": died.marker(RUN_ID)}
        api = FakeApi(comments=[quoted])
        self.assertEqual(run(api), "posted")
        self.assertEqual(api.writes[0][0], "POST")

    def test_another_runs_notice_is_left_alone(self):
        other = {"id": 902, "user": {"login": "github-actions[bot]"}, "body": died.marker("123")}
        api = FakeApi(comments=[other])
        self.assertEqual(run(api), "posted")


class NotPosting(unittest.TestCase):
    def assert_silent(self, api, **env):
        self.assertEqual(run(api, **env), "skipped")
        self.assertEqual(api.writes, [])

    def test_the_jobs_own_report_step_already_ran(self):
        self.assert_silent(FakeApi(job=step_failed_and_reported("success")))

    def test_the_pr_head_moved_on(self):
        self.assert_silent(FakeApi(pr={"state": "open", "draft": False, "head": {"sha": "b" * 40}}))

    def test_the_pr_is_closed_or_back_in_draft(self):
        self.assert_silent(FakeApi(pr={"state": "closed", "draft": False, "head": {"sha": HEAD}}))
        self.assert_silent(FakeApi(pr={"state": "open", "draft": True, "head": {"sha": HEAD}}))

    def test_a_newer_run_replaced_this_one(self):
        newer = {"id": 500, "run_number": 101, "pull_requests": [{"number": 7}]}
        self.assert_silent(FakeApi(newer_runs=[(newer, "success")]), REVIEW_RESULT="cancelled")
        self.assert_silent(FakeApi(newer_runs=[(newer, None)]), REVIEW_RESULT="cancelled")


class StillPosting(unittest.TestCase):
    def test_a_newer_run_that_skips_review_cancelled_nothing(self):
        label_run = {"id": 501, "run_number": 101, "pull_requests": [{"number": 7}]}
        api = FakeApi(newer_runs=[(label_run, "skipped")])
        self.assertEqual(run(api), "posted")

    def test_a_newer_run_for_another_pr_on_the_branch_does_not_count(self):
        other_pr = {"id": 502, "run_number": 101, "pull_requests": [{"number": 8}]}
        self.assertEqual(run(FakeApi(newer_runs=[(other_pr, "success")])), "posted")

    def test_a_report_step_that_failed_is_not_a_notice(self):
        api = FakeApi(job=step_failed_and_reported("failure"))
        self.assertEqual(run(api), "posted")
        self.assertIn('The step "Generate review findings" failed', api.writes[0][2]["body"])


class Reasons(unittest.TestCase):
    def test_cancelled_before_it_started(self):
        job = {"name": "Code Review", "conclusion": "cancelled", "steps": []}
        self.assertEqual(died.why_it_died(job, "cancelled"), "The Code Review job was cancelled before it started.")

    def test_cancelled_mid_step(self):
        job = dict(LOST_RUNNER_JOB, conclusion="cancelled")
        text = died.why_it_died(job, "cancelled")
        self.assertIn('cancelled during the step "Generate review findings", 12 min after the job started', text)
        self.assertIn("time limit", text)

    def test_unreadable_job(self):
        self.assertIn("could not be read", died.why_it_died(None, "failure"))


# Beside this file, or in the PR checkout the review job runs these tests from.
WORKFLOW = next((path for path in (
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "workflows", "claude-code-review.yml"),
    os.path.join(os.getcwd(), ".github", "workflows", "claude-code-review.yml"),
) if os.path.exists(path)), None)


def job_block(text, key):
    """The lines of one top-level job in the workflow, comments dropped."""
    lines = text.splitlines()
    start = lines.index("  %s:" % key)
    end = next((i for i in range(start + 1, len(lines))
                if lines[i].startswith("  ") and not lines[i].startswith("   ")
                and lines[i].strip() and not lines[i].strip().startswith("#")), len(lines))
    return [line for line in lines[start:end] if not line.strip().startswith("#")]


@unittest.skipIf(WORKFLOW is None, "claude-code-review.yml is not in this checkout")
class Workflow(unittest.TestCase):
    # A renamed job or report step would make the script post a second notice on every failure.

    @classmethod
    def setUpClass(cls):
        with open(WORKFLOW, encoding="utf-8") as handle:
            cls.text = handle.read()

    def test_the_review_and_pr_state_jobs_have_the_names_the_script_reads(self):
        self.assertIn("    name: %s" % died.REVIEW_JOB, job_block(self.text, "review"))
        self.assertIn("    name: %s" % died.PR_STATE_JOB, job_block(self.text, "pr-state"))

    def test_the_review_job_has_one_report_step_that_runs_on_failure(self):
        review = [line.strip() for line in job_block(self.text, "review")]
        at = [i for i, line in enumerate(review) if line == "- name: %s" % died.REPORT_STEP]
        self.assertEqual(len(at), 1)
        self.assertEqual(review[at[0] + 1], "if: failure()")

    def test_the_notice_runs_only_after_a_review_that_was_due_and_died(self):
        block = job_block(self.text, "review-died")
        condition = " ".join(" ".join(block).split())
        self.assertIn("if: >- always() && needs.pr-state.outputs.review == 'true' && "
                      "(needs.review.result == 'failure' || needs.review.result == 'cancelled')", condition)
        stripped = [line.strip() for line in block]
        self.assertIn("needs: [pr-state, review]", stripped)
        self.assertIn("runs-on: ubuntu-latest", stripped)
        self.assertNotIn("continue-on-error: true", stripped)
        self.assertNotIn("name: %s" % died.REVIEW_JOB, stripped)
        self.assertIn("REVIEW_RESULT: ${{ needs.review.result }}", stripped)
        self.assertIn("HEAD_SHA: ${{ needs.pr-state.outputs.head_sha }}", stripped)
        self.assertIn("run: python3 .github/scripts/review_job_died.py", stripped)
        permissions = stripped[stripped.index("permissions:") + 1:stripped.index("permissions:") + 4]
        self.assertEqual([p.split(" #")[0] for p in permissions],
                         ["contents: read", "actions: read", "pull-requests: write"])


if __name__ == "__main__":
    unittest.main()
