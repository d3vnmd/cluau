#!/usr/bin/env python3
"""
Behavioral evals for the cluau skill (Mongolian + English).

Grade saved responses (one file per case, named <case-id>.md):
    python3 tools/run_evals.py grade evals/runs/<run-dir>

Generate responses with any CLI that prints a reply for a prompt, then grade them, e.g. Claude Code
with the cluau plugin/skill installed:
    python3 tools/run_evals.py run --cmd "claude -p" [--only id1,id2] [--timeout 600]

Checks per case:
  • `must` regexes all match the response; `must_not` regexes match nothing.
  • kind=trigger: every ```lua/luau code block passes cluau-lint with zero errors and contains none of
    `global_must_not_in_code` (deprecated/unsafe APIs).
  • kind=no-trigger: the skill must not hijack unrelated requests (assertions say so).
  • lang=mn: at least 30% of letters in the prose are Cyrillic.
Exit code 1 if any case fails. Results also written to <run-dir>/report.json.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import re
import shlex
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CASES = os.path.join(ROOT, "evals", "cases.json")
sys.path.insert(0, os.path.join(ROOT, "skills", "cluau", "scripts"))
import luau_lint  # noqa: E402

CODE_BLOCK = re.compile(r"```(?:lua|luau)\s*\n(.*?)```", re.S | re.I)


def load_cases() -> dict:
    with open(CASES, encoding="utf-8") as fh:
        return json.load(fh)


def cyrillic_ratio(text: str) -> float:
    prose = CODE_BLOCK.sub(" ", text)
    prose = re.sub(r"`[^`]*`", " ", prose)
    letters = [c for c in prose if c.isalpha()]
    if not letters:
        return 0.0
    return sum(1 for c in letters if "Ѐ" <= c <= "ӿ") / len(letters)


def grade_case(case: dict, response: str, global_bad: list[str]) -> list[str]:
    problems: list[str] = []
    for pattern in case.get("must", []):
        if not re.search(pattern, response, re.I | re.S):
            problems.append(f"missing /{pattern}/")
    for pattern in case.get("must_not", []):
        m = re.search(pattern, response, re.S)
        if m:
            problems.append(f"forbidden /{pattern}/ matched {m.group(0)[:40]!r}")
    if case.get("lang") == "mn" and cyrillic_ratio(response) < 0.30:
        problems.append(f"reply not in Mongolian (Cyrillic ratio {cyrillic_ratio(response):.0%})")
    if case.get("kind") == "trigger":
        for index, block in enumerate(CODE_BLOCK.findall(response), start=1):
            for pattern in global_bad:
                m = re.search(pattern, luau_lint.build_views(block)[0])
                if m:
                    problems.append(f"code block {index}: deprecated/unsafe /{pattern}/")
            for f in luau_lint.lint_source(block, f"block{index}", require_strict=False):
                if f.severity == "error":
                    problems.append(f"code block {index}: lint {f.rule} {f.message[:70]}")
    return problems


def grade_dir(run_dir: str, only: set[str] | None = None) -> int:
    data = load_cases()
    global_bad = data.get("global_must_not_in_code", [])
    report = []
    failed = missing = 0
    for case in data["cases"]:
        if only and case["id"] not in only:
            continue
        path = os.path.join(run_dir, f"{case['id']}.md")
        if not os.path.isfile(path):
            missing += 1
            report.append({"id": case["id"], "status": "missing"})
            print(f"  ? {case['id']}: no response file")
            continue
        with open(path, encoding="utf-8") as fh:
            problems = grade_case(case, fh.read(), global_bad)
        status = "pass" if not problems else "fail"
        failed += status == "fail"
        report.append({"id": case["id"], "status": status, "problems": problems})
        print(f"  {'✓' if status == 'pass' else '✗'} {case['id']}")
        for p in problems:
            print(f"      - {p}")
    graded = len(report) - missing
    print(f"\n{graded - failed}/{graded} passed" + (f", {missing} missing" if missing else ""))
    with open(os.path.join(run_dir, "report.json"), "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2, ensure_ascii=False)
    return 1 if failed or missing else 0


def run(cmd: str, out_dir: str, only: set[str] | None, timeout: int) -> int:
    os.makedirs(out_dir, exist_ok=True)
    for case in load_cases()["cases"]:
        if only and case["id"] not in only:
            continue
        print(f"  … {case['id']}")
        try:
            proc = subprocess.run(shlex.split(cmd) + [case["prompt"]], capture_output=True, text=True, timeout=timeout)
            output = proc.stdout if proc.returncode == 0 else f"[exit {proc.returncode}]\n{proc.stdout}\n{proc.stderr}"
        except subprocess.TimeoutExpired:
            output = "[timeout]"
        with open(os.path.join(out_dir, f"{case['id']}.md"), "w", encoding="utf-8") as fh:
            fh.write(output)
    return grade_dir(out_dir, only)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="run_evals", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    g = sub.add_parser("grade", help="grade saved responses in a directory")
    g.add_argument("run_dir")
    g.add_argument("--only", default="")
    r = sub.add_parser("run", help="generate responses with a CLI, then grade")
    r.add_argument("--cmd", required=True, help='e.g. "claude -p"; the prompt is appended as the last argument')
    r.add_argument("--out", default=os.path.join(ROOT, "evals", "runs", _dt.datetime.now().strftime("%Y%m%d-%H%M%S")))
    r.add_argument("--only", default="")
    r.add_argument("--timeout", type=int, default=600)
    args = parser.parse_args(argv)
    only = {s for s in args.only.split(",") if s} or None
    if args.command == "grade":
        return grade_dir(args.run_dir, only)
    return run(args.cmd, args.out, only, args.timeout)


if __name__ == "__main__":
    sys.exit(main())
