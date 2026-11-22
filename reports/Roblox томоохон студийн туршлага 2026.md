## Товч дүгнэлт (Монгол хэлээр)

2026 оны байдлаар Roblox-ийн томоохон студиуд серверийг тоглоомын төлөвийн цорын ганц эх сурвалж болгодог. Клиентийг зөвхөн оролт өгөгч, дүрслэгч гэж үздэг. 2026 оны 7-р сарын 9-нд бүрэн гарсан **Server Authority** нь speed hack, fly hack зэрэг хөдөлгөөний хуурлыг хаадаг. Гэхдээ RemoteEvent, эдийн засаг, гэмтлийн шалгалтыг хөгжүүлэгч өөрөө хийх шаардлагатай хэвээр.

cluau skill одоо хэд хэдэн хуучирсан эсвэл буруу дүрэм агуулж байна:
- PhysicsService-ийн collision group API-г "шинэ" гэж заадаг. Гэтэл энэ үйлчилгээ бүхэлдээ 2026-09-нд deprecated болж, `workspace:RegisterCollisionGroup` руу шилжсэн.
- `TeleportOptions.ShouldReserveServer`-ийг зөвлөдөг. Энэ нь 2026-10-д deprecated болсон бөгөөд одоо `HttpService:GenerateGUID()` + `ReservedServerId` ашиглана.
- 2025-12 сарын "…Async" нэрийн өөрчлөлтийг мэдэхгүй (`LoadCharacterAsync`, `GetProductInfoAsync`, `IsFriendsWithAsync`, `GroupService:GetRolesInGroupAsync`).
- Linter нь Luau-д бүрэн хүчинтэй `math.pow`, `unpack`, `table.maxn`-ийг алдаа гэж буруу тэмдэглэдэг.

Хамгийн чухал засварууд дарааллаараа:
1. Deprecated хүснэгт ба linter-ийг шинэчлэх.
2. Server Authority, Input Action System, TextChatService, 2026 оны DataStore/мөнгө олох дүрмийг анхдагч мэдлэг болгох.
3. Тоглоомын төрөл бүрийн архитектурын playbook нэмэх (simulator, tycoon, tower defense, shooter, horror, farming, steal, fishing, dress-up).
4. 3D модель, asset pipeline, polish, QA, launch-ийн reference нэмэх.
5. ro-engineer-аас дараах санааг авах: нотолгооны шударга байдал, ID-тай sharp-edges каталог, asset-compliance gate, пропорциональ байдал.

Доорх P0/P1/P2 жагсаалт нь хэрэгжүүлэх дарааллыг өгнө.

---

# Rebuild cluau around Roblox's 2026 engine

Large Roblox studios in 2026 work from one principle. **The server owns every outcome. The client is only an input device and a display.** Roblox has now built that principle into the engine. **Server Authority** (stable 2026-07-09) gives native prediction and rollback, but it requires `Workspace.AuthorityMode = Server`, the Input Action System, deferred signals, fixed simulation and streaming. Around it, the platform changed a lot between 2024 and 2026:
- the whole `PhysicsService` collision-group API moved to `WorldRoot` (Sept 2026);
- every reserved-server teleport API was deprecated in favor of a developer GUID (Oct 2026);
- a December 2025 wave renamed dozens of yielding methods to `…Async`;
- legacy chat is gone, and DataStore budgets and storage were rewritten (July 2026);
- monetization gained Roblox Plus, external developer-product sales with ProcessReceipt audits, and strict paid-random-item rules;
- age-based accounts now gate who can even see a game.

The cluau skill is broadly well designed. It already has server-authoritative remotes, session-locked data, anti-slop UI and a linter. But it encodes several now-wrong facts and some false positives, and it lacks four things: genre-specific architecture, any 3D asset or polish guidance, a Server Authority path, and ro-engineer's evidence discipline. The fix is a prioritized set of edits, listed at the end:
- correct the deprecated table and the linter (P0);
- add six new reference files and update five existing ones (P1);
- refresh the templates and toolchain (P2).

Two caveats about the evidence. Most API facts come from Roblox's own `creator-docs` repository at commit `a23352b` (2026-11-21), which is the source of create.roblox.com, so they are high-confidence. DevForum material was reachable only through search snippets, so it is weaker.

## Twelve 2024–2026 engine changes cluau gets wrong or misses

### The deprecation table has three outright errors

The most damaging problem is that cluau *recommends* APIs that are now deprecated. SKILL.md §3 and `deprecated-apis.md` tell the model to replace `CreateCollisionGroup` with `PhysicsService:RegisterCollisionGroup`. But the entire **PhysicsService class is deprecated "in favor of per-world collision group configuration through `WorldRoot`"** (first in docs 2026-09-03). Every method has a `workspace:` twin: `RegisterCollisionGroup`, `CollisionGroupSetCollidable`, `CollisionGroupsAreCollidable`, `GetRegisteredCollisionGroups`, `UnregisterCollisionGroup`, `RenameCollisionGroup`, `IsCollisionGroupRegistered` and `GetMaxCollisionGroups`. `BasePart.CollisionGroupId` gives way to the string `CollisionGroup` ([PhysicsService](https://create.roblox.com/docs/reference/engine/classes/PhysicsService)).

The teleport row has the same problem. `deprecated-apis.md` advises `TeleportOptions.ShouldReserveServer = true`, and `architecture.md` advises `ReserveServer` for matchmaking. As of 2026-10-29, **`ReserveServer`, `ReserveServerAsync`, `TeleportOptions.ReservedServerAccessCode` and `ShouldReserveServer` are all deprecated**, alongside `Teleport`, `TeleportToPlaceInstance`, `TeleportPartyAsync`, `TeleportToSpawnByName` and `TeleportToPrivateServer`. The replacement is server-side `TeleportAsync(placeId, players, options)` with a GUID from `HttpService:GenerateGUID()` in `TeleportOptions.ReservedServerId` ([TeleportService](https://create.roblox.com/docs/reference/engine/classes/TeleportService); [migration guide](https://create.roblox.com/docs/projects/teleport#migrate-to-secure-teleports)).

The third error runs the other way: cluau "corrects" valid code. The linter flags `math.pow` with the message "does not exist in Luau", flags bare `unpack`, and lists `table.maxn` among "removed Lua 5.0" functions. **All three are valid Luau.** Luau's compatibility docs list `math.pow`, and say `unpack` and `table.unpack` are "equivalent" ([luau-lang/site library.md](https://github.com/luau-lang/site/blob/main/src/content/docs/reference/library.md)). `table.maxn` is still a documented member of the Roblox `table` library; only `getn`, `foreach` and `foreachi` are deprecated ([table](https://create.roblox.com/docs/reference/engine/libraries/table); [RFC](https://rfcs.luau.org/deprecate-table-getn-foreach.html)). False positives like these train users to ignore the linter, and they push the model to rewrite working code.

### The December 2025 Async wave and other quiet renames

Most yielding methods got `…Async` names on 2025-12-09:
- `Player:LoadCharacter`, `LoadCharacterWithHumanoidDescription`, `GetFriendsOnline`, `IsFriendsWith` and `IsInGroup`;
- `Players:CreateHumanoidModelFromDescription/FromUserId` and `GetHumanoidDescriptionFromUserId/FromOutfitId`;
- `Humanoid:ApplyDescription/ApplyDescriptionReset/PlayEmote`;
- `MarketplaceService:GetProductInfo`, `PlayerOwnsAsset` and `PlayerOwnsBundle`;
- `BadgeService:AwardBadge`;
- `InsertService:GetFreeModels`, `ContentProvider:Preload`, and several others ([Player](https://create.roblox.com/docs/reference/engine/classes/Player); [Players](https://create.roblox.com/docs/reference/engine/classes/Players); [BadgeService](https://create.roblox.com/docs/reference/engine/classes/BadgeService)).

One rename trap matters for admin code. **`GetRankInGroupAsync` and `GetRoleInGroupAsync` are themselves deprecated** in favor of `GroupService:GetRolesInGroupAsync()`. cluau's `networking-security.md` currently recommends `player:GetRankInGroup(groupId)` for admin checks, and `game-design.md` recommends `player:IsFriendsWith`.

The same docs snapshot deprecates many more APIs:
- `PathfindingService:FindPathAsync` → `CreatePath` + `Path:ComputeAsync`;
- `GuiObject.Draggable/DragBegin/DragStopped` → `UIDragDetector`;
- `GuiObject:TweenPosition/TweenSize/TweenSizeAndPosition` → TweenService;
- `Lighting.Technology` → `Lighting.LightingStyle` + `PrioritizeLightingQuality`;
- the whole `HapticService` → `HapticEffect`;
- `GuiService:IsTenFootInterface` → `GuiService.ViewportDisplaySize`;
- `Player.MembershipType` → `HasRobloxSubscription`, and `PromptPremiumPurchase` → `PromptRobloxSubscriptionPurchase`;
- `AnalyticsService:FireEvent`;
- `CollectionService:GetCollection/ItemAdded/ItemRemoved`;
- `AnimationTrack.KeyframeReached` → `GetMarkerReachedSignal`;
- `Sound.Pitch` → `PlaybackSpeed`, and `Sound.MaxDistance/MinDistance/EmitterSize` → `RollOffMaxDistance/RollOffMinDistance`;
- `TextFilterResult:GetChatForUserAsync`, which now returns an empty string;
- `InputAction:Fire()` → `InputBinding:Fire()` on a Scriptable binding (2026-06-15)

([GuiObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject); [Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting); [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService); [InputAction](https://create.roblox.com/docs/reference/engine/classes/InputAction)). The one platform-level *removal* is chat. **Legacy Chat is "gone" (2026-10-21), TextChatService is mandatory, and "by May 2027 scripts can't read message text."** `Player.Chatted` command parsing must move to `TextChatCommand`, and Roblox warns that games letting players converse outside TextChatService may be taken down ([latest-features.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/latest-features/latest-features.json); [chat guidelines](https://create.roblox.com/docs/chat/guidelines)).

### New current-path systems the skill should default to

Roblox publishes a machine-readable "latest features" feed aimed at AI agents. It names the current replacements, and cluau should treat it as canonical:
- **Input Action System** (stable 2026-06-11). Default player scripts use it, and "ContextActionService is being sunset". CAS has no deprecation tag yet.
- **Character Controller Library** (stable 2026-04-08), "recommended for all new games" via `require("@rbx/AvatarAbilities")`.
- **Audio API** (`AudioPlayer` → `Wire` → `AudioEmitter`/`AudioDeviceOutput`). `Sound` is not deprecated.
- **AnimationConstraint** joints via `StarterPlayer.AvatarJointUpgrade`.
- **ConfigService** (stable 2025-11-06) for server-side live config.
- **Script Sync** (`InstanceFileSyncService`, stable 2026-06-17).
- **SLIM** model LOD (beta).
- [latest-features.json](https://github.com/Roblox/creator-docs/blob/main/content/en-us/latest-features/latest-features.json)

Equally important is what is **not** deprecated. Over-zealous rewriting is a known AI failure mode, so the skill needs to know these:
- `RunService.Heartbeat`, `RenderStepped` and `Stepped` carry no deprecation tag.
- `CollectionService:AddTag/GetTagged` remain valid next to `Instance:AddTag/HasTag`.
- `SetNetworkOwner` is still the right tool outside Server Authority.
- [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService); [Instance](https://create.roblox.com/docs/reference/engine/classes/Instance)

On the language side, these are documented and safe to emit:
- `math.lerp`, `math.map`, `math.isnan/isinf/isfinite`;
- the `vector` library;
- `buffer.readbits/writebits` and the 2026 `buffer.read/writevectorf32x2/x3`;
- **`const` bindings** (Roblox docs section added 2026-08-10);
- require-by-string with `./`, `../`, `@self/` and `@game/`, which is non-blocking (it does not wait for the module);
- `@native` and `@[deprecated{...}]` attributes;
- user-defined type functions and `read`/`write` property modifiers.

Sources: [math](https://create.roblox.com/docs/reference/engine/libraries/math), [const](https://create.roblox.com/docs/luau/variables#const-variables), [require](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#require).

The model must **not** emit:
- `class` syntax;
- `if local` / `while local`;
- `export x = …`;
- any `integer.*` function. Luau formally rejected a 64-bit integer type in RFC #269 (Nov 2026) ([rfcs](https://github.com/luau-lang/rfcs)).

Two more facts belong in the skill:
- **The New Type Solver became the default for nonstrict and nocheck scripts in November 2025.** Strict-mode places had to opt in via `Workspace.UseNewLuauTypeSolver`, so `--!strict` code may still be checked by the old solver ([Luau page](https://create.roblox.com/docs/learn/more/luau)).
- `Knit` has been archived since July 2024 and "will no longer receive updates" ([Knit ARCHIVAL.md](https://github.com/Sleitnick/Knit/blob/main/ARCHIVAL.md)). cluau's claim that "the author no longer recommends it" is directionally right, but the archive date is the precise fact.

One SKILL.md claim is unsupported: "`workspace.SignalBehavior` is `Deferred` by default." No primary source confirms that the Default mode resolves to Deferred in every place. Deferred is guaranteed only when `AuthorityMode = Server`, which forces it ([server authority](https://create.roblox.com/docs/projects/server-authority)). The safe rule is to write handlers that are correct under both Immediate and Deferred.

## Server Authority hardens movement, not remotes

### What the engine now does and costs

Server Authority makes the server "the single source of truth for the entire game state", and "clients are only trusted to report their own inputs". It prevents "entire classes of cheating like flyhacks or speedhacks" ([server authority model](https://create.roblox.com/docs/projects/server-authority)). Setting `Workspace.AuthorityMode = Server` in Studio is the only switch, and scripts cannot set it. It automatically sets NextGenerationReplication, PlayerScriptsUseInputActionSystem, SignalBehavior = Deferred, UseFixedSimulation and StreamingEnabled. Code that uses it has to follow these rules:
- Gameplay code lives in a ReplicatedStorage ModuleScript, required by both a Script and a LocalScript, inside `RunService:BindToSimulation(fn, frequency, priority)`.
- Simulation state goes in attributes written only inside bound functions.
- Use `time()`, not `tick()`/`os.clock()`/`os.time()`, because `time()` is synchronized and rewinds on resimulation.
- Query `Animator:GetTrackByAnimationId()` instead of caching AnimationTracks.
- Spawn predicted objects with deterministic GUIDs ("instance stitching").

The reference game is Roblox's Soccer template ([techniques](https://create.roblox.com/docs/projects/server-authority/techniques)). MrChickenRocket wrote Chickynoid and maintains a reference written against the release. It adds that the default simulation frequency is 30 Hz, so `Enum.StepFrequency.Hz60` must be passed explicitly. It also notes:
- predicted attributes must be among an instance's first 64, with names and values capped at 50 characters;
- an Animator can play at most 8 tracks;
- **"RemoteEvents are not part of the simulation and are not rolled back"**, so inputs must be "range-validate[d] on the server exactly as you would a RemoteEvent"
([reference](https://github.com/MrChickenRocket/Server-Authority-Tutorial-Cakeman/blob/main/docs/reference/server-authority.md)).

There are costs. A Roblox deep-dive warns that resimulation can reach **6.25× the simulation load at 100 ms latency** ([tech deep dive](https://devforum.roblox.com/t/server-authority-tech-deep-dive-engineering-insights/4624565)). Tool support is also disputed. The official docs say Tools are "not fully supported yet", because `EquipTool` lacks simulation access, while the community reference says tools work. The skill should present Server Authority as the 2026 default for **competitive movement and physics games** (shooters, fighting, racing, sports), as optional for casual obbies and simulators, and should always warn that it needs a Studio property change and does not validate economy, inventory or remotes.

### The validation layer every studio still writes

For everything outside the simulation, the threat model is unchanged. Exploiters can:
- decompile client code and run saveinstance;
- fire any remote with any arguments at any rate;
- spoof `Touched` through parts they own;
- fire ProximityPrompts and ClickDetectors out of range.

Roblox staff say a server-side range check exists for prompts, but developers dispute how reliable it is ([prompt thread](https://devforum.roblox.com/t/is-there-any-way-to-protect-proximity-prompts/1274877); [Touched spoof](https://devforum.roblox.com/t/touched-call-a-client-can-use-an-exploit-to-spoof-the-engine-to-think-that-a-part-is-being-touched-on-server-even-if-the-person-is-nowhere-near-it/3448084)). Roblox's own rule is that "every piece of data sent from a client must be validated by the server before it's used" ([client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary)). Its "defensive design" page adds that mechanics should make cheating impossible or worthless:
- sequential server-validated checkpoints;
- server-computed damage;
- server cooldowns plus inventory-state checks on every transaction;
- reduced points for killing freshly spawned players
([defensive design](https://create.roblox.com/docs/scripting/security/defensive-design)).

cluau's six-step handler already covers type, rate, whitelist, state and cost. It is missing four studio-grade details:
1. **No yields between check and mutate.** A `task.wait`, DataStore call or Marketplace call between validation and the state write opens dupe races. Use a per-player or per-trade busy lock.
2. **Do your own distance check inside every `ProximityPrompt.Triggered`, `ClickDetector.MouseClick` and `Touched` handler.** Use spatial queries (`GetPartsInPart`/`GetPartBoundsInBox`) for authoritative triggers.
3. **Bounds-check every `buffer.read*`** when decoding client bytes, cap length prefixes, and reject NaN/inf after decoding. A fork author reports that Blink 0.18 once parsed hostile buffers without bounds ([BlinkBlox](https://devforum.roblox.com/t/blinkblox-buffer-networking-that-checks-everything-a-client-sends/4898948)), and Zap has "no rate limiting at all" ([networker thread](https://devforum.roblox.com/t/what-networker-should-i-use/4889485)).
4. **Shooter hit validation follows Roblox's Laser Tag curriculum.** The client raycasts, and the server re-derives the spread, checks the angle error and the shooter-origin and target-hit distances against tolerances, and re-raycasts for line of sight so local wall deletion is caught ([detect hits](https://create.roblox.com/docs/tutorials/curriculums/gameplay-scripting/detect-hits)). Competitive games add capped-window rewind buffers ([RollbackHitbox](https://devforum.roblox.com/t/rollbackhitbox-server-authoritative-lag-compensation-for-roblox-shooters-open-source/4553295)).

Enforcement has matured as well:
- **`Players:BanAsync`** (June 2024) takes `UserIds`, `ApplyToUniverse`, `Duration` (-1 means permanent), `DisplayReason`, `PrivateReason` and `ExcludeAltAccounts`. It is universe-wide and persistent, unlike `Kick`. Developers report weak alt detection, with one estimate around 15% ([Ban API](https://devforum.roblox.com/t/introducing-the-ban-api-and-alt-account-detection/3039740); [alt detection](https://devforum.roblox.com/t/anyone-find-the-banasync-alt-detection-very-lacking/4621753)).
- The studio pattern is detect, then log the evidence in PrivateReason, then queue a delayed ban wave. Honeypot remotes only log, so attackers cannot learn which remote is the trap. This practice is common but has no primary source.
- Since May 2025 Roblox acts against accounts on modified clients "up to and including account termination" ([modified clients](https://devforum.roblox.com/t/an-update-on-automated-action-against-modified-clients/3640609)).
- Secrets belong in the **Secrets Store** (`HttpService:GetSecret`). It is server-only, usable only in URL and headers, works only on live or collaborative servers, and can be domain-restricted ([secrets](https://create.roblox.com/docs/cloud-services/secrets)).
- Backdoor scanning should grep for numeric `require(`, `getfenv`/`setfenv`, `loadstring`, `InsertService:LoadAsset`, `LinkedSource` and obfuscation. These are exactly the Creator Store's restricted practices ([Creator Store](https://create.roblox.com/docs/production/creator-store)).

## Lag prevention runs on hard budgets

Pro teams budget bandwidth, entities and draw calls against published numbers:
- A Roblox staff post says physics updates **start throttling above about 40 KB/s per client**, and the receive counter caps at 50 KB/s.
- Each moving physics assembly costs about 0.4–0.9 KB/s, which gives a safe budget of roughly **40–60 moving replicated assemblies**.
- An average view should hold about **100 draw calls and about 150k triangles** ([staff optimization post](https://devforum.roblox.com/t/real-world-building-and-scripting-optimization-for-roblox/3127146)).
- Roblox's design-for-performance page gives the outer ceiling for a baseline device: "below 1,000 draw calls and 1,000,000 triangles" ([design for performance](https://create.roblox.com/docs/performance-optimization/design)).
- Each RemoteEvent fire carries roughly 9 bytes of overhead ([ByteNet thread](https://devforum.roblox.com/t/bytenet-advanced-networking-library-w-buffer-serialization-strict-luau-absurd-optimization-and-rbxts-support-043/2733365?page=4)).
- UnreliableRemoteEvents drop payloads **larger than 1000 bytes**, according to the 2026-11-21 docs repo. Older snippets say 900, so stay well under either figure ([UnreliableRemoteEvent](https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent)).

Simple arithmetic makes these concrete. Fifty entities each fired at 60 Hz cost about 27 KB/s in overhead alone, before any payload. That is why studios batch each tick into one `buffer`, quantize values (orientation as 3×uint8 "cut network usage in half"), and send non-critical state at 10–20 Hz ([custom NPC replication](https://devforum.roblox.com/t/performance-tips-network-bandwidth-client-framerate-etc-for-custom-npc-replication/4202236)). A conservative skill rule is **≤20–30 KB/s of custom traffic per client**.

On the server, Humanoids are "baseline heavy". Above roughly 30 moving NPCs, studios keep enemies as plain server tables and let clients build and move the models: tower-defense hordes, monster swarms ([hundreds of humanoids](https://devforum.roblox.com/t/how-to-optimise-hundreds-of-humanoids/1760085)). Moving 1,000 assemblies took about 6 ms per frame with `BulkMoveTo` before tuning. Animating `Transform` on bones or Motor6Ds brought it to about 1 ms ([1000 assemblies](https://devforum.roblox.com/t/struggling-to-efficiently-move-1000-assemblies/4203225)). `--!native` speeds up only numeric pure-Luau code, not engine calls ([native codegen](https://create.roblox.com/docs/luau/native-code-gen)). Parallel Luau pays off only when work is sharded across multiple Actors, with one desynchronize per batch and no DataModel writes in the parallel phase ([multithreading](https://create.roblox.com/docs/scripting/multithreading)).

On the client, these are the costs to watch:
- **Draw calls.** Every unique asset is a draw call. Identical MeshContent with identical SurfaceAppearance instances into one, while each ParticleEmitter is its own draw call ([improve performance](https://create.roblox.com/docs/performance-optimization/improve)).
- **Memory on low-end phones.** About 65% of a typical game's players are on Android, and about 60% of those devices have 2–4 GB of RAM ([test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)).
- **UI relayout.** Tweening sizes inside layouts triggers full relayouts ([UpdateUILayouts](https://devforum.roblox.com/t/updateuilayouts-gives-huge-performance-impact/4064226)).

Leaks are still dominated by undisconnected connections and per-player tables that are never cleared ([connection leaks](https://devforum.roblox.com/t/connecting-events-without-disconnecting-them-is-probably-the-most-common-memory-leak-nobody-talks-about/4525277)). `performance.md` has the right instincts, but it holds almost none of these numbers. It describes mobile memory only as "low gigabytes".

## Data, live-ops, monetization and policy changed their rules

### DataStores after July 2026

On **July 29, 2026**, Roblox unified game and Open Cloud request budgets into per-experience budgets and raised storage to **500 MB + 1 MB × lifetime users**, counted on the compressed latest version of each key ([limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits); [announcement](https://devforum.roblox.com/t/unifying-data-stores-open-cloud-and-game-apis-and-increasing-storage-limits/4739240)). The new budget categories are StandardRead, StandardWrite, StandardList and StandardRemove, plus Ordered* versions. Experience-level reads are `300 + CCU×40` and writes are `300 + CCU×20`. **UpdateAsync draws on both the read and the write budget**, and Open Cloud scripts now compete with live servers for the same budget. The old "60 + players × 10" GetAsync formula is obsolete, so the skill should tell the model to read `GetRequestBudgetForRequestType` rather than hard-code a number.

Other operational facts matter for correctness:
- GetAsync caches for **4 seconds**. Roblox recommends `DataStoreGetOptions.UseCache = false` for the verification read after a failed write, before deciding whether to retry or refund.
- Versions are created on the first write per key per UTC hour and expire 30 days after being overwritten.
- The Open Cloud snapshot API should run before "any game update that changes your data storage logic" ([versioning](https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching)).

The 2026 best-practice page names the target shape:
- one key per player, such as `User_{UserId}`, with static patterns so automated right-to-be-forgotten (RTBF) templates can delete it;
- writes through UpdateAsync;
- in-order retries per key with backoff, treating a failed write as having an unknown outcome;
- an autosave interval (the sample uses 180 s) shorter than the lock expiry.

It also states that **DataStore2 is legacy** ([best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices); [RTBF](https://create.roblox.com/docs/cloud-services/data-stores/right-to-be-forgotten)). **ProfileStore v1.0.3** is the maintained default, and ProfileService's README says it is "no longer supported". Some ProfileStore details the skill needs:
- `MessageAsync` + `MessageHandler` replace GlobalUpdates.
- `ProfileStore.Mock` serves tests.
- Autosave runs every 300 s, and a conflicting session is stolen after 40 s.
- Its developer-product guide yields ProcessReceipt until the PurchaseId appears in `Profile.LastSavedData`. This closes the crash-before-save gap ([ProfileStore.luau](https://github.com/MadStudioRoblox/ProfileStore/blob/main/ProfileStore.luau); [devproducts doc](https://github.com/MadStudioRoblox/ProfileStore/tree/main/docs/devproducts)).

A caution for cluau's templates. The current `DataService.luau` uses `Player_{UserId}`. Changing an *existing* game's key pattern orphans every save. So the skill should recommend `User_{UserId}` plus `userIds` metadata for **new** games only, and explicitly forbid silent key migrations.

### Monetization and policy in 2026

ProcessReceipt is now an audited, revenue-critical contract. **Roblox sells listed developer products outside the game**: on the homepage, in search, and after a Robux purchase. Roblox "checks your ProcessReceipt implementation on an ongoing basis", and flagged products disappear from those external surfaces ([developer products](https://create.roblox.com/docs/production/monetization/developer-products)). The callback also fires on join. It has no timeout, and the same purchase can run on two servers at once. If no callback is set, receipts are auto-acknowledged and cannot be recovered ([ProcessReceipt](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#ProcessReceipt)). cluau's idempotent PurchaseId pattern is correct. It should add three rules:
- never grant items on `PromptProductPurchaseFinished`;
- block purchases when the profile failed to load;
- read prices dynamically. Hard-coded prices block **price optimization**, which normally needs at least 60k transactions in 30 days ([price optimization](https://create.roblox.com/docs/production/monetization/price-optimization)).

The other 2026 rules the skill must carry:
- **Roblox Plus** launched on April 30, 2026 at $4.99/month and replaced new Premium sign-ups. Roblox funds the subscriber discount, which raises the creator's share to 78% at the 10% discount and 88% at the 20% discount. Sign-ups through `PromptRobloxSubscriptionPurchase` earn up to 750 Robux per subscriber ([Roblox Plus](https://create.roblox.com/docs/production/monetization/roblox-plus)).
- **Rewarded video ads must grant a developer product through ProcessReceipt.** Robux cannot be the reward ([rewarded ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)).
- **Paid random items** need disclosed odds that sum to exactly 100%, shown in an "Info"/"Details" pop-up (a bare (i) icon is not enough). The odds must update per user for once-only outcomes and with boosters.
- When `ArePaidRandomItemsRestricted` is true, the game must take a compliant path: a free earnable path, a disclosed sequence, a direct sale at expected value, hiding the item, or blocking the purchase ([paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)).
- When `IsPaidItemTradingAllowed` is false, trading of paid items must be blocked. Gifting and trading should be gated with `GetUsersPriceLevelsAsync`, because regional prices fall between 30% and 100% of the default ([regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing)).
- `AllowedExternalLinkReferences`, which cluau still lists, is legacy and always empty ([PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService)).

Policy now shapes architecture:
- **Chat requires an age check** (global since January 2026).
- **Roblox Kids (5–8) and Select (9–15)** launched globally in June 2026.
- Games without content ratings have restricted playability.
- Reaching players under 16 requires a Minimal, Mild or Moderate rating, a verified creator with 2FA, and an evaluation of 100 unique plays by engaged age-checked users within 60 days ([Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select); [content ratings](https://create.roblox.com/docs/production/promotion/content-ratings)).

The design consequence is that **core gameplay must never depend on chat**. The skill should also prompt users to fill in the questionnaire before launch.

AnalyticsService needs a wrapper because of its caps:
- 120 + 20 × CCU calls per minute;
- 10 economy resource types and 10 funnels;
- 100 custom event names and 3 custom fields.

Events should be logged only after the action succeeds ([event types](https://create.roblox.com/docs/production/analytics/event-types)).

### Live-ops patterns of 2025–2026 hits

Top games run a **fixed weekly update slot**, preceded by a one-hour "Admin Abuse" live event in which developers trigger server-wide weather, spawns and shop changes ([Grow a Garden admin abuse](https://www.sportskeeda.com/roblox-news/when-admin-abuse-start-grow-garden); [Steal a Brainrot](https://www.sportskeeda.com/roblox-news/steal-brainrot-admin-abuse-potential-start-times-prepare)). They also use **globally synchronized restocks**, reported at about 5/5/30 minutes in Grow a Garden 2 ([restock timing](https://allthings.how/grow-a-garden-2-stock-predictor-how-restock-timing-works/)).

GameAnalytics' 2025 report gives realistic retention targets: **median D1 10.3%, D7 1.6%, D30 0.5%**, and top 1% D1 22.2%. It found that return frequency, not session length, drove the biggest 2025 gains ([GameAnalytics 2025](https://www.gameanalytics.com/reports/2025-roblox-report)). In architecture terms, live-ops needs:
- data-driven event configs, using ConfigService for live values;
- a MessagingService broadcast plus a MemoryStore flag, so servers that start mid-event join it. MessagingService is best-effort and capped at 1 KB per message, so durable grants need a fallback ([MessagingService](https://create.roblox.com/docs/reference/engine/classes/MessagingService));
- restocks derived deterministically from `os.time()`, so no cross-server messaging is needed;
- timestamp-based growth and offline income that reward coming back.

## UI is now a styled, input-abstracted system

The engine now supports a CSS-like workflow:
- **UI Styling** (StyleSheet/StyleRule/StyleLink/StyleDerive) is fully released;
- **StyleQuery** arrived in May 2026;
- **Styling Transitions** reached full release in July 2026 with TweenInfo support ([UI Styling release](https://devforum.roblox.com/t/full-release-ui-styling-is-officially-released/4275082); [Styling Transitions](https://devforum.roblox.com/t/full-release-styling-transitions/4646870)).

So the cluau `Theme.luau` token approach is now expressible natively, with StyleDerive for theme switching. Flex layouts have limits. They add cost and should stay under 1,000 items. AutomaticSize with UIFlexItem is unsupported with a non-zero AnchorPoint, scale-sized items, scaled padding or TextScaled ([flex release](https://devforum.roblox.com/t/flex-features-for-uilistlayout-client-release/3096190)). **CanvasGroup** uses texture memory capped by QualityLevel. It renders blank over the cap, re-textures on every resize, keeps its memory while hidden, and has rendered black on some mobile devices ([CanvasGroup](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup)). Use it only for short, fixed-size fades, and destroy it when done.

cluau's safe-area advice needs a fix. The skill sets `DeviceSafeInsets` for the HUD in both SKILL.md §6 and `Components.screen()`. The enum has four values: None, DeviceSafeInsets, CoreUISafeInsets and TopbarSafeInsets. **CoreUISafeInsets keeps content clear of Roblox's core buttons as well as notches**, so it is the right default for interactive HUD. TopbarSafeInsets is for a topbar-row ScreenGui whose AbsoluteSize the game watches. The older 36 px topbar assumption is outdated, and TopbarSafeInsets is reported wrong on some consoles ([ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets); [console bug](https://devforum.roblox.com/t/screenguiscreeninsets-topbarsafeinsets-is-incorrect-on-consoles/4111410)).

Input should bind through **IAS contexts**: one InputContext per mode, such as gameplay and menu, kept in ReplicatedStorage. Use `InputActionLabel` or `UserInputService:GetImageForKeyCode` for glyphs. The current `Components.luau` binds modal close through `ContextActionService:BindActionAtPriority`, which still works but is on a sunset path.

Accessibility hooks are first-class and cheap:
- multiply panel transparency by `GuiService.PreferredTransparency`;
- zero or replace motion when `ReducedMotionEnabled` is on;
- respect `PreferredTextSize`, which pure TextScaled text defeats
([accessibility](https://create.roblox.com/docs/production/publishing/accessibility)).

Consoles call for a 1.5× scale factor for 10-foot viewing ([console guidelines](https://create.roblox.com/docs/production/publishing/console-guidelines)).

For frameworks, the professional options are:
- **React-Luau**, which Roblox maintains and on which its own app is built;
- **Fusion 0.3** (scopes replace Maids);
- **Vide**;
- **Charm** for atomic state with CharmSync replication. Roact and Rodux are legacy
([jsdotlua/react-lua](https://github.com/jsdotlua/react-lua); [Fusion releases](https://github.com/dphfox/Fusion/releases); [Charm](https://github.com/littensy/charm)).

Hit games such as Pet Simulator 99, Pls Donate and Sol's RNG use **custom image-based UI kits**, not default Frames ([DevForum discussion](https://devforum.roblox.com/t/unique-or-good-looking-ui/2914121)). The skill should therefore advise a 9-sliced art kit plus a consistent icon set for simulator-style games, not only code-drawn panels. Roblox's own UI guidance stresses hierarchy of information and mobile-first wireframes, and leaves room for the default touch controls ([UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)).

## Architecture should be chosen per genre, not per habit

The cross-genre baseline is Roblox's own **Plant reference project**. Its parts:
- one server entry Script and one client entry LocalScript;
- singleton systems;
- per-player plots cloned from a ServerStorage template and rebuilt from saved data;
- `CharacterAutoLoads` off until data loads;
- a central Network module that type-validates every client argument.

It also sets a replication preference order: (1) player-data subscriptions, (2) attributes set before parenting, (3) CollectionService tags, (4) direct messages ([Plant reference](https://create.roblox.com/docs/resources/plant-reference-project)). cluau's architecture matches this baseline. What it lacks is the genre layer. Its `game-design.md` covers loops for eight genres and none of the 2025–2026 breakout formats. The table below condenses the research into the playbook the skill should carry. The engine facts are cited above. The per-genre design choices are synthesis.

| Genre | Server owns | Client owns | Key technique | Top exploit and fix | Monetization fit |
|---|---|---|---|---|---|
| Obby | stage index, best times | Humanoid movement, moving-platform visuals | streamed static stages | teleport-to-end → accept stage N only from N−1, plus time sanity ([defensive design](https://create.roblox.com/docs/scripting/security/defensive-design)) | skip-stage product via ProcessReceipt, trails |
| Simulator / pet | currency, multipliers, pets, hatch RNG | pickup/orb/pet-follow visuals, egg animation after the server result | replicate aggregates, not per-coin remotes | auto-farm → per-player collect rate limit plus proximity; make it worthless or sell auto-farm | 2× currency, luck, slots, limited eggs |
| Tycoon | plot, purchases, income timer | optional visual droppers | plot pool from ServerStorage; save purchased IDs and rebuild | button double-fire → ownership/prerequisite/funds checks under a per-player lock | 2× cash, auto-collect |
| Round-based | state machine, roles, maps | UI, timers from `GetServerTimeNow` | roles revealed only to their holder | role leak via replicated attributes → never replicate roles globally | cosmetics, private servers |
| Shooter / melee | damage, ammo, cooldowns | aim, prediction, VFX | Laser Tag validation; Server Authority for competitive play | silent aim / wallhack → angle tolerance plus LOS re-raycast ([detect hits](https://create.roblox.com/docs/tutorials/curriculums/gameplay-scripting/detect-hits)) | cosmetics, battle pass, no pay-to-win stats |
| Tower defense | enemy tables (id, path progress, HP), placement, money | models positioned from `spawnTime + speed × elapsed` | send spawn/death deltas; spatial index for targeting ([tower optimization](https://devforum.roblox.com/t/how-to-optimize-tower-system/2830931/9)) | placement anywhere → server-repeatable raycast into a placement zone, overlap check, serialized placements ([placement exploits](https://devforum.roblox.com/t/tower-defense-game-preventing-exploiters-from-abusing-placements/3801331)) | unit crates, 2×/3× speed |
| Horror | monster AI, `SetNetworkOwner(nil)`, seeded rooms | lighting, local jumpscares, audio | raycast chase when in line of sight, pathfinding otherwise | client-owned monster → server ownership ([AI ownership](https://devforum.roblox.com/t/2454116)) | revives, cosmetics |
| RPG | quests, inventory as IDs plus rolled stats | animation interpolation | Persistent/Atomic streaming for quest NPCs; 5–10 Hz AI | inventory dupes → session lock plus atomic trades | space, convenience |
| Farming / idle (Grow a Garden-type) | plots, growth as `plantedAt + duration`, mutations | growth visuals | global restock from `floor(os.time()/300)` | buy-from-stale-stock → re-check the current slot on purchase | instant restock, luck/weather |
| Steal / base-plot | lock expiry, carrier attachment, slot income `rate × elapsed` | belt and carry visuals | lazy income on collect | remote steal → server proximity plus lock-expiry check | lock extensions, special units |
| Fishing | catch roll at cast time | cast/reel minigame | accept "reel success" only in a plausible window | macros → per-rod rate limit; sell auto-fish | rods, bait, luck |
| Dress-up | outfit item-ID list (server-enforced cap), votes | try-on visuals | round state machine | vote rings → one vote per voter per target, ignore self-votes | item-cap pass, theme picks |
| Survival co-op | session world state (fire fuel, nodes, clock) | atmosphere | no persistence beyond meta-unlocks | low DataStore risk | classes, cosmetics |

The most transferable lesson is the **tower-defense pattern**: simulate in plain tables on the server, replicate events rather than frames, render on clients. One developer reports smooth rendering up to about 1,000 enemies, with tower *targeting* as the real bottleneck ([TD rendering](https://devforum.roblox.com/t/how-to-start-on-client-rendering-for-a-tower-defense/3008166)). The same pattern underlies horde games, RTS games (16-bit X/Z positions in buffers) and steal-style belts.

## Quality models, polish and launch form a missing pillar

cluau has almost no 3D asset guidance. The only asset rules it carries are one line on CollisionFidelity and one on instancing. Studios work to documented hard specs:
- **20,000 triangles per mesh**, watertight geometry, quads where possible;
- a single UV set in 0–1 space, one material per mesh;
- at most 4 bone influences per vertex, with a root bone at the origin;
- one animation track per FBX ([specifications](https://create.roblox.com/docs/art/modeling/specifications); [textures](https://create.roblox.com/docs/art/modeling/texture-specifications)).

Blender export rules: Unit System None; FBX with **Apply Scalings = FBX Unit Scale, Y Up, Path Mode Copy + Embed Textures, no leaf bones**; or glTF, which needs no scale fix ([Blender guide](https://create.roblox.com/docs/art/blender); [export settings](https://create.roblox.com/docs/art/modeling/export-requirements)). Normal maps must be OpenGL tangent-space.

Texture limits conflict inside the docs: "up to 4096×4096" on one page, 1024 on others. The safe advice is ≤1024² for props, with 2048–4096 only for hero assets. SurfaceAppearance now supports five maps, emissive included ([surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance)).

Performance for assets comes from **instancing and LOD**:
- import each kit piece once and duplicate it in Studio, because importing a whole scene gives duplicates different IDs and breaks instancing;
- share one trim-sheet SurfaceAppearance across a kit, and manage kits as Packages;
- leave RenderFidelity on Automatic; many Precise meshes are a common cause of slow frames;
- use Box or Hull collision, with CanCollide/CanTouch/CanQuery off on decoration;
- group static set dressing into models of about 64 studs or less with **`LevelOfDetail = SLIM`** ([improve performance](https://create.roblox.com/docs/performance-optimization/improve); [SLIM](https://create.roblox.com/docs/workspace/streaming/slim)).

The new **Scene Analysis** tool breaks down triangles and memory ([scene analysis](https://create.roblox.com/docs/performance-optimization/scene-analysis)). Lighting should target `LightingStyle` (Realistic or Soft) plus `PrioritizeLightingQuality`. The retro look comes from ColorGradingEffect's Retro tonemapper ([lighting](https://create.roblox.com/docs/environment/lighting)).

AI generation is now part of the pipeline:
- Cube 3D powers `GenerationService` (`GenerateModelAsync` with the `Car5`/`Body1` schemas; `GenerateMeshAsync` is slated for future deprecation).
- Assistant `/generate_mesh` defaults to a 10k-triangle cap.
- The Texture Generator's Quality mode outputs 4K PBR.
- Studio's MCP exposes `generate_mesh`, `generate_material`, `generate_procedural_model`, `generate_avatar` and `generate_animation`
([GenerationService](https://create.roblox.com/docs/reference/engine/classes/GenerationService); [Studio MCP](https://create.roblox.com/docs/studio/mcp)).

Generated meshes still need rescaling, anchoring, collision and moderation review. The skill should advise AI meshes for background props and blockout, and hand-retopologized assets for hero items.

Polish, QA and launch are measurable, and front-page games are distinguished by numbers:
- **Recommendations** reward low first-play bounce, playtime per user (capped at 60 min per day), qualified plays and D1/D2–7/D8–28 retention, measured only on organically recommended users. A custom thumbnail is required for home recommendations ([discovery](https://create.roblox.com/docs/discovery)).
- **Thumbnail personalization** with two or more thumbnails averages **+8.5%** qualified play-through ([thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails)).
- **Experiments** run 14–60 days with up to 2 variants ([experiments](https://create.roblox.com/docs/production/experiments)).
- **Device testing** should use real low-end Android hardware; the docs name the Infinix Smart 9 and Moto G05 and say the emulator is inaccurate for memory ([test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)).
- **Audio** should move to AudioPlayer/Emitter/Listener with an AudioCompressor for loudness. `SoundGroup` is "legacy … now discouraged" ([sound groups](https://create.roblox.com/docs/sound/groups)).
- **Highlights** should be toggled rather than added and removed, which causes rebuild spikes ([highlighting](https://create.roblox.com/docs/effects/highlighting)).

Game-feel techniques such as trauma-based shake (0.1–0.3 s), hit-stop and FOV kicks come only from general game-dev sources ([game feel checklist](https://forum.godotengine.org/t/game-feel-checklist-for-godot-4-hit-stop-trauma-shake-coyote-time-and-more/145340)), so the skill should present them as heuristics gated on reduced-motion.

## AI-specific failure modes and the big-studio workflow

No rigorous benchmark of LLM Luau accuracy exists ([Star-AI PR](https://github.com/oncoursemail/Star-AI/pull/353)). Community sources agree on the failures:
- deprecated APIs;
- invented properties;
- **wrong script type or location**, which "works in Play Solo but breaks in a live game";
- client-trusted remotes;
- `SetAsync` on contended data;
- leaks and respawn bugs
([roblox-suite](https://github.com/nonlooped/roblox-suite); [rateblox guide](https://rateblox.com/guides/can-chatgpt-make-a-roblox-game)).

The mirror-image failure is just as real: over-correcting valid Luau. `//`, `+=`, `continue`, `math.pow`, `unpack`, `string.pack`, `utf8` and `const` are all present. What is genuinely absent is `goto`, the bitwise operators (use `bit32`), `__gc`, `<close>`, 5.4 `<const>` attribute syntax, `io`/`package`, and most of `os` ([compatibility](https://github.com/luau-lang/site/blob/main/src/content/docs/getting-started/compatibility.md)). cluau currently commits this second failure in its own linter.

**excaldev/ro-engineer** (v1.0.2, 2026-11-13, MIT) is a router-style skill: a 5.5 KB SKILL.md plus 22 on-demand references and 8 workflows. Several of its ideas are worth borrowing ([SKILL.md](https://github.com/excaldev/ro-engineer/blob/main/SKILL.md)):
- **Proportionality.** "A small fix does not need a new architecture." Its v1.0.1 changelog removed "count thresholds" for ECS and pooling as over-rigid ([CHANGELOG](https://github.com/excaldev/ro-engineer/blob/main/CHANGELOG.md)).
- **Evidence honesty.** "Never invent inspection, execution, or test results", backed by an evidence-levels table that separates static review, type checks, unit tests, Studio playtests, profiling and security checks ([testing.md](https://github.com/excaldev/ro-engineer/blob/main/references/testing.md)).
- **An ID'd, severity-ranked sharp-edges catalog** (SE-1 client-trusted currency … SE-30 `:: any` casts) designed to grow from real incidents ([sharp-edges.md](https://github.com/excaldev/ro-engineer/blob/main/references/sharp-edges.md)).
- A **7-step remote checklist**, an **ownership-map table** (state | owner | lives on | replicated how | persisted), and "one trove per lifetime".
- Review rules that forbid style-only nitpicks and require location, failure scenario and fix.
- An **asset-compliance gate** for Studio MCP. Preview is the default mode. Assets stage in `ServerStorage/_AssetStaging`, and there are hard stops before image uploads, script-bearing inserts, unknown rights and `save_place` ([asset-compliance.md](https://github.com/excaldev/ro-engineer/blob/main/references/asset-compliance.md)).

Its weaknesses are cluau's strengths: no UI reference, thin DataStore and deprecation coverage, no Mongolian or beginner path. cluau should therefore borrow its discipline, not its structure.

Big-studio workflow in 2026 runs like this:
- **Rojo** with Git as the source of truth. Roblox now documents "partially managed" (code only) and "fully managed" Rojo, where "places are built from the repo, never edited by hand", while noting it does not maintain Rojo ([Rojo docs](https://create.roblox.com/docs/projects/rojo); [fully managed](https://create.roblox.com/docs/projects/rojo/fully-managed)).
- **Rokit** pins tools, **Wally** and/or **pesde** manage packages, and **Selene, StyLua and luau-lsp** handle lint, format and analysis.
- **GitHub Actions** run tests in the real engine through the Open Cloud Luau Execution API, and publish to production only in a gated job ([place-ci-cd-demo](https://github.com/Roblox/place-ci-cd-demo)).
- Studio now ships a **built-in MCP server**, about 30 tools including `script_grep`, `inspect_instance`, `execute_luau`, `start_stop_play`, `get_console_output`, `screen_capture`, `user_mouse_input`, `http_get` and `save_place`. The legacy `studio-rust-mcp-server` is no longer developed ([tool reference](https://github.com/nonlooped/roblox-suite/blob/main/roblox-mcp/references/tool-reference.md); [legacy server](https://github.com/Roblox/studio-rust-mcp-server)).

This changes cluau's closing line. Today it says the model "cannot run Studio". With MCP connected, it can verify, and the honesty rule becomes "report exactly which checks ran". cluau's `rokit.toml` also pins Rojo 7.4.4, while 2026 templates use 7.7.1 ([luau_temp](https://github.com/SSuzuka/luau_temp)).

## Prioritized change list for the cluau skill

Priorities: **P0** fixes wrong or harmful output and should ship first. **P1** adds the missing big-studio knowledge. **P2** is depth and tooling. Every deprecation edit should, per the repo's CLAUDE.md, add a linter rule and a `-- expect` line in `tests/fixtures/bad.luau`.

### P0 — correct what is wrong now

| # | File | Change |
|---|---|---|
| P0-1 | `scripts/luau_lint.py` | **Remove CL082** (`math.pow` is valid Luau). **Remove CL081 or downgrade it to `info`** with "optional style: `table.unpack`" (`unpack` is valid). **Drop `maxn` from CL080** (it should flag only `getn/foreach/foreachi`). |
| P0-2 | `scripts/luau_lint.py` | **Rewrite the CL050 message** to recommend `workspace:RegisterCollisionGroup` / `workspace:CollisionGroupSetCollidable`. **Add CL059** `PhysicsService\s*:\s*(RegisterCollisionGroup\|CollisionGroupSetCollidable\|CollisionGroupsAreCollidable\|GetRegisteredCollisionGroups\|UnregisterCollisionGroup\|RenameCollisionGroup\|IsCollisionGroupRegistered\|GetMaxCollisionGroups)\s*\(` → error "PhysicsService is deprecated (2026-09) — call on `workspace` (WorldRoot)". **Add CL024** `\.CollisionGroupId\b` → `CollisionGroup` string. |
| P0-3 | `scripts/luau_lint.py` | **Add CL062** `:\s*ReserveServer(?:Async)?\s*\(` and `\b(ReservedServerAccessCode\|ShouldReserveServer)\b` → error "use `HttpService:GenerateGUID(false)` as `TeleportOptions.ReservedServerId` with `TeleportAsync`". |
| P0-4 | `scripts/luau_lint.py` | **Add CL063, the Async-rename rule** (error), matching `:\s*(LoadCharacter\|LoadCharacterWithHumanoidDescription\|GetFriendsOnline\|IsFriendsWith\|IsInGroup\|CreateHumanoidModelFromDescription\|CreateHumanoidModelFromUserId\|GetHumanoidDescriptionFromUserId\|GetHumanoidDescriptionFromOutfitId\|ApplyDescription\|ApplyDescriptionReset\|PlayEmote\|GetProductInfo\|PlayerOwnsAsset\|PlayerOwnsBundle\|AwardBadge\|GetFreeModels\|GetFreeDecals\|SearchAudio\|GetAssetIdsForPackage\|PromptLinkSharing\|GetTranslatorForPlayer\|GetAnimationClip\|CreateDockWidgetPluginGui\|Preload)\s*\(`. Because `\s*\(` must follow immediately, the `…Async` forms do not match. **Add CL064** `:\s*(GetRankInGroup\|GetRoleInGroup)(?:Async)?\s*\(` → `GroupService:GetRolesInGroupAsync`. Make **CL056 an error** that recommends `PlayerOwnsAssetAsync` or `UserOwnsGamePassAsync`. |
| P0-5 | `SKILL.md §3` + `references/deprecated-apis.md` | Fix the PhysicsService row (→ `workspace:` methods). Replace the `ShouldReserveServer` advice (→ GUID `ReservedServerId`). Remove "`unpack` (bare)" from the never-use row. Add rows for: the Async renames; group APIs → `GroupService:GetRolesInGroupAsync`; `FindPathAsync`, `CheckOcclusionAsync` → `Path.Blocked`, `GetPointCoordinates` → `GetWaypoints`; `Draggable`/`DragBegin`/`DragStopped` → `UIDragDetector`; `TweenPosition/TweenSize/TweenSizeAndPosition` → TweenService; `Lighting.Technology` → `LightingStyle` + `PrioritizeLightingQuality`; `HapticService` → `HapticEffect`; `IsTenFootInterface` → `ViewportDisplaySize`; `UserInputService.ModalEnabled` → `GuiService.TouchControlsEnabled`; `MembershipType`/`PromptPremiumPurchase` → `HasRobloxSubscription`/`PromptRobloxSubscriptionPurchase`; `Player.Chatted` → `TextChatCommand`; `GetChatForUserAsync`/`FilterAndTranslateStringAsync` (return empty); `KeyframeReached` → `GetMarkerReachedSignal`; `Sound.Pitch`/`MaxDistance`/`MinDistance`/`EmitterSize` → `PlaybackSpeed`/`RollOff*`; `CollectionService:GetCollection/ItemAdded/ItemRemoved`; `AnalyticsService:FireEvent`; `InputAction:Fire` → `InputBinding:Fire` (Scriptable); `BadgeService:IsDisabled` → `GetBadgeInfoAsync().IsEnabled`; `ResetPlayerGuiOnSpawn` → `ResetOnSpawn`; `ypcall`/`printidentity`/`version`/`stats`. In the Animation section, mark `ApplyDescription`, `LoadCharacter` and `CreateHumanoidModelFromDescription` with their Async names. |
| P0-6 | `deprecated-apis.md` | Add a **"NOT deprecated — do not rewrite" table**: `Heartbeat/RenderStepped/Stepped`, `CollectionService:AddTag/GetTagged`, `SetNetworkOwner` (outside Server Authority), `Sound` (Audio API preferred for new 3D/voice), `math.pow`, `unpack`, `table.maxn`, `//`, `continue`, `const`. Change the `time()` row: `time()` is **required** inside `BindToSimulation`. Stamp the file "verified against creator-docs 2026-11-21". |
| P0-7 | `SKILL.md §4`, §6; `Components.luau` | Replace "SignalBehavior is Deferred by default" with "write handlers correct under Immediate and Deferred; Deferred is forced by AuthorityMode=Server". Change the HUD default to **`CoreUISafeInsets`**, use `TopbarSafeInsets` for topbar-row UI, and change `Components.screen()` to match. |
| P0-8 | `networking-security.md`, `game-design.md`, `architecture.md` | Replace `GetRankInGroup` with `GroupService:GetRolesInGroupAsync`, `IsFriendsWith` with `IsFriendsWithAsync`, `ReserveServer` (matchmaking) with the GUID `ReservedServerId` pattern. Reword the Knit line to "archived July 2024, unmaintained". |
| P0-9 | `monetization-policy.md` | Replace the Premium section with Roblox Plus (Apr 2026, `PromptRobloxSubscriptionPurchase`, `HasRobloxSubscription`, creator-share math). Remove `AllowedExternalLinkReferences` (legacy, always empty). Add the ProcessReceipt audit and external-sales rule, "never grant on `PromptProductPurchaseFinished`", and dynamic price reads. |
| P0-10 | `tests/fixtures/` | Add **`good.luau`**, which must produce zero findings: `math.pow`, `unpack`, `table.maxn`, `//`, `continue`, `const`, `vector.create`, `workspace:RegisterCollisionGroup`, `LoadCharacterAsync`, `GetProductInfoAsync`, `RunService:BindToSimulation`. Add a test asserting no findings. Add `-- expect` lines for every new rule in `bad.luau`. |

### P1 — add big-studio knowledge (new references and SKILL.md rules)

| # | File | Content |
|---|---|---|
| P1-1 | **new `references/genre-playbooks.md`** | The genre table above, expanded per genre with a data schema, a remote list, entity budget, top exploits and fixes, monetization fit, and the live-ops hook. Add Plant as the reference skeleton, and the 2025–2026 formats (farming/idle, steal, fishing, dress-up, survival co-op). |
| P1-2 | **new `references/server-authority.md`** | When to opt in. The required Studio properties (scripts cannot set them). The `BindToSimulation` skeleton with `Hz60`, `time()`, attribute state, `GetTrackByAnimationId`, instance stitching and position smoothing. Limits (64 predicted attributes, 8 tracks, tool caveat, 6.25× resim cost). "Remotes still need validation". |
| P1-3 | **new `references/assets-pipeline.md`** | Mesh/UV/rig specs, Blender FBX/glTF settings, 3D Importer options (Upload off while iterating, Make Double Sided off), texture-size guidance and conflict, SurfaceAppearance/MaterialVariant/trim sheets, instancing rules, RenderFidelity/CollisionFidelity, SLIM, Packages, asset privacy (Open Use is irreversible; group-owned animations), audio limits (<20 MB, <7 min), Creator Store vetting and backdoor grep, AI-generation cleanup, and **an asset-compliance gate adapted from ro-engineer** (Preview default, `_AssetStaging`/`_AssetQuarantine`, hard stops before `upload_image`, script-bearing `insert_asset` and `save_place`). |
| P1-4 | **new `references/polish-qa-launch.md`** | Game-feel recipes gated on ReducedMotion, the Audio API graph and compressor, lighting mood presets via LightingStyle/ColorGrading, device-test matrix and budgets, multi-client testing, Experiments, FTUE funnels, discovery signals, launch checklist (icon ≥512², thumbnails 1920×1080 and personalization, content questionnaire, Kids/Select eligibility, localization). |
| P1-5 | **new `references/sharp-edges.md`** | An ID'd severity catalog (CRITICAL/HIGH/MEDIUM/LOW) merging ro-engineer's SE list with cluau-specific items: no yield between check and mutate, prompt/ClickDetector/Touched range checks, buffer decode bounds, receipt on two servers, `User_` key migration risk, CanvasGroup memory, flex/AutomaticSize combinations, require-by-string being non-blocking, `math.clamp` min>max, `table.sort` with `<=`. Format: symptom, cause, fix, linter ID. |
| P1-6 | **new `references/toolchain-workflow.md`** | Rojo partially vs fully managed, Rokit/Wally/pesde/Selene/StyLua/luau-lsp/Lune/Jest-Lua, the CI shape (lint → build → Luau Execution tests → gated publish), Script Sync, the Studio MCP verification sequence (`list_roblox_studios` → `get_studio_state` → `start_stop_play` → `execute_luau` → `get_console_output` → `screen_capture`), "avoid competing writers", and ro-engineer's **evidence-levels table**. |
| P1-7 | `SKILL.md §0` | Add steps: **classify the genre and load `genre-playbooks.md`**; **scale to risk** (a small fix gets no architecture; no ECS or pooling without profiling); for new systems, write an **ownership map** (state, owner, replication, persistence). After writing: **report the checks that actually ran and what remains unverified**. |
| P1-8 | `SKILL.md §5` | Add: no yields between validation and mutation (use a busy lock); a server distance check in every prompt, click and touch handler; buffer decode bounds; `BanAsync` with audit log and delayed waves; honeypots only log; Secrets Store; Server Authority for competitive movement. |
| P1-9 | `SKILL.md §7` + `data-persistence.md` | The July 2026 budgets (new request categories; read the budget, never hard-code); UpdateAsync counts double; 4 s cache and `UseCache=false` verification reads; `User_{UserId}` + `userIds` **for new games only**; snapshot before schema changes; ProfileStore v1.0.3 API (`MessageAsync`, `Mock`, `LastSavedData` receipt pattern); block purchases on load failure; MemoryStore and MessagingService limits. |
| P1-10 | `SKILL.md §8` + `monetization-policy.md` | Paid-random-item exact rules and the restricted-path options; `IsPaidItemTradingAllowed`; `GetUsersPriceLevelsAsync` for gifting; rewarded ads via dev products; subscriptions; age-based accounts; chat age checks ("never make core gameplay depend on chat"). |
| P1-11 | `SKILL.md §9` + `performance.md` | The hard numbers: 40/50 KB/s; ≤20–30 KB/s custom traffic; ~9 B per fire; 1000 B unreliable; 40–60 moving assemblies; 100 draw calls and 150k triangles target vs the 1,000 / 1M ceiling; Humanoid >30 → data + client visuals; BulkMoveTo/bone `Transform`; Android 2–4 GB; Scene Analysis. |
| P1-12 | `SKILL.md §6` + `ui-design-system.md` | Styling (StyleSheet/StyleRule/StyleQuery/Transitions) as the token implementation; flex limits; CanvasGroup rules; IAS-based input parity and glyphs; `PreferredTransparency`/`ReducedMotionEnabled`/`PreferredTextSize`; console 1.5×; image-based UI kit guidance per genre; framework options (React-Luau, Fusion 0.3, Vide, Charm). Replace "ContextActionService mobile buttons" with IAS. |
| P1-13 | `luau-modern.md` | A **Lua-vs-Luau "absent / present" table**; 2025–26 additions (`math.lerp/map/isnan`, `vector`, buffer bits and vectors, `const`, require-by-string semantics, `@native`, `@[deprecated]`, type functions, `read`/`write`); a "never emit" experimental list (`class`, `if local`, `export x =`, `integer.*`); a type-solver note (`UseNewLuauTypeSolver`). |
| P1-14 | `SKILL.md` frontmatter and §10 | Extend the description with "Server Authority, 3D models/Blender import, polish, launch, farming/steal/fishing/dress-up". Add the new references to the §10 map. Add a "last verified 2026-11-21; if unsure, check docs or MCP `http_get`" line. Keep SKILL.md under 500 lines by moving detail into references. |
| P1-15 | `scripts/luau_lint.py` (more rules) | **CL065** `:\s*(FindPathAsync\|CheckOcclusionAsync\|GetPointCoordinates)\s*\(` error. **CL066** `\.Chatted\b`, `:GetChatForUserAsync\(`, `:FilterAndTranslateStringAsync\(` error; promote **CL053 to error** (legacy chat gone). **CL041** `\.Draggable\s*=\|\bDragBegin\b\|\bDragStopped\b\|:\s*Tween(Position\|Size\|SizeAndPosition)\s*\(` error. **CL067** `\bLighting\b[^\n]*\.Technology\b\|\bHapticService\b` error. **CL068** `\.MembershipType\b\|:PromptPremiumPurchase\s*\(` error. **CL061** `:\s*OnUpdate\s*\(\|:\s*RemoveVersionAsync\s*\(` error. **CL083** `:\s*GetCollection\s*\(\|\.ItemAdded\b\|\.ItemRemoved\b` warn. **CL084** `Analytics\w*\s*:\s*FireEvent\s*\(` error. **CL069** `\.Pitch\s*=` (Sound) warn, `\.KeyframeReached\b` error. **CL025** `\.(Velocity\|Elasticity\|Friction\|SpecificGravity)\s*=` warn. **CL042** `:IsTenFootInterface\s*\(\|\.ModalEnabled\b` error. **CL077** `\b(ypcall\|printidentity)\s*\(` error. **CL078** experimental syntax `^\s*class\s+\w+\|\bif\s+local\b\|^\s*export\s+\w+\s*=\|\binteger\s*\.` error. **CL085** `PromptProductPurchaseFinished` info "never grant here". **CL086** `\w*[Aa]ction\w*\s*:\s*Fire\s*\(` warn "InputAction:Fire deprecated". **CL096** `ContextActionService\s*:\s*BindAction` info "IAS is the 2026 default for gameplay input". Extend **CL004** with "inside BindToSimulation use `time()`". |

### P2 — templates, toolchain, depth

| # | File | Change |
|---|---|---|
| P2-1 | `templates/server/DataService.luau` | Comment block on key choice: keep `Player_` for existing games, use `User_{UserId}` + return `{player.UserId}` as UpdateAsync's second value for new games (RTBF). Read the budget with the new request types. Add a `UseCache=false` verification read after an errored write. |
| P2-2 | `templates/server/MonetizationService.luau` | Optional ProfileStore path that waits for the PurchaseId in `LastSavedData`. Policy gating (`GetPolicyInfoForPlayerAsync` in pcall, cached on join). Client-side price display via `GetProductInfoAsync`. |
| P2-3 | **new templates** | `templates/shared/Simulation.luau` (a Server Authority skeleton), `templates/shared/InputContexts.luau` (IAS gameplay/menu contexts), `templates/server/ModerationService.luau` (BanAsync wrapper, evidence log, honeypot logging, delayed waves), `templates/server/LiveOpsService.luau` (ConfigService + MessagingService event bus + MemoryStore active-event flag + deterministic restock), `templates/shared/BufferCodec.luau` (bounds-checked encode/decode with NaN rejection). |
| P2-4 | `templates/ui/Components.luau` | IAS close binding (keep a CAS fallback); `UIScale`-only press tweens; PreferredTransparency/ReducedMotion hooks; a topbar ScreenGui helper using TopbarSafeInsets. |
| P2-5 | `assets/project/rokit.toml` | Bump Rojo toward 7.7.x (pin whatever is actually tested). Add `luau-lsp` and `lune`, and document pesde as optional. Add a CI example workflow (lint, format check, `luau-lsp analyze`, optional Luau Execution tests). |
| P2-6 | `game-design.md` | GameAnalytics benchmarks (median D1 10.3%), return-frequency design, weekly slot plus admin-abuse events, global restocks, per-genre monetization fit, AnalyticsService caps wrapper. |
| P2-7 | `debugging-testing.md` | The evidence-levels table, MCP runtime-verification steps, 50-cycle join/leave leak test, real-device test list. |
| P2-8 | **new workflow docs** (optional, ro-engineer-style) | `workflows/code-review.md` (severity, location, failure scenario, fix; no style-only nits), `workflows/performance-audit.md`, `workflows/economy-audit.md` (source/sink table, check-then-deduct races, NaN amounts). |

## Conclusion

The research shifts what "thinking like a big studio" means for cluau. The old picture was a checklist of good habits. The 2026 picture is **tracking a moving platform contract**. Roblox now deprecates whole services (PhysicsService), whole API families (reserved-server teleports, the Async wave) and whole systems (legacy chat) on a cadence of months. It also publishes an agent-targeted feed of what replaces what. A skill that freezes its deprecation table goes wrong within one quarter, and cluau's table has already drifted on three high-traffic APIs. The durable fix is structural: a dated deprecation table synced to `latest-features.json` and the creator-docs `deprecation_message` fields, a linter with a "must-not-flag" fixture so it never punishes valid Luau, and an evidence rule that lets the model verify through Studio MCP rather than assert.

The second insight is that Server Authority does not make validation obsolete. It splits security into two layers. The engine owns movement and physics, and the game still owns remotes, economy, inventory, prompts and receipts, where receipts are now audited by Roblox itself. The genre playbook is where these meet. Each genre has its own exploit surface, entity budget and monetization fit, and the dominant 2025–2026 formats (farming idle, steal-a-base, fishing) all lean on timestamp-based state and deterministic global schedules that cluau's current references never mention. Two areas remain weakly sourced: first-party studio internals and Roblox-specific game-feel standards. The skill should label its advice in those areas as heuristics rather than rules.
