#!/usr/bin/env python3
"""Post one "review did not run" notice when the Code Review job died.

The review job has its own "Report that the review did not run" step, but a
step runs only while the job's runner is alive. When a self-hosted runner is
lost mid-job (amdahl-pipelines #1556 on Nov 4 2026, 12 min into the review),
or the job is cancelled or times out, that step never runs and the PR shows
nothing. claude-code-review.yml runs this script in a small job on a
GitHub-hosted runner after the review job ends as failure or cancelled.

It posts nothing when:
  - the review job's own report step ran (it posted, or found the run
    superseded);
  - the PR is closed, merged or back in draft, or its head is no longer the
    commit this run reviewed: a newer run reviews the new head;
  - a newer run of this workflow on the PR may review (its "Read PR state"
    job was not skipped). That newer run cancelled this one through the
    concurrency group, or will review the same head.

Otherwise it posts one comment, or updates the one it posted on an earlier
attempt of this run (found by the hidden marker with the run id). The
comment says why the job died, links the run and says how to re-run it.

It never changes a check: the Code Review job stays failed or cancelled, so
a required Code Review check stays red.

Reads GITHUB_TOKEN, GITHUB_API_URL, GITHUB_SERVER_URL, GITHUB_REPOSITORY,
GITHUB_RUN_ID, GITHUB_RUN_ATTEMPT, PR_NUMBER, HEAD_SHA (the reviewed commit)
and REVIEW_RESULT. Standard library only.
"""

import datetime
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

REVIEW_JOB = "Code Review"
REPORT_STEP = "Report that the review did not run"
PR_STATE_JOB = "Read PR state"
COMMENT_AUTHOR = "github-actions[bot]"
ATTEMPTS = 3


def marker(run_id):
    return "<!-- amdahl-review-job-died run=%s -->" % run_id


class Api:
    """A small GitHub REST client. Tests replace it with a fake."""

    def __init__(self, base, token, sleep=time.sleep):
        self.base = base.rstrip("/")
        self.token = token
        self.sleep = sleep

    def request(self, method, path, body=None):
        data = None if body is None else json.dumps(body).encode()
        req = urllib.request.Request(
            path if path.startswith("http") else self.base + path,
            data=data,
            method=method,
            headers={
                "authorization": "Bearer " + self.token,
                "accept": "application/vnd.github+json",
                "x-github-api-version": "2022-11-28",
                "content-type": "application/json",
            },
        )
        for attempt in range(1, ATTEMPTS + 1):
            try:
                with urllib.request.urlopen(req, timeout=20) as response:
                    return json.loads(response.read() or b"null")
            except urllib.error.HTTPError as error:
                if error.code < 500 or attempt == ATTEMPTS:
                    raise
            except (urllib.error.URLError, TimeoutError):
                if attempt == ATTEMPTS:
                    raise
            print("::warning::%s %s failed (try %d of %d)" % (method, path, attempt, ATTEMPTS))
            self.sleep(5 * attempt)
        raise AssertionError("unreachable")

    def get(self, path):
        return self.request("GET", path)


def minutes_between(start, end):
    try:
        parse = lambda s: datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ")
        return max(0, round((parse(end) - parse(start)).total_seconds() / 60))
    except (TypeError, ValueError):
        return None


def newer_reviewing_run(api, repo, run_id, pr_number):
    """Return the id of a newer run of this workflow that may review this PR, or None."""
    run = api.get("/repos/%s/actions/runs/%s" % (repo, run_id))
    runs = api.get(
        "/repos/%s/actions/workflows/%s/runs?event=pull_request&per_page=30&branch=%s"
        % (repo, run["workflow_id"], urllib.parse.quote(run["head_branch"], safe=""))
    )["workflow_runs"]
    for other in runs:
        if other["run_number"] <= run["run_number"]:
            continue
        numbers = [p.get("number") for p in other.get("pull_requests") or []]
        if numbers and int(pr_number) not in numbers:
            continue
        jobs = api.get("/repos/%s/actions/runs/%s/jobs?per_page=100" % (repo, other["id"]))["jobs"]
        state = next((j for j in jobs if j["name"] == PR_STATE_JOB), None)
        # A run that can never review skips Read PR state and cancels nothing.
        if state is None or state.get("conclusion") != "skipped":
            return other["id"]
    return None


def why_it_died(job, result):
    """One or two sentences saying how the review job ended."""
    if job is None:
        return "The Code Review job ended as `%s`, and its details could not be read." % result
    steps = job.get("steps") or []
    unfinished = [s for s in steps if s.get("status") != "completed"]
    started = next((s["name"] for s in unfinished if s.get("status") == "in_progress"), None)
    minutes = minutes_between(job.get("started_at"), job.get("completed_at"))
    after = "" if minutes is None else ", %d min after the job started" % minutes
    runner = job.get("runner_name")
    on = " (`%s`)" % runner if runner else ""
    if result == "cancelled":
        if not steps:
            return "The Code Review job was cancelled before it started."
        cancelled_at = started or next(
            (s["name"] for s in steps if s.get("conclusion") == "cancelled"), None)
        where = ' during the step "%s"' % cancelled_at if cancelled_at else ""
        return ("The Code Review job was cancelled%s%s: by a person, by the job's time limit, or by GitHub. "
                "Its own report step does not run on a cancel." % (where, after))
    if unfinished:
        where = ' during the step "%s"' % started if started else ""
        return ("The runner%s stopped responding%s%s. GitHub marked the job failed, "
                "so its own report step never ran." % (on, where, after))
    failed = next((s["name"] for s in steps if s.get("conclusion") == "failure"), None)
    if failed:
        return ('The step "%s" failed, and the job\'s own report step did not post a notice.' % failed)
    return "The Code Review job failed before any step ran, so its own report step did not run."


def comment_body(run_id, attempt, head_sha, reason, run_url, repo):
    return "\n".join([
        marker(run_id),
        "**Automated review did not run** for commit %s." % head_sha[:12],
        "",
        reason,
        "",
        "The review bot did not approve this commit. It needs a human review, "
        "or a review run that finishes.",
        "",
        "To run the review again: `gh run rerun %s --failed --repo %s`, "
        "or open the run and choose **Re-run failed jobs**." % (run_id, repo),
        "",
        "Run: %s (attempt %s)" % (run_url, attempt),
    ]) + "\n"


def find_notice(api, repo, pr_number, run_id):
    tag = marker(run_id)
    page = 1
    while page <= 20:
        comments = api.get("/repos/%s/issues/%s/comments?per_page=100&page=%d" % (repo, pr_number, page))
        for comment in comments:
            if (comment.get("user") or {}).get("login") == COMMENT_AUTHOR and tag in (comment.get("body") or ""):
                return comment["id"]
        if len(comments) < 100:
            return None
        page += 1
    return None


def run(env, api, log=print):
    repo = env["GITHUB_REPOSITORY"]
    run_id = env["GITHUB_RUN_ID"]
    attempt = env.get("GITHUB_RUN_ATTEMPT", "1")
    pr_number = env["PR_NUMBER"]
    head_sha = env["HEAD_SHA"]
    result = env["REVIEW_RESULT"]

    pr = api.get("/repos/%s/pulls/%s" % (repo, pr_number))
    if pr["state"] != "open" or pr.get("draft"):
        log("PR #%s is %s: not posting." % (pr_number, "a draft" if pr.get("draft") else pr["state"]))
        return "skipped"
    if pr["head"]["sha"] != head_sha:
        log("The PR head is now %s; this run reviewed %s. The newer run reviews it: not posting."
            % (pr["head"]["sha"][:12], head_sha[:12]))
        return "skipped"

    newer = newer_reviewing_run(api, repo, run_id, pr_number)
    if newer is not None:
        log("Run %s replaced this one and reviews the PR: not posting." % newer)
        return "skipped"

    jobs = api.get("/repos/%s/actions/runs/%s/attempts/%s/jobs?per_page=100" % (repo, run_id, attempt))["jobs"]
    job = next((j for j in jobs if j["name"] == REVIEW_JOB), None)
    if job is not None:
        report = next((s for s in job.get("steps") or [] if s["name"] == REPORT_STEP), None)
        if report is not None and report.get("conclusion") == "success":
            log('The review job\'s own "%s" step ran: not posting a second notice.' % REPORT_STEP)
            return "skipped"

    reason = why_it_died(job, result)
    run_url = "%s/%s/actions/runs/%s" % (env.get("GITHUB_SERVER_URL", "https://github.com"), repo, run_id)
    body = comment_body(run_id, attempt, head_sha, reason, run_url, repo)
    log(body)
    existing = find_notice(api, repo, pr_number, run_id)
    if existing is None:
        api.request("POST", "/repos/%s/issues/%s/comments" % (repo, pr_number), {"body": body})
        log("Posted the notice on PR #%s." % pr_number)
        return "posted"
    api.request("PATCH", "/repos/%s/issues/comments/%s" % (repo, existing), {"body": body})
    log("Updated the notice (comment %s) on PR #%s." % (existing, pr_number))
    return "updated"


def main():
    env = os.environ
    api = Api(env.get("GITHUB_API_URL", "https://api.github.com"), env["GITHUB_TOKEN"])
    try:
        run(env, api)
    except Exception as error:  # the job goes red, and the run log says why
        print("::error::Could not post the review-did-not-run notice: %s" % error)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
