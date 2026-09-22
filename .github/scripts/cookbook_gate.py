#!/usr/bin/env python3
"""Decide whether the cookbook review bot may approve a pull request.

The rule, in order:

  1. No approval unless the review completed. A review that did not run, or
     ran on part of the diff, is not evidence that the PR is clean. The
     review-ack label does not change this.
  2. A finding blocks unless its severity starts with the sparkle emoji
     (CONSISTENCY, MARKDOWN), which marks it advisory. The warning-sign
     severities (LINK, CONTRACT, NAMES) block. So does a finding with a
     missing or unrecognised severity, and anything that is not a finding
     object, because the gate cannot tell it is harmless.
  3. The review-ack label approves despite blocking findings. A maintainer
     sets it after reading them, as in the code repos. The label is read on
     every run, so it also approves later pushes until someone removes it;
     the summary comment says so whenever the label is what approved.

CLI, used by .github/workflows/claude-code-review.yml:

  cookbook_gate.py --findings FILE --labels-file FILE \
      --review-completed true|false --summary-out FILE

It writes the PR summary comment to --summary-out and prints two lines,
"approve=true" or "approve=false", then "reason=<one line>". It exits 1,
printing no decision, when the findings file is missing or is not a JSON
list; the workflow treats that as a failed review.

Standard library only (python3 3.8 or later).
"""

import argparse
import json
import sys

ADVISORY_PREFIX = "✨"  # sparkles
REVIEW_ACK_LABEL = "review-ack"


def severity_of(finding):
    """The finding's severity with surrounding whitespace removed, or ''."""
    if not isinstance(finding, dict):
        return ""
    severity = finding.get("severity")
    return severity.strip() if isinstance(severity, str) else ""


def is_blocking(finding):
    """True unless the finding's severity marks it advisory."""
    return not severity_of(finding).startswith(ADVISORY_PREFIX)


def should_approve(findings, labels, review_completed):
    """Return (approve, reason) for one completed or failed review.

    findings: the list of finding objects the review produced.
    labels: the PR's label names.
    review_completed: True only when every review step succeeded.
    """
    if review_completed is not True:
        return False, "the review did not complete"
    if not isinstance(findings, list):
        return False, "the findings are not a list"

    blocking = [f for f in findings if is_blocking(f)]
    advisory = len(findings) - len(blocking)
    if not blocking:
        if advisory:
            return True, "no blocking findings (%d advisory)" % advisory
        return True, "no findings"
    if REVIEW_ACK_LABEL in set(labels or ()):
        return True, "%d blocking finding(s), approved through the %s label" % (len(blocking), REVIEW_ACK_LABEL)
    return False, "%d blocking finding(s)" % len(blocking)


def finding_line(finding):
    """One checklist line for a finding."""
    if not isinstance(finding, dict):
        return "- [ ] (not a finding object: %s)" % json.dumps(finding)[:200]
    path = finding.get("path") or "?"
    line = finding.get("line") or 0
    text = str(finding.get("body") or finding.get("summary") or "").split("\n")[0]
    severity = severity_of(finding)
    if not severity:
        text = "(no severity) " + text
    elif not text.startswith(severity):
        text = "%s: %s" % (severity, text)
    return "- [ ] `%s:%s` %s" % (path, line, text)


def render_summary(findings, approve, reason):
    """The PR comment for a completed review. It says 'allowed' only when approve is True."""
    if not findings:
        lines = ["\U0001f916 **Code Review Complete**: no issues found."]
    else:
        blocking = [f for f in findings if is_blocking(f)]
        advisory = [f for f in findings if not is_blocking(f)]
        lines = [
            "\U0001f916 **Code Review Summary**: %d blocking, %d advisory finding(s)"
            % (len(blocking), len(advisory))
        ]
        if blocking:
            lines += ["", "**Blocking** (link, contract and name findings; these hold the approval):", ""]
            lines += [finding_line(f) for f in blocking]
        if advisory:
            lines += ["", "**Advisory** (consistency and markdown findings; these do not hold the approval):", ""]
            lines += [finding_line(f) for f in advisory]

    # States the gate's decision. Whether the approval then lands depends on
    # the bot identity, which the workflow reports in its log.
    lines.append("")
    if approve:
        lines.append("**Approval: allowed** (review agent +1): %s." % reason)
        if any(is_blocking(f) for f in findings or ()):
            # Only the label approves past a blocking finding, and it is read
            # on every run, so it also covers pushes nobody has looked at.
            lines.append("")
            lines.append(
                "While the `%s` label is set, the bot also approves later pushes to this PR, "
                "including ones that add blocking findings. Remove the label once these "
                "findings are handled." % REVIEW_ACK_LABEL
            )
    else:
        lines.append("**Approval: withheld**: %s." % reason)
        lines.append("")
        lines.append(
            "Fix the blocking findings and push. If a finding is wrong, a maintainer can apply "
            "the `%s` label and re-run this workflow to approve anyway. If an earlier run "
            "approved this same commit, that approval still counts until a maintainer "
            "dismisses it." % REVIEW_ACK_LABEL
        )
    return "\n".join(lines) + "\n"


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Decide whether the cookbook review bot may approve.")
    parser.add_argument("--findings", required=True, help="JSON list of findings from the review step")
    parser.add_argument("--labels-file", required=True, help="the PR's label names, one per line")
    parser.add_argument("--review-completed", required=True, help="'true' only when every review step succeeded")
    parser.add_argument("--summary-out", required=True, help="file that receives the PR summary comment")
    return parser.parse_args(argv)


def main(argv=None, out=None, err=None):
    args = parse_args(argv)
    out = sys.stdout if out is None else out
    err = sys.stderr if err is None else err

    try:
        with open(args.findings, encoding="utf-8") as handle:
            findings = json.load(handle)
    except (OSError, ValueError) as error:
        err.write("cookbook_gate: cannot read %s: %s\n" % (args.findings, error))
        return 1
    if not isinstance(findings, list):
        err.write("cookbook_gate: %s is not a JSON list\n" % args.findings)
        return 1

    try:
        with open(args.labels_file, encoding="utf-8") as handle:
            labels = [row.strip() for row in handle if row.strip()]
    except OSError as error:
        err.write("cookbook_gate: cannot read %s: %s\n" % (args.labels_file, error))
        return 1

    approve, reason = should_approve(findings, labels, args.review_completed == "true")
    with open(args.summary_out, "w", encoding="utf-8") as handle:
        handle.write(render_summary(findings, approve, reason))
    out.write("approve=%s\n" % ("true" if approve else "false"))
    out.write("reason=%s\n" % reason)
    return 0


if __name__ == "__main__":
    sys.exit(main())
