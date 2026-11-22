#!/usr/bin/env python3
"""Tests for skills/cluau/scripts/luau_lint.py. Run: python3 -m unittest discover -s tests"""
from __future__ import annotations

import importlib.util
import os
import re
import sys
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINT_PATH = os.path.join(ROOT, "skills", "cluau", "scripts", "luau_lint.py")
TEMPLATES = os.path.join(ROOT, "skills", "cluau", "templates")
BAD = os.path.join(ROOT, "tests", "fixtures", "bad.luau")
GOOD = os.path.join(ROOT, "tests", "fixtures", "good.luau")

spec = importlib.util.spec_from_file_location("luau_lint", LINT_PATH)
assert spec and spec.loader
luau_lint = importlib.util.module_from_spec(spec)
sys.modules["luau_lint"] = luau_lint
spec.loader.exec_module(luau_lint)


def lint_file(path: str):
    with open(path, encoding="utf-8") as fh:
        return luau_lint.lint_source(fh.read(), path)


class BadFixtureTests(unittest.TestCase):
    def setUp(self):
        with open(BAD, encoding="utf-8") as fh:
            self.lines = fh.read().splitlines()
        self.findings = lint_file(BAD)

    def test_every_expected_rule_is_reported_on_its_line(self):
        for index, line in enumerate(self.lines, start=1):
            for rule_id in re.findall(r"CL\d{3}", line.split("-- expect", 1)[1]) if "-- expect" in line else []:
                hits = [f for f in self.findings if f.line == index and f.rule == rule_id]
                self.assertTrue(hits, f"line {index}: expected {rule_id} in: {line.strip()}")

    def test_no_findings_in_safe_section(self):
        start = next(i for i, l in enumerate(self.lines, start=1) if "must NOT be flagged" in l)
        unexpected = [f for f in self.findings if f.line >= start]
        self.assertEqual(unexpected, [], f"false positives: {unexpected}")

    def test_missing_strict_reported(self):
        self.assertTrue(any(f.rule == "CL100" for f in self.findings))


SECURITY = os.path.join(ROOT, "tests", "fixtures", "security")


def expected_on_lines(path: str) -> dict[int, list[str]]:
    expected: dict[int, list[str]] = {}
    with open(path, encoding="utf-8") as fh:
        for index, line in enumerate(fh.read().splitlines(), start=1):
            if "-- expect" in line:
                expected[index] = re.findall(r"CL\d{3}", line.split("-- expect", 1)[1])
    return expected


class SecurityFixtureTests(unittest.TestCase):
    def test_unsafe_fixtures_report_every_expected_rule(self):
        files = sorted(f for f in os.listdir(SECURITY) if f.startswith("unsafe_"))
        self.assertGreaterEqual(len(files), 5)
        for name in files:
            path = os.path.join(SECURITY, name)
            findings = lint_file(path)
            for line, rules in expected_on_lines(path).items():
                for rule in rules:
                    hits = [f for f in findings if f.line == line and f.rule == rule]
                    self.assertTrue(hits, f"{name}:{line}: expected {rule}; got {[(f.line, f.rule) for f in findings]}")

    def test_unsafe_fixtures_have_no_unexpected_findings(self):
        for name in sorted(f for f in os.listdir(SECURITY) if f.startswith("unsafe_")):
            path = os.path.join(SECURITY, name)
            expected = expected_on_lines(path)
            for f in lint_file(path):
                if f.rule == "CL100":
                    continue
                self.assertIn(f.rule, expected.get(f.line, []), f"{name}:{f.line}: unexpected {f.rule}")

    def test_safe_equivalent_is_clean(self):
        findings = lint_file(os.path.join(SECURITY, "safe_security.luau"))
        self.assertEqual(findings, [], f"false positives: {findings}")

    def test_file_rule_suppression(self):
        src = "--!strict\nworkspace.Coin.Touched:Connect(function() end) -- cluau-ignore CL113\n"
        self.assertEqual([f.rule for f in luau_lint.lint_source(src)], [])


class GoodFixtureTests(unittest.TestCase):
    def test_valid_modern_luau_has_no_findings(self):
        findings = lint_file(GOOD)
        self.assertEqual(findings, [], f"false positives in good.luau: {findings}")


class GeneratedRuleTests(unittest.TestCase):
    def test_generated_rules_loaded(self):
        ids = {rule_id for rule_id, *_ in luau_lint.GENERATED}
        self.assertTrue({"CL200", "CL201", "CL203"} <= ids, ids)

    def test_async_renames_and_group_apis_flagged(self):
        src = "--!strict\nlocal r = player:GetRankInGroup(1)\nplayer:LoadCharacter()\nlocal f = player:IsFriendsWith(2)\n"
        rules = [f.rule for f in luau_lint.lint_source(src)]
        self.assertEqual(rules.count("CL200"), 3, rules)


class TemplateTests(unittest.TestCase):
    def test_templates_are_clean(self):
        files = list(luau_lint.iter_files([TEMPLATES]))
        self.assertGreaterEqual(len(files), 10)
        for path in files:
            findings = lint_file(path)
            self.assertEqual(findings, [], f"{os.path.relpath(path, ROOT)}: {findings}")

    def test_templates_start_strict(self):
        for path in luau_lint.iter_files([TEMPLATES]):
            with open(path, encoding="utf-8") as fh:
                self.assertTrue(fh.readline().startswith("--!strict"), path)


class ViewTests(unittest.TestCase):
    def test_views_preserve_length_and_lines(self):
        src = 'local a = "x--y" -- c\n--[[ block\n wait() ]] local b = [==[ s ]==]\n'
        code, strings, text = luau_lint.build_views(src)
        for view in (code, strings, text):
            self.assertEqual(len(view), len(src))
            self.assertEqual(view.count("\n"), src.count("\n"))
        self.assertNotIn("wait", code)
        self.assertIn('"x--y"', strings)

    def test_file_suppression(self):
        self.assertEqual(luau_lint.lint_source("--!cluau-ignore-file\nwait(1)\n"), [])


if __name__ == "__main__":
    unittest.main()
