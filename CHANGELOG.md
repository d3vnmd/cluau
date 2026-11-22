# Changelog

All notable changes to **cluau** are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-11-22

Self-verification release: the skill now tests, lints and reviews its own output.

### Added
- **Luau unit tests (Lune)** — `tests/luau/` specs for `RateLimiter`, `Guard`, `BufferCodec`, `Trove` and
  `TradeLogic` (51 tests: truncated buffers, NaN, oversized length prefixes, stale trade versions, self-trades,
  all-or-nothing swaps…). Mutation-checked: removing a guard makes the suite fail. CI job installs Lune.
- **Independent review mode** — `agents/cluau-reviewer.md` (Claude Code plugin agent) and
  `references/review-workflow.md` (verbatim reviewer prompt, when review is mandatory, checklists).
  SKILL.md now requires a fresh reviewer for remotes/data/purchases/trades/rounds/teleports.
- `sharp-edges.md` grew from 35 to 65 ID'd bugs (trade dupes, bait-and-switch, respawn races, streaming nil,
  teleport-data trust, leaderboard write spam…) plus fast-review heuristics.
- **High-risk system templates** — `TradeLogic` + `TradeService` (dupe-proof trading), `RoundService`
  (Phase/EndsAt replication, death/leave/respawn), `LeaderboardService` (MemoryStore live board + slow
  OrderedDataStore), `InputController` (Input Action System contexts and bindings).
- **Security lint rules** — CL110 `SetAsync` on player keys, CL111 non-idempotent `ProcessReceipt`, CL112
  `PurchaseGranted` without persistence, CL113 prompt/click/touch handlers without distance checks, CL114
  unvalidated remote handlers, CL115 client sending prices/damage, CL116 `PlayerAdded` without `GetPlayers`,
  CL117 DataStore without `BindToClose`, CL118 ScreenGui without `ResetOnSpawn` decision; file-level rule
  engine; unsafe/safe security fixtures.
- **Bilingual eval suite** — `evals/cases.json` (19 Mongolian/English cases incl. no-trigger cases) and
  `tools/run_evals.py` (grades responses, lints every Luau code block, checks Mongolian replies; `run --cmd
  "claude -p"` generates responses). Grader has its own tests.
- "Last verified" stamps on every hand-written reference, enforced by `tools/build.py check`.

### Fixed (found by running the new independent reviewer on this release's own templates)
- **TradeService:** crash between the two players' saves could dupe/lose items → two-phase trade journal
  (`TradeJournal_v1`) + `AppliedTrades` markers + load-time reconciliation that applies a missing side only
  when the partner's saved data proves the trade committed. Per-player trade cooldown.
- **DataService:** save coalescing (one queued save per profile; trade/receipt spam can't drain the DataStore
  budget); lock heartbeat for idle profiles (a stale lock could let another server discard the last save);
  `AddLoadStep` and `ReadSavedAsync` hooks; `AppliedTrades` field.
- **RoundService:** `RequestStreamAroundAsync` before teleporting (players fell through unstreamed maps);
  abort with no rewards if fewer than `MIN_PLAYERS` actually start (solo reward farming); elimination also
  when the Humanoid disappears or the character changes; round connections cleaned on error; participation
  paid from the starting roster.
- **LeaderboardService:** separate live/all-time pending tallies (a partial failure double-counted scores),
  entries removed only after successful writes, in-flight guard against concurrent flushes, players already
  in-game get the board, round winners wired in.
- **InputController / new MovementService:** client no longer sets WalkSpeed (escaped server slows, false
  anti-cheat flags); sprint is a server intent. Backspace no longer closes menus while typing.
- **BufferCodec:** `writer(0)` looped forever; truncation could split UTF-8 characters.
- **ModerationService:** ban wave iterates a snapshot.
- `server-authority.md`: `PlayerScriptsUseInputActionSystem` is a Workspace property.
- `RateLimiter` rejects NaN/negative costs and accepts an injectable clock.
- `tools/verify_api_refs.py` now also checks `StarterPlayer.*` references.

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

[Unreleased]: https://github.com/d3vnmd/cluau/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/d3vnmd/cluau/releases/tag/v1.2.0
[1.1.0]: https://github.com/d3vnmd/cluau/releases/tag/v1.1.0
[1.0.0]: https://github.com/d3vnmd/cluau/releases/tag/v1.0.0
