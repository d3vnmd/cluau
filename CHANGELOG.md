# Changelog

All notable changes to **cluau** are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-11-22

### Added
- `skills/cluau/SKILL.md` — the core Cluau prompt: operating loop with a mandatory
  self-review gate, modern strict Luau rules, deprecated → modern API table,
  client/server architecture, exploit-proof remote handling, anti-slop UI doctrine,
  session-locked data, ethical monetization, performance, response format.
- Reference library (`skills/cluau/references/`): `luau-modern`, `deprecated-apis`,
  `architecture`, `networking-security`, `data-persistence`, `ui-design-system`,
  `performance`, `monetization-policy`, `game-design`, `debugging-testing`,
  `mongolian-glossary`.
- Production templates (`skills/cluau/templates/`): server/client bootstraps, `Net`
  remote registry, `Guard` validators, `RateLimiter`, `Trove`, `Config`,
  session-locked `DataService`, idempotent `MonetizationService`, validated
  `ShopService`, design-token `Theme`, stateful `Components` (button, panel, modal,
  toast, auto-scale, input detection) and a sample `UIController` HUD + shop.
- `scripts/luau_lint.py` — zero-dependency linter with 49 rules for deprecated APIs,
  unsafe patterns and UI-slop markers; line/file suppressions; JSON output.
- `scripts/scaffold.py` — generates a Rojo project (Selene, StyLua, Rokit, `.luaurc`)
  from the templates.
- Claude Code plugin + marketplace manifests (`.claude-plugin/`).
- `tools/build.py` validation and packaging; CI and tag-driven GitHub Release workflows.
- Bilingual (Mongolian / English) README, example prompts, contributing guide.

[Unreleased]: https://github.com/d3vnmd/cluau/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/d3vnmd/cluau/releases/tag/v1.0.0
