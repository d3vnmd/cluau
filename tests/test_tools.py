#!/usr/bin/env python3
"""Tests for the cluau tools: migrate_legacy.py, audit_project.py, economy_sim.py."""
from __future__ import annotations

import importlib.util
import os
import sys
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS = os.path.join(ROOT, "skills", "cluau", "scripts")
sys.path.insert(0, SCRIPTS)


def load(name: str):
    spec = importlib.util.spec_from_file_location(name, os.path.join(SCRIPTS, f"{name}.py"))
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


migrate = load("migrate_legacy")
audit = load("audit_project")
economy = load("economy_sim")
lint = sys.modules["luau_lint"]

FIX = os.path.join(ROOT, "tests", "fixtures")


class MigrateTests(unittest.TestCase):
    def setUp(self):
        with open(os.path.join(FIX, "migrate", "legacy.luau"), encoding="utf-8") as fh:
            self.src = fh.read()
        with open(os.path.join(FIX, "migrate", "legacy.expected.luau"), encoding="utf-8") as fh:
            self.expected = fh.read()

    def test_matches_expected_output(self):
        out, changes = migrate.migrate_source(self.src)
        self.assertEqual(out, self.expected)
        self.assertGreaterEqual(len(changes), 15)

    def test_idempotent(self):
        once, _ = migrate.migrate_source(self.src)
        twice, changes = migrate.migrate_source(once)
        self.assertEqual(once, twice)
        self.assertEqual(changes, [])

    def test_strings_and_comments_untouched(self):
        src = 'local s = "wait(1) game.Players :connect("\n-- spawn(f) tick()\n--[[ delay(1) ]]\n'
        out, changes = migrate.migrate_source(src)
        self.assertEqual(out, src)
        self.assertEqual(changes, [])

    def test_member_calls_not_rewritten(self):
        src = "task.wait(1)\nsignal:Wait()\nobj.wait(1)\nmyLib.spawn(f)\n"
        out, _ = migrate.migrate_source(src)
        self.assertEqual(out, src)

    def test_unsafe_items_left_for_manual_review(self):
        out, _ = migrate.migrate_source(self.src)
        rules = {f.rule for f in migrate.manual_items(out, "x")}
        self.assertIn("CL020", rules)  # BodyVelocity is never auto-rewritten
        self.assertIn("BodyVelocity", out)

    def test_migrated_output_has_no_lint_errors_except_manual(self):
        out, _ = migrate.migrate_source(self.src)
        errors = {f.rule for f in lint.lint_source(out, require_strict=False) if f.severity == "error"}
        self.assertEqual(errors, {"CL020"})


class AuditTests(unittest.TestCase):
    def setUp(self):
        self.report = audit.audit(os.path.join(FIX, "project", "src"))

    def test_remote_inventory_resolves_names_and_flags_unsafe_handler(self):
        by_name = {r["remote"]: r for r in self.report["remotes"]}
        self.assertEqual(set(by_name), {"BuyItem", "Equip"})
        self.assertFalse(by_name["BuyItem"]["validated"])
        self.assertFalse(by_name["BuyItem"]["rate_limited"])
        self.assertTrue(by_name["BuyItem"]["yields"])
        self.assertTrue(by_name["Equip"]["validated"])
        self.assertTrue(by_name["Equip"]["rate_limited"])

    def test_placement_problems_found(self):
        problems = " ".join(p["problem"] for p in self.report["placement"])
        self.assertIn("CurrentCamera", problems)
        self.assertIn("DataStoreService", problems)

    def test_persistence_map(self):
        self.assertEqual([s["name"] for s in self.report["stores"]], ["PlayerData_v1"])
        self.assertTrue(any(p.endswith("Safe.server.luau") for p in self.report["bind_to_close"]))

    def test_markdown_renders(self):
        md = audit.to_markdown(self.report)
        self.assertIn("## 1. Remote handlers", md)
        self.assertIn("`BuyItem`", md)

    def test_templates_have_no_placement_problems(self):
        report = audit.audit(os.path.join(ROOT, "skills", "cluau", "templates"))
        self.assertEqual(report["placement"], [])
        for r in report["remotes"]:
            if r["validated"] != "n/a":
                self.assertTrue(r["validated"], r)


class EconomyTests(unittest.TestCase):
    def test_exact_times(self):
        cfg = {"base_income_per_sec": 1, "horizon_minutes": 60,
               "upgrades": [{"id": "A", "cost": 10, "income_add": 1}, {"id": "B", "cost": 20, "income_mult": 2}]}
        events, unreached = economy.simulate(cfg)
        self.assertEqual(unreached, [])
        self.assertAlmostEqual(events[0].at_sec, 10.0)   # 10 coins at 1/s
        self.assertAlmostEqual(events[1].at_sec, 20.0)   # 20 coins at 2/s
        self.assertAlmostEqual(events[1].income_after, 4.0)

    def test_grind_wall_spike_and_unreachable(self):
        cfg = {"base_income_per_sec": 1, "horizon_minutes": 30,
               "upgrades": [{"id": "A", "cost": 10}, {"id": "B", "cost": 1200}, {"id": "C", "cost": 10 ** 9}],
               "targets": {"max_wait_sec": 600, "max_wait_ratio": 3}}
        events, unreached = economy.simulate(cfg)
        self.assertIn("GRIND_WALL", events[1].flags)
        self.assertIn("SPIKE", events[1].flags)
        self.assertEqual(unreached, ["C"])

    def test_rebirth_multiplier_applies(self):
        cfg = {"base_income_per_sec": 10, "horizon_minutes": 60, "upgrades": [{"id": "A", "cost": 100}],
               "rebirth": {"cost": 100, "multiplier_add": 1, "max_rebirths": 1}}
        events, _ = economy.simulate(cfg)
        self.assertEqual([e.name for e in events], ["A", "Rebirth 1", "A"])
        self.assertAlmostEqual(events[2].wait_sec, 5.0)  # 100 coins at 20/s after rebirth

    def test_example_config_runs(self):
        events, _ = economy.simulate(economy.EXAMPLE)
        self.assertGreater(len(events), 5)


if __name__ == "__main__":
    unittest.main()
