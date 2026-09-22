"""Tests for cookbook_gate.py.

Run: python3 -m unittest discover -s .github/scripts -p 'test_*.py' -v
"""

import io
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import cookbook_gate as gate  # noqa: E402

LINK = {"path": "prompts/a.md", "line": 3, "severity": "⚠️ Link", "body": "⚠️ Link: bad anchor"}
CONTRACT = {"path": "prompts/b.md", "line": 9, "severity": "⚠️ Contract", "body": "wrong param"}
NAMES = {"path": "prompts/c.md", "line": 1, "severity": "⚠️ Names", "body": "real customer name"}
MARKDOWN = {"path": "README.md", "line": 5, "severity": "✨ Markdown", "body": "✨ Markdown: open fence"}
CONSISTENCY = {"path": "README.md", "line": 8, "severity": "✨ Consistency", "body": "contradicts line 2"}
NO_SEVERITY = {"path": "README.md", "line": 2, "body": "something"}

EVERY_FINDING_SET = [
    [],
    [MARKDOWN],
    [MARKDOWN, CONSISTENCY],
    [LINK],
    [LINK, MARKDOWN],
    [NO_SEVERITY],
]


class ShouldApproveTest(unittest.TestCase):
    def test_incomplete_review_never_approves(self):
        for findings in EVERY_FINDING_SET:
            for labels in ([], ["review-ack"]):
                for completed in (False, None, "true", 1):
                    with self.subTest(findings=findings, labels=labels, completed=completed):
                        approve, reason = gate.should_approve(findings, labels, completed)
                        self.assertFalse(approve)
                        self.assertEqual(reason, "the review did not complete")

    def test_one_link_finding_blocks(self):
        approve, reason = gate.should_approve([LINK], [], True)
        self.assertFalse(approve)
        self.assertEqual(reason, "1 blocking finding(s)")

    def test_review_ack_label_overrides_a_link_finding(self):
        approve, reason = gate.should_approve([LINK], ["documentation", "review-ack"], True)
        self.assertTrue(approve)
        self.assertIn("review-ack", reason)

    def test_every_warning_severity_blocks(self):
        for finding in (LINK, CONTRACT, NAMES):
            with self.subTest(severity=finding["severity"]):
                approve, _ = gate.should_approve([finding, MARKDOWN], [], True)
                self.assertFalse(approve)

    def test_warning_sign_without_variation_selector_blocks(self):
        finding = dict(LINK, severity="⚠ Link")
        self.assertFalse(gate.should_approve([finding], [], True)[0])

    def test_only_advisory_findings_approve(self):
        approve, reason = gate.should_approve([MARKDOWN, CONSISTENCY], [], True)
        self.assertTrue(approve)
        self.assertEqual(reason, "no blocking findings (2 advisory)")

    def test_empty_findings_approve(self):
        self.assertEqual(gate.should_approve([], [], True), (True, "no findings"))

    def test_missing_severity_blocks(self):
        for finding in (
            NO_SEVERITY,
            dict(NO_SEVERITY, severity=None),
            dict(NO_SEVERITY, severity=""),
            dict(NO_SEVERITY, severity="   "),
            dict(NO_SEVERITY, severity=7),
        ):
            with self.subTest(finding=finding):
                self.assertFalse(gate.should_approve([finding], [], True)[0])

    def test_unrecognised_severity_blocks(self):
        for severity in ("Link", "Markdown", "\U0001f6a8 Critical", "info"):
            with self.subTest(severity=severity):
                finding = dict(MARKDOWN, severity=severity)
                self.assertFalse(gate.should_approve([finding], [], True)[0])

    def test_advisory_severity_with_leading_space_is_advisory(self):
        finding = dict(MARKDOWN, severity="  ✨ Markdown")
        self.assertTrue(gate.should_approve([finding], [], True)[0])

    def test_non_object_finding_blocks(self):
        for finding in ("✨ Markdown", None, ["✨ Markdown"], 3):
            with self.subTest(finding=finding):
                self.assertFalse(gate.should_approve([finding], [], True)[0])

    def test_findings_that_are_not_a_list_never_approve(self):
        for findings in (None, {}, "[]", {"severity": "✨ Markdown"}):
            with self.subTest(findings=findings):
                self.assertFalse(gate.should_approve(findings, ["review-ack"], True)[0])

    def test_label_match_is_exact(self):
        for labels in (["Review-Ack"], ["review-ack-pending"], ["review"], None):
            with self.subTest(labels=labels):
                self.assertFalse(gate.should_approve([LINK], labels, True)[0])


class RenderSummaryTest(unittest.TestCase):
    def test_says_allowed_only_when_approving(self):
        cases = [
            ([], [], True),
            ([MARKDOWN], [], True),
            ([LINK], [], True),
            ([LINK], ["review-ack"], True),
        ]
        for findings, labels, completed in cases:
            approve, reason = gate.should_approve(findings, labels, completed)
            text = gate.render_summary(findings, approve, reason)
            with self.subTest(findings=findings, labels=labels):
                self.assertEqual("Approval: allowed" in text, approve)
                self.assertEqual("Approval: withheld" in text, not approve)

    def test_lists_blocking_and_advisory_separately(self):
        text = gate.render_summary([LINK, MARKDOWN, NO_SEVERITY], False, "2 blocking finding(s)")
        blocking_part, advisory_part = text.split("**Advisory**")
        self.assertIn("`prompts/a.md:3` ⚠️ Link: bad anchor", blocking_part)
        self.assertIn("`README.md:2` (no severity) something", blocking_part)
        self.assertIn("`README.md:5` ✨ Markdown: open fence", advisory_part)
        self.assertIn("2 blocking, 1 advisory", text)
        self.assertIn("`review-ack`", text)

    def test_label_approval_says_the_label_covers_later_pushes(self):
        approve, reason = gate.should_approve([LINK], ["review-ack"], True)
        text = gate.render_summary([LINK], approve, reason)
        self.assertTrue(approve)
        self.assertIn("also approves later pushes", text)
        self.assertIn("Remove the label", text)

    def test_approval_without_the_label_has_no_label_warning(self):
        for findings in ([], [MARKDOWN]):
            with self.subTest(findings=findings):
                approve, reason = gate.should_approve(findings, ["review-ack"], True)
                text = gate.render_summary(findings, approve, reason)
                self.assertTrue(approve)
                self.assertNotIn("later pushes", text)

    def test_withheld_summary_says_an_earlier_approval_still_counts(self):
        approve, reason = gate.should_approve([LINK], [], True)
        text = gate.render_summary([LINK], approve, reason)
        self.assertFalse(approve)
        self.assertIn("that approval still counts", text)


class CliTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.dir.cleanup)

    def path(self, name):
        return os.path.join(self.dir.name, name)

    def write(self, name, text):
        with open(self.path(name), "w", encoding="utf-8") as handle:
            handle.write(text)
        return self.path(name)

    def run_cli(self, findings_text, labels_text="", completed="true"):
        findings = self.write("findings.json", findings_text) if findings_text is not None else self.path("missing.json")
        labels = self.write("labels.txt", labels_text)
        out, err = io.StringIO(), io.StringIO()
        code = gate.main(
            [
                "--findings", findings,
                "--labels-file", labels,
                "--review-completed", completed,
                "--summary-out", self.path("summary.md"),
            ],
            out=out,
            err=err,
        )
        return code, out.getvalue(), err.getvalue()

    def test_link_finding_prints_approve_false(self):
        code, out, _ = self.run_cli(json.dumps([LINK]))
        self.assertEqual(code, 0)
        self.assertEqual(out, "approve=false\nreason=1 blocking finding(s)\n")
        with open(self.path("summary.md"), encoding="utf-8") as handle:
            self.assertIn("Approval: withheld", handle.read())

    def test_review_ack_in_labels_file_prints_approve_true(self):
        code, out, _ = self.run_cli(json.dumps([LINK]), labels_text="documentation\nreview-ack\n")
        self.assertEqual(code, 0)
        self.assertTrue(out.startswith("approve=true\n"))

    def test_only_the_string_true_counts_as_completed(self):
        for completed in ("", "false", "True", "1", "yes"):
            with self.subTest(completed=completed):
                code, out, _ = self.run_cli("[]", completed=completed)
                self.assertEqual(code, 0)
                self.assertTrue(out.startswith("approve=false\n"))

    def test_missing_or_invalid_findings_file_exits_1_without_a_decision(self):
        for text in (None, "", "not json", "{}", '"[]"'):
            with self.subTest(text=text):
                code, out, err = self.run_cli(text)
                self.assertEqual(code, 1)
                self.assertEqual(out, "")
                self.assertIn("cookbook_gate:", err)
                self.assertFalse(os.path.exists(self.path("summary.md")))

    def test_missing_labels_file_exits_1(self):
        out, err = io.StringIO(), io.StringIO()
        code = gate.main(
            [
                "--findings", self.write("findings.json", "[]"),
                "--labels-file", self.path("no-labels.txt"),
                "--review-completed", "true",
                "--summary-out", self.path("summary.md"),
            ],
            out=out,
            err=err,
        )
        self.assertEqual(code, 1)
        self.assertEqual(out.getvalue(), "")


if __name__ == "__main__":
    unittest.main()
