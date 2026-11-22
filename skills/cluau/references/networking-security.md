# Networking & Security — Server-Authoritative by Default

## Contents
1. Threat model
2. Remote design rules
3. Validation recipes
4. Rate limiting
5. Common feature patterns (shop, combat, pickups, trading, admin)
6. Movement & physics sanity checks
7. Text & user-generated content
8. Free models & backdoors
9. Review checklist

---

## 1. Threat model

An exploiter with a script executor can:

- Fire any RemoteEvent/RemoteFunction with any arguments (wrong types, NaN, huge tables, negative numbers, other players' instances), at any rate.
- Read all client-visible code: LocalScripts, ModuleScripts in ReplicatedStorage/ReplicatedFirst/StarterGui/StarterPlayer, and remote names.
- Modify anything on their client: UI, local values, WalkSpeed, JumpPower, their character's CFrame, unanchored parts they own.
- Delete your client-side anti-cheat.
- Return arbitrary values (or never return) from `OnClientInvoke`.

They **cannot**: run server code, read ServerScriptService/ServerStorage, change server-side variables, or directly change other players' data — unless *your remote lets them*.

So: every remote is a public API exposed to the internet. Design it like one.

## 2. Remote design rules

1. **Intent, not outcome.** Client says `RequestPurchase("Sword")`, not `GiveItem("Sword")` or `SetCoins(9999)`.
2. **Few, well-named remotes** per feature; created by the server at boot (`templates/shared/Net.luau`) so names are a single source of truth.
3. **Server→client**: RemoteEvent `:FireClient` / `:FireAllClients`. Never `RemoteFunction:InvokeClient`.
4. **Client→server request/response**: RemoteFunction `OnServerInvoke` is OK if the handler is fast and validated; it must always return. Or use a RemoteEvent request + RemoteEvent reply.
5. **UnreliableRemoteEvent** only for loss-tolerant cosmetics; payload size limited (~1 KB); ordering not guaranteed.
6. **Payload hygiene**: send ids (strings/numbers), not instances when avoidable. If you accept an Instance argument, verify it is the expected class, is a descendant of the expected container, and is in range.
7. **Responses are hints**: the client UI updates from server-replicated state, not from what the client assumed.

## 3. Validation recipes (see `templates/shared/Guard.luau`)

```lua
local function isFiniteNumber(x: unknown): boolean
	return typeof(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

local function isInteger(x: unknown, min: number, max: number): boolean
	return isFiniteNumber(x) and (x :: number) % 1 == 0 and (x :: number) >= min and (x :: number) <= max
end

local function isShortString(x: unknown, maxLen: number): boolean
	if typeof(x) ~= "string" then return false end
	local len = utf8.len(x)
	return len ~= nil and len <= maxLen
end

local function isEnumMember(x: unknown, allowed: { [string]: any }): boolean
	return typeof(x) == "string" and allowed[x] ~= nil
end

local function isDescendantPart(x: unknown, ancestor: Instance): boolean
	return typeof(x) == "Instance" and x:IsA("BasePart") and x:IsDescendantOf(ancestor)
end
```

Order of checks in a handler: **types → rate → existence → permission/ownership → state (alive? in round? cooldown?) → distance → cost → mutate → replicate.** Reject silently (just `return`) for malformed input; optionally log counts per player for moderation.

## 4. Rate limiting

Token bucket per player per remote (`templates/shared/RateLimiter.luau`): capacity = burst, refill = sustained rate. Clean the player's bucket on `PlayerRemoving`.

Typical budgets:

| Remote | Burst | Per second |
|---|---|---|
| UI purchase | 3 | 1 |
| Equip/unequip | 5 | 3 |
| Weapon fire (with server fire-rate check too) | weapon RPM/60 + 2 | weapon RPM/60 |
| Chat-like text submit | 2 | 0.5 |

Rate limiting is a floor, not the logic. A weapon still needs a server-side cooldown per weapon.

## 5. Common feature patterns

### Shop (soft currency)
- Price, availability, level requirements live in server-read config.
- Per-player purchase lock while the handler yields (prevents double-spend from rapid fire).
- Deduct and grant in the same synchronous block; then mark data dirty / save on schedule.

### Combat (melee/ranged)
- Client: input → plays animation/VFX immediately (feel) → fires `RequestAttack(targetPosition or direction)`.
- Server: check cooldown (server clock), weapon equipped, attacker alive, origin near attacker's root, target within weapon range (+ latency tolerance ~ 4–8 studs), line of sight via `workspace:Raycast` with attacker's character excluded; compute damage from **server** stats; apply `humanoid:TakeDamage`.
- Hit registration models: server raycast (authoritative, simple) or client-reported hit + server validation (better feel at high ping). Never client-reported damage.

### Pickups / coins
- Use server-side touch or proximity: `.Touched` on the server with per-player debounce, or a server loop checking distance for tagged coins. Don't let the client fire `CollectCoin(coin)` without a server distance check.

### ProximityPrompt
- `ProximityPrompt.Triggered` fires on the server with the player — still check distance (`MaxActivationDistance` is client-enforced), cooldown and state.

### Tools
- Tool `Activated` fires on client; server logic via `Tool.Activated` in a server Script inside the tool also works (server-side fires through replication) — validate that `tool.Parent` is the player's character.

### Trading
- Server-held trade session: both offers stored server-side, both must confirm after the last change, re-validate inventories at execute time, execute atomically in one function, log the trade, save both profiles. Add a short confirm delay after any change to stop last-second swaps.

### Admin commands
- Whitelist of UserIds or `player:GetRankInGroup(groupId) >= rank` (pcall, cache) checked **on the server** on every command. Use `TextChatCommand` for chat commands.

## 6. Movement & physics sanity checks

Server loop at 2–5 Hz per player:

- Horizontal speed over interval vs. `WalkSpeed` (+ tolerance for knockback/vehicles/teleports you caused).
- Vertical: airtime without `Freefall`/`Jumping` states, or position above max map height.
- Teleport distance between samples.
- Noclip: raycast between last valid and current position against walls tagged `AntiNoclip`.

Respond proportionally: rubber-band (set CFrame back), then flag, then kick after repeated high-confidence violations. Whitelist legitimate server-caused movement (teleports, launch pads) by setting a grace window.

Never make physics-critical shared objects client-owned when exploitation matters: `part:SetNetworkOwner(nil)` for server-owned physics (balls in sports games, vehicles you control server-side), knowing it adds input latency for players.

## 7. Text & user-generated content

```lua
local TextService = game:GetService("TextService")

local function filterForBroadcast(text: string, fromUserId: number): string?
	local ok, result = pcall(function()
		local filterResult = TextService:FilterStringAsync(text, fromUserId, Enum.TextFilterContext.PublicChat)
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)
	if ok and typeof(result) == "string" then
		return result
	end
	return nil -- on failure, show nothing
end
```

- Filter on the server, every time text is shown to anyone other than the author (pet names, plot signs, guild names, custom messages). Store the raw text if you must, but re-filter when displaying later (filters change) or store filtered text per display.
- `TextChatService` messages are filtered automatically.
- Limit length and allowed characters before filtering.

## 8. Free models & backdoors

When the user imports models:
- Search descendants for `Script`/`LocalScript`/`ModuleScript`; read each. Red flags: `require(<number>)`, `getfenv`, `loadstring`, `string.reverse`/`string.char` chains, long base64-like strings, `HttpService:PostAsync` to unknown hosts, `MarketplaceService:PromptPurchase` hidden in models, scripts named like core services ("Vaccine", "Antivirus", "Fix", "Weld" with no welding).
- Never "insert this module ID" from strangers.
- Packages from trusted sources should still be vendored and version-pinned.

## 9. Review checklist

- [ ] Remote names describe intent; no `SetX`/`GiveX` remotes.
- [ ] All arguments typed `unknown` and narrowed.
- [ ] NaN/inf/negative/huge numbers rejected.
- [ ] String length via `utf8.len` with nil check.
- [ ] Instance args checked for class + ancestry + distance.
- [ ] Per-player rate limit + per-action cooldown on server clock.
- [ ] Yielding handlers hold a per-player lock.
- [ ] No `InvokeClient`.
- [ ] No secrets or server logic in replicated containers.
- [ ] Text shown to others is filtered.
- [ ] Admin checks server-side by UserId/group rank.
