# Data Persistence — Never Lose, Never Duplicate

## Contents
1. Decision: ProfileStore vs custom
2. Data shape & versioning
3. The session-lock algorithm (custom UpdateAsync)
4. Load / autosave / leave / shutdown lifecycle
5. Budgets, limits, retries
6. Leaderboards (OrderedDataStore)
7. Cross-server: MessagingService & MemoryStoreService
8. Testing data in Studio
9. Failure-mode table

---

## 1. Decision

| Situation | Choice |
|---|---|
| Typical game, wants battle-tested locking | **ProfileStore** (by loleris; successor to ProfileService). Vendor the module into `ServerScriptService/Packages`. |
| User wants zero dependencies or to learn | `templates/server/DataService.luau` — custom UpdateAsync session lock |
| Simple global value (server config, event toggle) | Plain DataStore `GetAsync` with cache + `UpdateAsync` writes |
| Ranking | OrderedDataStore (numbers only) |
| Ephemeral cross-server (queues, live counts) | MemoryStoreService |

Never recommend DataStore2 or ProfileService for new projects; mention ProfileStore instead. Never write player progress with plain `SetAsync` in a loop.

### ProfileStore usage sketch

```lua
--!strict
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ProfileStore = require(ServerScriptService.Packages.ProfileStore)

local TEMPLATE = {
	Coins = 0,
	Inventory = {},
	Version = 1,
}

local PlayerStore = ProfileStore.New("PlayerData_v1", TEMPLATE)
local profiles: { [Player]: any } = {}

local function onPlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		player:Kick("Your data could not be loaded. Please rejoin.")
		return
	end
	profile:AddUserId(player.UserId) -- GDPR
	profile:Reconcile()
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your data was loaded on another server. Please rejoin.")
	end)
	if player.Parent == Players then
		profiles[player] = profile
	else
		profile:EndSession()
	end
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	local profile = profiles[player]
	if profile then
		profile:EndSession()
	end
end)
```

Verify the exact ProfileStore API against the version the user installs (method names above match the official README as of its 2024+ releases).

## 2. Data shape & versioning

```lua
local TEMPLATE = table.freeze({
	Version = 3,
	Coins = 0,
	Gems = 0,
	Level = 1,
	Xp = 0,
	Inventory = {} :: { [string]: number },   -- itemId -> count
	Equipped = {} :: { [string]: string },    -- slot -> itemId
	Settings = { Music = 0.6, Sfx = 0.8, ReducedMotion = false },
	ProcessedReceipts = {} :: { [string]: number }, -- PurchaseId -> os.time()
	Stats = { JoinCount = 0, PlaytimeSeconds = 0 },
})
```

- Keep it JSON-compatible: strings, numbers, booleans, arrays, string-keyed dictionaries. **No mixed tables** (array + dict in one), no number keys stored as sparse arrays (they get serialized weirdly) — use string keys (`tostring(id)`).
- No Instances, Vector3, CFrame, Color3 — serialize (`{x, y, z}` or hex strings).
- `Version` + ordered migration functions `MIGRATIONS[n](data)` that upgrade n → n+1.
- Reconcile: deep-fill missing keys from template; never overwrite existing keys.
- Cap unbounded growth (receipts history: keep last ~100 / last 30 days; logs not in player data).

## 3. Session-lock algorithm (custom)

Stored value:

```lua
{
	Data = { ... },          -- the profile
	Lock = { JobId = "...", Time = 1700000000 } | nil,
}
```

Load (UpdateAsync):
1. If no record → create `{ Data = deepCopy(TEMPLATE), Lock = { JobId = game.JobId, Time = os.time() } }`.
2. If `Lock` exists, `Lock.JobId ~= game.JobId`, and `os.time() - Lock.Time < LOCK_EXPIRE (e.g. 30 min)` → **return nil** (abort write) and report "locked". Retry a few times with waits (the other server may be saving on leave). After ~5 attempts, either steal the lock if it's stale or kick the player.
3. Otherwise set `Lock = { JobId = game.JobId, Time = os.time() }`, return record.

Save (UpdateAsync):
1. If stored `Lock.JobId ~= game.JobId` → **abort** (another server owns it; this session lost the lock).
2. Write `Data`, refresh `Lock.Time`. On release (leave), set `Lock = nil`.

In Studio `game.JobId` is an empty string — that still works because it's consistent per session.

`UpdateAsync` callbacks must be **pure and fast**: no yielding, no side effects other than computing the return value, because Roblox may call them more than once.

## 4. Lifecycle

- **Join**: load with retries + backoff (1 s, 2 s, 4 s...). On final failure: `player:Kick("...")`. Don't let them play with defaults.
- **Ready gate**: other services must wait for data (`DataService:WaitForProfile(player)` / signal) before granting rewards or reading inventory. Client UI shows a loading state until the first snapshot arrives.
- **Autosave**: every 60–180 s per player, staggered (not all at once), only if dirty.
- **Leave**: `PlayerRemoving` → final save + release lock. Remove from memory *after* save completes.
- **Shutdown**: `game:BindToClose(function() ... end)` → save all in parallel (`task.spawn` each + wait for completion counter), total ≤ ~25 s. In Studio, saves are optional; common pattern: `if RunService:IsStudio() then return end` only if the user prefers no Studio writes.
- **Teleport**: save before `TeleportAsync`, release lock on PlayerRemoving as usual; the destination server's lock retry loop handles the overlap.

## 5. Budgets, limits, retries

- Per-key write cooldown: ~6 s between writes to the same key. Batch changes in memory.
- Budgets scale with player count; check `DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)` before non-critical writes.
- Value size: 4 MB max per key. Keep player data well under 100 KB.
- Key name ≤ 50 chars; DataStore name ≤ 50 chars.
- Errors to retry: throttling and 5xx-like internal errors. Don't retry forever; don't retry inside a tight loop without `task.wait`.
- `UpdateAsync` returning `nil` from the callback cancels the write (useful for lock checks).

## 6. Leaderboards

- `DataStoreService:GetOrderedDataStore("Wins_AllTime")`; values must be integers.
- Write on a slow cadence (on leave + every few minutes), not on every win.
- Read with `GetSortedAsync(false, 50)` → `:GetCurrentPage()` every 60–120 s on the server; push results to a SurfaceGui/UI via attributes or a remote.
- Resolve names with `Players:GetNameFromUserIdAsync` (pcall, cache) or `UserService:GetUserInfosByUserIdsAsync` in batches.
- Weekly boards: key the store by week number (`"Wins_" .. weekIndex`).

## 7. Cross-server

- **MessagingService**: `PublishAsync(topic, msg)` / `SubscribeAsync(topic, cb)`. Fire-and-forget, ~1 KB messages, no delivery guarantee. Good for global announcements, shutdown notices.
- **MemoryStoreService**: `GetSortedMap`, `GetQueue`, `GetHashMap`. Data expires (max 45 days). Good for matchmaking queues, cross-server trade locks, live leaderboards, rate limits across servers. Use `UpdateAsync` for atomic changes.

## 8. Testing in Studio

- Game Settings → Security → **Enable Studio Access to API Services** (otherwise DataStore calls error in Studio).
- Use a separate DataStore name for testing (`PlayerData_dev`) via a config flag, or use a separate test place in the same experience.
- Test: join, earn, leave, rejoin; two-player Start Server; kill the server (Stop) mid-session; spam purchase remote.

## 9. Failure modes

| Failure | Symptom | Prevention |
|---|---|---|
| No lock, two servers | Items duplicated or lost after server hop | Session lock |
| Load failed, played with defaults, saved | Player "wiped" | Kick on load failure; never save unloaded profiles |
| Save on leave not awaited at shutdown | Last minutes lost | BindToClose waits for all saves |
| SetAsync of stale copy | Rollback | UpdateAsync + lock |
| Callback yields in UpdateAsync | Errors/duplicate writes | Pure callbacks |
| Mixed/sparse tables | Data silently malformed | String keys, validate shape |
| Saving every coin | Throttling, queue warnings in Output | Mark dirty, autosave interval |
