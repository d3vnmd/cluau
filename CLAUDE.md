# CLAUDE.md — working on the cluau repository

This repo ships a Claude skill (`skills/cluau/`) plus a Claude Code plugin manifest (`.claude-plugin/`).

- The skill prompt is `skills/cluau/SKILL.md` (keep ≤ 500 lines; depth goes in `references/`).
- Luau templates in `skills/cluau/templates/` must stay `--!strict`, complete, and lint-clean.
- Before committing run:
  - `python3 -m unittest discover -s tests`
  - `lune run tests/luau/run.luau` (Lune 0.11.1: `cargo install lune --locked --version 0.11.1`)
  - `python3 tools/build.py check`
- Pure template logic (no Instances/yields) belongs in modules with Lune specs in `tests/luau/`.
- New security lint rules need an `unsafe_*.luau` fixture line (`-- expect CLxxx`) and must keep
  `tests/fixtures/security/safe_security.luau` clean.
- Version lives in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`; releases need a matching
  `## [x.y.z]` section in `CHANGELOG.md` and a `vx.y.z` tag (see CONTRIBUTING.md).
- When adding a deprecated-API mapping, also add a linter rule + a `-- expect` line in `tests/fixtures/bad.luau`.
- Valid Luau that must never be flagged goes in `tests/fixtures/good.luau`.
- Deprecation data is generated: `python3 tools/sync_deprecations.py <creator-docs clone>`; never hand-edit
  `scripts/data/deprecated_apis.json`, `references/deprecated-index.md` or `references/platform-features.md`.
- Before release, `python3 tools/verify_api_refs.py <creator-docs clone>` must report 0 missing APIs.
