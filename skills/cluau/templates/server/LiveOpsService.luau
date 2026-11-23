--!strict
--[[
	LiveOpsService — live values, global shop rotations and server-wide events, the way 2025–26 hits run
	weekly updates without republishing.
	Location: ServerScriptService/Services/LiveOpsService (ModuleScript)
	Depends on: Shared/Restock; DataService (per-player stock lives in the session-locked profile)

	1. Live values — ConfigService (Creator Dashboard → Configs). Read with LiveOpsService.Get(key, default).
	   A failed load or a missing key always falls back to the default (the game must work without configs).
	2. Global restock — every server shows the same stock per slot (Restock.luau, no messaging needed).
	   Clients read ReplicatedStorage.LiveOps attributes: StockSlot, NextRestockAt (unix seconds; compare
	   with workspace:GetServerTimeNow()). Soft-currency purchases: TryTakeStock(player, itemId) in the same
	   synchronous block as the charge; ReleaseStock if the charge then fails. Robux restock products: check
	   stock BEFORE prompting and always honour the receipt — never let stock decide a ProcessReceipt grant.
	3. Server-wide events ("admin abuse" hour, double coins) — LiveOpsService.StartEvent(name, seconds)
	   publishes via MessagingService (fast, best-effort) AND writes a MemoryStore flag (servers that start
	   later still join the event). Clients read attributes EventName / EventEndsAt.

	Budget notes: MessagingService messages ≤ 1 KB and are not guaranteed; MemoryStore entries expire
	(≤ 45 days) — both are handled by re-reading the flag every EVENT_POLL_SECONDS.
]]

local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Restock = require(Shared:WaitForChild("Restock"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local STOCK_PERIOD_SECONDS = 300
local STOCK_SALT = 7 -- change to reshuffle all future rotations
local STOCK_ENTRIES: { Restock.Entry } = {
	{ id = "Carrot", chance = 1.0, minQty = 5, maxQty = 25 },
	{ id = "Corn", chance = 0.6, minQty = 2, maxQty = 8 },
	{ id = "Mango", chance = 0.12, minQty = 1, maxQty = 2 },
}
local EVENT_TOPIC = "LiveOpsEvent"
local EVENT_KEY = "ActiveEvent"
local EVENT_POLL_SECONDS = 60
local MAX_EVENT_SECONDS = 6 * 60 * 60

local LiveOpsService = {}

local state: Folder
local snapshot: ConfigSnapshot? = nil
local eventMap = MemoryStoreService:GetHashMap("LiveOps")
local currentSlot = -1
local currentStock: { [string]: number } = {}
local activeEventEndsAt = 0

--- Typed live value with a safe fallback. Never errors.
function LiveOpsService.Get<T>(key: string, default: T): T
	if snapshot == nil then
		return default
	end
	local ok, value = pcall(function()
		return (snapshot :: ConfigSnapshot):GetValue(key)
	end)
	if ok and value ~= nil and typeof(value) == typeof(default) then
		return value :: any
	end
	return default
end

local function loadConfig()
	local ok, result = pcall(function()
		return game:GetService("ConfigService"):GetConfigAsync()
	end)
	if not ok then
		warn(`[LiveOps] configs unavailable, using defaults: {result}`)
		return
	end
	snapshot = result
	result.UpdateAvailable:Connect(function()
		pcall(function()
			result:Refresh()
		end)
	end)
end

local function refreshStock()
	local now = os.time()
	local slot = Restock.slot(now, STOCK_PERIOD_SECONDS)
	if slot ~= currentSlot then
		currentSlot = slot
		currentStock = Restock.stockFor(slot, STOCK_SALT, STOCK_ENTRIES)
		state:SetAttribute("StockSlot", slot)
	end
	state:SetAttribute("NextRestockAt", now + Restock.secondsUntilNext(now, STOCK_PERIOD_SECONDS))
end

--- Server-side stock check + reservation of one unit for this player in the current slot.
--- The count lives in the player's session-locked profile, so rejoining or hopping servers can't reset it.
--- Call after validating the request, in the same synchronous block as the charge (no yields in between).
function LiveOpsService.TryTakeStock(player: Player, itemId: string): boolean
	refreshStock() -- recompute at purchase time: never trust a client's view of the stock
	local available = currentStock[itemId]
	if available == nil then
		return false
	end
	local taken = false
	DataService.Update(player, function(data)
		local purchases = data.StockPurchases
		if purchases.Slot ~= currentSlot then
			purchases.Slot = currentSlot
			table.clear(purchases.Counts)
		end
		if (purchases.Counts[itemId] or 0) < available then
			purchases.Counts[itemId] = (purchases.Counts[itemId] or 0) + 1
			taken = true
		end
	end)
	return taken
end

--- Gives back a unit reserved by TryTakeStock (e.g. the charge failed). No-op if the slot already changed.
function LiveOpsService.ReleaseStock(player: Player, itemId: string)
	DataService.Update(player, function(data)
		local purchases = data.StockPurchases
		local count = purchases.Counts[itemId]
		if purchases.Slot == currentSlot and count and count > 0 then
			purchases.Counts[itemId] = if count > 1 then count - 1 else nil
		end
	end)
end

function LiveOpsService.GetStock(): { [string]: number }
	refreshStock()
	return table.clone(currentStock)
end

local function applyEvent(name: string?, endsAt: number?)
	local active = name ~= nil and endsAt ~= nil and endsAt > os.time()
	activeEventEndsAt = if active then endsAt :: number else 0
	state:SetAttribute("EventName", if active then name else "")
	state:SetAttribute("EventEndsAt", if active then endsAt else 0)
end

local function pollEvent()
	local ok, value = pcall(eventMap.GetAsync, eventMap, EVENT_KEY)
	if ok and typeof(value) == "table" and typeof(value.name) == "string" and typeof(value.endsAt) == "number" then
		applyEvent(value.name, value.endsAt)
	elseif ok then
		applyEvent(nil, nil)
	end
end

--- Starts a server-wide event on every server (call from an admin command or a scheduled job).
function LiveOpsService.StartEvent(name: string, durationSeconds: number): boolean
	local duration = math.clamp(math.floor(durationSeconds), 1, MAX_EVENT_SECONDS)
	local payload = { name = string.sub(name, 1, 40), endsAt = os.time() + duration }
	-- Persist first (with retries): if the MemoryStore flag isn't written, every server's next poll would read
	-- "no event" and silently cancel what we just announced.
	local stored = false
	for attempt = 1, 3 do
		stored = pcall(eventMap.SetAsync, eventMap, EVENT_KEY, payload, duration)
		if stored then
			break
		end
		task.wait(2 ^ attempt)
	end
	if not stored then
		warn("[LiveOps] event not started: couldn't store the event flag")
		return false
	end
	pcall(MessagingService.PublishAsync, MessagingService, EVENT_TOPIC, payload)
	applyEvent(payload.name, payload.endsAt)
	return true
end

function LiveOpsService.IsEventActive(name: string): boolean
	return state:GetAttribute("EventName") == name and (state:GetAttribute("EventEndsAt") :: number) > os.time()
end

function LiveOpsService.Init()
	local existing = ReplicatedStorage:FindFirstChild("LiveOps")
	if existing and existing:IsA("Folder") then
		state = existing :: Folder
	else
		state = Instance.new("Folder")
		state.Name = "LiveOps"
		state:SetAttribute("EventName", "")
		state:SetAttribute("EventEndsAt", 0)
		state.Parent = ReplicatedStorage
	end
	refreshStock()
end

function LiveOpsService.Start()
	task.spawn(loadConfig)
	pcall(MessagingService.SubscribeAsync, MessagingService, EVENT_TOPIC, function(message)
		local data = message.Data
		-- Messages can arrive late or out of order: never let an older event replace a newer one.
		if typeof(data) == "table" and typeof(data.name) == "string" and typeof(data.endsAt) == "number"
			and data.endsAt >= activeEventEndsAt then
			applyEvent(data.name, data.endsAt)
		end
	end)
	task.spawn(function()
		while true do
			refreshStock()
			task.wait(math.min(5, Restock.secondsUntilNext(os.time(), STOCK_PERIOD_SECONDS)))
		end
	end)
	task.spawn(function()
		while true do
			pollEvent()
			task.wait(EVENT_POLL_SECONDS)
		end
	end)
end

return LiveOpsService
