# Debugging & Testing

## Contents
1. Reading Output errors
2. Common errors → causes → fixes
3. "It works in Studio but not in game"
4. Systematic debugging method
5. Testing in Studio
6. Automated tests (optional toolchain)
7. Logging conventions

---

## 1. Reading Output errors

```
ServerScriptService.Services.ShopService:42: attempt to index nil with 'Coins'
Stack Begin
Script 'ServerScriptService.Services.ShopService', Line 42 - function purchase
Script 'ServerScriptService.Main', Line 18
Stack End
```

- Path + line = where it broke. The value that was nil is the thing *before* `.Coins` on that line.
- Red = error (thread stopped). Orange = warning. Blue = info.
- "Infinite yield possible on 'X:WaitForChild("Y")'" = Y never appeared under X — wrong name, wrong parent, created only on server/client, or streamed out.

## 2. Common errors

| Error message | Typical cause | Fix |
|---|---|---|
| `attempt to index nil with 'X'` | `FindFirstChild`/`Character`/data not loaded returned nil | Guard; wait for the right signal; check name/location |
| `X is not a valid member of Y "Path"` | Wrong name/case, object not created yet, client can't see server-only object | `WaitForChild` on client; check container replication |
| `Infinite yield possible on ...` | See above | Fix path; add timeout and handle nil |
| `attempt to call a nil value (method 'X')` | Typo, deprecated/removed method, wrong object type | Check API; correct class |
| `attempt to perform arithmetic (add) on nil and number` | Missing data field | Reconcile data with template |
| `attempt to compare number <= nil` | Same | Same |
| `Unable to cast value to Object` | Passed wrong type to API | Check argument types |
| `invalid argument #3 to 'clamp' (max must be greater than or equal to min)` | Dynamic bounds swapped | Validate bounds |
| `invalid order function for sorting` | Comparator uses `<=` or is inconsistent | Strict `<` |
| `DataStore request was added to queue...` | Too many writes per key | Save less often; batch |
| `502: API Services rejected request` / `Studio access to APIs is not allowed` | Studio API access disabled | Game Settings → Security → Enable Studio Access to API Services |
| `HTTP 403 (Forbidden)` on HttpService | HTTP requests disabled | Game Settings → Security → Allow HTTP Requests |
| `LoadAnimation requires an Animator object` / animation not playing for others | Loaded on Humanoid or wrong side; animation not owned by the experience owner/group | Use Animator; publish animation under the same owner as the experience |
| `Sound failed to load` / silent asset | Asset not permitted for this experience | Use audio you own or that's public/permitted for the experience |
| `Players.X.PlayerGui.Y: ... ` errors after death | `ResetOnSpawn = true` destroyed UI | `ResetOnSpawn = false` |
| `Callbacks cannot yield` / `attempt to yield across metamethod/C-call boundary` | Yielding inside callbacks that don't allow it | Move yield out; use `task.spawn` |
| `Script timeout: exhausted allowed execution time` | Infinite loop without yield | Add `task.wait` / fix loop condition |
| `Maximum event re-entrancy depth exceeded` | Event handler triggers itself (e.g. Changed → set property) | Guard flag; compare before set |

## 3. Studio vs live differences

- Studio Play Solo has ~0 latency and one player; bugs from race conditions and replication appear live. Use **Start Server + 2–3 Players** and the network simulator (Studio settings → Network → Incoming Replication Lag).
- `game.JobId` is `""` in Studio.
- DataStores need API access in Studio.
- `RunService:IsStudio()` branches can hide production bugs — keep them minimal.
- Published place must be **published** for asset permission and DataStore behavior to match.
- Streaming behavior differs if `StreamingEnabled` was toggled — test with the live setting.

## 4. Systematic method

1. Reproduce reliably (exact steps).
2. Read the full error and stack; open the line.
3. Form one hypothesis; add targeted `print`/`warn` with context (`warn("[Shop] coins before", coins)`), or breakpoints (Studio debugger supports breakpoints & watch on server and client).
4. Fix the cause, not the symptom (don't wrap everything in `pcall` to hide errors).
5. Remove debug prints; add a guard/test so it doesn't regress.

When the user pastes broken code, Cluau: identifies the root cause in one sentence, lists any other real bugs found (security, leaks, deprecated APIs) briefly, then gives fixed code.

## 5. Testing in Studio — checklist per feature

- [ ] Play Solo basic path.
- [ ] Start Server with 2+ players: both see correct state; actions by one don't break the other.
- [ ] Die/respawn during the action.
- [ ] Leave during the action (other player's view + data after rejoin).
- [ ] Spam the button / remote (exploit simulation via a temporary test LocalScript firing the remote 100× with bad args — delete after).
- [ ] Mobile emulator (Test → Device) portrait/landscape; gamepad (Studio emulates via connected controller).
- [ ] Network lag simulation.

## 6. Automated tests (optional)

- **TestEZ**-style or **Jest-Lua** (`jsdotlua/jest-lua`) for pure modules; run in Studio via a test runner script or with **Lune** / **run-in-roblox** in CI.
- Keep game logic in pure functions (no instance access) where possible so it can be unit-tested: damage formulas, economy math, inventory operations, validation.
- Lint: **Selene** (`selene.toml` with `std = "roblox"`), format: **StyLua**, types: **luau-lsp analyze** with Roblox definitions.
- This skill's `scripts/luau_lint.py` catches deprecated/unsafe patterns without any install.

## 7. Logging

- Prefix with system name: `[DataService]`, `[Shop]`.
- `print` for development info (remove or gate behind a `DEBUG` flag), `warn` for recoverable problems, `error` for programmer errors.
- Never log other players' private data or full DataStore payloads in live servers.
