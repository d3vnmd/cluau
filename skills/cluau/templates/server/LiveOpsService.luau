--!strict
--[[
	LiveOpsService — live values, global shop rotations and server-wide events, the way 2025–26 hits run
	weekly updates without republishing.
	Location: ServerScriptService/Services/LiveOpsService (ModuleScript)
	Depends on: Shared/{Restock, Config}

	1. Live values — ConfigService (Creator Dashboard → Configs). Read with LiveOpsService.Get(key, default).
	   A failed load or a missing key always falls back to the default (the game must work without configs).
	2. Global restock — every server shows the same stock per slot (Restock.luau, no messaging needed).
	   Clients read ReplicatedStorage.LiveOps attributes: StockSlot, NextRestockAt (unix seconds; compare
	   with workspace:GetServerTimeNow()). Purchases call LiveOpsService.TryTakeStock(player, itemId).
	3. Server-wide events ("admin abuse" hour, double coins) — LiveOpsService.StartEvent(name, seconds)
	   publishes via MessagingService (fast, best-effort) AND writes a MemoryStore flag (servers that start
	   later still join the event). Clients read attributes EventName / EventEndsAt.

	Budget notes: MessagingService messages ≤ 1 KB and are not guaranteed; MemoryStore entries expire
	(≤ 45 days) — both are handled by re-reading the flag every EVENT_POLL_SECONDS.
]]

local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Restock = require(Shared:WaitForChild("Restock"))

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
-- Per-player stock (each player can buy the slot's quantity) — reset when the slot changes.
local bought: { [Player]: { [string]: number } } = {}

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
		table.clear(bought)
		state:SetAttribute("StockSlot", slot)
	end
	state:SetAttribute("NextRestockAt", now + Restock.secondsUntilNext(now, STOCK_PERIOD_SECONDS))
end

--- Server-side stock check + reservation for one unit. Call inside your purchase handler, after validating
--- the request and BEFORE charging (no yields in between).
function LiveOpsService.TryTakeStock(player: Player, itemId: string): boolean
	refreshStock() -- recompute at purchase time: never trust a client's view of the stock
	local available = currentStock[itemId]
	if available == nil then
		return false
	end
	local mine = bought[player]
	if mine == nil then
		mine = {}
		bought[player] = mine
	end
	if (mine[itemId] or 0) >= available then
		return false
	end
	mine[itemId] = (mine[itemId] or 0) + 1
	return true
end

function LiveOpsService.GetStock(): { [string]: number }
	refreshStock()
	return table.clone(currentStock)
end

local function applyEvent(name: string?, endsAt: number?)
	local active = name ~= nil and endsAt ~= nil and endsAt > os.time()
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
	local stored = pcall(eventMap.SetAsync, eventMap, EVENT_KEY, payload, duration)
	pcall(MessagingService.PublishAsync, MessagingService, EVENT_TOPIC, payload)
	applyEvent(payload.name, payload.endsAt)
	return stored
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
		if typeof(data) == "table" and typeof(data.name) == "string" and typeof(data.endsAt) == "number" then
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
	Players.PlayerRemoving:Connect(function(player)
		bought[player] = nil
	end)
end

return LiveOpsService
