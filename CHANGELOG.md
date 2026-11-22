# Changelog

All notable changes to **cluau** are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.1.0] - 2026-11-22

Deep-research release: rebuilt against Roblox's official docs (`Roblox/creator-docs` @ 2026-11-21) and
big-studio practice, with ideas adapted from excaldev/ro-engineer (MIT).

### Added
- **Official-docs sync** — `tools/sync_deprecations.py` turns Roblox's docs source into
  `scripts/data/deprecated_apis.json`, `references/deprecated-index.md` (~560 deprecated members) and
  `references/platform-features.md` (Roblox's agent-facing "use this now" feed, CC BY 4.0).
- **Hallucination check** — `tools/verify_api_refs.py` verifies every `Class:Member` / `Enum.X.Y` in the skill
  exists in the official docs (CI job + weekly docs-drift workflow).
- Linter rules **CL200–CL203** generated from the docs (391 deprecated names, only names deprecated on every
  class), plus CL053 (legacy Chat is gone, now an error), CL059 (PhysicsService), CL064 (`Chatted`), CL077
  (unshipped Luau syntax), CL078 (`PromptProductPurchaseFinished`).
- New references: `genre-playbooks.md` (14 genres incl. farming/idle, steal, fishing, dress-up, survival;
  ownership maps, exploits, budgets), `server-authority.md`, `assets-pipeline.md` (Blender/FBX/glTF,
  20k-tri meshes, PBR, instancing, SLIM, collision, rigs, lighting, AI assets, free-model vetting,
  asset-compliance gate), `polish-qa-launch.md` (game feel, Audio API, accessibility, device lab,
  Experiments, discovery signals, launch checklist), `sharp-edges.md` (35 ID'd bugs), `toolchain-workflow.md`
  (evidence levels, Rojo, CI, Studio MCP verification).
- Templates: `BufferCodec.luau` (bounds-checked untrusted buffer reader), `ModerationService.luau`
  (evidence + delayed `BanAsync` waves). UI components honour `ReducedMotionEnabled` and
  `PreferredTransparency`.
- `tests/fixtures/good.luau` must-not-flag fixture.

### Changed
- SKILL.md thinks like a studio: genre classification, scale-to-risk, ownership maps, no yields between
  check and mutate, hard performance budgets, evidence honesty (report exactly what was checked).
- Corrected now-deprecated advice: PhysicsService → `workspace` (WorldRoot) collision groups; reserved
  servers via `TeleportOptions.ReservedServerId` + GUID; `…Async` renames; `GroupService:GetRolesInGroupAsync`;
  Roblox Plus instead of Premium; Input Action System; `CoreUISafeInsets` for HUD; July 2026 DataStore budgets
  and storage; ProcessReceipt audits and external developer-product sales; age-based accounts.
- Rojo pin 7.7.1; Lune added.

### Fixed
- Linter false positives: `math.pow`, `unpack` and `table.maxn` are valid Luau.

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

[Unreleased]: https://github.com/d3vnmd/cluau/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/d3vnmd/cluau/releases/tag/v1.1.0
[1.0.0]: https://github.com/d3vnmd/cluau/releases/tag/v1.0.0
