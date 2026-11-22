#!/usr/bin/env python3
"""
Check that every `Class:Method` / `Class.Member` / `Enum.X.Y` mentioned in the skill exists in the official docs.

    python3 tools/verify_api_refs.py /path/to/creator-docs

Scans SKILL.md, references/*.md (except generated files) and templates/**/*.luau. Inherited members are resolved
through each class's `inherits` chain. Exit code 1 if any reference cannot be found — i.e. a likely hallucination.
"""
from __future__ import annotations

import glob
import os
import re
import sys

import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILL = os.path.join(ROOT, "skills", "cluau")
GENERATED = {"deprecated-index.md", "platform-features.md"}
SECTIONS = ("properties", "methods", "events", "callbacks")

TOKEN = re.compile(r"\b([A-Z][A-Za-z0-9]+)([:.])([A-Za-z_][A-Za-z0-9_]*)\b")
ENUM_TOKEN = re.compile(r"\bEnum\.([A-Za-z0-9]+)\.([A-Za-z0-9_]+)\b")
# Prefixes that look like classes but are namespaces/modules/our own code.
IGNORE_PREFIX = {
    "Enum", "Config", "Theme", "Components", "Net", "Guard", "RateLimiter", "Trove", "DataService", "ShopService",
    "MonetizationService", "UIController", "ProfileStore", "Dash", "Timer", "Main", "Shared", "Services", "Controllers",
    "ReplicatedStorage", "ServerScriptService", "StarterPlayer", "StarterPlayerScripts", "ServerStorage", "Workspace_",
    "Window", "Test", "Game", "File", "Settings", "Avatar", "Assistant", "Shift", "Ctrl", "Left", "Studio", "Font",
    "UDim", "UDim2", "Vector2", "Vector3", "CFrame", "Color3", "TweenInfo", "Random", "DateTime", "Ray", "Region3",
    "NumberSequence", "ColorSequence", "NumberRange", "Rect", "PhysicalProperties", "RaycastParams", "OverlapParams",
    "BrickColor", "Instance", "Players_", "TextChannels", "Packages", "BufferCodec", "ModerationService", "Simulation",
}


# Enums used throughout the docs' own code samples but lacking a reference page in the snapshot.
KNOWN_UNDOCUMENTED_ENUMS = {"FontWeight"}


def load_docs(docs: str):
    base = os.path.join(docs, "content", "en-us", "reference", "engine")
    classes: dict[str, dict] = {}
    for path in glob.glob(os.path.join(base, "classes", "*.yaml")) + glob.glob(os.path.join(base, "datatypes", "*.yaml")):
        try:
            data = yaml.safe_load(open(path, encoding="utf-8"))
        except yaml.YAMLError:
            continue
        if not isinstance(data, dict) or not data.get("name"):
            continue
        members = set()
        for sec in SECTIONS + ("constructors", "functions", "math_operations"):
            for m in data.get(sec) or []:
                if isinstance(m, dict) and m.get("name"):
                    members.add(re.split(r"[.:]", str(m["name"]))[-1])
        entry = classes.setdefault(str(data["name"]), {"inherits": [], "members": set()})
        entry["inherits"] += [i for i in (data.get("inherits") or []) if i not in entry["inherits"]]
        entry["members"] |= members  # classes/Instance.yaml and datatypes/Instance.yaml share a name
    enums: dict[str, set[str]] = {}
    for path in glob.glob(os.path.join(base, "enums", "*.yaml")):
        data = yaml.safe_load(open(path, encoding="utf-8"))
        if isinstance(data, dict):
            enums[str(data.get("name"))] = {str(i.get("name")) for i in data.get("items") or [] if isinstance(i, dict)}
    return classes, enums


def has_member(classes, cls: str, member: str, seen=None) -> bool:
    seen = seen or set()
    if cls in seen or cls not in classes:
        return False
    seen.add(cls)
    if member in classes[cls]["members"]:
        return True
    return any(has_member(classes, parent, member, seen) for parent in classes[cls]["inherits"])


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    classes, enums = load_docs(sys.argv[1])
    files = [os.path.join(SKILL, "SKILL.md")]
    files += [f for f in glob.glob(os.path.join(SKILL, "references", "*.md")) if os.path.basename(f) not in GENERATED]
    files += glob.glob(os.path.join(SKILL, "templates", "**", "*.luau"), recursive=True)

    problems: list[str] = []
    checked = 0
    for path in sorted(files):
        text = open(path, encoding="utf-8").read()
        for lineno, line in enumerate(text.splitlines(), start=1):
            if "verify-ignore" in line:
                continue
            for cls, _sep, member in TOKEN.findall(line):
                if cls in IGNORE_PREFIX or cls not in classes or len(member) < 2:
                    continue
                checked += 1
                if not has_member(classes, cls, member):
                    problems.append(f"{os.path.relpath(path, ROOT)}:{lineno}: {cls}{_sep}{member} not found in docs")
            for enum, item in ENUM_TOKEN.findall(line):
                if enum in KNOWN_UNDOCUMENTED_ENUMS or "verify-ignore" in line:
                    continue
                checked += 1
                if enum not in enums:
                    problems.append(f"{os.path.relpath(path, ROOT)}:{lineno}: Enum.{enum} not found in docs")
                elif item not in enums[enum]:
                    problems.append(f"{os.path.relpath(path, ROOT)}:{lineno}: Enum.{enum}.{item} not found in docs")

    for p in problems:
        print(p)
    print(f"verify_api_refs: {checked} API references checked, {len(problems)} not found")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
