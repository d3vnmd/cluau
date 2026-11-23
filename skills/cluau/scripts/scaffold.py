#!/usr/bin/env python3
"""
cluau-scaffold: create a ready-to-sync Rojo project from the cluau templates.

Usage:
    python3 scaffold.py <target-dir> [--name my-game] [--force]

Produces:
    <target>/default.project.json, selene.toml, stylua.toml, rokit.toml, .luaurc, .gitignore
    <target>/src/server/Main.server.luau
    <target>/src/server/Services/{DataService,MonetizationService,ShopService}.luau
    <target>/src/client/Main.client.luau
    <target>/src/client/Controllers/UIController.luau
    <target>/src/shared/{Config,Net,Guard,RateLimiter,Trove}.luau
    <target>/src/shared/UI/{Theme,Components}.luau

Studio-only users: create the same hierarchy by hand (see SKILL.md §10 for Instance types).
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import sys

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATES = os.path.join(SKILL_DIR, "templates")
ASSETS = os.path.join(SKILL_DIR, "assets", "project")

FILE_MAP = {
    "server/Main.server.luau": "src/server/Main.server.luau",
    "server/DataService.luau": "src/server/Services/DataService.luau",
    "server/MonetizationService.luau": "src/server/Services/MonetizationService.luau",
    "server/ShopService.luau": "src/server/Services/ShopService.luau",
    "server/ModerationService.luau": "src/server/Services/ModerationService.luau",
    "server/TradeLogic.luau": "src/server/Services/TradeLogic.luau",
    "server/MovementService.luau": "src/server/Services/MovementService.luau",
    "server/LiveOpsService.luau": "src/server/Services/LiveOpsService.luau",
    "server/NpcService.luau": "src/server/Services/NpcService.luau",
    "shared/Restock.luau": "src/shared/Restock.luau",
    "client/AudioController.luau": "src/client/Controllers/AudioController.luau",
    "server/TradeService.luau": "src/server/Services/TradeService.luau",
    "server/RoundService.luau": "src/server/Services/RoundService.luau",
    "server/LeaderboardService.luau": "src/server/Services/LeaderboardService.luau",
    "client/InputController.luau": "src/client/Controllers/InputController.luau",
    "shared/BufferCodec.luau": "src/shared/BufferCodec.luau",
    "client/Main.client.luau": "src/client/Main.client.luau",
    "client/UIController.luau": "src/client/Controllers/UIController.luau",
    "shared/Config.luau": "src/shared/Config.luau",
    "shared/Net.luau": "src/shared/Net.luau",
    "shared/Guard.luau": "src/shared/Guard.luau",
    "shared/RateLimiter.luau": "src/shared/RateLimiter.luau",
    "shared/Trove.luau": "src/shared/Trove.luau",
    "ui/Theme.luau": "src/shared/UI/Theme.luau",
    "ui/Components.luau": "src/shared/UI/Components.luau",
}

ASSET_MAP = {
    "default.project.json": "default.project.json",
    "selene.toml": "selene.toml",
    "stylua.toml": "stylua.toml",
    "rokit.toml": "rokit.toml",
    ".luaurc": ".luaurc",
    "gitignore.txt": ".gitignore",
}


def copy(src: str, dst: str, force: bool) -> None:
    if os.path.exists(dst) and not force:
        print(f"  skip (exists): {dst}")
        return
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(src, dst)
    print(f"  wrote: {dst}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="cluau-scaffold", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("target")
    parser.add_argument("--name", default=None, help="Rojo project name (defaults to target folder name)")
    parser.add_argument("--force", action="store_true", help="overwrite existing files")
    args = parser.parse_args(argv)

    target = os.path.abspath(args.target)
    os.makedirs(target, exist_ok=True)
    print(f"cluau-scaffold → {target}")

    for src_rel, dst_rel in ASSET_MAP.items():
        copy(os.path.join(ASSETS, src_rel), os.path.join(target, dst_rel), args.force)
    for src_rel, dst_rel in FILE_MAP.items():
        copy(os.path.join(TEMPLATES, src_rel), os.path.join(target, dst_rel), args.force)

    project_path = os.path.join(target, "default.project.json")
    with open(project_path, encoding="utf-8") as fh:
        project = json.load(fh)
    project["name"] = args.name or os.path.basename(target.rstrip(os.sep)) or "cluau-game"
    with open(project_path, "w", encoding="utf-8") as fh:
        json.dump(project, fh, indent=2)
        fh.write("\n")

    print("\nNext steps:")
    print("  1. rokit install            (installs rojo, selene, stylua, wally)")
    print("  2. rojo serve               (then connect from the Rojo plugin in Studio)")
    print("  3. Studio: Game Settings → Security → Enable Studio Access to API Services")
    print("  4. Fill Config.luau ids (game passes, products, icons) and rewrite Theme.luau's art direction")
    return 0


if __name__ == "__main__":
    sys.exit(main())
