# Contributing to Cluau

Thanks for helping keep Roblox code modern and Roblox UI human. / Хувь нэмэр оруулж байгаад баярлалаа!

## Ground rules

1. **Accuracy over volume.** Every API claim must be true for current Roblox. If you add a deprecated → modern
   mapping, link the Creator Hub docs page or DevForum announcement in your PR description.
2. **Templates stay production-grade.** `--!strict`, lint-clean, no TODOs in core paths, no third-party `require(id)`.
3. **SKILL.md stays under 500 lines.** Put depth in `references/` and point to it from SKILL.md.
4. **No anti-slop regressions.** UI changes must pass the audit in `references/ui-design-system.md` §12.
5. **Original games only.** Examples describe mechanics and genres, never clone a specific existing game.

## Workflow

```bash
python3 -m unittest discover -s tests     # must pass
python3 tools/build.py check              # must pass
```

- **New linter rule**: add it to `RULES` in `skills/cluau/scripts/luau_lint.py` with the next free id in its
  group, add a line to `tests/fixtures/bad.luau` ending in `-- expect CLxxx`, and make sure no template or the
  "must NOT be flagged" section triggers it.
- **New template**: put it under `skills/cluau/templates/<side>/`, list it in SKILL.md §10, add it to
  `FILE_MAP` in `scripts/scaffold.py`, and run the checks.
- **New reference**: add a contents list at the top if it's over ~100 lines and link it from SKILL.md §10.

## Releasing (maintainers)

1. Update `version` in `.claude-plugin/plugin.json` **and** `.claude-plugin/marketplace.json` (both places).
2. Move `[Unreleased]` notes in `CHANGELOG.md` into a new `## [x.y.z] - YYYY-MM-DD` section; update links.
3. Commit, then `git tag vx.y.z && git push origin vx.y.z`.
4. The Release workflow verifies the tag matches the version, runs tests, builds the zips and publishes the release.

Versioning: **major** = breaking change to template APIs or skill behavior, **minor** = new references/templates/rules,
**patch** = corrections.
