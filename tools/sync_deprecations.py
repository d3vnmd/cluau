#!/usr/bin/env python3
"""
Regenerate cluau's deprecated-API database from the official Roblox docs source.

    git clone --depth 1 https://github.com/Roblox/creator-docs /path/to/creator-docs
    python3 tools/sync_deprecations.py /path/to/creator-docs

Writes:
    skills/cluau/scripts/data/deprecated_apis.json   (consumed by luau_lint.py, rules CL2xx)
    skills/cluau/references/deprecated-index.md      (human/Claude-readable table)

Only members whose *name* is deprecated everywhere it appears are turned into lint rules, so names that are
still valid on another class (e.g. `BindableEvent:Fire` vs deprecated `InputAction:Fire`) never false-positive.
"""
from __future__ import annotations

import datetime as _dt
import glob
import json
import os
import re
import subprocess
import sys

import yaml  # PyYAML

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_JSON = os.path.join(ROOT, "skills", "cluau", "scripts", "data", "deprecated_apis.json")
OUT_MD = os.path.join(ROOT, "skills", "cluau", "references", "deprecated-index.md")
OUT_FEATURES = os.path.join(ROOT, "skills", "cluau", "references", "platform-features.md")

SECTIONS = ("properties", "methods", "events", "callbacks", "functions")
SKIP_OWNER = re.compile(r"Plugin|Studio|Selection|Dragger|CoreGui|DebuggerManager|ScriptEditor|Toolbar|Ribbon|Lasso")
# Names that collide with common user fields / R6 body parts / non-API usage. Never lint these generically.
GENERIC_NAMES = {
    "Color", "Score", "Pitch", "Rotation", "Root", "Torso", "LeftLeg", "RightLeg", "size", "position", "force",
    "velocity", "cframe", "location", "maxForce", "maxTorque", "angularvelocity", "changed", "focus", "hit",
    "target", "equipped", "unequipped", "part1", "Shiny", "Specular", "Puffiness", "Stiffness", "ShrinkFactor",
    "Localize", "Elasticity", "Friction", "SpecificGravity", "AssetId", "ApiKey", "OnClose", "workspace",
    "lighting", "Transparency", "Insert", "Reset", "Sense", "fire", "Interpolate", "move", "moveTo", "resize",
}
CLASS_CONTEXT_SKIP = {"Plane", "Status", "Hat", "Flag", "Message", "Hint", "Skin", "Hole"}  # only via Instance.new/IsA


def clean(msg: str | None) -> str:
    if not msg:
        return ""
    text = re.sub(r"`(?:Class|Enum|Datatype|Library|Global)\.([\w.:]+)\|([^`]+)`", r"`\2`", msg)
    text = re.sub(r"`(?:Class|Enum|Datatype|Library|Global)\.([\w.:]+)`", r"`\1`", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = " ".join(text.split())
    first = re.split(r"(?<=[.!?])\s", text, maxsplit=1)[0]
    return first[:220]


def load(docs: str):
    base = os.path.join(docs, "content", "en-us", "reference", "engine")
    deprecated: list[dict] = []
    alive_names: set[str] = set()
    classes_deprecated: list[dict] = []
    for kind in ("classes", "datatypes", "enums", "globals", "libraries"):
        for path in sorted(glob.glob(os.path.join(base, kind, "*.yaml"))):
            try:
                data = yaml.safe_load(open(path, encoding="utf-8"))
            except yaml.YAMLError:
                continue
            if not isinstance(data, dict):
                continue
            owner = str(data.get("name", ""))
            owner_dep = "Deprecated" in (data.get("tags") or [])
            if owner_dep and kind in ("classes", "enums"):
                classes_deprecated.append({"name": owner, "kind": "class" if kind == "classes" else "enum", "message": clean(data.get("deprecation_message"))})
            for sec in SECTIONS:
                for member in data.get(sec) or []:
                    if not isinstance(member, dict) or not member.get("name"):
                        continue
                    full = str(member["name"])
                    short = re.split(r"[.:]", full)[-1]
                    is_dep = "Deprecated" in (member.get("tags") or []) or bool(member.get("deprecation_message")) or owner_dep
                    if is_dep:
                        if not SKIP_OWNER.search(owner):
                            deprecated.append({
                                "full": full if (":" in full or "." in full) else f"{owner}.{full}",
                                "name": short,
                                "kind": sec[:-1] if sec != "properties" else "property",
                                "owner": owner,
                                "message": clean(member.get("deprecation_message")),
                            })
                    else:
                        alive_names.add(short)
    return deprecated, alive_names, classes_deprecated


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    docs = sys.argv[1]
    deprecated, alive, classes = load(docs)
    try:
        rev = subprocess.check_output(["git", "-C", docs, "log", "-1", "--format=%H %cs"], text=True).strip()
    except Exception:
        rev = "unknown"

    seen: set[tuple[str, str]] = set()
    members = []
    for entry in sorted(deprecated, key=lambda e: (e["owner"], e["name"])):
        key = (entry["name"], entry["kind"])
        lintable = entry["name"] not in alive and entry["name"] not in GENERIC_NAMES and len(entry["name"]) >= 4
        entry["lint"] = lintable
        if lintable and key in seen:
            entry["lint"] = False  # one rule per name is enough
        seen.add(key)
        members.append(entry)

    for e in members:
        if e["owner"].lower().endswith("globals"):
            e["kind"] = "global"
            e["full"] = e["name"]
    globals_ = sorted({e["name"] for e in members if e["kind"] == "global"})
    payload = {
        "source": "https://github.com/Roblox/creator-docs",
        "source_revision": rev,
        "generated": _dt.date.today().isoformat(),
        "classes": [c for c in classes],
        "class_context_only": sorted(CLASS_CONTEXT_SKIP),
        "members": members,
        "globals": globals_,
    }
    os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
    with open(OUT_JSON, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=1, ensure_ascii=False)
        fh.write("\n")

    lines = [
        "# Deprecated API Index (generated)",
        "",
        f"Generated from the official Roblox docs source (`Roblox/creator-docs` @ `{rev}`, CC BY 4.0 by Roblox)",
        "by `tools/sync_deprecations.py`.",
        "Do not edit by hand — re-run the tool. Hand-written migration advice lives in `deprecated-apis.md`.",
        "",
        "Never emit anything in this file in new code. `lint` = flagged automatically by `scripts/luau_lint.py`.",
        "",
        "## Deprecated classes / enums",
        "",
        "| Name | Kind | Replacement / note |",
        "|---|---|---|",
    ]
    for c in classes:
        lines.append(f"| `{c['name']}` | {c['kind']} | {c['message'] or '—'} |")
    lines += ["", "## Deprecated members", "", "| Member | Kind | Lint | Replacement / note |", "|---|---|---|---|"]
    for m in members:
        lines.append(f"| `{m['full']}` | {m['kind']} | {'yes' if m['lint'] else ''} | {m['message'] or '—'} |")
    with open(OUT_MD, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")

    write_features(docs, rev)
    print(f"{len(classes)} classes/enums, {len(members)} members ({sum(m['lint'] for m in members)} lintable) → {OUT_JSON}")
    return 0


def write_features(docs: str, rev: str) -> None:
    """Render Roblox's agent-facing feature feed (what to use now, what it replaces) into a reference file."""
    feed_path = os.path.join(docs, "content", "en-us", "latest-features", "latest-features.json")
    if not os.path.isfile(feed_path):
        return
    with open(feed_path, encoding="utf-8") as fh:
        feed = json.load(fh)
    lines = [
        "# Current Platform Features (generated)",
        "",
        f"Source: Roblox `latest-features.json` (updated {feed.get('updatedAt', '?')}) from `Roblox/creator-docs` @ `{rev}`,",
        "licensed CC BY 4.0 by Roblox. Regenerate with `tools/sync_deprecations.py`; do not edit by hand.",
        "",
        "Roblox publishes this feed for AI agents: each entry is the *current* way to build something and lists what it",
        "replaces. When a request touches one of these areas, follow the guidance here over older habits.",
        "",
    ]
    for f in feed.get("features", []):
        lines += [
            f"## {f.get('name')} — {f.get('status')} ({f.get('releasedAt', '?')})",
            "",
            f.get("summary", ""),
            "",
            "- **Use:** " + ", ".join(f"`{a}`" for a in f.get("apis", [])),
            "- **Replaces:** " + "; ".join(f.get("replaces", [])),
            f"- **Guidance:** {f.get('guidance', '')}",
            f"- **Docs:** {f.get('docsUrl', '')}",
            "",
        ]
    with open(OUT_FEATURES, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


if __name__ == "__main__":
    sys.exit(main())
