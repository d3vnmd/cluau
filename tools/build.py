#!/usr/bin/env python3
"""
Validate the cluau skill and package release artifacts.

    python3 tools/build.py check      # validate only
    python3 tools/build.py package    # validate + write dist/

Artifacts (dist/):
    cluau-skill-v<version>.zip   — upload to Claude.ai (Settings → Capabilities → Skills) or unzip into ~/.claude/skills/
    cluau-skill.zip              — same, stable name for "latest" download links
    SHA256SUMS.txt
"""
from __future__ import annotations

import glob
import hashlib
import json
import os
import re
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILL_DIR = os.path.join(ROOT, "skills", "cluau")
DIST = os.path.join(ROOT, "dist")
PLUGIN_JSON = os.path.join(ROOT, ".claude-plugin", "plugin.json")
MARKETPLACE_JSON = os.path.join(ROOT, ".claude-plugin", "marketplace.json")
CHANGELOG = os.path.join(ROOT, "CHANGELOG.md")

NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
EXCLUDE_DIRS = {"__pycache__", ".pytest_cache"}
EXCLUDE_FILES = {".DS_Store"}


def fail(errors: list[str]) -> None:
    for e in errors:
        print(f"  ✗ {e}")
    sys.exit(1)


def parse_frontmatter(text: str) -> dict[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        raise ValueError("SKILL.md must start with a YAML frontmatter block")
    try:
        import yaml  # type: ignore

        data = yaml.safe_load(m.group(1))
        return {str(k): str(v) for k, v in data.items()}
    except ImportError:
        data: dict[str, str] = {}
        for line in m.group(1).splitlines():
            if ":" in line and not line.startswith(" "):
                key, value = line.split(":", 1)
                data[key.strip()] = value.strip()
        return data


def check() -> str:
    errors: list[str] = []
    skill_md_path = os.path.join(SKILL_DIR, "SKILL.md")
    with open(skill_md_path, encoding="utf-8") as fh:
        skill_md = fh.read()

    fm = parse_frontmatter(skill_md)
    name = fm.get("name", "")
    desc = fm.get("description", "")
    if not NAME_RE.match(name) or len(name) > 64:
        errors.append(f"frontmatter name '{name}' must be lowercase-hyphenated, ≤ 64 chars")
    if name != os.path.basename(SKILL_DIR):
        errors.append(f"frontmatter name '{name}' must match folder name '{os.path.basename(SKILL_DIR)}'")
    if not desc or len(desc) > 1024:
        errors.append(f"description must be 1..1024 chars (is {len(desc)})")
    if "<" in desc or ">" in desc:
        errors.append("description must not contain angle brackets")

    body_lines = skill_md.count("\n")
    if body_lines > 500:
        errors.append(f"SKILL.md is {body_lines} lines; keep it ≤ 500 and move detail into references/")

    # Every referenced bundled file must exist.
    for ref in sorted(set(re.findall(r"`((?:references|templates|scripts|assets)/[^`\s*]+)`", skill_md))):
        if not os.path.exists(os.path.join(SKILL_DIR, ref)):
            errors.append(f"SKILL.md references missing file: {ref}")

    with open(PLUGIN_JSON, encoding="utf-8") as fh:
        plugin = json.load(fh)
    with open(MARKETPLACE_JSON, encoding="utf-8") as fh:
        marketplace = json.load(fh)
    version = plugin.get("version", "")
    if not re.match(r"^\d+\.\d+\.\d+$", version):
        errors.append(f"plugin.json version '{version}' is not semver")
    if plugin.get("name") != name:
        errors.append("plugin.json name must equal the skill name")
    entries = [p for p in marketplace.get("plugins", []) if p.get("name") == name]
    if not entries:
        errors.append("marketplace.json must list the cluau plugin")
    elif entries[0].get("version") not in (None, version):
        errors.append("marketplace.json plugin version must match plugin.json")

    with open(CHANGELOG, encoding="utf-8") as fh:
        if f"## [{version}]" not in fh.read():
            errors.append(f"CHANGELOG.md has no '## [{version}]' section")

    # Freshness: every hand-written reference carries a "Last verified: YYYY-MM-DD" stamp.
    import datetime

    for ref_path in sorted(glob.glob(os.path.join(SKILL_DIR, "references", "*.md"))):
        ref_name = os.path.basename(ref_path)
        if ref_name in ("deprecated-index.md", "platform-features.md"):
            continue  # generated; carry the docs revision instead
        with open(ref_path, encoding="utf-8") as fh:
            m = re.search(r"Last verified: (\d{4}-\d{2}-\d{2})", fh.read())
        if not m:
            errors.append(f"references/{ref_name} has no 'Last verified: YYYY-MM-DD' stamp")
            continue
        age = (datetime.date.today() - datetime.date.fromisoformat(m.group(1))).days
        if age > 120:
            print(f"  ! references/{ref_name} last verified {age} days ago — re-run tools/verify_api_refs.py and restamp")

    data_path = os.path.join(SKILL_DIR, "scripts", "data", "deprecated_apis.json")
    if not os.path.isfile(data_path):
        errors.append("scripts/data/deprecated_apis.json missing — run tools/sync_deprecations.py <creator-docs>")
    else:
        with open(data_path, encoding="utf-8") as fh:
            if sum(1 for m in json.load(fh).get("members", []) if m.get("lint")) < 100:
                errors.append("deprecated_apis.json has suspiciously few lintable members")

    # Lint the templates: they must be clean.
    sys.path.insert(0, os.path.join(SKILL_DIR, "scripts"))
    import luau_lint  # type: ignore

    for path in luau_lint.iter_files([os.path.join(SKILL_DIR, "templates")]):
        with open(path, encoding="utf-8") as fh:
            for f in luau_lint.lint_source(fh.read(), path):
                errors.append(f"{os.path.relpath(path, ROOT)}:{f.line}: {f.rule} {f.message}")

    if errors:
        print("cluau check failed:")
        fail(errors)
    print(f"cluau check passed (skill '{name}', version {version})")
    return version


def package(version: str) -> None:
    os.makedirs(DIST, exist_ok=True)
    versioned = os.path.join(DIST, f"cluau-skill-v{version}.zip")
    latest = os.path.join(DIST, "cluau-skill.zip")

    for target in (versioned, latest):
        with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as zf:
            for root, dirs, files in os.walk(SKILL_DIR):
                dirs[:] = sorted(d for d in dirs if d not in EXCLUDE_DIRS)
                for fname in sorted(files):
                    if fname in EXCLUDE_FILES or fname.endswith(".pyc"):
                        continue
                    full = os.path.join(root, fname)
                    arc = os.path.join("cluau", os.path.relpath(full, SKILL_DIR))
                    info = zipfile.ZipInfo(arc, date_time=(2024, 1, 1, 0, 0, 0))  # reproducible
                    info.external_attr = (0o755 if fname.endswith(".py") else 0o644) << 16
                    info.compress_type = zipfile.ZIP_DEFLATED
                    with open(full, "rb") as fh:
                        zf.writestr(info, fh.read())

    with open(os.path.join(DIST, "SHA256SUMS.txt"), "w", encoding="utf-8") as out:
        for target in (versioned, latest):
            with open(target, "rb") as fh:
                digest = hashlib.sha256(fh.read()).hexdigest()
            out.write(f"{digest}  {os.path.basename(target)}\n")
    print(f"packaged → {os.path.relpath(versioned, ROOT)}, {os.path.relpath(latest, ROOT)}")


def main() -> int:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    if cmd not in ("check", "package"):
        print(__doc__)
        return 2
    version = check()
    if cmd == "package":
        package(version)
    return 0


if __name__ == "__main__":
    sys.exit(main())
