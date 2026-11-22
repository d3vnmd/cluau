#!/usr/bin/env python3
"""
cluau-lint: zero-dependency checker for deprecated, legacy and unsafe Roblox Luau patterns.

Usage:
    python3 luau_lint.py PATH [PATH ...] [--format text|json] [--min-severity info|warn|error]
    python3 luau_lint.py --list-rules

PATH may be a .lua/.luau file or a directory (searched recursively).

Suppress a finding on one line:      foo() -- cluau-ignore CL001
Suppress several rules on one line:  foo() -- cluau-ignore CL001,CL022
Suppress all rules for a file:       --!cluau-ignore-file   (anywhere in the first 5 lines)

Exit code: 1 if any finding at severity "error" (after filters), else 0.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, asdict
from typing import Iterable

SEVERITY_ORDER = {"info": 0, "warn": 1, "error": 2}

# Target views a rule can match against:
#   code    - comments AND string contents blanked (identifiers / calls only)
#   strings - comments blanked, string literals intact (class names passed as strings)
#   text    - string literal contents only (UI copy checks)
@dataclass(frozen=True)
class Rule:
    id: str
    severity: str
    view: str
    pattern: re.Pattern
    message: str


def R(rule_id: str, severity: str, view: str, pattern: str, message: str, flags: int = 0) -> Rule:
    return Rule(rule_id, severity, view, re.compile(pattern, flags), message)


NOT_MEMBER = r"(?<![\w.:])"  # not preceded by identifier char, '.' or ':'

RULES: list[Rule] = [
    # ── scheduling ────────────────────────────────────────────────────────────
    R("CL001", "error", "code", NOT_MEMBER + r"wait\s*\(", "Deprecated `wait()` — use `task.wait()`."),
    R("CL002", "error", "code", NOT_MEMBER + r"spawn\s*\(", "Deprecated `spawn()` — use `task.spawn()` or `task.defer()`."),
    R("CL003", "error", "code", NOT_MEMBER + r"delay\s*\(", "Deprecated `delay()` — use `task.delay()`."),
    R("CL004", "warn", "code", NOT_MEMBER + r"tick\s*\(", "`tick()` is legacy — use `os.clock()`, `os.time()` or `workspace:GetServerTimeNow()`."),
    R("CL005", "warn", "code", NOT_MEMBER + r"(?:elapsedTime|ElapsedTime)\s*\(", "Legacy time function — use `os.clock()`."),
    # ── instances ─────────────────────────────────────────────────────────────
    R("CL010", "error", "strings", r"Instance\.new\s*\(\s*(?:\"[^\"\n]*\"|'[^'\n]*'|[\w.]+)\s*,", "`Instance.new(class, parent)` — set properties first and assign `.Parent` last."),
    R("CL011", "error", "code", r":\s*(?:connect|disconnect|wait)\s*\(", "Lowercase event methods are deprecated — use `:Connect`, `:Disconnect`, `:Wait`."),
    R("CL012", "error", "code", r":\s*Remove\s*\(\s*\)", "`:Remove()` is deprecated — use `:Destroy()`."),
    R("CL013", "error", "code", r":\s*(?:children|getChildren|findFirstChild|isA|clone|destroy|getService|service|IsDescendentOf|isDescendantOf)\s*\(", "Deprecated lowercase/misspelled Instance method — use the PascalCase API (`GetChildren`, `FindFirstChild`, `IsA`, `Clone`, `Destroy`, `GetService`, `IsDescendantOf`)."),
    R("CL014", "warn", "code", r"\bgame\s*\.\s*(?:Players|Workspace|ReplicatedStorage|ReplicatedFirst|ServerStorage|ServerScriptService|Lighting|StarterGui|StarterPack|StarterPlayer|SoundService|Teams|Chat|TextChatService)\b", "Access services with `game:GetService(\"Name\")` (cached in a local at the top)."),
    R("CL015", "error", "code", r":\s*(?:SetPrimaryPartCFrame|GetPrimaryPartCFrame|GetModelCFrame|GetModelSize)\s*\(", "Deprecated Model API — use `PivotTo`, `GetPivot`, `GetBoundingBox`, `GetExtentsSize`."),
    R("CL016", "error", "code", r":\s*(?:MakeJoints|BreakJoints)\s*\(", "`MakeJoints/BreakJoints` are deprecated — create `WeldConstraint`s explicitly."),
    R("CL017", "error", "strings", r"Instance\.new\s*\(\s*[\"'](?:Hint|Message|ManualWeld|ManualGlue|Glue|Snap|Rotate|RotateP|RotateV|VelocityMotor)[\"']", "Deprecated instance class — use custom UI / `WeldConstraint` / `Motor6D` / constraints."),
    R("CL018", "error", "code", r"\.\s*RotVelocity\b", "`RotVelocity` is deprecated — use `AssemblyAngularVelocity`."),
    R("CL019", "warn", "code", r"\bJointsService\b", "`JointsService` is deprecated."),
    # ── physics movers ────────────────────────────────────────────────────────
    R("CL020", "error", "strings", r"\b(?:BodyVelocity|BodyPosition|BodyGyro|BodyForce|BodyAngularVelocity|BodyThrust|RocketPropulsion)\b", "Legacy BodyMover — use `LinearVelocity`, `AlignPosition`, `AlignOrientation`, `VectorForce` or `AngularVelocity` with an Attachment."),
    # ── spatial queries ───────────────────────────────────────────────────────
    R("CL021", "error", "code", r":\s*FindPartOnRay(?:WithIgnoreList|WithWhitelist)?\s*\(", "Deprecated raycast — use `workspace:Raycast(origin, direction, RaycastParams)`."),
    R("CL022", "error", "code", r":\s*(?:FindPartsInRegion3(?:WithIgnoreList|WithWhiteList)?|IsRegion3Empty(?:WithIgnoreList)?)\s*\(", "Deprecated region query — use `GetPartBoundsInBox/InRadius` or `GetPartsInPart` with `OverlapParams`."),
    R("CL023", "error", "code", r"Enum\s*\.\s*RaycastFilterType\s*\.\s*(?:Blacklist|Whitelist)\b", "Use `Enum.RaycastFilterType.Exclude` / `Include`."),
    # ── animation / characters ────────────────────────────────────────────────
    R("CL030", "error", "code", r"\b\w*[Hh]umanoid\w*\s*:\s*LoadAnimation\s*\(", "`Humanoid:LoadAnimation` is deprecated — use the `Animator` inside the Humanoid."),
    R("CL031", "error", "code", r"\b\w*[Cc]ontroller\w*\s*:\s*LoadAnimation\s*\(", "`AnimationController:LoadAnimation` is deprecated — use its `Animator`."),
    # ── input ─────────────────────────────────────────────────────────────────
    R("CL040", "warn", "code", r":\s*GetMouse\s*\(\s*\)", "`Player:GetMouse()` is legacy — use `UserInputService`/`ContextActionService` and `Camera:ViewportPointToRay` + `workspace:Raycast`."),
    # ── services ──────────────────────────────────────────────────────────────
    R("CL050", "error", "code", r":\s*(?:CreateCollisionGroup|SetPartCollisionGroup|GetCollisionGroupId|RemoveCollisionGroup|GetCollisionGroupName)\s*\(", "Deprecated collision group API — use `RegisterCollisionGroup` and `BasePart.CollisionGroup = \"Name\"`."),
    R("CL051", "error", "code", r":\s*(?:Teleport|TeleportToPlaceInstance|TeleportToPrivateServer|TeleportPartyAsync|TeleportToSpawnByName)\s*\(", "Legacy teleport — use `TeleportService:TeleportAsync(placeId, players, TeleportOptions)`."),
    R("CL052", "error", "code", r":\s*(?:ComputeRawPathAsync|ComputeSmoothPathAsync)\s*\(", "Deprecated pathfinding — use `PathfindingService:CreatePath(params)` + `path:ComputeAsync()`."),
    R("CL053", "warn", "strings", r"GetService\s*\(\s*[\"']Chat[\"']\s*\)", "Legacy `Chat` service — use `TextChatService` and `TextService:FilterStringAsync`."),
    R("CL054", "error", "code", r":\s*(?:FilterStringForBroadcast|FilterStringForPlayerAsync)\s*\(", "Legacy chat filtering — use `TextService:FilterStringAsync` + `GetNonChatStringForBroadcastAsync`."),
    R("CL055", "error", "code", r":\s*UserHasBadge\s*\(", "Use `BadgeService:UserHasBadgeAsync` (server, in pcall)."),
    R("CL056", "warn", "code", r":\s*PlayerOwnsAsset\s*\(", "For game passes use `MarketplaceService:UserOwnsGamePassAsync`."),
    R("CL057", "error", "code", r"\bPointsService\b", "`PointsService` was removed."),
    R("CL058", "warn", "code", r"\bFilteringEnabled\b", "FilteringEnabled is always on — remove the check and design server-authoritatively."),
    # ── data ──────────────────────────────────────────────────────────────────
    R("CL060", "warn", "code", r":\s*SetAsync\s*\(", "Prefer `UpdateAsync` (session-locked) or ProfileStore for player data; `SetAsync` overwrites blindly."),
    # ── security ──────────────────────────────────────────────────────────────
    R("CL070", "error", "code", NOT_MEMBER + r"loadstring\s*\(", "`loadstring` enables remote code execution — never use it."),
    R("CL071", "error", "code", NOT_MEMBER + r"(?:getfenv|setfenv)\s*\(", "`getfenv/setfenv` disable Luau optimizations and are a backdoor/obfuscation smell."),
    R("CL072", "error", "code", NOT_MEMBER + r"require\s*\(\s*\d+\s*\)", "`require(<assetId>)` loads third-party code that can change at any time — vendor and review it."),
    R("CL073", "error", "code", r":\s*InvokeClient\s*\(", "`RemoteFunction:InvokeClient` lets a client hang the server — use RemoteEvents for server→client."),
    R("CL074", "error", "code", NOT_MEMBER + r"LoadLibrary\s*\(", "`LoadLibrary` was removed."),
    R("CL075", "warn", "code", NOT_MEMBER + r"(?:_G|shared)\s*\.", "Avoid `_G`/`shared` globals — use ModuleScripts."),
    R("CL076", "warn", "code", r"\bLoadStringEnabled\b", "Never enable `LoadStringEnabled`."),
    # ── stdlib ────────────────────────────────────────────────────────────────
    R("CL080", "error", "code", r"\btable\s*\.\s*(?:getn|foreach|foreachi|maxn)\b", "Removed Lua 5.0 table function — use `#t` and generalized `for`."),
    R("CL081", "warn", "code", NOT_MEMBER + r"unpack\s*\(", "Use `table.unpack`."),
    R("CL082", "warn", "code", r"\bmath\s*\.\s*pow\s*\(", "`math.pow` does not exist in Luau — use `x ^ y`."),
    # ── UI anti-slop ──────────────────────────────────────────────────────────
    R("CL090", "warn", "code", r"\bTextScaled\s*=\s*true\b", "`TextScaled = true` causes inconsistent text sizes — use a type scale (`TextSize`) + `UITextSizeConstraint` only where needed."),
    R("CL091", "warn", "code", r"\bFont\s*=\s*Enum\s*\.\s*Font\s*\.", "Use `FontFace = Font.new(\"rbxasset://fonts/families/<Family>.json\", weight)` for weights and consistency."),
    R("CL092", "warn", "code", r"\bBorderSizePixel\s*=\s*[1-9]", "Use `UIStroke` instead of `BorderSizePixel` borders."),
    R("CL093", "warn", "code", r"\bAutoButtonColor\s*=\s*true\b", "Implement explicit hover/pressed/disabled states instead of `AutoButtonColor`."),
    R("CL094", "warn", "text", "[\U0001F300-\U0001FAFF\U00002600-\U000026FF\U00002700-\U000027BF\U0001F000-\U0001F2FF]", "Emoji in UI text — use a consistent icon set (images) or plain text."),
    R("CL095", "info", "text", r"(?i)\b(?:welcome to the game|click here|lorem ipsum|awesome shop|item \d+)\b", "Generic placeholder copy — write specific copy in the game's voice."),
]

RULES_BY_ID = {rule.id: rule for rule in RULES}

SUPPRESS_RE = re.compile(r"--\s*cluau-ignore\s+([A-Z0-9,\s]+)")
FILE_SUPPRESS_RE = re.compile(r"--!cluau-ignore-file")


@dataclass
class Finding:
    path: str
    line: int
    column: int
    severity: str
    rule: str
    message: str


def _long_bracket_level(src: str, i: int) -> int | None:
    """If src[i] starts a long bracket `[==[`, return its level, else None."""
    if src[i] != "[":
        return None
    j = i + 1
    level = 0
    while j < len(src) and src[j] == "=":
        level += 1
        j += 1
    if j < len(src) and src[j] == "[":
        return level
    return None


def build_views(src: str) -> tuple[str, str, str]:
    """
    Returns (code, strings, text) views of `src`, all the same length with newlines preserved:
      code    - comments and string contents replaced by spaces (quotes kept)
      strings - comments replaced by spaces, strings intact
      text    - only string contents kept; everything else spaces
    """
    n = len(src)
    code = list(src)
    strings = list(src)
    text = [c if c == "\n" else " " for c in src]

    def blank(buf: list[str], start: int, end: int) -> None:
        for k in range(start, end):
            if buf[k] != "\n":
                buf[k] = " "

    def keep_text(start: int, end: int) -> None:
        for k in range(start, end):
            text[k] = src[k]

    i = 0
    while i < n:
        c = src[i]
        # comments
        if c == "-" and src.startswith("--", i):
            start = i
            level = _long_bracket_level(src, i + 2) if i + 2 < n else None
            if level is not None:
                close = "]" + "=" * level + "]"
                end = src.find(close, i + 2)
                end = n if end == -1 else end + len(close)
            else:
                end = src.find("\n", i)
                end = n if end == -1 else end
            blank(code, start, end)
            blank(strings, start, end)
            i = end
            continue
        # long strings
        if c == "[":
            level = _long_bracket_level(src, i)
            if level is not None:
                open_len = level + 2
                close = "]" + "=" * level + "]"
                end = src.find(close, i + open_len)
                end = n if end == -1 else end + len(close)
                inner_start, inner_end = i + open_len, max(i + open_len, end - len(close))
                blank(code, inner_start, inner_end)
                keep_text(inner_start, inner_end)
                i = end
                continue
        # quoted / interpolated strings
        if c in "\"'`":
            quote = c
            j = i + 1
            while j < n:
                ch = src[j]
                if ch == "\\":
                    j += 2
                    continue
                if ch == quote:
                    break
                if ch == "\n" and quote != "`":
                    break  # unterminated; stop at end of line
                j += 1
            end = min(j, n)
            blank(code, i + 1, end)
            keep_text(i + 1, end)
            i = end + 1
            continue
        i += 1

    return "".join(code), "".join(strings), "".join(text)


def _line_starts(src: str) -> list[int]:
    starts = [0]
    for idx, ch in enumerate(src):
        if ch == "\n":
            starts.append(idx + 1)
    return starts


def _locate(starts: list[int], offset: int) -> tuple[int, int]:
    lo, hi = 0, len(starts) - 1
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if starts[mid] <= offset:
            lo = mid
        else:
            hi = mid - 1
    return lo + 1, offset - starts[lo] + 1


def lint_source(src: str, path: str = "<input>", require_strict: bool = True) -> list[Finding]:
    lines = src.splitlines()
    head = "\n".join(lines[:5])
    if FILE_SUPPRESS_RE.search(head):
        return []

    code, strings, text = build_views(src)
    views = {"code": code, "strings": strings, "text": text}
    starts = _line_starts(src)
    findings: list[Finding] = []

    def suppressed(line_no: int, rule_id: str) -> bool:
        if line_no - 1 >= len(lines):
            return False
        m = SUPPRESS_RE.search(lines[line_no - 1])
        if not m:
            return False
        ids = {part.strip() for part in m.group(1).replace(",", " ").split()}
        return rule_id in ids or "ALL" in ids

    for rule in RULES:
        for match in rule.pattern.finditer(views[rule.view]):
            line_no, col = _locate(starts, match.start())
            if suppressed(line_no, rule.id):
                continue
            findings.append(Finding(path, line_no, col, rule.severity, rule.id, rule.message))

    if require_strict and src.strip():
        first_code = next((ln for ln in lines if ln.strip()), "")
        if not any(ln.strip().startswith("--!strict") for ln in lines[:3]) and not first_code.startswith("--!nonstrict"):
            if not suppressed(1, "CL100"):
                findings.append(Finding(path, 1, 1, "info", "CL100", "Add `--!strict` at the top of new scripts."))

    findings.sort(key=lambda f: (f.line, f.column, f.rule))
    return findings


def iter_files(paths: Iterable[str]) -> Iterable[str]:
    for p in paths:
        if os.path.isdir(p):
            for root, dirs, files in os.walk(p):
                dirs[:] = [d for d in dirs if not d.startswith(".") and d not in ("node_modules", "Packages", "DevPackages")]
                for name in sorted(files):
                    if name.endswith((".lua", ".luau")):
                        yield os.path.join(root, name)
        elif os.path.isfile(p):
            yield p
        else:
            print(f"cluau-lint: no such file or directory: {p}", file=sys.stderr)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="cluau-lint", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="*", help="files or directories to lint")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument("--min-severity", choices=tuple(SEVERITY_ORDER), default="info")
    parser.add_argument("--no-strict-check", action="store_true", help="don't report missing --!strict")
    parser.add_argument("--list-rules", action="store_true")
    args = parser.parse_args(argv)

    if args.list_rules:
        for rule in RULES:
            print(f"{rule.id}  {rule.severity:<5}  {rule.message}")
        print("CL100  info   Add `--!strict` at the top of new scripts.")
        return 0

    if not args.paths:
        parser.error("no paths given")

    threshold = SEVERITY_ORDER[args.min_severity]
    all_findings: list[Finding] = []
    file_count = 0
    for path in iter_files(args.paths):
        file_count += 1
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            src = fh.read()
        for f in lint_source(src, path, require_strict=not args.no_strict_check):
            if SEVERITY_ORDER[f.severity] >= threshold:
                all_findings.append(f)

    errors = sum(1 for f in all_findings if f.severity == "error")
    warns = sum(1 for f in all_findings if f.severity == "warn")
    infos = sum(1 for f in all_findings if f.severity == "info")

    if args.format == "json":
        print(json.dumps({
            "files": file_count,
            "errors": errors,
            "warnings": warns,
            "infos": infos,
            "findings": [asdict(f) for f in all_findings],
        }, indent=2, ensure_ascii=False))
    else:
        for f in all_findings:
            print(f"{f.path}:{f.line}:{f.column}: {f.severity} {f.rule} {f.message}")
        print(f"cluau-lint: {file_count} file(s), {errors} error(s), {warns} warning(s), {infos} info", file=sys.stderr)

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
