# Performance — Measure, Then Fix

> Last verified: 2026-11-22 against Roblox/creator-docs @ a23352b (docs snapshot 2026-11-21). Re-verify with `tools/verify_api_refs.py`.

## Contents
1. Diagnosis workflow
2. Script performance
3. Physics & parts
4. Rendering & assets
5. Network
6. Memory
7. Parallel Luau
8. Mobile budget

---

## 1. Diagnosis workflow

1. **Reproduce** with realistic player counts (Test → Start Server with 4–8 players; or live server).
2. **Developer Console (F9)**: Memory (by category: PlaceScriptMemory, Instances, PhysicsParts, GraphicsTexture...), Scripts (activity % per script — anything > 3% constant is suspicious), Network (KB/s in/out, per-remote breakdown on server).
3. **MicroProfiler (Ctrl+Alt+F6 / Ctrl+F6)**: pause on a spike, look for wide bars under `Heartbeat`, `Physics`, `Render`. Add labels in your code:
   ```lua
   debug.profilebegin("EnemyAI.update")
   -- ...
   debug.profileend()
   ```
4. **Script Profiler** (Studio, View → Script Profiler) for CPU time by function.
5. Fix the top item, re-measure. Don't micro-optimize code that isn't on the profile.

## 2. Script performance

- **Event-driven over polling.** Replace `while true do task.wait() check() end` with the signal that changes the condition.
- **One loop, many objects**: a single `RunService.Heartbeat` connection iterating a registry of enemies is far cheaper than one connection (or one Script) per enemy.
- **Throttle**: AI decisions at 5–10 Hz, not 60. Use an accumulator: `acc += dt; if acc < 0.1 then return end; acc = 0`.
- Cache lookups: `local humanoid = character:FindFirstChildOfClass("Humanoid")` once per character, not per frame.
- Avoid creating tables/closures/`Vector3`s per frame in hot loops where avoidable; reuse.
- `table.insert` at end is fine; `table.remove(t, 1)` in a big queue is O(n) — use head/tail indices.
- Don't call `:GetDescendants()` per frame. Use CollectionService registries.
- String building in loops: collect parts in a table and `table.concat`.
- Native code generation: `--!native` at the top of a ModuleScript (server, or client where supported) can speed up heavy pure-math modules. Use only for measured hotspots; it doesn't help code that's mostly engine API calls.

## 3. Physics & parts

- Anchor everything that doesn't move.
- `CanCollide = false`, `CanTouch = false`, `CanQuery = false` on decorative parts (each flag reduces physics/query work).
- Prefer fewer, larger parts; use MeshParts with `CollisionFidelity = Box`/`Hull` for decoration; `RenderFidelity = Automatic`.
- Many moving objects: move with `CFrame` on the client (visual) and keep the server's representation simple, or use `workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)`.
- `.Touched` fires many times per contact; debounce per player and prefer spatial queries for zones (`GetPartBoundsInBox` at 5–10 Hz).
- Network ownership: server-owned unanchored parts near players cost server physics; client-owned cost trust. Choose consciously.
- Humanoids are expensive. For large NPC crowds, use simplified rigs, `Humanoid` state disabling (`SetStateEnabled` for unused states), or custom movers; disable `EvaluateStateMachine` when NPC is idle if appropriate.

## 4. Rendering & assets

- Part count & draw calls: reuse identical meshes/materials (instancing).
- `CastShadow = false` on small or interior parts.
- Textures: reasonable resolutions (512–1024 for most), reuse via MaterialVariants.
- Particles: limit `Rate`, `Lifetime`; disable emitters off-screen or far away.
- Lighting: `Future` technology is costly with many lights; limit `PointLight`/`SpotLight` with `Shadows = true`.
- UI: hundreds of frames updating each frame are costly; update text only when value changes; CanvasGroups allocate textures — use sparingly.
- StreamingEnabled with sensible `StreamingTargetRadius` reduces memory on mobile.

## 5. Network

**Hard numbers (2024–2026 sources):**
- Physics replication starts throttling above ~40 KB/s per client (receive counter caps at 50 KB/s). Keep custom traffic ≤ 20–30 KB/s.
- Each moving replicated assembly ≈ 0.4–0.9 KB/s → budget ~40–60 moving assemblies; Humanoids are "baseline heavy" (≈ 160 KB/s for 500 in one measurement).
- RemoteEvent overhead ≈ 9 bytes per fire: 50 entities × 60 Hz ≈ 27 KB/s before payload. Batch per tick.
- `UnreliableRemoteEvent`: payloads > 1000 bytes are dropped (older docs said 900 — stay well below).
- Quantize: orientation as 3×uint8 (~1.4° precision) halved one game's traffic; RTS-style positions as int16.
- > ~30 moving NPCs → keep enemies as plain server tables, replicate spawn/death/hit events, let clients build and move models (TD pattern, `genre-playbooks.md`).
- Moving 1,000 assemblies: `BulkMoveTo` ~6 ms/frame (tuned to 2.5 ms); animating bone/Motor6D `Transform` ~1 ms.


- Every `FireClient`/`FireAllClients` costs bandwidth for the payload and overhead. Batch: collect changes during a frame/interval and send one table.
- Send deltas, not full snapshots, after the initial sync.
- Replicated property changes also cost: changing `Position` on 500 server parts every frame floods the network. Move visual-only things on clients.
- Attributes and ValueObjects replicate on change — don't change them every frame.
- Use `UnreliableRemoteEvent` for high-frequency cosmetic streams; quantize numbers (round to 0.01) to shrink payloads; consider `buffer` for compact encoding.
- Soft budget: aim for < 50 KB/s per player sustained.

## 6. Memory

- Clean per-player tables on `PlayerRemoving`.
- Disconnect connections (Trove), stop tweens (`tween:Cancel()`), destroy instances you create.
- Watch `Instances` count over time — steady growth = leak.
- Don't keep references to destroyed instances in long-lived tables (they can't be GC'd).
- Sounds: `sound:Destroy()` after one-shot playback (or pool); preload important ones with `ContentProvider:PreloadAsync` in the loading screen only.

## 7. Parallel Luau

- Put scripts under an `Actor`. Use `task.desynchronize()` to enter parallel phase, compute, then `task.synchronize()` before writing instance properties.
- Good for: raycasts in bulk, procedural terrain/noise, pathfinding prep, heavy math.
- Communicate between actors with `Actor:SendMessage` / `BindToMessageParallel`, or `SharedTable`.
- Not a fix for bad algorithms or for engine-bound work.

## 8. Mobile budget (low-end phone baseline)

- ~65% of a typical game's players are on Android; ~60% of those devices have 2–4 GB RAM; >50% of devices score 10k–20k Passmark. Test on real low-end phones (the emulator is inaccurate for memory).
- Rendering: comfortable view ≈ 100 draw calls / 150k triangles; ceiling 1,000 draw calls / 1M triangles. Use Scene Analysis (Window → Performance Summary) to find triangle/memory hogs.

- Memory: low-end phones and tablets can crash when client memory climbs into the low gigabytes; keep it as low as practical. Textures and meshes dominate — check the Developer Console Memory tab on a real device.
- Keep active particles and lights modest; test with Studio's device emulator and on a real device.
- UI must remain readable at small physical sizes — see `ui-design-system.md`.
