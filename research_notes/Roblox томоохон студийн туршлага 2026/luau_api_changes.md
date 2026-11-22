# Roblox engine + Luau language/API changes and deprecations, 2024 to late 2026 (current vs deprecated fact sheet)

> **Method note (read first).** In this session devforum.roblox.com, create.roblox.com and luau.org did not resolve (sandbox network allowlist), so their pages could not be fetched directly. Instead I cloned the **primary-source repositories** and read them locally:
> - `github.com/Roblox/creator-docs` (the source of create.roblox.com/docs), HEAD `a23352b`, committed 2026-11-21, with `STUDIO_VERSION` = 0.748.0.7481526. API facts below come from its `content/en-us/reference/engine/**.yaml` files, which carry `deprecation_message` and `tags: [Deprecated]`. I fetched history back to 2024-01-01 with `git log -S` to date when text first appeared.
> - `github.com/luau-lang/rfcs` (rfcs.luau.org), HEAD 2026-11-20; `github.com/luau-lang/site` (luau.org); `github.com/luau-lang/luau` (source, synced to release 0.748 on 2026-11-20).
> - `github.com/Sleitnick/Knit` and `github.com/MadStudioRoblox/ProfileStore`.
>
> URLs below point to the public pages. For creator-docs, the create.roblox.com URL maps 1:1 to the repo file path. Repo-history dates mean "first appeared in the docs repo". That is usually within days of the engine release, but it is NOT an announcement date. Any date shown as "2024-01-02" means the item already existed before the history cutoff (pre-2024). Some DevForum facts came from web-search snippets only, and are marked "(search snippet)".
>
> **Roblox now publishes an AI-agent-targeted "latest features" feed** at `content/en-us/latest-features/latest-features.json` (updatedAt 2026-11-20), plus `retired.json`. It is quoted heavily below because it is Roblox's own statement of what replaces what. Source: https://github.com/Roblox/creator-docs/blob/main/content/en-us/latest-features/latest-features.json

## Luau language and library features added 2024-2026

### Takeaway
As of Nov 2026, Roblox Luau has:
- the `vector` library, plus `math.lerp`, `math.map`, `math.isnan`, `math.isinf`, `math.isfinite` and `math.nan`;
- `buffer.readbits`/`writebits` and `buffer.read/writevectorf32x2/x3`;
- the `const` keyword;
- require-by-string with `./`, `../`, `@self/` and `@game/`;
- the `@native`, `@checked` and `@deprecated` attributes, including the `@[deprecated{...}]` parameter form;
- user-defined type functions and `read`/`write` property modifiers.

The New Type Solver reached general release in November 2025, as the default for non-strict and nocheck scripts; strict-mode projects had to opt in. A 64-bit integer type was formally **rejected** (RFC #269, Nov 2026). Classes, `if local`, `while local` and export-by-value are still experimental or flagged.

### Cited Findings
**Type solver**
- New Type Solver general release: "In November 2025, the New Type Solver reached general release, becoming the default for scripts using nocheck and nonstrict modes, while strict-mode projects could opt in at that point." — [create.roblox.com/docs/learn/more/luau](https://create.roblox.com/docs/learn/more/luau) (repo: content/en-us/learn/more/luau.md).
- DevForum general-release post, 2025: the solver "is rolling out automatically for … everyone who is not currently using strict mode". Strict-mode users "will be opted out of the New Type Solver by default" but can enable it. New Roblox templates default to **Nonstrict**. The Weekly Recap for Nov 17–21, 2025 says both the New Type Solver and "Non-Strict by Default" left Studio Beta (search snippet) — [General Release: Luau's New Type Solver](https://devforum.roblox.com/t/general-release-luau%E2%80%99s-new-type-solver/4084991); [Weekly Recap Nov 17-21 2025](https://devforum.roblox.com/t/weekly-recap-november-17-21-2025/4087895)
- The Studio Beta was announced in 2024 — [New Type Solver [Beta]](https://devforum.roblox.com/t/new-type-solver-beta/3155804)
- Per-place controls:
  - `Workspace.UseNewLuauTypeSolver` (Enum.RolloutState) "controls whether the new Luau type solver is used…; `Default` follows the current engine-wide rollout state". It first appeared in the docs 2025-06-11.
  - `Workspace.LuauTypeCheckMode` (Enum.LuauTypeCheckMode) sets strict/nonstrict.
  - [Workspace API](https://create.roblox.com/docs/reference/engine/classes/Workspace)
- Rollout issues were reported, including high memory use and autocomplete breakage (search snippets) — [devforum memory thread](https://devforum.roblox.com/t/new-luau-type-solver-causing-extremely-high-memory-usage/4110630)

**math library** (Roblox reference [math](https://create.roblox.com/docs/reference/engine/libraries/math); RFCs at rfcs.luau.org)
- Members: `math.lerp(a, b, t)` and `math.map(x, inmin, inmax, outmin, outmax)`, documented on Roblox 2025-02-10 (creator-docs PR #1020). `math.isnan(x)`, `math.isinf(x)` and `math.isfinite(x)` all return `boolean` and were documented 2026-02-11 (PR #1434). Constants are `math.e`, `math.huge`, `math.nan`, `math.phi`, `math.pi`, `math.sqrt2` and `math.tau` (RFC "Math constants", Implemented) — [RFC math.lerp](https://rfcs.luau.org/function-math-lerp.html), [RFC math.map](https://rfcs.luau.org/function-math-map.html), [RFC isnan/isinf/isfinite](https://rfcs.luau.org/math-isnan-isfinite-isinf.html), [RFC math constants](https://rfcs.luau.org/math-constants.html)
- The Luau team's own recap confirms that `vector`, `math.map`, `math.lerp`, `math.isnan/isinf/isfinite` and `buffer.readbits/writebits` were added during 2025 — [Luau Recap for 2025: Runtime (2025-12-19)](https://luau.org/news/2025-12-19-luau-recap-runtime-2025)
- **`math.clamp` errors when min > max: TRUE.** Luau VM source `VM/src/lmathlib.cpp` has `luaL_argcheck(L, min <= max, 3, "max must be greater than or equal to min")`. The Roblox docs say only that max "must be greater than or equal to min" — [luau lmathlib.cpp](https://github.com/luau-lang/luau/blob/master/VM/src/lmathlib.cpp)

**vector library** (Roblox [vector](https://create.roblox.com/docs/reference/engine/libraries/vector))
- Members: `vector.zero`, `vector.one`, `vector.create`, `vector.magnitude`, `vector.normalize`, `vector.cross`, `vector.dot`, `vector.angle`, `vector.floor`, `vector.ceil`, `vector.abs`, `vector.sign`, `vector.clamp`, `vector.lerp`, `vector.max` and `vector.min`.
- `vector.lerp(vec1, vec2, alpha)` was documented 2025-09-03; alpha is "not limited to [0,1]". `vector.create` also has a 2-component form (RFC "2-component vector constructor", Implemented).
- The library gives fast-calls, constant folding and native codegen lowering, and `vector.dot` lowers to a CPU dot instruction — [Luau Recap 2025](https://luau.org/news/2025-12-19-luau-recap-runtime-2025); [RFC vector library](https://rfcs.luau.org/vector-library.html)

**buffer library** (Roblox [buffer](https://create.roblox.com/docs/reference/engine/libraries/buffer))
- Full member list: `create`, `fromstring`, `tostring`, `len`, `readbits`, `writebits`, `readi8/u8/i16/u16/i32/u32/f32/f64` and the matching writes, `readvectorf32x2`, `readvectorf32x3`, `writevectorf32x2`, `writevectorf32x3`, `readstring`, `writestring`, `copy` and `fill`.
- `readbits`/`writebits` were documented on Roblox 2025-03-31 (RFC function-buffer-bits, Implemented). The `readvectorf32x2/x3` and `writevectorf32x2/x3` functions were documented on Roblox **2026-11-05** and were added in Luau 0.747. Offsets are 0-based — [Luau releases](https://github.com/luau-lang/luau/releases)

**table, string and coroutine**
- Table members: `table.clear`, `clone`, `concat`, `create`, `find`, `freeze`, `isfrozen`, `insert`, `maxn`, `move`, `pack`, `remove`, `sort` and `unpack`. `table.getn`, `foreach` and `foreachi` are deprecated (RFC "Deprecate table.getn/foreach/foreachi", Implemented) — [table](https://create.roblox.com/docs/reference/engine/libraries/table); [RFC](https://rfcs.luau.org/deprecate-table-getn-foreach.html)
- **`table.sort` "invalid order function for sorting": TRUE, with nuance.** The Roblox docs say the error "is thrown if both `comp(a, b)` and `comp(b, a)` return `true`". In the VM source it is raised when the partition scan runs off the array bounds. A `<=` comparator therefore errors when elements are equal and the scan hits the boundary; it is not guaranteed to error on every call, and can otherwise just mis-sort. Always use strict `<` — [table docs](https://create.roblox.com/docs/reference/engine/libraries/table#sort); [ltablib.cpp](https://github.com/luau-lang/luau/blob/master/VM/src/ltablib.cpp)
- String members: `string.byte`, `char`, `find`, `format`, `gmatch`, `gsub`, `len`, `lower`, `match`, `pack`, `packsize`, `rep`, `reverse`, `split`, `sub`, `unpack` and `upper`. No new string functions appeared in 2024-2026; there were only optimizations (`string.gsub` fast path in 0.742, `string.split` optimized in 0.740) — [string](https://create.roblox.com/docs/reference/engine/libraries/string); [Luau releases](https://github.com/luau-lang/luau/releases)
- `coroutine.finally(co, callback(status: "finished"|"error"|"cancelled", ...))` has an RFC in the rfcs repo. In Luau 0.742 (Oct 2025) it was "no longer behind a debug flag". It is **not** listed in the Roblox coroutine reference I checked, so treat it as not yet confirmed in Roblox — [RFC coroutine.finally](https://rfcs.luau.org/function-coroutine-finally.html)

**Syntax and keywords**
- **`const` keyword (Implemented).** `const X = 5` creates a binding that cannot be reassigned, including via `+=`; the value itself stays mutable. The Roblox Luau docs have a "Const variables" section, first added **2026-08-10**: "To give it local scope and also prevent reassigning it, use `const` instead of `local`." The style guide says `LOUD_SNAKE_CASE` for constants — [Roblox variables doc](https://create.roblox.com/docs/luau/variables#const-variables); [RFC const](https://rfcs.luau.org/const-keyword.html)
- **Explicit type parameter instantiation** (RFC Implemented) — [RFC](https://rfcs.luau.org/explicit-type-parameter-instantiation.html)
- **Experimental or flagged (do NOT emit in code):**
  - `class` syntax, behind the `DebugLuauUserDefinedClasses` flag; releases 0.744-0.747 call it "Classes (experimental)".
  - `if local` / `while local` / `while const`, behind the `LuauExperimentalIfLocalSyntax` and `LuauExperimentalWhileLocalSyntax` flags. Release 0.740 says "`if local` is moving toward full release".
  - `export` by value (`export foo = 5`), behind `LuauExportValueSyntax`.
  - Exact table types (0.740).
  - Sources: [Parser.cpp](https://github.com/luau-lang/luau/blob/master/Ast/src/Parser.cpp); [Luau releases](https://github.com/luau-lang/luau/releases); [RFC classes](https://github.com/luau-lang/rfcs/blob/master/docs/syntax-classes.md)
- **64-bit integer type: REJECTED.** The latest rfcs commit (2026-11-20) is titled "RFC: We will not be adding a 64-bit Integer Type (#269)". Luau 0.747 "Clipped in-progress integer work (RFC 269)". Earlier releases (0.740, 0.744) had shipped experimental `integer.*` functions, but these must not be used — [rfcs repo](https://github.com/luau-lang/rfcs); [Luau releases](https://github.com/luau-lang/luau/releases)

**Attributes**
- `--!native` (whole script) or `@native` (per function) enables native code generation — [Roblox native-code-gen](https://create.roblox.com/docs/luau/native-code-gen)
- The parser accepts `@checked`, `@native` and `@deprecated`. `@checked` is used in built-in definitions and is not a general user feature.
- The parameterized form is `@[deprecated {use = "bar()", reason = "…"}]`; inside `@[...]` there is no leading `@` (RFCs "Function Attribute Parameters" and "Deprecated Attribute", both Implemented) — [RFC deprecated attr](https://rfcs.luau.org/syntax-attribute-functions-deprecated.html); [RFC attr params](https://rfcs.luau.org/syntax-attributes-functions-parameters.html)

**Types**
- **User-defined type functions:** `type function name(ty) … end` (RFC Implemented). Later RFCs (Implemented) added support for generic function types, thread types and buffer types. Since 0.746/0.748, type functions can no longer reference expression globals — [luau.org type functions](https://luau.org/types/type-functions); [RFC](https://rfcs.luau.org/user-defined-type-functions.html)
- **`read`/`write` property modifiers:** `type ReadOnly = { read x: number }` and `{ write x: number }` (RFC "Syntax for table property access modifiers", Implemented). These need the new solver — [RFC](https://rfcs.luau.org/syntax-property-access-modifiers.html)
- `keyof`, `index` and `rawget` type operators and metatable type functions all have Implemented RFCs — [rfcs repo docs/](https://github.com/luau-lang/rfcs/tree/master/docs)

**require-by-string** (Roblox side, documented 2025-05-19)
- "Paths with the `./` prefix begin resolution at `script.Parent`. `../` → `script.Parent.Parent`. `@self/` → `script`. `@game/` → `game`." Each component is a child; `..` is the parent.
- It is **non-blocking**: "If the desired ModuleScript is not present at the time … the call will fail… it does not implicitly wait."
- Source: [LuaGlobals require](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#require)
- The first-party `@rbx/` alias exists. Example: `require("@rbx/AvatarAbilities")` for the Character Controller Library — [CCL docs](https://create.roblox.com/docs/characters/character-controller-library)
- RFCs for require-by-string relative paths, aliases, abstract module paths and `init.luau`, and `.config.luau` config are all Implemented. A standalone Luau.Require library shipped in 2025 — [Luau Recap 2025](https://luau.org/news/2025-12-19-luau-recap-runtime-2025)

### Inferences
- A skill can safely emit `math.lerp`, `math.map`, `math.isnan`, `vector.*`, `const`, `@native`, `read`-only property types and `require("./Module")`. It should keep `require(script.Parent.Module)` as an equally valid form. It should not emit `class`, `if local`, `export x =`, or any `integer.*` function.
- Studio's default typecheck mode for new templates is nonstrict, with the new solver. Code annotated `--!strict` may be checked by the old solver unless the place opted in, so type-function/`read` features could behave differently there.

### Gaps
- I could not fetch the exact DevForum post dates for the type-solver general release; the November 2025 month is confirmed by Roblox docs.
- `coroutine.finally` and exact-table availability on Roblox are unconfirmed.
- No Roblox doc page confirming `@deprecated` attribute support in Studio was found; it is confirmed only in the Luau parser and RFC.

## Roblox engine API changes 2024-2026 (what is current)

### Takeaway
Several systems are now the recommended current path:
- **Input Action System** (stable 2026-06-11), with ContextActionService "being sunset".
- **Audio API** (stable 2024-09-10). Sound is not deprecated.
- **TextChatService**, mandatory for all player chat; legacy Chat is "gone" (2026-10-21).
- **Server Authority** (stable 2026-07-09), configured via `Workspace.AuthorityMode`, `RunService:BindToSimulation()`, `RunService:SetPredictionMode()` and related APIs.
- **Character Controller Library** (stable 2026-04-08).
- **AnimationConstraint** joints via `StarterPlayer.AvatarJointUpgrade`.
- **ConfigService** (2025-11-06).
- **Script Sync** (2026-06-17).

Many Workspace behaviors are now `Enum.RolloutState` toggles.

### Cited Findings
**Input Action System**
- Classes: `InputContext` (properties `Priority: int`, `Sink: boolean`, `Enabled`), `InputAction` (`Type: Enum.InputActionType` = Bool, Direction1D, Direction2D, Direction3D or ViewportPosition; events `Pressed`, `Released`, `StateChanged(value)`; method `GetState()`) and `InputBinding` (`KeyCode`, `Type: Enum.InputBindingType`, `Fire(state)`).
- **`InputAction:Fire()` is DEPRECATED.** Its message reads: "Use `InputBinding:Fire()` with a `Enum.InputBindingType|Scriptable` binding instead", added 2026-06-15.
- Sources: [InputAction](https://create.roblox.com/docs/reference/engine/classes/InputAction), [InputBinding](https://create.roblox.com/docs/reference/engine/classes/InputBinding), [InputContext](https://create.roblox.com/docs/reference/engine/classes/InputContext)
- latest-features entry `input-action-system`: status stable, released **2026-06-11**. "Default player scripts now use it, and ContextActionService is being sunset." It replaces `ContextActionService:BindAction()`, `UserInputService.InputBegan` for gameplay actions, and "PlayerModule internals such as GetControls()". Guidance: "Put InputContexts in ReplicatedStorage… Ask the user to set Workspace.PlayerScriptsUseInputActionSystem to Enabled; scripts can't." — [latest-features.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/latest-features/latest-features.json); [IAS guide](https://create.roblox.com/docs/input/input-action-system)
- Nuance: ContextActionService itself has **no** deprecation tag in the API reference as of 2026-11-21. Only `BindActionToInputTypes` is deprecated. CAS is "being sunset", not formally deprecated — [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService)
- Release stages:
  - Studio Beta: [Studio Beta: New Input Action System](https://devforum.roblox.com/t/studio-beta-new-input-action-system/3656214) (2025).
  - Client Beta (publishable): [Client Beta](https://devforum.roblox.com/t/client-beta-input-action-system-is-now-available-to-publish-in-experiences/3890979).
  - Full release "IAS + newly converted player scripts": [Full Release](https://devforum.roblox.com/t/full-release-input-action-system-ias-newly-converted-player-scripts/4678416).
  - Input Action Manager editor full release: [Full Release: Input Action Manager](https://devforum.roblox.com/t/full-release-input-action-manager/4965021) (search snippets).
- **`UserInputService.PreferredInput`** (read-only, Enum.PreferredInput = KeyboardAndMouse, Gamepad, Touch or MicroGamepad) was documented 2025-06-02 — [UserInputService](https://create.roblox.com/docs/reference/engine/classes/UserInputService)

**Audio API**
- `AudioPlayer` (`Asset: ContentId`, `Play(atTime: double?)`), `AudioEmitter`, `AudioListener`, `Wire`, `AudioDeviceOutput` and `AudioDeviceInput`.
- latest-features `audio-api`: stable, **2024-09-10**. Guidance: "wire an AudioPlayer (set Asset, not AssetId) to an AudioDeviceOutput for 2D or an AudioEmitter for 3D. 3D needs a listener: set SoundService.DefaultListenerLocation… For voice, set VoiceChatService.UseAudioApi to Enabled. **Sound isn't deprecated**, so keep working Sound code unless asked, but it gets no acoustic simulation." — [latest-features.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/latest-features/latest-features.json); [audio objects](https://create.roblox.com/docs/audio/objects)
- Deprecated Sound properties: `Sound.EmitterSize`, `MaxDistance` and `MinDistance`, replaced by `RollOffMinDistance`/`RollOffMaxDistance`; `Sound.Pitch` is replaced by `PlaybackSpeed` — [Sound](https://create.roblox.com/docs/reference/engine/classes/Sound)

**TextChatService and legacy chat**
- The `Chat` class is deprecated ("Use TextChatService instead", added to docs 2024-07-18). `TextChatService.ChatVersion` is deprecated "in newly created Studio experiences. TextChatService is the only allowed chat system and is automatically enabled" (2025-06-26) — [Chat](https://create.roblox.com/docs/reference/engine/classes/Chat); [TextChatService](https://create.roblox.com/docs/reference/engine/classes/TextChatService)
- latest-features `textchatservice-for-all-chat`: stable, **2026-10-21**. "Legacy Chat is gone, and **by May 2027 scripts can't read message text**." It replaces `Player.Chatted` command parsing, RemoteEvents that relay player messages, and custom UIs reading `TextChatMessage.Text`. Commands should use `TextChatCommand` (`PrimaryAlias`, `Triggered`). Custom UI should use `TextChannelWindow`. Private channels should call `TextChannel:SetDirectChatRequester()` before `AddUserAsync` — [latest-features.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/latest-features/latest-features.json)
- Chat guidelines: "If players can converse in your game outside TextChatService, Roblox might take your game down". Player-editable visible text needs filtering and a one-minute rate limit. By May 2027, preset phrases must use Quick Words. There is also a DevForum post, "Migrate to TextChatService: Removing support for legacy chat and custom chat systems" — [chat guidelines](https://create.roblox.com/docs/chat/guidelines); [DevForum 3237100](https://devforum.roblox.com/t/migrate-to-textchatservice-removing-support-for-legacy-chat-and-custom-chat-systems/3237100)
- `TextFilterResult:GetChatForUserAsync` is deprecated and "returns an empty string" — [TextFilterResult](https://create.roblox.com/docs/reference/engine/classes/TextFilterResult)

**Server Authority** (name: "Server Authority")
- Announced at RDC 2025 for early testing. Studio Beta: ["Build Fair, Responsive Games with Server Authority"](https://devforum.roblox.com/t/studio-beta-build-fair-responsive-games-with-server-authority/4139157). Full release: ["Ship Fair And Competitive Games with Server Authority"](https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993). Roblox newsroom post, July 2026: [newsroom](https://about.roblox.com/newsroom/2026/07/creating-responsive-cheat-resistant-games-roblox-server-authority) (search snippets).
- latest-features `server-authority`: stable, **2026-07-09**. APIs: `Workspace.AuthorityMode`, `RunService:BindToSimulation()`, `InputAction:GetState()`, `Instance:SetAttribute()`, `Animator:GetTrackByAnimationId()`, `Player:GetCameraState()`, `RunService:SetPredictionMode()` and `RunService.PostSimulation`. It replaces `SetNetworkOwner()` for anti-cheat, "Gameplay loops on Heartbeat or RenderStepped" and "UserInputService events in gameplay simulation" — [latest-features.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/latest-features/latest-features.json)
- Setup (docs): "`Workspace.AuthorityMode` must be `Server` (setting this automatically sets the following five)". The five are `NextGenerationReplication` enabled, `PlayerScriptsUseInputActionSystem` enabled, `SignalBehavior` = Deferred, `UseFixedSimulation` enabled and `StreamingEnabled` enabled.
- Gameplay code goes in a ReplicatedStorage ModuleScript, required by both a Script and a LocalScript, and calls `RunService:BindToSimulation(function(deltaTime) … end)`.
- Use `time()` inside simulation; it is synced and rewinds on resimulation. Do not use `tick()`, `os.time()` or `os.clock()` there.
- Prediction is controlled with `RunService:SetPredictionMode(instance, Enum.PredictionMode)` and checked with `RunService:GetPredictionStatus(instance)`.
- Source: [Server authority docs](https://create.roblox.com/docs/projects/server-authority)
- Signatures:
  - `RunService:BindToSimulation(function, frequency: StepFrequency, priority: int) -> RBXScriptConnection`, documented 2025-12-01.
  - `Enum.AuthorityMode` = {Server, Automatic}; `Workspace.AuthorityMode` was documented 2025-06-20.
  - Source: [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService)

**Instance tags, RunService events and Players**
- `Instance:AddTag(tag)`, `HasTag(tag)`, `RemoveTag(tag)` and `GetTags()` exist; `CollectionService:AddTag/GetTagged` remain valid and are not deprecated. `CollectionService:GetCollection` and `ItemAdded`/`ItemRemoved` are deprecated — [Instance](https://create.roblox.com/docs/reference/engine/classes/Instance)
- `RunService.PreRender(deltaTimeRender)`, `PreAnimation(deltaTimeSim)`, `PreSimulation(deltaTimeSim)` and `PostSimulation(deltaTimeSim)` exist. **`RenderStepped`, `Heartbeat` and `Stepped` are NOT deprecated** (no deprecation tag as of 2026-11-21). `RunService:Reset` is deprecated — [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService)
- `Players.UseStrafingAnimations: boolean` exists and predates 2024. It "Determines whether R15 character models play directional strafing and backpedaling animations" — [Players](https://create.roblox.com/docs/reference/engine/classes/Players)

**Avatar and characters**
- `AnimationConstraint` is "The default joint type for R15 avatar rigs" (documented 2024-11-05). `StarterPlayer.AvatarJointUpgrade` (RolloutState, Roblox-script-security, so set it in Studio) "Controls whether avatars spawn with AnimationConstraint joints". Motor6D is "Superseded by AnimationConstraint for avatar/character rigs" — [AnimationConstraint](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint); [characters](https://create.roblox.com/docs/characters)
- **Character Controller Library (CCL)**, stable **2026-04-08**: a Luau ability framework on `ControllerManager`/`GroundController`/`AirController` that "replaces Humanoid movement… Roblox recommends it for all new games". APIs: `require("@rbx/AvatarAbilities")`, `AvatarAbilities.getAbilityConfigurationForCharacter()`, `waitForAbilityManager()` and `AbilityManager:AddAbility()`. Custom abilities need the "AvatarAbilities" Studio beta. `AvatarAbilities.addAbilityForCharacter` is listed as replaced — [latest-features.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/latest-features/latest-features.json); [CCL docs](https://create.roblox.com/docs/characters/character-controller-library)
- `Animator:GetTrackByAnimationId(animationId)` returns an existing track (2026-05-05). `Player:LoadCharacterAsync()` supersedes `LoadCharacter()` (2025-12-09). `Workspace.PlayerCharacterDestroyBehavior` auto-destroys old characters and leaving Player objects — [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator); [Player](https://create.roblox.com/docs/reference/engine/classes/Player)

**EditableImage and EditableMesh**
- Both exist and are `NotCreatable` via `Instance.new`.
- Create them with `AssetService:CreateEditableImage(options?)` / `CreateEditableMesh(options?)` (empty) or `CreateEditableImageAsync(content: Content, options?)` / `CreateEditableMeshAsync(content: Content, options?)`.
- Display them with `ImageLabel.ImageContent = Content.fromObject(editableImage)`.
- Source: [AssetService](https://create.roblox.com/docs/reference/engine/classes/AssetService)

**Content data type**
- `Content.fromUri(uri)` and `Content.fromObject(object)`. `ImageLabel.ImageContent: Content` was documented 2024-10-17 and supports asset URIs and EditableImage — [Content](https://create.roblox.com/docs/reference/engine/datatypes/Content)

**Capabilities and sandboxing**
- `Instance.Sandboxed: boolean` and `Instance.Capabilities: SecurityCapabilities` were documented 2024-04-03. `Workspace.SandboxedInstanceMode` = `Experimental` enables it, so it is still experimental — [Instance](https://create.roblox.com/docs/reference/engine/classes/Instance); [capabilities](https://create.roblox.com/docs/scripting/capabilities)

**Workspace properties** (2026-11-21 reference)
- Rollout toggles typed `Enum.RolloutState`: `NextGenerationReplication`, `UseFixedSimulation`, `PlayerScriptsUseInputActionSystem`, `UseNewLuauTypeSolver`, `ImprovedPhysicsReplication`, `MeshStreamingAndImprovedLods`, `EnableSLIMAvatars`, `NextGenerationPhysicsSolver` (experimental) and `LayeredClothingCacheOptimizations`.
- Other properties: `AuthorityMode`, `SignalBehavior` (Default, Immediate, Deferred or AncestryDeferred), `StreamingEnabled` (not scriptable, set in Studio), `PhysicsSteppingMethod` (Default, Fixed or Adaptive; not settable from Luau), `RejectCharacterDeletions`, `PlayerCharacterDestroyBehavior`, `SandboxedInstanceMode`, `LuauTypeCheckMode`, `PathfindingUseImprovedSearch`, `AvatarUnificationMode` (R6 to R15 adapter) and `FallHeightEnabled`.
- `FilteringEnabled` and `InterpolationThrottling` are deprecated.
- Source: [Workspace](https://create.roblox.com/docs/reference/engine/classes/Workspace)
- The `SignalBehavior` resumption points include `task.wait/spawn/delay`, `Heartbeat` and `BindToClose` — [Deferred events](https://create.roblox.com/docs/scripting/events/deferred)

**UI**
- `UIFlexItem`, `UIListLayout.Wraps` and `UIListLayout.HorizontalFlex` (UIFlexAlignment).
- `GuiObject.Interactable: boolean` exists (pre-2024).
- `ScreenGui.ScreenInsets`, with `Enum.ScreenInsets` = {None, DeviceSafeInsets, CoreUISafeInsets, TopbarSafeInsets}, plus `ScreenGui.SafeAreaCompatibility`.
- `UIDragDetector`, `Path2D` (2D cubic spline), `DragDetector` (3D) and `CanvasGroup`.
- `Instance:GetStyled(name, selector?)` belongs to the styling system.
- **`GuiObject.Draggable`, `DragBegin` and `DragStopped` are deprecated → use `UIDragDetector`** (2024-08-14). `GuiObject:TweenPosition`, `TweenSize` and `TweenSizeAndPosition` are deprecated → use TweenService.
- Sources: [GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject); [ScreenInsets enum](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets)
- Fonts: `Font.fromName(name, weight?, style?)`, `Font.fromEnum(Enum.Font)` and `Font.fromId(id, weight?, style?)` exist. `TextLabel.FontFace: Font` is the current property; `TextLabel.Font` (Enum.Font) is tagged **Hidden**/NotReplicated, so it is legacy — [Font](https://create.roblox.com/docs/reference/engine/datatypes/Font); [TextLabel](https://create.roblox.com/docs/reference/engine/classes/TextLabel)

**Services**
- `HttpService:GetSecret(key) -> Secret` (pre-2024) — [HttpService](https://create.roblox.com/docs/reference/engine/classes/HttpService)
- MarketplaceService:
  - `GetUserSubscriptionStatusAsync(user: Player, subscriptionId: string)` (pre-2024).
  - `PromptSubscriptionPurchase(user, subscriptionId)`.
  - `PromptBulkPurchase(player, lineItems, options)`, for avatar items, documented 2024-05-15.
  - `GetDeveloperProductsAsync()`.
  - `UserOwnsGamePassAsync(userId, gamePassId)`.
  - **`GetProductInfo` is deprecated → `GetProductInfoAsync(assetId, infoType)`** (2025-12-09). `PlayerOwnsAsset`/`PlayerOwnsBundle` → `…Async`. `PromptPremiumPurchase` → `PromptRobloxSubscriptionPurchase`.
  - `Player.MembershipType` is deprecated → `Player.HasRobloxSubscription`.
  - Source: [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService)
- AnalyticsService signatures:
  - `LogEconomyEvent(player, flowType, currencyType, amount, endingBalance, transactionType, itemSku?, customFields?)`
  - `LogFunnelStepEvent(player, funnelName, funnelSessionId?, step, stepName?, customFields?)`
  - `LogOnboardingFunnelStepEvent(player, step, stepName?, customFields?)`
  - `LogCustomEvent(player, eventName, value?, customFields?)`
  - `LogProgressionEvent(player, progressionPathName, status, level?, levelName?, customFields?)`
  - `FireEvent` is deprecated.
  - Source: [AnalyticsService](https://create.roblox.com/docs/reference/engine/classes/AnalyticsService)
- **ConfigService** (stable 2025-11-06): `ConfigService:GetConfigAsync()`, `GetConfigForPlayerAsync(player)`, `ConfigSnapshot:GetValue`, `UpdateAvailable`, `Refresh` and `GetValueChangedSignal`. Server only — [configs doc](https://create.roblox.com/docs/production/configs)
- **Script Sync** (stable 2026-06-17): `InstanceFileSyncService`. Built-in two-way sync of `.luau` files, where `x.server.luau` is a Script and `x.luau` a ModuleScript — [sync doc](https://create.roblox.com/docs/scripting/sync)
- SLIM (beta, 2026-05-12): `Model.LevelOfDetail = Enum.ModelLevelOfDetail.SLIM` and `Workspace.EnableSLIMAvatars` — [SLIM](https://create.roblox.com/docs/workspace/streaming/slim)
- Lighting: `Lighting.Technology` is deprecated → `Lighting.LightingStyle` + `Lighting.PrioritizeLightingQuality` (LightingStyle documented 2024-12-05). `HapticService` (whole service) is deprecated → `HapticEffect` instance (2025-02-06). `GuiService:IsTenFootInterface` → `GuiService.ViewportDisplaySize` — [Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting); [HapticService](https://create.roblox.com/docs/reference/engine/classes/HapticService)

### Inferences
- For new gameplay input, emit an IAS-based setup (InputContext/InputAction/InputBinding) as the default. Mention CAS/UIS only for legacy code or non-gameplay cases.
- For competitive games, mention Server Authority, but note that it requires a Studio property change the script cannot make.
- For audio, either Sound or the Audio API is acceptable, with the Audio API preferred for new 3D or voice work.
- The Workspace "RolloutState" properties mean behavior differs per place. A skill should not assume, for example, that SignalBehavior is Deferred unless AuthorityMode is Server or it is a new place.

### Gaps
- I found no primary source confirming that the `SignalBehavior` "Default" now resolves to Deferred for all places. The docs only describe the modes.
- Exact default values in new 2026 Studio templates for StreamingEnabled and similar properties were not verified.
- The EditableImage/EditableMesh publishing restrictions (ID-verified/13+ requirement, memory budgets) were not verified in this pass.
- No authoritative source was found for a "Camera changes" item.

## Officially deprecated APIs 2024-2026 beyond the classic list (with replacements)

### Takeaway
Since 2024, Roblox has deprecated:
- many yielding methods, in favour of `…Async` names (Dec 2025 wave);
- the **entire PhysicsService**, in favour of `WorldRoot` collision-group methods (Sept 2026);
- **all reserved-server/legacy teleport methods**, in favour of `TeleportAsync` + `TeleportOptions.ReservedServerId` with a developer GUID (Oct 2026);
- `PathfindingService:FindPathAsync`, in favour of `CreatePath` + `Path:ComputeAsync`;
- `GuiObject.Draggable`, in favour of `UIDragDetector`;
- `HapticService` and `Lighting.Technology`.

### Cited Findings (source for every row: the class page `https://create.roblox.com/docs/reference/engine/classes/<Class>`, from repo yaml `deprecation_message` at commit a23352b, 2026-11-21; dates are first appearance in the docs repo)

**Collision groups.** The `PhysicsService` class is deprecated "in favor of per-world collision group configuration through `WorldRoot`" (2026-09-03). The replacements are:

| Deprecated (PhysicsService) | Replacement (WorldRoot) |
|---|---|
| `RegisterCollisionGroup`, `CreateCollisionGroup` | `WorldRoot:RegisterCollisionGroup` (call it on `workspace`) |
| `CollisionGroupSetCollidable` | `WorldRoot:CollisionGroupSetCollidable` |
| `CollisionGroupsAreCollidable` | `WorldRoot:CollisionGroupsAreCollidable` |
| `GetRegisteredCollisionGroups` | `WorldRoot:GetRegisteredCollisionGroups` |
| `UnregisterCollisionGroup` | `WorldRoot:UnregisterCollisionGroup` |
| `RenameCollisionGroup` | `WorldRoot:RenameCollisionGroup` |
| `IsCollisionGroupRegistered` | `WorldRoot:IsCollisionGroupRegistered` |
| `GetMaxCollisionGroups` | `WorldRoot:GetMaxCollisionGroups` |

`BasePart.CollisionGroupId` is deprecated → use `BasePart.CollisionGroup` (string) — [PhysicsService](https://create.roblox.com/docs/reference/engine/classes/PhysicsService)

**Teleports** (2026-10-29)
- `TeleportService:Teleport`, `TeleportToPlaceInstance`, `TeleportPartyAsync`, `TeleportToSpawnByName`, `TeleportToPrivateServer`, `ReserveServer` and **`ReserveServerAsync`** → `TeleportService:TeleportAsync(placeId, players, teleportOptions)`.
- For reserved servers, "Generate a GUID with HttpService:GenerateGUID() and pass it as `TeleportOptions.ReservedServerId`". `TeleportOptions.ReservedServerAccessCode` and `ShouldReserveServer` are deprecated; VIP servers use `TeleportOptions.VipServerId`.
- Client teleports should signal the server with a RemoteEvent.
- Source: [TeleportService](https://create.roblox.com/docs/reference/engine/classes/TeleportService); [teleport guide](https://create.roblox.com/docs/projects/teleport#migrate-to-secure-teleports)

**Async renames** (most first appeared 2025-12-09)
- `Player:LoadCharacter` → `LoadCharacterAsync`
- `Player:LoadCharacterWithHumanoidDescription` → `LoadCharacterWithHumanoidDescriptionAsync`
- `Player:GetFriendsOnline` → `GetFriendsOnlineAsync`
- `Player:IsFriendsWith` → `IsFriendsWithAsync`
- `Player:IsInGroup` → `IsInGroupAsync`
- `Player:GetRankInGroup` and `GetRoleInGroup` → the `…Async` versions. **The `…Async` versions are themselves deprecated → `GroupService:GetRolesInGroupAsync()`.**
- `Players:CreateHumanoidModelFromDescription` and `CreateHumanoidModelFromUserId` → `…Async`
- `Players:GetHumanoidDescriptionFromUserId` and `FromOutfitId` → `…Async`
- `Humanoid:ApplyDescription` and `ApplyDescriptionReset` → `…Async`; `Humanoid:PlayEmote` → `PlayEmoteAsync`
- `MarketplaceService:GetProductInfo` → `GetProductInfoAsync`; `PlayerOwnsAsset` and `PlayerOwnsBundle` → `…Async`
- `BadgeService:AwardBadge` → `AwardBadgeAsync`; `UserHasBadge` → `UserHasBadgeAsync`; `IsDisabled` → `GetBadgeInfoAsync().IsEnabled`
- `InsertService:GetFreeModels` and `GetFreeDecals` → `…Async`
- `AssetService:SearchAudio` and `GetAssetIdsForPackage` → `…Async`
- `SocialService:PromptLinkSharing` → `PromptLinkSharingAsync`
- `LocalizationService:GetTranslatorForPlayer` → `GetTranslatorForPlayerAsync`
- `AnimationClipProvider:GetAnimationClip` → `GetAnimationClipAsync`
- `Plugin:CreateDockWidgetPluginGui` → `CreateDockWidgetPluginGuiAsync`
- `ContentProvider:Preload` → `PreloadAsync`
- Sources: [Player](https://create.roblox.com/docs/reference/engine/classes/Player), [Players](https://create.roblox.com/docs/reference/engine/classes/Players), [Humanoid](https://create.roblox.com/docs/reference/engine/classes/Humanoid), [BadgeService](https://create.roblox.com/docs/reference/engine/classes/BadgeService)

**Other deprecations**
- **Pathfinding:** `PathfindingService:FindPathAsync` is deprecated → `PathfindingService:CreatePath(agentParams)` + `Path:ComputeAsync(start, finish)` (this predates 2024 in the docs). `ComputeRawPathAsync` and `ComputeSmoothPathAsync` are deprecated. `Path:CheckOcclusionAsync` → `Path.Blocked`; `GetPointCoordinates` → `GetWaypoints` — [PathfindingService](https://create.roblox.com/docs/reference/engine/classes/PathfindingService)
- **Physics and parts:** `BasePart.Velocity` → `AssemblyLinearVelocity`; `RotVelocity` → `AssemblyAngularVelocity`. `Elasticity`, `Friction` and `SpecificGravity` → `CustomPhysicalProperties`. `BreakJoints`/`MakeJoints` are deprecated → destroy joints from `GetJoints()` / use WeldConstraint. `BodyVelocity` → `LinearVelocity`; `BodyGyro` → `AlignOrientation`; `BodyPosition` → `AlignPosition` — [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart)
- **Model:** `GetModelSize` is deprecated → `GetExtentsSize` (**claim TRUE**). `SetPrimaryPartCFrame` and `GetPrimaryPartCFrame` are tagged Deprecated → use `PVInstance:PivotTo`/`GetPivot`. `GetModelCFrame` is deprecated — [Model](https://create.roblox.com/docs/reference/engine/classes/Model)
- **Animation:** `Humanoid:LoadAnimation` → `Animator:LoadAnimation`. `AnimationTrack.KeyframeReached` → `GetMarkerReachedSignal`. `Humanoid:GetPlayingAnimationTracks` and `Humanoid.AnimationPlayed` are tagged deprecated. The `KeyframeSequenceProvider` class is deprecated → `AnimationClipProvider`.
- **Raycasting and queries:** `WorldRoot:FindPartOnRay`, `FindPartOnRayWithIgnoreList` and `FindPartOnRayWithWhitelist` → `WorldRoot:Raycast(origin, direction, RaycastParams)`. `FindPartsInRegion3*` and `IsRegion3Empty*` → `GetPartBoundsInBox` with `OverlapParams` — [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot)
- **Data stores:** `GlobalDataStore:OnUpdate` → MessagingService; `DataStore:RemoveVersionAsync` is deprecated — [GlobalDataStore](https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore)
- **Removed or non-functional:** `OpenCloudService` and `OpenCloudApiV1` (→ HttpService); `TextService:FilterAndTranslateStringAsync` (returns empty); `AssetService:CreatePlaceInPlayerInventoryAsync` (removed); `CustomEvent` (→ BindableEvent).
- **Other:** `StarterGui.ResetPlayerGuiOnSpawn` → `LayerCollector.ResetOnSpawn`. `UserInputService.ModalEnabled` → `GuiService.TouchControlsEnabled`. `UserInputService:GetUserCFrame`, `UserCFrameChanged` and `VREnabled` → `VRService`. `Attachment.WorldRotation` → `WorldOrientation`. `CaptureService.CaptureSaved` → `UserCaptureSaved`. `GenerationService:GenerateMeshAsync` is "scheduled for future deprecation" → `GenerateModelAsync`.
- **Globals:** `wait`, `spawn` and `delay` → `task.*`; `getfenv`/`setfenv`, `ypcall`, `elapsedTime`, `stats`, `version` and `printidentity` are deprecated — [LuaGlobals](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals); [RobloxGlobals](https://create.roblox.com/docs/reference/engine/globals/RobloxGlobals)
- **Hint/Message:** both are deprecated → TextLabel. All camelCase aliases (`Instance:clone`, `Players.localPlayer`, `Instance:remove`, etc.) are deprecated.

**Data store guidance** (latest-features `data-store-player-saves`, stable 2026-07-15)
- "one key per player, an in-memory session copy, UpdateAsync writes, pcall retries with backoff, and saves on leave and shutdown". It replaces "SetAsync for read-modify-write saves", "Saving only on PlayerRemoving" and "DataStore2 or one key per stat".
- APIs to use: `DataStoreService:GetRequestBudgetForRequestType()`, `DataStoreGetOptions.UseCache` and `DataStore:GetVersionAtTimeAsync()`.
- RTBF (beta, 2026-04-10): key names should look like `"User_" .. player.UserId`, and `{player.UserId}` should be passed as SetAsync's userIds argument or returned as the second value from the UpdateAsync callback.
- Source: [latest-features.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/latest-features/latest-features.json); [best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)

### Inferences
- The highest-risk outdated patterns a model might still emit are:
  - `PhysicsService:RegisterCollisionGroup`/`CollisionGroupSetCollidable` (now deprecated; use `workspace:` methods);
  - `TeleportService:ReserveServer` / `TeleportToPrivateServer` (deprecated; generate a GUID);
  - `Player:LoadCharacter()` (use `LoadCharacterAsync`);
  - `MarketplaceService:GetProductInfo` (use `GetProductInfoAsync`);
  - `PathfindingService:FindPathAsync`;
  - `GuiObject.Draggable`;
  - `Player:IsInGroup`/`GetRankInGroup` (use `GroupService:GetRolesInGroupAsync`);
  - `InputAction:Fire`.
- Deprecated APIs generally still run; Roblox rarely removes them. The exceptions are TextChatService, where legacy chat is "gone", and a few no-op methods.

### Gaps
- The exact DevForum announcement dates for the Dec 2025 Async-rename wave, the Sept 2026 PhysicsService deprecation and the Oct 2026 teleport deprecation were not fetched. Dates given are docs-repo dates.

## Verification of specific claims

### Takeaway
All the listed claims check out except "Knit author recommends against new projects". That one is effectively true, but the actual wording is that Knit is archived and "will no longer receive updates" (archived July 2024). `table.sort` with `<=` errors only sometimes.

### Cited Findings
- `Enum.ScreenInsets.DeviceSafeInsets` and `CoreUISafeInsets`: **TRUE**. The enum is {None, DeviceSafeInsets, CoreUISafeInsets, TopbarSafeInsets} — [ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets)
- `math.clamp` errors when min > max: **TRUE**, with "max must be greater than or equal to min" — [lmathlib.cpp](https://github.com/luau-lang/luau/blob/master/VM/src/lmathlib.cpp)
- `table.sort` with a `<=` comparator errors "invalid order function for sorting": **TRUE but not deterministic.** It errors when the inconsistent comparator makes the partition run past the bounds, which is typical with equal elements; otherwise it may mis-sort silently — [ltablib.cpp](https://github.com/luau-lang/luau/blob/master/VM/src/ltablib.cpp); [table docs](https://create.roblox.com/docs/reference/engine/libraries/table)
- DataStore value limit is 4 MB: **TRUE**. The limit is "4,194,304 per key" (characters of serialized data), and best practices say "4 MB object size limit" — [error codes and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- UnreliableRemoteEvent payload limit: **TRUE, ~1000 bytes**. "Events with payloads larger than 1000 bytes are dropped" — [UnreliableRemoteEvent](https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent)
- `Font.fromName(name, weight?, style?)`: **TRUE**, e.g. "FredokaOne" — [Font](https://create.roblox.com/docs/reference/engine/datatypes/Font)
- `GuiObject.Interactable` exists: **TRUE** — [GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject)
- Knit: **archived and unmaintained.** The README says "No Longer Maintained… Knit has been archived and will no longer receive updates". Last commit: 2024-07-31 ("archive" PR #247). ARCHIVAL.md explains that Knit "cannot fully benefit from types, and thus does not have good intellisense". It says ModuleScripts cover the service role, and a shallow wrapper over RemoteEvents plus runtime type checks covers networking. It recommends no specific replacement library — [Knit README](https://github.com/Sleitnick/Knit); [ARCHIVAL.md](https://github.com/Sleitnick/Knit/blob/main/ARCHIVAL.md)
- ProfileStore API (MadStudioRoblox, wally version 1.0.3): **TRUE** for every listed name.
  - `ProfileStore.New(store_name, template?)`
  - `ProfileStore:StartSessionAsync(profile_key, params?) -> Profile | nil`
  - `profile:EndSession()`
  - `profile.OnSessionEnd` (Signal)
  - `profile:Reconcile()`
  - `profile:AddUserId(user_id)` and `RemoveUserId`
  - Also: `profile.Data`, `:IsActive()`, `:Save()`, `:SetAsync()`, `:MessageHandler()`, `OnSave`, `OnLastSave(reason)`, `OnAfterSave`, `ProfileStore:GetAsync`, `:MessageAsync`, `:VersionQuery`, `:RemoveAsync`, `.Mock`, `ProfileStore.OnError`, `OnOverwrite`, `IsClosing` and `DataStoreState`.
  - Source: [ProfileStore api.md](https://github.com/MadStudioRoblox/ProfileStore/blob/main/docs/api.md)
- `Model:GetModelSize` is deprecated → `GetExtentsSize`: **TRUE** — [Model](https://create.roblox.com/docs/reference/engine/classes/Model)

### Inferences
- ProfileStore's `profile:AddUserId(player.UserId)` lines up with Roblox's RTBF key and userIds guidance (2026). The `User_{UserId}`-style key pattern is recommended.

### Gaps
- I did not find whether Sleitnick explicitly endorses a successor framework. ARCHIVAL.md deliberately names none.
