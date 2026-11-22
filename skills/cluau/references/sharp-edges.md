# Sharp Edges — The Bugs That Ship

A severity-ranked catalog of the mistakes that actually reach live Roblox games (and that AI assistants make most). Use it two ways: **before writing** a system, scan the rows for its area; **when reviewing** code, cite the ID in each finding. Grow this file from real incidents. (Format inspired by excaldev/ro-engineer's SE catalog, MIT.)

Severity: **CRITICAL** = data loss, duplication, money, or full exploit · **HIGH** = exploitable or crash/leak in normal play · **MEDIUM** = lag, wrong behavior in edge cases · **LOW** = maintainability.

| ID | Sev | Area | Symptom | Cause | Fix | Lint |
|---|---|---|---|---|---|---|
| CX-01 | CRITICAL | Remotes | Infinite coins / items | Server trusts amount/price/reward from the client | Client sends intent; server reads cost and reward from server config | — |
| CX-02 | CRITICAL | Economy | Items duplicated by spamming | A yield (`task.wait`, DataStore, Marketplace, `InvokeServer`) between "check" and "mutate" | Check → mutate in one synchronous block; per-player/per-trade busy lock around anything that must yield | — |
| CX-03 | CRITICAL | Data | Progress rolled back / duped after server hop | No session lock; `SetAsync` of a stale copy | `UpdateAsync` session lock or ProfileStore; never `SetAsync` player data | CL060 |
| CX-04 | CRITICAL | Data | Player "wiped" | Load failed, player played on defaults, defaults saved | On final load failure: kick, never save, block purchases | — |
| CX-05 | CRITICAL | Purchases | Robux taken, item not given / given twice | Grant outside `ProcessReceipt`, non-idempotent grant, `PurchaseGranted` before save, multiple `ProcessReceipt` assignments | One handler; record `PurchaseId` in the locked profile; save; then `PurchaseGranted` | CL078 |
| CX-06 | CRITICAL | Purchases | Receipt processed on two servers | Same purchase delivered to two servers concurrently | Idempotency via the session-locked profile; only the lock owner grants | — |
| CX-07 | CRITICAL | Security | Backdoor / admin takeover | `require(<assetId>)`, `loadstring`, `getfenv`, obfuscated free-model scripts | Vendor and read code; grep inserts; never enable LoadStringEnabled | CL070–072 |
| CX-08 | HIGH | Remotes | Server values become NaN; leaderboards break | `n ~= n` / inf accepted | `Guard.finite` before any math | — |
| CX-09 | HIGH | Remotes | Server thread hangs forever | `RemoteFunction:InvokeClient` | RemoteEvent + server-side timeout state | CL073 |
| CX-10 | HIGH | Interactions | Items collected from across the map | `ProximityPrompt.Triggered` / `ClickDetector.MouseClick` / `Touched` handlers without server distance check (executors can fire them) | Server distance + state check in every handler; spatial queries for authoritative triggers | — |
| CX-11 | HIGH | Networking | Server crash/error on crafted payload | Decoding client `buffer` without bounds; trusting length prefixes | Check `buffer.len` before every read; cap lengths; reject NaN after decode | — |
| CX-12 | HIGH | Remotes | Server CPU spikes, lag for everyone | No rate limit; remote flooding | Token bucket per player per remote + per-action cooldown on server clock | — |
| CX-13 | HIGH | Lifecycle | Memory climbs every round/respawn | Connections never disconnected; per-player tables not cleared on leave | One Trove per lifetime (session/character/round/UI) | — |
| CX-14 | HIGH | Lifecycle | Bugs only for players who joined early | `PlayerAdded` connected after players already joined | Also loop `Players:GetPlayers()` at start | — |
| CX-15 | HIGH | Lifecycle | Last minutes of progress lost on shutdown | No `BindToClose` save, or not waiting for in-flight saves | Save all in parallel and wait (≤ ~25 s) | — |
| CX-16 | HIGH | Streaming | `attempt to index nil` only on live servers / phones | Client assumes workspace instances exist under StreamingEnabled | `WaitForChild` with timeout; tag signals; handle stream-out | — |
| CX-17 | HIGH | UI | HUD/shop disappears or duplicates after death | `ScreenGui.ResetOnSpawn = true` with controllers holding references | `ResetOnSpawn = false` for persistent UI (decide deliberately) | — |
| CX-18 | HIGH | Physics | Exploiters fling/teleport shared objects | Gameplay-critical unanchored parts owned by a client | `SetNetworkOwner(nil)` or Server Authority | — |
| CX-19 | HIGH | Secrets | API key stolen | Secret in ReplicatedStorage/LocalScript/attribute | Secrets Store (`HttpService:GetSecret`) on the server only | — |
| CX-20 | HIGH | Text | Moderation action against the game | Showing unfiltered user text (pet names, signs) | `TextService:FilterStringAsync` → `GetNonChatStringForBroadcastAsync`; on failure show nothing | — |
| CX-21 | MEDIUM | Data | Throttling warnings, queued requests | Saving on every change | Mark dirty; autosave interval; save on leave/shutdown/purchase | — |
| CX-22 | MEDIUM | Data | "Fixed" save shows old data | Reading within GetAsync's 4 s cache after a write | `DataStoreGetOptions.UseCache = false` for verification reads | — |
| CX-23 | MEDIUM | Data | All existing saves "lost" after an update | Changing the DataStore name/key pattern on a live game | Never migrate keys silently; migrate in-record via `Version` | — |
| CX-24 | MEDIUM | Networking | Bandwidth spikes, rubber-banding | Remote fired every frame; per-entity remotes | Batch per tick, quantize, 10–20 Hz for non-critical; `UnreliableRemoteEvent` < 1000 B for cosmetics | — |
| CX-25 | MEDIUM | Networking | One "action" remote with a string switch becomes an attack surface | Generic dispatcher remote | One remote per intent with its own validator and limiter | — |
| CX-26 | MEDIUM | Signals | Works in Studio, flaky live | Code assumes immediate signal handling | Correct under both Immediate and Deferred `SignalBehavior` | — |
| CX-27 | MEDIUM | Lua vs Luau | Runtime "attempt to call nil" | `math.clamp(x, min, max)` with min > max errors; `table.sort` comparator using `<=` | Guard bounds; strict `<` comparators | — |
| CX-28 | MEDIUM | Modules | `require("./X")` returns nothing / errors at start | require-by-string does not wait for the module | Use instance requires with `WaitForChild` for runtime-created modules | — |
| CX-29 | MEDIUM | UI | Blank/black panels on phones, memory spikes | Many/resizing `CanvasGroup`s | CanvasGroup only for short fixed-size fades; destroy after | — |
| CX-30 | MEDIUM | UI | Layout jitter, CPU on resize | Tweening `Size` inside list layouts; AutomaticSize + UIFlexItem unsupported combos | Tween `UIScale`; follow flex limits (< 1000 items) | — |
| CX-31 | MEDIUM | Economy | Inflation, nothing worth buying | Sources with no sinks; unbounded multiplier stacking | Source/sink table; cap/diminish multipliers | — |
| CX-32 | MEDIUM | Pooling | Reused projectiles carry old state | Pool returns objects without reset | Reset every field on release | — |
| CX-33 | LOW | Types | Strict mode "passes" while code is wrong | `:: any` casts to silence errors | Narrow with `typeof`/`IsA`; fix the type | — |
| CX-34 | LOW | Tuning | Every balance change needs a code edit | Hard-coded numbers in logic | Frozen Config / ConfigService for live values | — |
| CX-35 | LOW | Legacy | Deprecated API in new code | Training-data habits (`wait`, `BodyVelocity`, `LoadAnimation` on Humanoid, PhysicsService, pre-Async names) | `deprecated-apis.md` + generated `deprecated-index.md` | CL0xx, CL2xx |

## Review output format (use for every code review)

For each finding: `[ID or new] [severity] file:line — what fails, the concrete scenario that triggers it, the consequence, the specific fix.` No style-only findings (pairs vs ipairs, module shape, "use a framework"). Separate **observed** failures from **hypotheses**. A review never claims runtime success.
