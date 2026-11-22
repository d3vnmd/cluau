# Modern Luau — Language, Types, Style

This is the coding standard Cluau follows. It targets current Roblox Luau (strict type checking, new type solver era). When in doubt, choose the simpler, well-established construct.

## Contents
1. File header & module shape
2. Types
3. Control flow & syntax features
4. Tables & standard library
5. Instances & properties
6. Concurrency (task library, yielding, coroutines)
7. Error handling
8. Naming & formatting
9. Things that look clever but are wrong

---

## 1. File header & module shape

```lua
--!strict
-- ShopService: validates and executes purchases with in-game currency.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local ShopService = {}

-- private state
local purchaseLocks: { [Player]: boolean } = {}

-- private helpers
local function isLocked(player: Player): boolean
	return purchaseLocks[player] == true
end

-- public API
function ShopService.Init()
	-- create remotes, read config; no yielding on other services here
end

function ShopService.Start()
	-- connect events; may depend on other services having Init'ed
end

return ShopService
```

- One responsibility per module. A ModuleScript returns exactly one table (or one function).
- `Init` must not yield (keeps boot order deterministic). `Start` may.
- Use `script.Parent`-relative `require` inside a package; absolute service paths across packages.
- `require` at the top of the file, not inside hot functions.
- Avoid circular requires. If A needs B and B needs A, extract the shared part into C, or pass dependencies in `Start`.

## 2. Types

```lua
--!strict
export type ItemId = string

export type Item = {
	id: ItemId,
	displayName: string,
	price: number,
	rarity: "Common" | "Rare" | "Epic" | "Legendary", -- singleton string union
	icon: string?, -- optional
}

export type Inventory = { [ItemId]: number } -- map
export type ItemList = { Item } -- array

type Callback = (player: Player, amount: number) -> ()
```

- `unknown` for anything that crosses a trust boundary (Remote arguments). Narrow with `typeof`/`type` before use.
- `any` only when interfacing with genuinely dynamic code; never as a shortcut to silence errors.
- Casting: `value :: Type` only after you've checked it. `(x :: any) :: T` is a smell.
- Instance types: `local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?` then nil-check.
- `typeof(x) == "Instance"` then `x:IsA("BasePart")` to narrow instances.
- OOP class pattern with types:

```lua
--!strict
local Timer = {}
Timer.__index = Timer

export type Timer = typeof(setmetatable({} :: {
	duration: number,
	startedAt: number?,
}, Timer))

function Timer.new(duration: number): Timer
	return setmetatable({ duration = duration, startedAt = nil }, Timer)
end

function Timer.start(self: Timer)
	self.startedAt = os.clock()
end

function Timer.remaining(self: Timer): number
	local startedAt = self.startedAt
	if startedAt == nil then
		return self.duration
	end
	return math.max(0, self.duration - (os.clock() - startedAt))
end

return Timer
```

## 3. Control flow & syntax features

- Generalized iteration: `for key, value in dictionary do`. `ipairs` when you want array semantics that stop at the first nil.
- `continue` inside loops.
- Compound assignment: `+=`, `-=`, `*=`, `/=`, `//=`, `%=`, `^=`, `..=`.
- If-expressions: `local label = if count == 1 then "item" else "items"`.
- String interpolation: `` `{player.Name} has {coins} coins` `` (use `string.format("%.1f", x)` for number formatting).
- Floor division `//`.
- Numeric literal separators: `1_000_000`. Hex `0xFF`, binary `0b1010`.
- `type(x)` for Lua types; `typeof(x)` for Roblox types (`Vector3`, `CFrame`, `Instance`, `EnumItem`...). **Use `typeof` for Remote validation.**

## 4. Tables & standard library

- `table.create(n, value)` to preallocate arrays; `table.clear(t)` to reuse.
- `table.clone(t)` is **shallow** — write a `deepCopy` for nested templates.
- `table.freeze(t)` for config; freezing is shallow — freeze nested tables too.
- `table.find(array, value)` for small arrays; use a set `{ [value] = true }` for frequent lookups.
- `table.insert`, `table.remove` (O(n) in the middle — swap-remove for unordered arrays), `table.sort` (comparator must be strict `<`, not `<=`, or it can error "invalid order function").
- `#t` only for proper arrays (no holes).
- `math.clamp(x, min, max)` errors if `min > max` — guard dynamic bounds.
- `math.round`, `math.sign`, `math.noise`.
- `string.split`, `string.format`, `string.rep`, `utf8.len` for user text length (not `#`).
- `buffer` library for compact binary serialization when bandwidth matters.
- `bit32` for bit ops.
- `Random.new(seed)`: `:NextInteger(a, b)`, `:NextNumber(a, b)`, `:Shuffle(t)`.

## 5. Instances & properties

```lua
local part = Instance.new("Part")
part.Name = "Coin"
part.Size = Vector3.new(2, 2, 0.4)
part.Anchored = true
part.CanCollide = false
part.Material = Enum.Material.Neon
part.Color = Color3.fromRGB(255, 196, 56)
part:SetAttribute("Value", 10)
part:AddTag("Coin") -- CollectionService tag
part.Parent = workspace.Coins -- Parent LAST
```

- `FindFirstChild(name)` returns nil; `WaitForChild(name, timeout)` yields (client side for replicated/streamed content). `WaitForChild` without timeout warns after 5 s "Infinite yield possible" — that warning means a real bug (wrong name/location).
- On the server, objects you placed in Studio exist at start; `WaitForChild` is usually unnecessary except for things created at runtime.
- `FindFirstChildOfClass`, `FindFirstChildWhichIsA`, `FindFirstAncestorOfClass`.
- `GetPropertyChangedSignal("Prop")` for one property; `.Changed` on ValueBase objects gives the new value.
- Attributes: `SetAttribute`, `GetAttribute`, `GetAttributeChangedSignal`. Supported types: string, number, boolean, UDim, UDim2, BrickColor, Color3, Vector2, Vector3, CFrame, NumberSequence, ColorSequence, NumberRange, Rect, Font, EnumItem. Not tables or Instances.
- Tags: `inst:AddTag`, `inst:RemoveTag`, `inst:HasTag`, `CollectionService:GetTagged`, `GetInstanceAddedSignal`, `GetInstanceRemovedSignal`.
- `Instance:Destroy()` disconnects the instance's own events and locks Parent. Clean your *external* references too.
- `Clone()` doesn't clone `Archivable = false` instances.
- Character access: `player.Character or player.CharacterAdded:Wait()`, then `character:WaitForChild("Humanoid")`. Re-bind on every `CharacterAdded`.

## 6. Concurrency

- `task.spawn(fn, ...)` — run now on a new thread (resumes immediately until first yield).
- `task.defer(fn, ...)` — run at the end of the current resumption cycle.
- `task.delay(seconds, fn, ...)` — run later. Returns a thread; `task.cancel(thread)` to cancel.
- `task.wait(seconds)` — yields at least one frame; returns elapsed time. Never use bare `wait()`.
- `RunService.Heartbeat:Wait()` to wait exactly one frame on the frame loop.
- Long-running loops always have an exit condition:

```lua
local running = true
task.spawn(function()
	while running do
		-- work
		task.wait(1)
	end
end)
-- later: running = false
```

- Avoid race conditions with per-player locks for yielding operations:

```lua
local busy: { [Player]: true } = {}
local function withLock(player: Player, fn: () -> ())
	if busy[player] then return end
	busy[player] = true
	local ok, err = pcall(fn)
	busy[player] = nil
	if not ok then warn(err) end
end
```

- Yielding inside `ProcessReceipt`, `BindToClose`, and `OnServerInvoke` is allowed but must be bounded.
- Don't yield inside `__index`/metamethods or `table.sort` comparators.

## 7. Error handling

```lua
local function withRetries<T>(label: string, attempts: number, fn: () -> T): (boolean, T | string)
	local lastErr: string = "unknown"
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = tostring(result)
		warn(`[{label}] attempt {attempt}/{attempts} failed: {lastErr}`)
		if attempt < attempts then
			task.wait(2 ^ (attempt - 1)) -- 1, 2, 4, 8 ...
		end
	end
	return false, lastErr
end
```

- `pcall` every `*Async` network call (DataStore, MarketplaceService, BadgeService, HttpService, TeleportService, TextService, Players:GetUserIdFromNameAsync...).
- `xpcall(fn, debug.traceback)` when you need a stack trace.
- `error("message", 2)` to blame the caller for bad arguments in public module APIs.
- `assert` for programmer errors (bad config at boot), not for client input — client input should be silently rejected, not crash a thread.
- Never swallow errors silently in core systems: `warn` with context.

## 8. Naming & formatting

- Tabs, 120-column soft limit (StyLua defaults; `assets/project/stylua.toml`).
- `PascalCase`: modules, classes, types, Instances' `Name`.
- `camelCase`: locals, functions, methods, fields.
- `UPPER_SNAKE_CASE`: constants.
- Booleans read as questions: `isAlive`, `hasPass`, `canBuy`.
- Events/signals: past tense `CoinsChanged`, `RoundEnded`.
- Remote names: verb-noun `RequestPurchase`, `EquipItem`; server→client `InventoryUpdated`.
- File extensions in Rojo: `.server.luau` (Script), `.client.luau` (LocalScript), `.luau` (ModuleScript).

## 9. Things that look clever but are wrong

| Pattern | Problem | Do instead |
|---|---|---|
| `while wait() do` | Deprecated `wait`, hidden throttle, no exit | `while running do ... task.wait(x) end` or events |
| `repeat task.wait() until x` polling | Burns frames | Use the signal that makes `x` true |
| `script.Parent.Touched:Connect` copied into 300 parts | Memory, unmaintainable | One script + CollectionService tag |
| `game.Players.LocalPlayer` in a Script | nil on server | Only in LocalScripts |
| `player.Character.Humanoid.Health` without checks | Character can be nil/respawning | Guard every step |
| `Instance.new("Part", workspace)` then set 10 props | Replicates 10 property changes | Parent last |
| `:FindFirstChild("X").Y` | Errors when nil | Check result first |
| `tostring(number) == "nan"` | Fragile | `x ~= x` is the NaN test |
| Using `_G.PlayerData` | Untyped global, load-order bugs | ModuleScript service |
| `math.random()` for loot with weights done wrong | Biased results | Cumulative weight table + `Random:NextNumber(0, total)` |
| `string.len(userText) > 50` | Counts bytes, not characters | `utf8.len(userText)` (returns nil on invalid UTF-8 — reject) |
| `table.sort(t, function(a, b) return a <= b end)` | "invalid order function" | Strict `<` |
