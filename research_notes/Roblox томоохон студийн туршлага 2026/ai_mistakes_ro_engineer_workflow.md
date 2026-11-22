# ro-engineer, AI-generated Roblox code/UI failure patterns, and big-studio engineering workflow (2025-2026)

Research date: 2026-11-22. Method note: the ro-engineer repo and several related GitHub repos were read in full through a git clone (anonymous git reads worked). WebFetch to create.roblox.com, devforum.roblox.com, techcrunch.com and rocode.app was blocked in this session (DNS refused by the sandbox network policy). Claims about official Roblox docs therefore come from (a) search-engine summaries of those pages, (b) Roblox's own GitHub repos, and (c) community skill repos that cite and date-stamp the official docs (nonlooped/roblox-suite, last reviewed 2026-11-16). Each of these is marked where it matters. To verify primary text, create.roblox.com and devforum.roblox.com need to be allowed in the session's network settings.

## 1. ro-engineer (github.com/excaldev/ro-engineer): what it is, structure, rules, license, ideas to borrow

### Takeaway
ro-engineer v1.0.2 (2026-11-13, MIT, by "excaldev") is a single, router-style **agent skill** (one `SKILL.md` plus on-demand references, workflows and templates), packaged as a Claude Code plugin, a standalone Claude/Codex skill, and an OpenAI/ChatGPT plugin. Its main ideas are proportionality ("a small fix needs no architecture"), evidence honesty ("never invent inspection, execution, or test results"), server authority with a 7-point remote-validation checklist, lifecycle and cleanup ownership, a severity-ranked "sharp edges" table, and (new in v1.0.2) an asset-compliance gate for Studio MCP asset generation, upload and save. It has **no UI/UX reference at all**, and its DataStore, deprecated-API, toolchain, animation, physics and teleport coverage is thin.

### Cited Findings

**Identity and metadata**
- Repo HEAD commit `54067e1` (2026-11-13, "Minor change too readme"). README: "Project-aware Roblox/Luau engineering for Claude Code, Codex, and supported ChatGPT environments. Inspect existing systems, choose architecture that fits, protect server boundaries, and validate actual behavior. Optional game-design references cover loops, onboarding, economy, and fair retention." It also says the skill "does not install libraries, connect MCP, or grant Roblox Studio access." — [README](https://github.com/excaldev/ro-engineer/blob/main/README.md)
- **License: MIT**, "Copyright (c) 2026 excaldev". Plugin manifests also declare `"license": "MIT"`. — [LICENSE](https://github.com/excaldev/ro-engineer/blob/main/LICENSE)
- SKILL.md frontmatter has exactly two fields. `name: ro-engineer`; `description: "Build, debug, review, and design Roblox/Luau gameplay systems. Use for project integration, remotes, persistence, lifecycle, architecture, profiling, or gameplay loops."` `scripts/validate.py` enforces that only name and description exist, the name is kebab-case and ≤64 chars, the description is ≤1024 chars, and the folder name equals the skill name. — [SKILL.md](https://github.com/excaldev/ro-engineer/blob/main/SKILL.md), [validate.py](https://github.com/excaldev/ro-engineer/blob/main/scripts/validate.py)
- Version history from [CHANGELOG](https://github.com/excaldev/ro-engineer/blob/main/CHANGELOG.md):
  - v1.0.0 (2026-10-30): router, 21 references, 8 workflows, 4 templates.
  - v1.0.1 (2026-11-01) was a self-correction. v1.0.0 "included unnecessary generic programming explanations, repeated rules, and overly rigid planning/template requirements". The fix made routing "progressive, project-aware, and proportional", replaced "count thresholds" for ECS/pooling with fit/profiling criteria, and removed the compulsory class template.
  - v1.0.2 (2026-11-13) added asset guardrails for the Studio MCP.

**Installation** — [README](https://github.com/excaldev/ro-engineer/blob/main/README.md), [docs/installation.md](https://github.com/excaldev/ro-engineer/blob/main/docs/installation.md)
- Claude Code plugin: `/plugin marketplace add excaldev/ro-engineer`, then `/plugin install ro-engineer@ro-engineer`. Invoke with `/ro-engineer:ro-engineer`.
- Claude standalone: put the folder in `.claude/skills/ro-engineer/` or `~/.claude/skills/ro-engineer/`. Invoke with `/ro-engineer`.
- Codex: put the folder in `.agents/skills/` or `~/.agents/skills/`. Invoke with `$ro-engineer`.
- ChatGPT: plugin ZIP upload where enabled, or desktop Settings > Import from a Claude setup.
- Release assets: `ro-engineer-skill-v1.0.2.zip`, `ro-engineer-openai-plugin-v1.0.2.zip` and `SHA256SUMS.txt`.

**Complete file list** (from the cloned tree; text sizes in bytes)
- Root: `SKILL.md` (5.5 KB), `README.md`, `CHANGELOG.md`, `LICENSE`, `.gitattributes`, `.gitignore`.
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`: Claude packaging, `"skills": "./"`, category `game-development`.
- `packaging/openai-plugin.json`: Agent Plugins schema 1.0.0. `agents/openai.yaml`: display name "Ro-Engineer".
- `references/` (22 files):
  - Engineering: `luau-modern`, `luau-types`, `client-server-boundaries`, `networking-remotes`, `state-management`, `cleanup-lifecycle`, `performance`, `object-pooling`, `pattern-selection`, `oop-patterns`, `composition`, `ecs`, `system-design`, `testing`, `sharp-edges`, `tool-modes`, `asset-compliance` (10.6 KB, the largest).
  - Game design: `game-loops`, `market-references`, `player-incentives`, `retention-psychology` (11 KB), `progression-economy`, `live-ops-events`.
- `workflows/` (8): `plan`, `implement`, `code-review`, `design-system`, `design-game-loop`, `performance-audit`, `economy-audit`, `retention-audit`.
- `templates/` (4): `plan-template`, `design-doc-template`, `game-loop-template`, `module-template`.
- `scripts/validate.py` (reference-link and metadata checks, stdlib only) and `scripts/package.py` (deterministic ZIPs with SHA-256). `tests/test_distribution.py` holds unittest packaging tests.
- `docs/`: `installation.md`, `benchmark.md`, `releasing.md`, `release-v1.0.2.md`. `assets/`: banner and logo PNGs.
- No Luau example code directory, no Luau tests, and no lint config. All Luau appears inline in the markdown.

**SKILL.md core rules (paraphrased or quoted)** — [SKILL.md](https://github.com/excaldev/ro-engineer/blob/main/SKILL.md)
- "Inspect existing project code before proposing systems: relevant scripts, dependencies, call sites, remotes, persistence, and lifecycle conventions. Reuse suitable interfaces and libraries… a small fix does not need a new architecture or a game-design phase."
- **Evidence modes:** Studio (MCP), ROTEX (a project/library context tool), Repository and Offline. The Offline mode requires stating "assumptions, placement (service/path and Script, LocalScript, or ModuleScript), integration points, and manual tests". Other rules:
  - "Detect actual tool descriptions and permissions; names… vary between MCP implementations."
  - "**Never invent inspection, execution, or test results.**"
- **Routing table:** a Task → Start here map that loads references only when needed. It is explicitly "not a bundle to read in full". Game-design references stay out of unrelated engineering work.
- **Roblox safeguards (always-on):**
  1. The server is authoritative for outcomes, economy, inventory and grants. Validate "type/shape, finite numbers, bounds, ownership, legal state, distance where relevant, and rate limits. Typed payloads do not replace runtime validation."
  2. Purchase grants are "idempotent and durable through supported server receipt processing". Handle save failures, retries, concurrency, session ownership and migrations.
  3. Every resource has an owner and a lifetime. End subscriptions and delayed work, reset pooled state, and account for respawn, player departure and streaming.
  4. Prefer `--!strict` and typed public interfaces for new code. "A ModuleScript returns exactly one non-nil value, which need not be a table."
  5. Check current policy on paid randomness and trading. "avoid manipulative pressure, particularly on young players."
- **Closing rules:** "Scale planning and validation to risk… ask only for material missing requirements… Report changes, checks actually run, and unverified behavior. Distinguish static review, types, runtime tests, security, and profiling."

**sharp-edges.md: an ID'd, severity-ranked catalog** (CRITICAL > HIGH > MEDIUM > LOW). It is meant to grow: "Add real incidents here as you hit them: ID, severity, symptom, cause, fix." — [sharp-edges.md](https://github.com/excaldev/ro-engineer/blob/main/references/sharp-edges.md)
- CRITICAL:
  - SE-1: client-trusted state or currency.
  - SE-9: price or reward taken from the remote payload.
  - SE-10: dev products granted outside receipt processing or non-idempotently.
  - SE-11: DataStore saves without session locking.
- HIGH:
  - SE-12: NaN/inf accepted as numbers (`n ~= n`).
  - SE-13: `RemoteFunction:InvokeClient` from the server ("Never; a client can yield the server thread forever").
  - SE-14: saving on every change.
  - SE-15: no save in `BindToClose`.
  - SE-2: leaked connections.
  - SE-3: pooled objects keep stale state.
  - SE-16: per-player tables never cleared.
  - SE-4: remote flooding.
  - SE-5: economy with no sinks.
- MEDIUM:
  - SE-17: character connections survive respawn.
  - SE-18: missing players who joined before `PlayerAdded` connected (also loop `Players:GetPlayers()`).
  - SE-19: streaming, where the client assumes workspace instances exist.
  - SE-20: firing remotes every frame (use `UnreliableRemoteEvent` for cosmetic streams).
  - SE-21: a generic "action" remote with string dispatch.
  - SE-22: hardcoded tuning.
  - SE-23: unbounded multiplier stacking.
  - SE-24: punishing streaks.
  - SE-25: legacy `wait`/`spawn`/`delay`.
  - SE-26: ECS structural changes during iteration.
  - SE-29: gameplay-critical parts owned by the client (fix with `SetNetworkOwner(nil)`).
- LOW:
  - SE-27: `Instance.new(class, parent)` before setting properties (set properties first, parent last).
  - SE-28: `Humanoid:LoadAnimation` (use `Animator:LoadAnimation`).
  - SE-30: `:: any` casts to silence strict mode.

**client-server-boundaries.md** — [file](https://github.com/excaldev/ro-engineer/blob/main/references/client-server-boundaries.md)
- "The server is authoritative. The client is an input device and a display. Anything the client says is a request that can be forged." Exploiters can fire any remote with any arguments at any rate, read all client code and ReplicatedStorage, and change their own character's physics.
- **7-step validation checklist for every remote handler:**
  1. Type (`typeof`; reject NaN/inf)
  2. Range (integers, max string length, enum allow-list)
  3. Ownership
  4. State (alive, in round, not stunned)
  5. Distance (server-side character position)
  6. Cooldown/rate
  7. Cost computed from server config, never from the payload
- Server-only / client-only / shared placement table. Do not put secrets such as loot weights or admin lists in ReplicatedStorage.
- `Touched` can be spoofed by the client that owns the part. Validate that the touch comes from a live character, debounce per player, and prefer `GetPartBoundsInBox` or `Raycast` for critical checks.
- Purchases:
  - Use `ProcessReceipt` (or `BindReceiptHandler` where adopted), record receipt ids, and return `PurchaseGranted` only after the save.
  - Check game passes on the server with `UserOwnsGamePassAsync` (cached).
  - "Never grant on a client message saying 'I bought it'."

**networking-remotes.md** — [file](https://github.com/excaldev/ro-engineer/blob/main/references/networking-remotes.md)
- Remote type table: RemoteEvent, UnreliableRemoteEvent, RemoteFunction (never `InvokeClient`), Attributes/ValueObjects, Instance replication.
- One remote per intent. Define remotes in one module. The server creates them and clients `WaitForChild` them.
- Typed networking libraries are mentioned (Zap, Blink, ByteNet, Packet, marked **[verify]**).
- Includes a `--!strict` sliding-window per-player rate limiter that clears `lastCalls[player] = nil` on `PlayerRemoving`.
- Bandwidth rules: send ids rather than tables, batch per tick, send deltas, quantize with `buffer`. Requests describe intent, not results. Give late joiners a snapshot.

**cleanup-lifecycle.md** — [file](https://github.com/excaldev/ro-engineer/blob/main/references/cleanup-lifecycle.md)
- Cleanup table: connections, custom signals, `task` threads, tweens, created instances, per-player tables, store subscriptions, `BindToRenderStep` → `UnbindFromRenderStep`.
- Use Trove, Maid or Janitor, with "One trove per lifetime: per object, per character, per round, per UI screen."
- Lifetimes to manage: Player (including existing players), Character (until the next CharacterAdded/Removing), Round, Instance (`Destroying`), Server (`BindToClose`).
- `Destroy()` semantics: it does not disconnect your connections to *other* instances. `Debris:AddItem` cannot be cancelled. Weak-key caches (`__mode = "k"`) are only for objects you don't own.
- Leak testing: watch LuaHeap and Instances in the Developer Console over 50 spawn/die and join/leave cycles. A final checklist ends with "`Destroy` is idempotent".

**luau-modern.md / luau-types.md** — [luau-modern](https://github.com/excaldev/ro-engineer/blob/main/references/luau-modern.md), [luau-types](https://github.com/excaldev/ro-engineer/blob/main/references/luau-types.md)
- `task.spawn` resumes immediately. `task.defer` resumes "at the end of the current resumption cycle, not necessarily next frame".
- "Heartbeat is not a deprecated API to replace mechanically." `table.freeze` is shallow. `getfenv`/`setfenv` inhibit optimizations.
- `ipairs` stops at the first nil, so "do not change traversal semantics for style".
- Type untrusted payloads as `unknown`, then validate at runtime. "A cast to Model is not an IsA check."
- Keep persisted plain-data schemas separate from live Instance types. Keep any unavoidable `any` localized.
- Includes an `isFiniteNumber` helper: `typeof(value) == "number" and value == value and math.abs(value) < math.huge`.

**testing.md: an evidence-levels table** (an idea worth borrowing) — [file](https://github.com/excaldev/ro-engineer/blob/main/references/testing.md)

| Evidence | Establishes | Does NOT establish |
|---|---|---|
| Generated code / static review | Proposed logic | Execution success |
| Type checking | Compatibility with the configured checker | Runtime payload safety |
| Unit tests | Tested logic | Real replication, physics, persistence |
| Studio multiplayer playtest | Observed engine behavior | All production/device scenarios |
| Profiling | Measured cost in one workload | Universal speedup |
| Security checks | Tested attack paths | Absence of all exploits |

- Edge cases to cover: exact or insufficient funds, NaN/negative/inf, concurrent spend, duplicate receipt retries, save failure or session conflict, migration, respawn, join/leave, late join, streaming.
- Tooling notes: Jest Lua ("do not assume bare describe/it/expect globals exist"), TestEZ, Lune ("not a complete Roblox engine"), luau-lsp ("A bare analyzer without engine definitions is not equivalent to Studio"), StyLua/Selene ("neither proves runtime correctness"), Rojo.

**code-review.md workflow** — [file](https://github.com/excaldev/ro-engineer/blob/main/workflows/code-review.md)
- Review areas: Security, Persistence, Lifecycle, Integration (require/startup order, replication snapshots), Types/APIs, Architecture, Performance.
- "Do not flag pairs/ipairs, module return shape, inheritance depth, or a missing new framework merely for style. Report actionable findings by severity with location, failure scenario, consequence, and a specific fix. Distinguish observed failures from hypotheses… a review does not claim runtime success."

**Other engineering references**
- `implement.md`: the last step is "Report files/instances changed, behavior, checks run/results, and unverified work… Do not call generated code tested." — [file](https://github.com/excaldev/ro-engineer/blob/main/workflows/implement.md)
- `pattern-selection.md`: "Entity count is an input, not an adoption threshold. ECS is not inherently faster than OOP; frequent spawning alone does not justify a pool." — [file](https://github.com/excaldev/ro-engineer/blob/main/references/pattern-selection.md)
- `system-design.md`:
  - Example layout: `ReplicatedStorage/Shared|Client|Packages`, `ServerScriptService/Main.server.luau`, `ServerStorage/Services`, `StarterPlayerScripts/Main.client.luau`.
  - Lifecycle is `init()` then `start()`.
  - Ownership map table with the columns State | Owner | Lives on | Replicated how | Persisted. "If two systems claim the same state, redesign."
  - Economy mutations carry a `reason` argument. No global "GameManager".
  - Persistence: session-locked library (ProfileStore-style, **[verify]**), versioned schema with migrate-on-load, "never save per change". — [file](https://github.com/excaldev/ro-engineer/blob/main/references/system-design.md)
- `performance.md`: "Target low-end mobile". Tools are the MicroProfiler (Ctrl+F6, `debug.profilebegin`), the Developer Console (F9) and the Script Profiler. Ranked candidate costs: parts/draw calls, per-frame scripts, physics (CollisionFidelity, CanTouch/CanQuery), network, memory, UI rebuilds and unvirtualized scrolling, lighting/VFX. Hot-path rules: cache `GetService`/`FindFirstChild`, use spatial queries and `BulkMoveTo`, measure Parallel Luau. — [file](https://github.com/excaldev/ro-engineer/blob/main/references/performance.md)
- `tool-modes.md`: "Select capabilities, not product labels". Execution tools can mutate the place, so avoid competing writers (Rojo sync vs. the Studio bridge). "Silence is not a pass." "Do not fabricate playtests." — [file](https://github.com/excaldev/ro-engineer/blob/main/references/tool-modes.md)

**asset-compliance.md (v1.0.2)**: gating for Studio MCP asset tools — [file](https://github.com/excaldev/ro-engineer/blob/main/references/asset-compliance.md), [release notes](https://github.com/excaldev/ro-engineer/blob/main/docs/release-v1.0.2.md)
- Tools covered: `generate_mesh`, `generate_material`, `generate_procedural_model`, `generate_animation`, `search_asset`/`insert_asset`, `upload_image`/`store_image`, `save_place`.
- **Preview mode is the default.** Assets are staged in `ServerStorage/_AssetStaging` (not replicated). A Preview Card shows front, three-quarter and close-up captures, then waits for Approve / Revise / Regenerate / Discard.
- **Autopilot is opt-in.** It allows ≤2 self-correction retries, then quarantines to `ServerStorage/_AssetQuarantine`, and ends with an Autopilot Report.
- **Hard stops in every mode:**
  1. Any image upload.
  2. Inserting a store asset that contains scripts or `require(assetId)` / `loadstring` / `LinkedSource`.
  3. Any DO NOT UPLOAD finding.
  4. Content with unknown rights.
  5. Saving a cloud place.
  6. Deleting user content.
- Results are PASS, REVISE, DO NOT UPLOAD or NEEDS POLICY CHECK. "Never claim an asset will pass."
- Prompt hygiene: describe wear as "rust, mud, oil stains, chipped paint". Avoid blood/gore, brands and "in the style of [franchise]". Use no text in textures (use `SurfaceGui`/`TextLabel` for signage instead). Describe animations neutrally.
- Script-insert grep list: numeric `require(`, `loadstring`, `getfenv`/`setfenv`, `HttpService`, `MarketplaceService` prompts, `TeleportService`, `LinkedSource`, long encoded strings, obfuscation.
- Cites a reported (unverified) case of a one-day suspension for a texture atlas with blood-like stains.

**Game-design half (optional references)**
- `game-loops.md`: action → reward → progression → reinvestment, at micro/session/meta time scales, plus a "base-and-collect" building-block anatomy (fantasy verb, unique mechanic, RNG source and reveal timing, tension, collection). — [file](https://github.com/excaldev/ro-engineer/blob/main/references/game-loops.md)
- `market-references.md` is self-labelled "Historical notes: 2026-10; unverified source analysis" (games such as "Steal an Egg", "Escape Tsunami for Brainrots"). — [file](https://github.com/excaldev/ro-engineer/blob/main/references/market-references.md)
- `retention-psychology.md` maps principles (variable reward, goal gradient, Zeigarnik, scarcity, loss aversion…) to features. Each principle has a risk level and a fair vs. manipulative version: "Many Roblox players are children." — [file](https://github.com/excaldev/ro-engineer/blob/main/references/retention-psychology.md)
- `economy-audit.md`: source/sink table, pacing, multiplier max-stack, and an exploit list (client values, retries/rejoin dupes, check-then-deduct races, buy/sell loops, NaN amounts). — [file](https://github.com/excaldev/ro-engineer/blob/main/workflows/economy-audit.md)

**Benchmark plan (not results)** — [docs/benchmark.md](https://github.com/excaldev/ro-engineer/blob/main/docs/benchmark.md)
- Compares A (no skill), B (v1.0.0) and C (v1.0.1). At least 3 trials per condition, with fresh sessions and fixed fixtures.
- 8 tasks: projectile cleanup, inventory concurrency, remote security with seeded NaN/inf/flood/replay defects, refactor without rewrite, performance diagnosis, persistence with a fake store, architecture choice, component integration.
- "Fewer instruction bytes do not establish better answers." It claims no measured gains.

### Inferences
- **Ideas worth borrowing into cluau:**
  1. An ID'd sharp-edges table with severity that grows from real incidents.
  2. The 7-step remote validation checklist with explicit NaN/inf rejection.
  3. The evidence-levels table and an honesty rule ("never claim generated code is tested; report checks actually run").
  4. Offline answers always state placement: service path plus Script/LocalScript/ModuleScript.
  5. Proportionality: small fixes need no design doc, and no ECS or pooling without profiling.
  6. Review rules that forbid style-only nitpicks and require location + failure scenario + fix.
  7. Capability-based MCP detection.
  8. The asset-compliance Preview/Autopilot, staging/quarantine and hard-stop model.
  9. "One trove per lifetime".
  10. The ownership-map table.
  11. The validate.py and package.py release hygiene.
  12. A benchmark methodology built on seeded-defect fixtures.
- **Gaps in ro-engineer that cluau can fill:**
  - No UI/UX reference: ScreenGui, ResetOnSpawn, Scale/Offset, UIAspectRatioConstraint, ScreenInsets/safe areas, TextScaled vs. UITextSizeConstraint, AutomaticSize, layouts, input, tweening, accessibility, localization, mobile touch targets.
  - No detailed DataStore reference: UpdateAsync purity, pcall everywhere, budgets/`GetRequestBudgetForRequestType`, 30 s BindToClose window, ProfileStore specifics, the Data Stores Manager.
  - No deprecated-API catalog beyond `wait`/`spawn`/`delay` and `Humanoid:LoadAnimation`. Missing: BodyMovers → constraints, legacy Teleport methods → `TeleportAsync`, `PhysicsService` collision-group methods, Mouse → UserInputService/ContextActionService.
  - No Lua 5.x-vs-Luau language pitfalls (goto, bitwise operators, io/os).
  - No toolchain setup (Rojo project format, Rokit, Wally/pesde, CI).
  - No animation, physics, teleport, audio, Mongolian-language or beginner guidance.
- ro-engineer is aimed at experienced engineers in existing codebases. cluau probably also needs a "from-scratch beginner" path with exact placement instructions.

### Gaps
- The author's identity and background beyond the "excaldev" handle are unknown. "ROTEX" is referenced as a connectable project-context tool, but the repo gives no public endpoint or docs, so I could not identify what it is.
- No measured benchmark results exist (the plan only).

## 2. Common mistakes AI assistants make in Roblox Luau code and UI (with correct alternatives)

### Takeaway
I found **no rigorous published benchmark** of LLM Luau accuracy. The evidence is community reports, vendor blogs and curated community skill repos. They agree on a consistent set of failures:
- deprecated APIs (wait/spawn/delay, `Humanoid:LoadAnimation`, BodyMovers, legacy Teleport)
- invented properties and methods
- wrong script type or location
- client-trusted remotes
- `SetAsync` on contended data and missing `BindToClose`
- leaks and respawn bugs
- Lua 5.3/5.4 or other-language idioms

Several of the assumed "Lua-isms" are actually **fine in modern Luau** (`//`, `+=`, `continue`, `math.pow`, `table.unpack`, `unpack`, `string.pack`, `utf8`, and now `const`). cluau must not over-correct these.

### Cited Findings

**Overall evidence quality**
- A search for a systematic study found none. "I didn't find a published benchmark or study that measures LLM Luau code accuracy, deprecated-API use, or hallucinations" (search synthesis). Star-AI's deprecated-API lint PR states there is no model-quality benchmark. — [Star-AI PR #353](https://github.com/oncoursemail/Star-AI/pull/353)
- DevForum anecdotes: AI examples use deprecated `wait()` instead of `task.wait()` and "Lua 5.1 techniques where newer Luau-specific approaches exist". Users also describe AI as "confidently incorrect" and say ChatGPT output often "will just not work at all, or… only in specific circumstances". There are community calls to ban ChatGPT answers on the forum. — [DevForum: Code Assist beta thread](https://devforum.roblox.com/t/code-assist-beta-ai-powered-code-completion/2224387?page=2), [DevForum: Ban chatGPT for answers](https://devforum.roblox.com/t/ban-chatgpt-for-answers-and-resources/2091013), [DevForum: Is using chatgpt a bad idea?](https://devforum.roblox.com/t/is-using-chatgpt-a-bad-idea/2187262) (via search snippets; fetch blocked)
- Roblox's own Code Assist docs reportedly warn that suggestions "may use older APIs" (secondary report). — [rowatcher.com](https://rowatcher.com/news/roblox-ai-tools-in-2026-what-s-actually-changed-for-developers)

**Deprecated APIs**
- roblox-suite README: "Agents can suggest deprecated APIs such as `Humanoid:LoadAnimation` or use `SetAsync` where concurrent writes could overwrite player data." — [nonlooped/roblox-suite README](https://github.com/nonlooped/roblox-suite) (MIT, 2026; reviewed against Creator Docs on 2026-11-16 and 2026-11-20)
- Mapping from deprecated API to current API (roblox-suite skills, citing Creator Docs):

| Deprecated / AI-typical | Current |
|---|---|
| `wait()`, `spawn()`, `delay()` | `task.wait`, `task.spawn`, `task.defer`, `task.delay`, `task.cancel` |
| `Humanoid:LoadAnimation` | `Animator:LoadAnimation` |
| `BodyVelocity`, `BodyPosition`, other BodyMovers | Mover constraints such as `LinearVelocity`, `AlignPosition`, `AlignOrientation` |
| Legacy `Teleport` (client), `TeleportPartyAsync`, `TeleportToPlaceInstance`, `TeleportToPrivateServer`, `TeleportToSpawnByName` | Server-only `TeleportAsync` with `TeleportOptions`; client requests via RemoteEvent |
| `CustomizedTeleportUI` | Deprecated and does nothing |
| `ReserveServerAsync`, `ReservedServerAccessCode`, `ShouldReserveServer` (deprecated in a 2026-11 docs change) | `HttpService:GenerateGUID(false)` with `ReservedServerId` |
| `PhysicsService` collision-group methods | Per-world `WorldRoot` methods |
| `GlobalDataStore.OnUpdate` | MessagingService |
| `RemoveVersionAsync` | Keep versions; inspect with `ListVersionsAsync`, `GetVersionAsync`, `GetVersionAtTimeAsync` |
| HopperBin | Legacy |

  Sources: [roblox-core](https://github.com/nonlooped/roblox-suite/blob/main/roblox-core/SKILL.md), [roblox-animation](https://github.com/nonlooped/roblox-suite/blob/main/roblox-animation/SKILL.md), [roblox-physics](https://github.com/nonlooped/roblox-suite/blob/main/roblox-physics/SKILL.md), [roblox-teleport](https://github.com/nonlooped/roblox-suite/blob/main/roblox-teleport/SKILL.md), [source-drift review 2026-11-16](https://github.com/nonlooped/roblox-suite/blob/main/reviews/2026-11-16-source-drift.md), [CHANGELOG](https://github.com/nonlooped/roblox-suite/blob/main/CHANGELOG.md), [roblox-datastores](https://github.com/nonlooped/roblox-suite/blob/main/roblox-datastores/SKILL.md)
- ro-engineer flags the same items: SE-25 (wait/spawn/delay), SE-28 (`Humanoid:LoadAnimation`) and SE-27 (`Instance.new(class, parent)`; set properties first, parent last). — [sharp-edges.md](https://github.com/excaldev/ro-engineer/blob/main/references/sharp-edges.md)

**Hallucinated APIs and properties**
- Guides report that ChatGPT "makes up service methods and property names that compile-fail or silently return nil", and that it "now and then uses a property or event that doesn't exist" (red Output error with a line number). These are SEO-style sources; frequency is unmeasured. — [rateblox.com](https://rateblox.com/guides/can-chatgpt-make-a-roblox-game), [soonlab.ai](https://www.soonlab.ai/blog/best-ai-for-roblox-scripting/)
- Correct approach used by roblox-suite: CI type-checks every Luau example against the Roblox API (strict mode, new solver) using bundled `types/globalTypes.None.d.luau`. — [roblox-suite](https://github.com/nonlooped/roblox-suite) ([skillsllm listing](https://skillsllm.com/skill/roblox-skills) describes a similar claim for "roblox-skills")
- Specific hallucinated property names reported by users were not retrievable, because the DevForum and Reddit fetches were blocked. See Gaps.

**Wrong client/server placement**
- A common failure is putting "server-only logic in a LocalScript (or the reverse), which works in Play Solo but breaks in a live game". Others are "a server Script pasted as a LocalScript" and "a script that expects to sit inside a part but ends up in ServerScriptService". The advice: tell the AI the script location and type, and ask which side it runs on. — [rateblox.com](https://rateblox.com/guides/can-chatgpt-make-a-roblox-game), [generaiblog.com](https://generaiblog.com/blog/games/what-better-ai-making-roblox-game/)
- Correct approach (ro-engineer offline mode): every answer states the service path and the Script/LocalScript/ModuleScript type. Server-only code goes in ServerScriptService/ServerStorage, client code in StarterPlayerScripts/StarterGui/ReplicatedStorage client modules, and shared code in ReplicatedStorage. — [SKILL.md](https://github.com/excaldev/ro-engineer/blob/main/SKILL.md), [system-design.md](https://github.com/excaldev/ro-engineer/blob/main/references/system-design.md)

**Trusting the client** (ro-engineer SE-1, SE-9, SE-12, SE-13, SE-21, SE-29)
- Common errors: currency, price or damage taken from the payload; no NaN/inf checks; `InvokeClient`; generic action remotes; client-owned physics; touch spoofing.
- Fix: the 7-step checklist, server-side config lookup, per-player rate limits, `SetNetworkOwner(nil)`, and server spatial queries. — [client-server-boundaries.md](https://github.com/excaldev/ro-engineer/blob/main/references/client-server-boundaries.md)

**DataStore misuse** — [roblox-datastores SKILL](https://github.com/nonlooped/roblox-suite/blob/main/roblox-datastores/SKILL.md), [ro-engineer sharp-edges](https://github.com/excaldev/ro-engineer/blob/main/references/sharp-edges.md)
- "Using SetAsync for contended values (race condition → lost updates or duplication)." Fix: `UpdateAsync` with a pure, non-yielding transform. Transforms "can run multiple times and must not yield or produce external side effects."
- "**Every** datastore call must be inside pcall." "Never assume a failed Set/Update/Increment means 'no change occurred'". Handle committed, rejected and unknown outcomes explicitly.
- `UpdateAsync` counts against both the read and the write budget. Check `DataStoreService:GetRequestBudgetForRequestType`.
- Save on leave, in BindToClose (bounded grace of about 30 s) and on an autosave interval (30–60 s). Never save per change.
- Use session locking (ProfileStore-style), otherwise cross-server overwrites occur.

**Lifecycle bugs** (ro-engineer SE-2, SE-16, SE-17, SE-18, SE-19) — [cleanup-lifecycle.md](https://github.com/excaldev/ro-engineer/blob/main/references/cleanup-lifecycle.md)
- Typical bugs:
  - Not handling players already in game: loop `Players:GetPlayers()` after connecting `PlayerAdded`.
  - Character connections that survive respawn.
  - Per-player tables never nil'd.
  - Assuming workspace instances exist under StreamingEnabled: use `WaitForChild` with a timeout, nil handling, and CollectionService signals.
  - Leaked connections and threads.
- An unbounded `WaitForChild` causes infinite-yield warnings. ro-engineer: "timeout is not proof content will never stream in." — [luau-modern.md](https://github.com/excaldev/ro-engineer/blob/main/references/luau-modern.md)

**Lua 5.x / other-language confusion: what is actually NOT in Luau** (primary source: Luau docs repo, commit 2026-11-18) — [compatibility.md](https://github.com/luau-lang/site/blob/main/src/content/docs/getting-started/compatibility.md), [library.md](https://github.com/luau-lang/site/blob/main/src/content/docs/reference/library.md), [syntax.md](https://github.com/luau-lang/site/blob/main/src/content/docs/getting-started/syntax.md)
- **Not available:**
  - `goto` ("complicates the compiler").
  - 5.3 64-bit integers ("backwards compatibility and performance").
  - **Bitwise operators `& | ~ << >>`**: "`bit32` library covers this".
  - `__gc` finalizers, `<close>` and 5.4 `<const>` attribute syntax, `__pairs`/`__ipairs` (superseded by `__iter`).
  - `io`, `package`, most of `os`/`debug`, `loadfile`, `dofile`, `loadstring` bytecode and `string.dump`.
  - Yieldable metamethods.
  - In Roblox, `loadstring` is additionally disabled by default (ServerScriptService.LoadStringEnabled). That is general knowledge, not verified in this session.
- **Available (do NOT "correct" these):**
  - Floor division `//` and `//=`.
  - Compound assignment `+= -= *= /= %= ^= ..=`.
  - `continue` (a contextual keyword).
  - If-then-else expressions.
  - String interpolation with backticks.
  - Generalized iteration (`for k, v in t do`).
  - Type annotations.
  - `math.pow` (still present).
  - `unpack` and `table.unpack` ("equivalent").
  - `table.pack`; `string.pack/unpack/packsize`; the `utf8` library.
  - `bit32`, `buffer` and `vector` libraries.
  - `math.clamp/sign/round/noise/lerp/map/isnan/isinf/isfinite`.
- **New in 2026: `const` bindings** (`const x = 5` prevents reassignment). The docs show this, but I could not confirm whether Roblox Studio has shipped it. Flag it as version-sensitive.
- Note on `table.unpack`: it does not use `table.pack`'s `n` field, so write `table.unpack(args, 1, args.n)`.
- `#` on a dictionary or a table with holes is unreliable (general Lua semantics; the border is undefined). Count with a loop. Not separately sourced here.
- `string.format`: Luau inherits 5.1 options. I could not verify which extra specifiers are unsupported in this session (gap).

**UI mistakes**
- General guidance from community threads: make sizes Scale-based and put a `UIAspectRatioConstraint` on the parent frame only. Constraints on every element caused problems. TextScaled is simple but can produce too-large text; one alternative is Offset text size with Scale position. — [DevForum: Methods for scaling UIs](https://devforum.roblox.com/t/methods-for-scaling-uis-consistently/467869), [DevForum: How to scale text perfectly](https://devforum.roblox.com/t/how-to-scale-text-perfectly-solved/479087), [DevForum: How to reposition UI to all platforms](https://devforum.roblox.com/t/how-to-reposition-ui-to-all-platforms/3887076?page=2) (search snippets)
- Known 2026 engine bug: a `UIAspectRatioConstraint` inside a TextLabel in a BillboardGui renders oversized on Android. — [DevForum bug report](https://devforum.roblox.com/t/uiaspectratioconstraint-inside-textlabel-in-billboardgui-fails-on-android/4804370)
- roblox-suite UI rules, summarized from the Creator Docs:
  - Prefer Scale over Offset "for almost everything".
  - Use UIListLayout/UIGridLayout with AutomaticSize and padding instead of manual positions.
  - Keep `ScreenInsets = CoreUISafeInsets` for interactive content (respects the top bar and notches).
  - Make the "ResetOnSpawn behavior understood and intentional". It depends on direct ancestry of StarterGui.
  - SurfaceGui/BillboardGui buttons only receive input when under PlayerGui with the part's `CanQuery = true`. BillboardGui also needs `Active = true`.
  - Hide core UI with `StarterGui:SetCoreGuiEnabled` and hide touch controls with `GuiService.TouchControlsEnabled`.

  — [roblox-user-interfaces SKILL](https://github.com/nonlooped/roblox-suite/blob/main/roblox-user-interfaces/SKILL.md)
- I found no source that specifically documents the "generic AI look" of generated Roblox UI (emojis as icons, gradients, TextScaled everywhere). This is a common perception but unsourced here (see Gaps).

### Inferences
- A cluau "anti-hallucination" layer should combine:
  1. A deprecated-to-modern mapping table, kept dated.
  2. A Lua-vs-Luau table that lists both what is missing **and** what is present, to prevent false corrections such as rewriting `//` or removing `continue`.
  3. A placement rule for every snippet.
  4. Server-authority and DataStore checklists.
  5. Type-checking examples with luau-lsp against Roblox definitions where tooling exists.
- Deprecations keep moving (reserved-server APIs in Nov 2026), so cluau should carry a "last verified" date and tell the model to check the docs or the Studio MCP `http_get`/`skill` tools when unsure.
- ResetOnSpawn, a typical AI failure mode, is confirmed only indirectly. It matters because a ScreenGui in StarterGui with ResetOnSpawn=true is re-cloned on every respawn, so LocalScripts inside re-run and state is lost. This is general Roblox behavior and should be verified against the ScreenGui docs.

### Gaps
- No quantitative data on which mistakes are most frequent per model (ChatGPT, Claude, Copilot, Roblox Assistant).
- DevForum and Reddit threads with concrete hallucinated property examples could not be fetched (devforum.roblox.com blocked; Reddit not surfaced by search).
- Roblox Assistant-specific failure documentation was not found.
- `string.format` specifier differences, and whether `const` is live in Roblox, are unverified.
- I found no sourced material on AI "UI aesthetic" failures (emojis, gradients, TextScaled overuse).

## 3. How big studios structure Roblox engineering workflow in 2025-2026 (toolchain, review, testing, CI, Studio MCP/Assistant)

### Takeaway
The professional stack is:
- **Rojo** (or Argon) for file-system sync with Git as source of truth
- **Rokit** for pinning tool versions (it replaced Aftman/Foreman)
- **Wally and/or pesde** for packages
- **luau-lsp, Selene and StyLua** for analysis, lint and format
- **Jest-Lua or TestEZ** for tests, with **Lune** for standalone Luau
- **GitHub Actions** that lint, format-check, build with Rojo, run tests in a real engine via the **Open Cloud Luau Execution API**, and gate publishing to production

Roblox now documents Rojo workflows officially (partially vs. fully managed) while stating it does not maintain Rojo. On the AI side, Roblox Studio ships a **built-in MCP server** (enabled from Assistant > Manage MCP Servers) with about 30 tools for scripts, instance inspection, Luau execution, playtest control and input simulation, screenshots, asset generation and upload, and `save_place`. The older `Roblox/studio-rust-mcp-server` is no longer actively developed. Roblox Assistant gained Planning Mode and a playtesting agent in April 2026.

### Cited Findings

**Toolchain**
- A 2026 toolchain guide lists Rojo (Studio sync), Selene (lint), StyLua (format), Wally (packages), Rokit (tool versions), luau-lsp (editor intelligence), TestEZ (testing) and Lune (standalone runtime). "As of 2026, active maintenance continues." — [oflight.co.jp toolchain guide 2026](https://www.oflight.co.jp/en/columns/luau-developer-toolchain-rojo-selene-wally-2026)
- Recent versions seen in 2026 templates and plugins: Rojo 7.7.1, Rokit 1.2.0, pesde 0.7.4, Lune 0.11.1. pesde can pull Wally packages and installs them into `roblox_packages/`. A typical CI gate runs `rokit install`, `pesde install`, `rojo sourcemap`, `selene`, `stylua --check` and `luau-lsp analyze`. This is a single user's template, not a standard. — [SSuzuka/luau_temp](https://github.com/SSuzuka/luau_temp), [bug-ops/claude-plugins PR #15](https://github.com/bug-ops/claude-plugins/pull/15)
- AI editors and skills are bundling this toolchain:
  - Luano (beta AI editor) supports Rojo or Argon, Selene, StyLua, luau-lsp, Wally and pesde.
  - afrxo/roblox-agent-skills covers "Rojo project format, sync rules, Wally + Pesde, Rokit, Luau LSP, CI".

  — [Luano](https://github.com/ltfupb/Luano), [afrxo/roblox-agent-skills](https://github.com/afrxo/roblox-agent-skills)
- ro-engineer's testing reference (checked 2026-11-01) names [Jest Lua (jsdotlua/jest-lua)](https://github.com/jsdotlua/jest-lua), [TestEZ](https://github.com/Roblox/testez), [Lune](https://github.com/lune-org/lune), [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp), [StyLua](https://github.com/JohnnyMorganz/StyLua), [Selene](https://github.com/Kampfkarren/selene) and [Rojo](https://rojo.space/docs/). Caveats: "A bare analyzer without engine definitions is not equivalent to Studio", and Lune is "not a complete Roblox engine or multiplayer simulator". — [testing.md](https://github.com/excaldev/ro-engineer/blob/main/references/testing.md)

**Official Roblox Rojo docs (2025-2026)**
- Roblox's Creator Docs have a Rojo section with two modes:
  - **Partially managed:** Rojo manages code and Git is its source of truth. Roblox recommends this for most teams that use Git.
  - **Fully managed:** Rojo manages the whole game, including models and images.
- The page states Rojo "is not maintained by Roblox and can change or stop working at any time". — [create.roblox.com/docs/projects/rojo](https://create.roblox.com/docs/projects/rojo) (via search summary)
- The fully managed guide (via search summary):
  - "Places are built from the repo, never edited by hand, and every build can be traced to a commit."
  - Engineers branch off main, and a merge to main triggers a publish to Dev.
  - Never edit the Dev or Stable places by hand, because the next CI publish overwrites them.
  - Studio becomes a deployment target.
  - `rojo serve` uses the plugin API, which cannot set some properties (MeshPart.MeshId, terrain, CSG).

  — [Fully managed Rojo](https://create.roblox.com/docs/projects/rojo/fully-managed)
- These docs changed around 2026-11-16 (a third-party tracker flagged it). — [roblox-suite issue #77](https://github.com/nonlooped/roblox-suite/issues/77)
- Roblox's "Third-party tools" page mentions:
  - rbx-merge, for readable Git diffs and merges of place and model files.
  - Hosting and reviewing code on GitHub, GitLab or Bitbucket.
  - Selene "to catch common issues and enforce coding standards" and StyLua for formatting.

  — [create.roblox.com/docs/projects/external-tools](https://create.roblox.com/docs/projects/external-tools) (via search summary)
- A known pain point: in partially managed teams, Studio-side edits (UI, models) live outside Git and cause merge or overwrite problems with Team Create. — [DevForum: Partially managed Rojo git workflow in teams](https://devforum.roblox.com/t/partially-managed-rojo-git-workflow-in-teams/1381762), [DevForum 2026 thread](https://devforum.roblox.com/t/how-to-approach-team-based-partially-managed-rojo/4711504)
- No Roblox-published PR or code-review standard was found. A 2026 DevForum feature request complains that Studio has "no structural hierarchy or code review process" and asks for role-gated pull requests in Studio (not shipped). — [DevForum feature request](https://devforum.roblox.com/t/feature-push-pull-clone-git-like-architecture-for-scripting/4646086)

**CI/CD with Open Cloud**
- Roblox's official demo, `Roblox/place-ci-cd-demo` (archived 2024-09-25, so dated), has a GitHub Actions workflow. Triggers are `pull_request` and `push` to `production`.
  - Jobs: install-tools (Foreman, now superseded by Rokit), Selene lint, StyLua format check, then "Run Luau tests via Open Cloud" (`tasks/runTests.luau` against a test universe/place, with secret `ROBLOX_API_KEY`).
  - The `concurrency: group: luau-execution` setting exists because the Luau Execution API was limited to 2 concurrent requests per universe.
  - Deployment runs only on push to production after all checks pass.
  - API key scopes: `universe.places:write` and `universe.place.luau-execution-session:write`.

  — [Roblox/place-ci-cd-demo](https://github.com/Roblox/place-ci-cd-demo) (read via clone)
- Stability claim (single source, verify): "Luau Execution is STABLE; place publishing is BETA". — [laazyj PR #9](https://github.com/laazyj/amy-and-the-rainforest-roblox/pull/9)
- Test runners via Open Cloud: the Avant Open Cloud GitHub Action supports TestEZ only. Jest via Luau Execution depends on jsdotlua/jest-lua. — [Avant Open Cloud](https://github.com/marketplace/actions/avant-open-cloud)
- Typical pipeline shape:
  1. Build the place with Rojo as the single artifact.
  2. Upload as Saved (not Published) to a separate test place.
  3. Smoke-test via Luau Execution.
  4. Publish to production in a separate job that holds its own key and is gated on approval.

  One project removed whole-place Rojo publishing from live in favor of script-only sync plus a manual safety variable. — [roblox-agent cloud skill](https://github.com/m4bwav/roblox-agent/blob/main/skills/roblox-agent-cloud/SKILL.md), [RBLX-Tiny-Factory PR #69](https://github.com/LiamTheMo/RBLX-Tiny-Factory/pull/69), [DevForum: Automate place publishing with partially managed Rojo](https://devforum.roblox.com/t/how-to-automate-place-publishing-with-partially-managed-rojo/2443196)

**Roblox Studio built-in MCP server**
- Roblox documents a Studio MCP server "built into Roblox Studio" that implements the Model Context Protocol.
  - Enable it in Studio: Assistant > "…" > **Manage MCP Servers** > **Enable Studio as MCP server**.
  - Quick-connect clients include Claude Code, Claude Desktop, Cursor and Codex CLI.
  - Security warning: MCP clients "can read and modify content in your open Roblox places. Make sure to only connect clients you trust."

  — [create.roblox.com/docs/studio/mcp](https://create.roblox.com/docs/studio/mcp) (via search summary)
- Transport details: on Windows the local proxy launches as `cmd.exe /c "cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat"`; on macOS it is the `StudioMCP` binary in the app bundle. It speaks newline-delimited JSON-RPC 2.0 over stdio. `studio_id` changes on every Studio restart. — [bdidk235/RobloxStudioMCP README](https://github.com/bdidk235/RobloxStudioMCP) (third-party, AI-written; 2026-11-12)
- **Current tool list** (roblox-suite, last reviewed 2026-11-16 against the official docs):
  - Scripts and inspection:
    - `script_read`
    - `multi_edit` (requires `datamodel_type = Edit`; can create scripts)
    - `script_search` (fuzzy name search, ≤10 results)
    - `script_grep` (≤50 matches)
    - `search_game_tree`
    - `inspect_instance`
    - `subagent` (`explore` / `playtest` types)
  - Execution and playtest:
    - `get_studio_state`
    - `execute_luau` (`Edit` / `Client` / `Server`)
    - `start_stop_play`
    - `get_console_output`
    - `screen_capture`
    - `character_navigation`
    - `user_keyboard_input`
    - `user_mouse_input`
  - Assets:
    - `generate_animation` (R15, ≤10 s)
    - `generate_avatar`
    - `generate_mesh`
    - `generate_material`
    - `generate_procedural_model`
    - `wait_job_finished`
    - `search_asset`
    - `insert_asset`
    - `upload_image`
    - `store_image`
  - Documentation and discovery:
    - `http_get` (allowed Roblox docs URLs)
    - `skill` (Studio's own task guidance)
    - `list_roblox_studios`
  - Place:
    - `save_place` (saves a new place version without a dialog)
    - `submit_feedback`
  - Renames: old names such as `explore_subagent`/`playtest_subagent` were replaced by `subagent`, and `set_active_studio` by explicit `studio_id` targeting.
  - Open Cloud calls through the signed-in session are documented at `create.roblox.com/docs/en-us/studio/mcp-open-cloud`.

  — [roblox-suite roblox-mcp/tool-reference.md](https://github.com/nonlooped/roblox-suite/blob/main/roblox-mcp/references/tool-reference.md)
- Recommended agent sequence: `list_roblox_studios` → pass `studio_id` on every call → `get_studio_state` → `start_stop_play` → confirm `Server` is available → `execute_luau` → `get_console_output`. "Use a dedicated test place before operations that can publish… or write persistent data." — [same source](https://github.com/nonlooped/roblox-suite/blob/main/roblox-mcp/references/tool-reference.md)
- The legacy server [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server) (last commit 2026-04-03) carries this banner: "This MCP Server is no longer being actively developed… We've shifted ongoing engineering investment to the built-in MCP Server included with Roblox Studio." Its tools were `run_code`, `insert_model`, `get_console_output`, `start_stop_play`, `run_script_in_play_mode` and `get_studio_mode`. For Claude Code it was added with `claude mcp add --transport stdio Roblox_Studio -- <path> --stdio`.
- Third-party alternatives exist, for example boshyxd/robloxstudio-mcp ("51 tools"). — [boshyxd/robloxstudio-mcp](https://github.com/boshyxd/robloxstudio-mcp)

**Roblox Assistant (2026)**
- April 16–17, 2026: Roblox announced **Planning Mode** for Roblox Assistant. Select "plan" in the dropdown or type `/plan`. It analyzes code and the data model, asks clarifying questions, and produces an editable action plan. It can run parallel agents for scripting, layout and UI.
- A **playtesting agent** (beta) reads output logs, takes screenshots, and simulates keyboard and mouse input to find bugs, then feeds them back to the Assistant for automatic fixes.
- Mesh and procedural-model generation shipped alongside. One source says Procedural Models reached GA on 2026-05-18 (unverified). BloxBot dates the announcement to May 1 (conflicting).

  — [TechCrunch 2026-04-16](https://techcrunch.com/2026/04/16/robloxs-ai-assistant-gets-new-agentic-tools-to-plan-build-and-test-games/), [DevForum: Announcing Planning Mode](https://devforum.roblox.com/t/announcing-planning-mode-for-roblox-assistant/4580715), [technology.org](https://www.technology.org/2026/04/17/roblox-assistant-now-plans-your-game-builds-it-plays-it-and-judges-itself/), [BloxBot (conflicting date)](https://www.bloxbot.ai/guide/whats-new-roblox-ai-2026)

### Inferences
- For cluau: when a Rojo project is detected (`default.project.json`), treat the file system as the source of truth. Do not edit the same scripts via the Studio MCP `multi_edit` at the same time ("avoid competing writers", ro-engineer tool-modes). Run `selene`, `stylua --check` and `luau-lsp analyze` if they are installed. Report which of these actually ran.
- With the Studio MCP connected, cluau can verify instead of guessing:
  - `search_game_tree` / `inspect_instance` before editing
  - `execute_luau` in Server/Client during play for runtime checks
  - `get_console_output` for errors
  - `screen_capture` to review UI on different viewports
  - `user_mouse_input` to click-test UI
  - `save_place` and `upload_image` only with explicit approval (ro-engineer hard stops)
- The ResetOnSpawn, safe-inset and Scale/Offset checks can be validated visually with `screen_capture` during a playtest.
- The big-studio pattern is branch → PR review (human + Selene/StyLua/luau-lsp + engine tests via Open Cloud) → merge to main deploys Dev → gated promote to Stable/production. Nobody hand-edits CI-owned places.

### Gaps
- No public code-review standards from named large studios were found.
- Argon (an alternative to Rojo) has no primary source in this session.
- The exact Open Cloud Luau Execution limits in 2026 are unverified (the "2 concurrent per universe" figure is from 2024).
- The official Studio MCP page text and its launch date could not be read directly (create.roblox.com blocked), and the tool list relies on roblox-suite's 2026-11-16 transcription.
- Whether Studio's Script Editor gained new AI features in late 2026 beyond Assistant/Planning Mode was not researched.
