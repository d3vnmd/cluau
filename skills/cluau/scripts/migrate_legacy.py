#!/usr/bin/env python3
"""
cluau-migrate: mechanically modernize legacy Roblox Luau (2015–2024 habits) — safely.

    python3 migrate_legacy.py PATH [PATH ...]            # dry run: prints a unified diff
    python3 migrate_legacy.py PATH --write               # apply in place
    python3 migrate_legacy.py PATH --json                # machine-readable summary

Only rewrites that keep behaviour equivalent are automatic (wait→task.wait, :connect→:Connect,
game.Players→game:GetService("Players"), SetPrimaryPartCFrame→PivotTo, pre-2025 names→…Async, …).
Changes inside strings and comments are never touched. Everything that needs judgement (BodyMovers,
FindPartOnRay, Region3, PhysicsService, legacy teleports, SetAsync on player data…) is reported as
MANUAL with the cluau-lint message, never rewritten.

Exit code: 0 always for dry runs; with --write, 0 on success.
"""
from __future__ import annotations

import argparse
import difflib
import json
import os
import re
import sys
from dataclasses import dataclass

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import luau_lint  # noqa: E402

NOT_MEMBER = r"(?<![\w.:])"

SERVICES = (
    "Players|Workspace|ReplicatedStorage|ReplicatedFirst|ServerStorage|ServerScriptService|Lighting|"
    "StarterGui|StarterPack|StarterPlayer|SoundService|Teams|TextChatService"
)

# Pre-2025 yielding names whose …Async replacement takes the same arguments.
ASYNC_RENAMES = (
    "LoadCharacter|LoadCharacterWithHumanoidDescription|IsFriendsWith|IsInGroup|GetFriendsOnline|"
    "ApplyDescription|ApplyDescriptionReset|PlayEmote|GetProductInfo|PlayerOwnsAsset|PlayerOwnsBundle|"
    "AwardBadge|UserHasBadge|CreateHumanoidModelFromDescription|CreateHumanoidModelFromUserId|"
    "GetHumanoidDescriptionFromUserId|GetHumanoidDescriptionFromOutfitId"
)


@dataclass(frozen=True)
class Rewrite:
    id: str
    pattern: re.Pattern
    replacement: str  # re.sub template applied to the matched text
    note: str


def RW(rule_id: str, pattern: str, replacement: str, note: str) -> Rewrite:
    return Rewrite(rule_id, re.compile(pattern), replacement, note)


REWRITES: list[Rewrite] = [
    RW("M01", NOT_MEMBER + r"wait(\s*\()", r"task.wait\1", "wait() → task.wait()"),
    RW("M02", NOT_MEMBER + r"spawn(\s*\()", r"task.spawn\1", "spawn() → task.spawn()"),
    RW("M03", NOT_MEMBER + r"delay(\s*\()", r"task.delay\1", "delay() → task.delay()"),
    RW("M04", r":(\s*)connect(\s*\()", r":\1Connect\2", ":connect → :Connect"),
    RW("M05", r":(\s*)disconnect(\s*\()", r":\1Disconnect\2", ":disconnect → :Disconnect"),
    RW("M06", r":(\s*)wait(\s*\()", r":\1Wait\2", ":wait → :Wait"),
    RW("M07", r":(\s*)Remove(\s*\(\s*\))", r":\1Destroy\2", ":Remove() → :Destroy()"),
    RW("M08", r":(\s*)(?:children|getChildren)(\s*\()", r":\1GetChildren\2", ":children → :GetChildren"),
    RW("M09", r":(\s*)findFirstChild(\s*\()", r":\1FindFirstChild\2", ":findFirstChild → :FindFirstChild"),
    RW("M10", r":(\s*)isA(\s*\()", r":\1IsA\2", ":isA → :IsA"),
    RW("M11", r":(\s*)clone(\s*\()", r":\1Clone\2", ":clone → :Clone"),
    RW("M12", r":(\s*)destroy(\s*\()", r":\1Destroy\2", ":destroy → :Destroy"),
    RW("M13", r":(\s*)(?:service|getService)(\s*\()", r":\1GetService\2", ":service → :GetService"),
    RW("M14", r"\bgame\s*\.\s*(" + SERVICES + r")\b", r'game:GetService("\1")', 'game.X → game:GetService("X")'),
    RW("M15", r":(\s*)SetPrimaryPartCFrame(\s*\()", r":\1PivotTo\2", "SetPrimaryPartCFrame → PivotTo"),
    RW("M16", r":(\s*)GetPrimaryPartCFrame(\s*\(\s*\))", r":\1GetPivot\2", "GetPrimaryPartCFrame → GetPivot"),
    RW("M17", r"Enum\.RaycastFilterType\.Blacklist\b", "Enum.RaycastFilterType.Exclude", "Blacklist → Exclude"),
    RW("M18", r"Enum\.RaycastFilterType\.Whitelist\b", "Enum.RaycastFilterType.Include", "Whitelist → Include"),
    RW("M19", r":(\s*)(" + ASYNC_RENAMES + r")(\s*\()", r":\1\2Async\3", "pre-2025 yielding name → …Async"),
    RW("M20", r"\btable\s*\.\s*getn\s*\(\s*([A-Za-z_][\w.]*)\s*\)", r"#\1", "table.getn(t) → #t"),
    RW("M21", r"\.(\s*)RotVelocity\b", r".\1AssemblyAngularVelocity", "RotVelocity → AssemblyAngularVelocity"),
    RW("M22", r"Players\s*\.\s*localPlayer\b", "Players.LocalPlayer", "Players.localPlayer → LocalPlayer"),
    RW("M23", r":(\s*)GetModelSize(\s*\(\s*\))", r":\1GetExtentsSize\2", "GetModelSize → GetExtentsSize"),
]


@dataclass
class Change:
    rule: str
    line: int
    before: str
    after: str
    note: str


def migrate_source(src: str) -> tuple[str, list[Change]]:
    """Applies all safe rewrites outside strings/comments. Returns (new_source, changes)."""
    changes: list[Change] = []
    current = src
    for rw in REWRITES:
        code_view = luau_lint.build_views(current)[0]
        edits: list[tuple[int, int, str]] = []
        for m in rw.pattern.finditer(code_view):
            original = current[m.start():m.end()]
            if original != m.group(0):
                continue  # match overlaps a string/comment region — leave it alone
            replacement = m.expand(rw.replacement)
            if replacement != original:
                edits.append((m.start(), m.end(), replacement))
        for start, end, replacement in reversed(edits):
            line = current.count("\n", 0, start) + 1
            changes.append(Change(rw.id, line, current[start:end], replacement, rw.note))
            current = current[:start] + replacement + current[end:]
    changes.sort(key=lambda c: (c.line, c.rule))
    return current, changes


def manual_items(src: str, path: str) -> list[luau_lint.Finding]:
    """Remaining errors/warnings after migration — things a human (or Claude) must decide."""
    return [f for f in luau_lint.lint_source(src, path, require_strict=False) if f.severity in ("error", "warn")]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="cluau-migrate", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--write", action="store_true", help="rewrite files in place")
    parser.add_argument("--json", action="store_true", help="print a JSON summary instead of diffs")
    args = parser.parse_args(argv)

    summary = []
    total = 0
    for path in luau_lint.iter_files(args.paths):
        with open(path, encoding="utf-8", errors="replace") as fh:
            src = fh.read()
        new_src, changes = migrate_source(src)
        manual = manual_items(new_src, path)
        total += len(changes)
        summary.append({
            "path": path,
            "changes": [c.__dict__ for c in changes],
            "manual": [{"line": f.line, "rule": f.rule, "message": f.message} for f in manual],
        })
        if args.write and changes:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(new_src)
        if not args.json:
            if changes and not args.write:
                sys.stdout.writelines(difflib.unified_diff(
                    src.splitlines(keepends=True), new_src.splitlines(keepends=True), f"a/{path}", f"b/{path}"))
            for f in manual:
                print(f"MANUAL {path}:{f.line}: {f.rule} {f.message}")

    if args.json:
        print(json.dumps(summary, indent=2, ensure_ascii=False))
    else:
        verb = "applied" if args.write else "proposed (dry run; use --write)"
        manual_count = sum(len(s["manual"]) for s in summary)
        print(f"cluau-migrate: {total} automatic change(s) {verb}; {manual_count} item(s) need manual migration", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
