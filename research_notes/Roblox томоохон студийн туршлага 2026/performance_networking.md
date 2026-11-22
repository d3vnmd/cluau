# Roblox Performance Optimization & Networking (Lag Prevention) — Professional Practice as of Nov 2026

> Research constraints note: In this session `create.roblox.com`, `devforum.roblox.com` and the GitHub API for the relevant repos were NOT reachable by direct fetch (DNS blocked / repo access not enabled). All findings below come from web-search result extracts of those pages (titles + quoted snippets), not full-page reads. Numbers quoted are those the search extracts attributed to the named page. Items marked **[background, unverified]** are from model prior knowledge and were not confirmed this session; the report writer should treat them as such. To verify, allow `create.roblox.com` and `devforum.roblox.com` in the session network settings.

## 1. Networking: remote overhead, bandwidth budgets, UnreliableRemoteEvent, buffer, libraries, batching/quantization, NPC replication, Server Authority

### Takeaway
The practical bandwidth ceiling is ~50 KB/s receive per client (physics throttling begins ~40 KB/s per a Roblox staff post), each fired RemoteEvent carries ~9 bytes of overhead, and UnreliableRemoteEvents cap payloads at roughly 900–1000 bytes (docs say 900; a later release note says 1000). Pro pattern: batch per frame into one `buffer`, quantize (uint8/uint16), replicate only entity IDs + compact state at a low rate and render/interpolate on clients; Server Authority (full release July 2026) is the new native prediction/rollback model and requires StreamingEnabled.

### Cited Findings

**Bandwidth budgets / throttling**
- Roblox staff post: "if this is over 40 KB/s, physics objects will start having their updates throttled, so you'll want to stay well below that"; the receive counter "caps out at 50 KB/s before it turns red and throttles." Post is ~2 years old (Aug 2024 era). — [Real world building and scripting optimization for Roblox (Roblox Staff)](https://devforum.roblox.com/t/real-world-building-and-scripting-optimization-for-roblox/3127146)
- Same post: each moving physics object costs ~0.4–0.9 KB/s, giving "a rough safe budget of around 40-60 physics assemblies" (moving, replicated). — [Roblox Staff post](https://devforum.roblox.com/t/real-world-building-and-scripting-optimization-for-roblox/3127146)
- Custom-NPC tutorial: if bandwidth exceeds 50 KB/s, "Roblox will attempt to throttle replication back down," making Humanoids move slowly or teleport. — [Performance tips for custom NPC replication](https://devforum.roblox.com/t/performance-tips-network-bandwidth-client-framerate-etc-for-custom-npc-replication/4202236)
- Unit confusion: the figure has been written as "50 kb/s" (kilobits) but is actually 50 kB/s (kilobytes); the limit is described as soft, not hard. — [Network Optimization (2021)](https://devforum.roblox.com/t/network-optimization-2021-preventing-high-latency-reducing-lag/1046078) (older, 2021)
- Measured Humanoid NPC bandwidth: ~4 KB/s for 5 Humanoids → ~160 KB/s for 500 (anecdotal). — search extract from [Humanoid/NPC threads, e.g. Handle 100 humanoids NPC](https://devforum.roblox.com/t/handle-100-humanoids-npc/2648769)

**RemoteEvent / buffer overhead**
- RemoteEvent fire carries ~9 bytes overhead; networking libraries aim to reduce it; "UnreliableRemoteEvents do not have the 9 byte overhead" (forum claim). — [ByteNet thread](https://devforum.roblox.com/t/bytenet-advanced-networking-library-w-buffer-serialization-strict-luau-absurd-optimization-and-rbxts-support-043/2733365?page=4); [QuickNet thread](https://devforum.roblox.com/t/quicknet-v040-up-to-10x-faster-than-remoteevents-drop-in-networking-library/4624342?page=3)
- A buffer sent over a remote has ~9 bytes overhead (8-byte length integer + 1-byte type tag). — [ByteNet thread](https://devforum.roblox.com/t/bytenet-advanced-networking-library-w-buffer-serialization-strict-luau-absurd-optimization-and-rbxts-support-043/2733365?page=4)
- Roblox docs: "a sufficiently large buffer will be compressed before sending … and decompressed on the other side automatically"; recommends grouping smaller buffers into larger buffers. — search extract attributing to Roblox docs, via [Introducing Luau buffer type [Beta]](https://devforum.roblox.com/t/introducing-luau-buffer-type-beta/2724894)
- Merging same-structure buffers is beneficial because Roblox adds bytes depending on buffer size. — [ByteNet thread](https://devforum.roblox.com/t/bytenet-advanced-networking-library-w-buffer-serialization-strict-luau-absurd-optimization-and-rbxts-support-043/2733365?page=4)
- Batch many small updates into a single RemoteEvent call rather than many individual fires; "send as little data as possible." — [Data Handling: Remote Events](https://devforum.roblox.com/t/data-handling-remote-events/4527246); [What point does sending large data cause lag?](https://devforum.roblox.com/t/what-point-does-sending-large-data-cause-lag/278034) (old)

**UnreliableRemoteEvent**
- Official reference: 900-byte payload limit; larger payloads are dropped; buffers are compressed so it's hard to know pre-fire whether you're under. — [UnreliableRemoteEvent reference](https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent)
- Conflicting: a release-notes post says limit increased to 1000 bytes on client and server; API mirror says >1000 bytes dropped. Date of change unconfirmed. — [robloxapi mirror](https://robloxapi.github.io/ref-temp/class/UnreliableRemoteEvent.html); [Introducing UnreliableRemoteEvents thread](https://devforum.roblox.com/t/introducing-unreliableremoteevents/2724155)
- Community measurements: exact max 908 bytes; another claimed 3873 bytes (unreliable observation, likely compression effects). — [What are real limits…](https://devforum.roblox.com/t/what-are-real-limits-of-data-being-sent-when-using-unreliableremoteevent/3038324); [Incorrect size limit thread](https://devforum.roblox.com/t/incorrect-size-of-data-being-sent-limit-specified-when-using-unreliableremoteevent/3048788)
- Studio logs a "payload too large / dropped" warning stating how many bytes over; there is a thread on silencing "Packet Dropped" warnings. — [Payload too large problem](https://devforum.roblox.com/t/unrealible-events-dropped-as-its-payload-is-too-large-problem/3246001); [Silence Packet Dropped warnings](https://devforum.roblox.com/t/how-to-silence-packet-dropped-warnings-for-unreliableremoteevents/4042507)
- Used for server state replication (e.g., continuous transforms). — [Server State Replication Using Unreliable Remote Events](https://devforum.roblox.com/t/server-state-replication-using-unreliable-remote-events/3219424)

**Quantization**
- Orientation as 3×uint8 (~1.4° accuracy) instead of Vector3 "cut network usage in half." — [Performance tips for custom NPC replication](https://devforum.roblox.com/t/performance-tips-network-bandwidth-client-framerate-etc-for-custom-npc-replication/4202236)
- RTS with 200+ units stores X/Z positions as 16-bit values via buffer instead of full numbers. — [RTS game with 200+ units](https://devforum.roblox.com/t/how-we-are-developing-an-rts-game-with-good-performance-for-more-than-200-units/3281168)
- Packet Profiler plugin measures actual RemoteEvent bandwidth. — [Packet networking library thread](https://devforum.roblox.com/t/packet-networking-library/3573907/90)

**Networking libraries (2025–2026 status)**
- Zap vs Blink: a ~Sept 2026 thread says both are still maintained "by their own respective developers," Blink "more active"; an older (~mid-2025) thread thought Zap more active — conflicting. — [What networker should I use?](https://devforum.roblox.com/t/what-networker-should-i-use/4889485); [Zap or ByteNet Max?](https://devforum.roblox.com/t/zap-or-bytenet-max/3820579)
- Blink authors claim faster than ByteNet and Zap; Warp author's benchmark shows Blink and Zap ahead of ByteNetMax on FPS, Warp "dynamic" mode lower FPS but lower bandwidth in some cases (self-run benchmarks). — [Warp thread](https://devforum.roblox.com/t/warp-very-fast-powerful-networking-library/2779813); [Which network libraries do you use?](https://devforum.roblox.com/t/which-network-libraries-do-you-use/3659422)
- Criticism: Zap has "no rate limiting at all." — [What networker should I use?](https://devforum.roblox.com/t/what-networker-should-i-use/4889485)
- New entrants: BlinkBlox (IDL compiler, claims 6x faster server decode than Zap/Blink and flood protection; self-reported), QuickNet v0.4.0 ("up to 10x faster than RemoteEvents"), Packet (Suphi), bitnet. — [BlinkBlox](https://devforum.roblox.com/t/blinkblox-6x-faster-server-decoding-than-zap-blink-and-exploiters-cant-flood-your-server/4898948); [BlinkBlox PR #45](https://github.com/XopoIII/BlinkBlox/pull/45); [QuickNet](https://devforum.roblox.com/t/quicknet-v040-up-to-10x-faster-than-remoteevents-drop-in-networking-library/4624342?page=2); [bitnet](https://github.com/minecoiii2/bitnet)
- Caution: libraries "could initially seem to harm network performance because they're adding extra data overhead"; if no lag, gains may not matter. — [Questions about Networking Libraries such as Warp, FastNet2](https://devforum.roblox.com/t/questions-about-networking-libraries-such-as-warp-fastnet2-etc/2917430)

**Many-entity replication (tower defense / NPC hordes)**
- Pattern: enemies as plain server tables (no models); send batched data to clients every 10–20 Heartbeats; client builds and tweens visuals. — [Tower Defense Enemy Movement (2022)](https://devforum.roblox.com/t/tower-defense-enemy-movement/1930853)
- Server holds only values (incl. CFrame) per enemy; clients create models; "hundreds of enemies" at ~60 server FPS, client tweens smooth infrequent updates. — [Best way to go about client replication?](https://devforum.roblox.com/t/best-way-to-go-about-client-replication/4173285)
- Old approach struggling at ~160–200+ NPCs moved to Value objects (CFrameValue) — older. — [Server/Client NPC Movement replication](https://devforum.roblox.com/t/server-client-npc-movement-replication/1089362)
- 1000+ CFrame-driven NPCs cause client frame instability on low-end; fixes: lerp with delta-time, spread rendering across frames in batches, distance culling with buffer zone, `BulkMoveTo`. — [Performance tips for custom NPC replication](https://devforum.roblox.com/t/performance-tips-network-bandwidth-client-framerate-etc-for-custom-npc-replication/4202236)
- Framework claims: ~500 NPCs at ~120 FPS (client-side movement on TD path); "thousands of NPCs" with client-only movement. — [Lightweight NPCs](https://devforum.roblox.com/t/lightweight-npcs/4224897); [Simulating thousands of moving NPCs](https://devforum.roblox.com/t/simulating-thousands-of-moving-npcs-with-humanoidsphysics-performantly/4603494)

**Server Authority (native)**
- Timeline: Early Access → Studio Beta (with Latency Compensation) → Client Beta → Full Release ~July 9, 2026 for all creators; opt-in. — [Full Release post](https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993); [Roblox newsroom July 2026](https://about.roblox.com/newsroom/2026/07/creating-responsive-cheat-resistant-games-roblox-server-authority); [Roblox on X](https://x.com/Roblox/status/2075267517111582783?lang=en)
- Server is single source of truth; client predicts inputs and rolls back + resimulates buffered inputs on misprediction; blocks flings, wall clips, speed hacks without custom anti-cheat. — [Newsroom](https://about.roblox.com/newsroom/2026/07/creating-responsive-cheat-resistant-games-roblox-server-authority); [Server authority model docs](https://create.roblox.com/docs/projects/server-authority)
- Required settings (applied automatically when `Workspace.AuthorityMode = Server`): StreamingEnabled, NextGenerationReplication, PlayerScriptsUseInputActionSystem, SignalBehavior = Deferred, UseFixedSimulation. — [Server authority model docs](https://create.roblox.com/docs/projects/server-authority)
- Community tutorial (pre-full-release; provisional): client resimulates ~6 frames after misprediction; Automatic prediction mode default; non-BasePart instances don't roll back under Automatic. — [MrChickenRocket Server-Authority tutorial](https://github.com/MrChickenRocket/Server-Authority-Tutorial-Cakeman/blob/main/docs/reference/server-authority.md)
- Beta noted "attribute replication has strict limits"; community reports bandwidth/perf issues and R6 questions, no official answer found. — [Studio Beta post](https://devforum.roblox.com/t/studio-beta-build-fair-responsive-games-with-server-authority/4139157); [Server Authority Issues](https://devforum.roblox.com/t/server-authority-issues/4728153)

### Inferences
- Safe skill rule: budget ≤ ~20–30 KB/s average per client for custom traffic, leaving headroom below the ~40 KB/s physics-throttle point (derived from staff numbers).
- Firing one remote per entity per frame is the core anti-pattern: at 60 Hz × 9 B overhead × N entities, overhead alone for 50 entities ≈ 27 KB/s. Batch into one buffer per tick and send at 10–20 Hz for non-critical state.
- For TD/hordes: server simulates path progress (e.g., distance along path as uint16 + enemy id) not CFrames; clients reconstruct positions → bandwidth is O(events) not O(entities × frames).
- Library choice in 2026: IDL-compiler approach (Zap/Blink) is the "pro" default; ByteNet/Warp/BridgeNet2/Red appear less central in 2026 discussions (Red/BridgeNet2 rarely mentioned — likely stale). Add own rate limiting if using Zap.

### Gaps
- Could not fetch the UnreliableRemoteEvent doc page to confirm current limit (900 vs 1000 bytes) or ordering semantics. **[background, unverified]**: unreliable events are unordered and may be dropped; reliable RemoteEvents are ordered.
- **[background, unverified]** RemoteEvent argument restrictions: no functions, metatables stripped, mixed/sparse tables and non-string dictionary keys get mangled, Instances not replicated to receiver arrive as nil; RemoteFunction `InvokeClient` can hang the server forever if the client never returns — avoid.
- Server tick rate: not found. **[background, unverified]**: Heartbeat ~60 Hz; physics solver 240 Hz; network replication ~20–30 Hz (older figures). Server Authority uses fixed simulation (exact Hz unconfirmed).
- Network ownership/SetNetworkOwner and interpolation specifics: no sources found this session.
- No 2026 maintenance status for ByteNet, Warp, BridgeNet2, Red confirmed (GitHub API blocked).
- Chickynoid status: not found.

## 2. Server performance: Heartbeat budget, Humanoids, physics, BulkMoveTo, spatial queries, pooling, native codegen, Parallel Luau

### Takeaway
Humanoids are the heaviest per-NPC cost (CPU + bandwidth); pros replace them with lightweight rigs/CFrame-driven client visuals. `--!native` gives ~1.5–2.5x only for compute-heavy pure-Luau code (not engine API calls); Parallel Luau only helps when work is split across multiple Actors with minimal sync/desync switching and no DataModel writes in parallel.

### Cited Findings
- "Humanoids are baseline heavy and can only be optimized so far"; full rig "quite a heavy thing to do in terms of performance (both bandwidth and cpu)." — [How to optimise hundreds of humanoids](https://devforum.roblox.com/t/how-to-optimise-hundreds-of-humanoids/1760085); [Custom NPC replication tips](https://devforum.roblox.com/t/performance-tips-network-bandwidth-client-framerate-etc-for-custom-npc-replication/4202236)
- Conflicting: one test found Humanoid Animator faster than AnimationController for playing animations (~110 FPS vs ~44 FPS); others say AnimationController avoids Humanoid's extra calculations. — [Humanoids are more performant than Animation Controllers…](https://devforum.roblox.com/t/humanoids-are-more-performant-than-animation-controllers-when-playing-animations/4170689); [Exploring performance on Humanoids](https://devforum.roblox.com/t/exploring-a-bit-of-performance-on-humanoids/4598686)
- Micro-benchmark: Bones ~0.002 ms, CFrame set ~0.023–0.03 ms, BulkMoveTo ~0.012–0.16 ms; moving 1000 assemblies: BulkMoveTo ~6 ms/frame → 2.5 ms after tuning; switching to `Transform` (Motor6D/bones) ~6 ms → ~1 ms. — [Struggling to efficiently move 1000 assemblies](https://devforum.roblox.com/t/struggling-to-efficiently-move-1000-assemblies/4203225)
- Native codegen: enable via `--!native` or per-function `@native`; improves "some scripts on the server, in particular those that have a lot of numerical computation"; calls into Luau libraries/engine APIs don't get faster; slightly slower load and more memory; type mispredictions can slow code. — [Native code generation docs](https://create.roblox.com/docs/luau/native-code-gen); [Native Codegen Preview](https://devforum.roblox.com/t/luau-native-code-generation-preview-studio-beta/2572587)
- Typical speedup 1.5x–2.5x for compute-intensive code (secondary source, no primary cited). — [Wikipedia: Luau](https://en.wikipedia.org/wiki/Luau_(programming_language))
- Parallel Luau: parallel phase can read but not write DataModel (property writes, instance creation, reparenting error); `task.desynchronize`/`ConnectParallel` require the script to be under an Actor; scripts in the same Actor run serially — parallelism only across multiple Actors. — [Parallel Luau docs](https://create.roblox.com/docs/scripting/multithreading); [Parallel Luau and Actors guide](https://simplified.media/guides/parallel-luau-actors); [Question About Parallel Lua…](https://devforum.roblox.com/t/question-about-parallel-lua-script-actor-parenting-and-parallel-not-helping-optimization/3173285)
- Sync/desync switching has measurable overhead; pattern: one desynchronize → whole batch → one synchronize → one bulk apply. — [Parallel Luau and Actors guide](https://simplified.media/guides/parallel-luau-actors); [Parrallel lua is just as slow as serial lua](https://devforum.roblox.com/t/parrallel-lua-is-just-as-slow-as-serial-lua/2223357)
- Reported: `task.wait()` outside top scope in parallel context reverts to serial (single-user observation). — [Using task.wait() inside parallel scripts reverts to serial](https://devforum.roblox.com/t/using-taskwait-inside-parallel-scripts-reverts-to-serial-execution/2922018)
- Community demand for better Parallel Luau technical docs (pitfalls poorly documented). — [Parallel Luau needs better technical documentation](https://devforum.roblox.com/t/parallel-luau-needs-better-technical-documentation/3548312)

### Inferences
- Skill rule: for >~30 NPCs, don't use server Humanoids that move every frame; use server data + client visuals. For moving many parts use one `workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged/FireNoEvents)` call; for rigged visuals prefer animating `Transform`/bones over moving parts.
- Use `--!native` on server modules with hot numeric loops (pathing math, serialization, simulation), with strict type annotations; don't expect gains in API-bound code.
- Parallel Luau is worth it only for heavy read-only computation (raycasts, pathfinding math, terrain gen) sharded across many Actors.

### Gaps
- No sourced numbers this session for: Heartbeat per-frame budget, PathfindingService cost, collision group costs, Touched vs `GetPartBoundsInBox`/`GetPartsInPart` cost, PartCache benchmarks, CollectionService registry patterns, physics throttling (`PhysicsSteppingMethod` adaptive).
- **[background, unverified]**: 60 FPS frame = 16.67 ms; server Heartbeat should stay well under that; spatial queries with `OverlapParams` + collision groups are preferred over `Touched` for hitboxes; PartCache (Fractality) avoids Instance.new/Destroy churn by moving parts far away (CFrame) instead of reparenting; anchoring static parts eliminates physics cost; `CanQuery/CanTouch/CanCollide=false` on decoration reduces broadphase work.

## 3. Client performance: draw calls, triangles, memory on mobile, StreamingEnabled, UI, particles/lights, LOD

### Takeaway
Staff-recommended scene budget is ~100 draw calls / ~150k triangles average view (≤500k triangles in scene); every unique asset is a draw call and each ParticleEmitter is its own draw call. Low-end mobile crashes when Roblox's usable memory (~800 MB on a 2 GB phone, anecdotal) is exceeded; StreamingEnabled is the primary mitigation. UI relayouts (UIListLayout + AutomaticSize, tweening sizes) are a measurable CPU cost.

### Cited Findings
- Average view ~100 scene draw calls and ~150k triangles; suggested 500,000-triangle "in scene" budget; per-zone budget 40,000 triangles and 40 draw calls (with 8 zones in view). — [Roblox Staff post](https://devforum.roblox.com/t/real-world-building-and-scripting-optimization-for-roblox/3127146)
- "Every unique asset in your game represents a draw call on the GPU." — [Optimize your game (Roblox docs, env-art curriculum)](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/optimize-your-experience)
- Identical meshes with identical SurfaceAppearances consolidate into one draw call (instancing). — [HyperDevs polygon limits guide](https://hyperdevs.app/guides/roblox-polygon-limits/) (third-party)
- "Particle emitters are evil for draw calls — each one counts as 1 draw call even if they use the same texture." — [Roblox Optimization Guide – Memory, Draw Calls, Network](https://devforum.roblox.com/t/tutorial-roblox-optimization-guide-memory-draw-calls-and-network-tips/3881861)
- Memory: 2 GB phone, ~800 MB usable by Roblox; crashes mid-game when hit (anecdote). Crashes most frequent on Android/iOS; streaming can raise memory faster than it clears on slow devices. — [Roblox game crashes for mobile users?](https://devforum.roblox.com/t/roblox-game-crashes-for-mobile-users/472652); [Streaming Enabled can run over memory management](https://devforum.roblox.com/t/streaming-enabled-can-run-over-memory-management-to-crash-client/3305729); [Increase in memory causing crashing on mobile](https://devforum.roblox.com/t/increase-in-memory-causing-crashing-on-mobile-devices/2805203)
- 32-bit client: StreamingEnabled didn't stream out when memory limit reached (old bug). — [StreamingEnabled does not stream out… 32 bit](https://devforum.roblox.com/t/streamingenabled-does-not-stream-out-content-if-memory-limit-for-32-bit-client-is-reached/1619527)
- StreamingEnabled reduces memory and load times on low-end; tune StreamingMinRadius/StreamingTargetRadius (no recommended values given); with streaming, parts outside radius don't exist on client → `WaitForChild`/streaming-aware code mandatory. — [Kitsblox advanced optimization](https://kitsblox.com/blog/roblox-performance-optimization-advanced) (third-party)
- UI: AutomaticSize "is made for use primarily with offset" (staff); constraints (UISizeConstraint/UIAspectRatioConstraint) override layouts; 30–40 objects in a ScrollingFrame with AutomaticCanvasSize can accumulate size error; workaround: set CanvasSize from `UIListLayout.AbsoluteContentSize`. — [Size modifiers and constraints docs](https://create.roblox.com/docs/building-and-visuals/ui/automatic-sizing); [AutomaticSize with UIListLayouts is completely broken](https://devforum.roblox.com/t/automaticsize-with-uilistlayouts-is-completely-broken/3630449); [AutoCanvasSize padding bug](https://devforum.roblox.com/t/scrollingframeautocanvassize-does-not-take-listlayout-or-gridlayout-padding-size-into-account-properly/2928640)
- Tweening/resizing children of layouts triggers full relayouts ("UpdateUILayouts gives huge performance impact"); staff closed as feature request (still behavior). — [UpdateUILayouts gives huge performance impact](https://devforum.roblox.com/t/updateuilayouts-gives-huge-performance-impact/4064226)

### Inferences
- Skill rules: reuse identical MeshParts/textures (instancing), limit ParticleEmitters and merge effects, avoid tweening `Size` on items inside UIListLayout every frame (tween a UIScale on a non-layout wrapper or use `Position` on an absolute container), keep AutomaticSize to offset-based leaves, and enable StreamingEnabled for anything beyond a small map.

### Gaps
- No sourced numbers for CanvasGroup memory, texture memory per resolution, light/shadow costs, RenderFidelity, `ModelLevelOfDetail`, `ModelStreamingMode` (Atomic/Persistent/PersistentPerPlayer/Nonatomic), `StreamingIntegrityMode`, `StreamingTargetRadius` defaults.
- **[background, unverified]**: CanvasGroup renders to an offscreen texture (memory scales with pixel size; avoid many or full-screen ones on mobile); `TextScaled` and frequent `TextBounds` reads trigger text layout; shadows from many PointLights/SpotLights (Shadows=true) are expensive on Future lighting; `RenderFidelity=Automatic` enables mesh LOD; `ModelLevelOfDetail=StreamingMesh` shows imposter meshes for streamed-out models; default StreamingTargetRadius 1024 studs, StreamingMinRadius 64.
- No official mobile memory ceiling found.

## 4. Memory leaks and profiling tools

### Takeaway
The dominant leak is undisconnected connections and per-player tables never cleared on PlayerRemoving; detect via Developer Console → Memory → LuaHeap/Place memory climbing without dropping.

### Cited Findings
- Undisconnected connections are a common leak; audit by searching `:Connect` / `:ConnectParallel`. — [Connecting events without disconnecting them…](https://devforum.roblox.com/t/connecting-events-without-disconnecting-them-is-probably-the-most-common-memory-leak-nobody-talks-about/4525277); [Huge memory leak prevention](https://devforum.roblox.com/t/huge-memory-leak-prevention-for-everyone-or-most-people-atleast/3099605)
- `Destroy()` disconnects an instance's events, but a Player only parented to nil keeps connections (e.g., CharacterAdded) alive; reports conflict on whether Roblox always destroys Player on leave. Fix: store connections per player and disconnect + nil the table entry in PlayerRemoving; or defer-destroy player/character in removing events. — [Question about Memory Leak](https://devforum.roblox.com/t/question-about-memory-leak/2412627); [PSA: Connections can memory leak Instances!](https://devforum.roblox.com/t/psa-connections-can-memory-leak-instances/90082?page=3); [Does this kill old connections…](https://devforum.roblox.com/t/does-this-kill-old-connections-and-prevent-memory-leaks/3909496)
- Detection: Developer Console → Memory → Place memory → LuaHeap; leak = continuously rising, never released. Setting a disconnected connection to nil doesn't immediately free memory (GC lag). — [Tracking memory leaks](https://devforum.roblox.com/t/tracking-memory-leaks/3007337); [Trying to understand memory leaks](https://devforum.roblox.com/t/trying-to-understand-memory-leaks-here/3042995?page=2)
- Engine-side leak report: server network/raknet memory leak thread exists (engine bug, not dev code). — [Server network/raknet Memory Leak?](https://devforum.roblox.com/t/server-networkraknet-memory-leak/2388071?page=3)

### Inferences
- Skill rule: every `:Connect` in a per-player/per-object scope must have an owner (Trove/Maid/Janitor or a connections table) cleaned on PlayerRemoving/Destroying; every `tbl[player]` must be nil'd on PlayerRemoving; never spawn infinite `while true do` loops per object without an exit condition tied to the object's lifetime.

### Gaps
- No sourced tips this session for MicroProfiler (Ctrl+F6, frame-pause, labels via `debug.profilebegin/profileend`) or Script Profiler — these are **[background, unverified]**.

## 5. Concrete-number cheat sheet (consolidated)

### Takeaway
Numbers a skill can enforce; all carry the source caveats above.

### Cited Findings
- Frame budget 16.67 ms at 60 FPS — standard arithmetic (1000/60).
- Client receive soft cap ~50 KB/s; physics throttling >40 KB/s; 0.4–0.9 KB/s per moving physics assembly; ~40–60 moving assemblies safe budget. — [Roblox Staff post](https://devforum.roblox.com/t/real-world-building-and-scripting-optimization-for-roblox/3127146)
- Humanoid NPC bandwidth ~0.8 KB/s each (≈4 KB/s for 5, ≈160 KB/s for 500 → ~0.32 KB/s each at scale). — [Humanoid/NPC threads](https://devforum.roblox.com/t/handle-100-humanoids-npc/2648769)
- RemoteEvent ~9 B overhead/fire; buffer ~9 B overhead. — [ByteNet thread](https://devforum.roblox.com/t/bytenet-advanced-networking-library-w-buffer-serialization-strict-luau-absurd-optimization-and-rbxts-support-043/2733365?page=4)
- UnreliableRemoteEvent payload 900 B (docs) / 1000 B (later release note). — [Docs](https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent); [Mirror](https://robloxapi.github.io/ref-temp/class/UnreliableRemoteEvent.html)
- Scene ~100 draw calls / ~150k tris average view; ≤500k tris in scene. — [Roblox Staff post](https://devforum.roblox.com/t/real-world-building-and-scripting-optimization-for-roblox/3127146)
- `--!native` ~1.5–2.5x on numeric code. — [Wikipedia: Luau](https://en.wikipedia.org/wiki/Luau_(programming_language))
- ~800 MB usable on a 2 GB phone (anecdotal). — [Roblox game crashes for mobile users?](https://devforum.roblox.com/t/roblox-game-crashes-for-mobile-users/472652)
- Entity snapshot rate for TD enemies: every 10–20 Heartbeats (~3–6 Hz). — [Tower Defense Enemy Movement](https://devforum.roblox.com/t/tower-defense-enemy-movement/1930853)

### Inferences
- A per-client custom networking budget of ~10–20 KB/s for gameplay traffic plus streaming/physics is a conservative pro target.

### Gaps
- Recommended max remote calls/sec has no official figure found; RemoteEvent throttling queue limits are undocumented in sources reached.
- Official "performance-optimization/improve|identify|design" pages could not be fetched; their contents should be checked once create.roblox.com is reachable.
