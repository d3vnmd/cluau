#!/usr/bin/env python3
"""Tests for tools/run_evals.py — the grader must pass good answers and fail bad ones."""
from __future__ import annotations

import importlib.util
import json
import os
import re
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location("run_evals", os.path.join(ROOT, "tools", "run_evals.py"))
assert spec and spec.loader
run_evals = importlib.util.module_from_spec(spec)
sys.modules["run_evals"] = run_evals
spec.loader.exec_module(run_evals)

DATA = run_evals.load_cases()
CASES = {c["id"]: c for c in DATA["cases"]}
BAD = DATA["global_must_not_in_code"]

GOOD_COLLISION = """Тоглогчдыг хооронд нь мөргөлдөхгүй болгохын тулд collision group ашиглана.
`ServerScriptService` дотор **Script** болгож тавина уу.
```lua
--!strict
local Players = game:GetService("Players")
workspace:RegisterCollisionGroup("Players")
workspace:CollisionGroupSetCollidable("Players", "Players", false)
local function onCharacter(character: Model)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Players"
		end
	end
end
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacter)
end)
```
Ингэснээр тоглогчид бие биеэрээ нэвтэрч явна."""

BAD_COLLISION = """Use PhysicsService:
```lua
local PhysicsService = game:GetService("PhysicsService")
PhysicsService:CreateCollisionGroup("Players")
wait(1)
```"""


class CaseFileTests(unittest.TestCase):
    def test_ids_unique_and_fields_present(self):
        ids = [c["id"] for c in DATA["cases"]]
        self.assertEqual(len(ids), len(set(ids)))
        for c in DATA["cases"]:
            self.assertIn(c["kind"], ("trigger", "no-trigger"))
            self.assertIn(c["lang"], ("mn", "en"))
            self.assertTrue(c["prompt"].strip())

    def test_all_regexes_compile(self):
        for c in DATA["cases"]:
            for p in c.get("must", []) + c.get("must_not", []):
                re.compile(p)
        for p in BAD:
            re.compile(p)

    def test_both_languages_and_negative_cases_present(self):
        langs = {c["lang"] for c in DATA["cases"]}
        kinds = {c["kind"] for c in DATA["cases"]}
        self.assertEqual(langs, {"mn", "en"})
        self.assertIn("no-trigger", kinds)


class GraderTests(unittest.TestCase):
    def test_good_answer_passes(self):
        self.assertEqual(run_evals.grade_case(CASES["mn-collision-groups"], GOOD_COLLISION, BAD), [])

    def test_deprecated_code_fails(self):
        problems = run_evals.grade_case(CASES["mn-collision-groups"], BAD_COLLISION, BAD)
        joined = "\n".join(problems)
        self.assertIn("PhysicsService", joined)
        self.assertIn("wait", joined)
        self.assertIn("Mongolian", joined)  # English reply to a Mongolian prompt
        self.assertIn("missing", joined)

    def test_no_trigger_case_rejects_roblox_hijack(self):
        hijack = "Here is a Roblox Luau version instead:\n```lua\nlocal s = string.reverse('abc')\n```"
        self.assertTrue(run_evals.grade_case(CASES["no-python"], hijack, BAD))
        ok = "```python\ndef reverse(s):\n    return s[::-1]\n```"
        self.assertEqual(run_evals.grade_case(CASES["no-python"], ok, BAD), [])

    def test_grade_dir_reports_missing_and_failures(self):
        with tempfile.TemporaryDirectory() as d:
            with open(os.path.join(d, "mn-collision-groups.md"), "w", encoding="utf-8") as fh:
                fh.write(GOOD_COLLISION)
            code = run_evals.grade_dir(d, {"mn-collision-groups"})
            self.assertEqual(code, 0)
            code = run_evals.grade_dir(d, {"mn-collision-groups", "en-dev-product"})
            self.assertEqual(code, 1)  # en-dev-product response missing
            with open(os.path.join(d, "report.json"), encoding="utf-8") as fh:
                statuses = {r["id"]: r["status"] for r in json.load(fh)}
            self.assertEqual(statuses["en-dev-product"], "missing")


if __name__ == "__main__":
    unittest.main()
