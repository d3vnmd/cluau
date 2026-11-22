--!strict
--[[
	ShopService — example of a fully validated client request (soft-currency purchase + equip).
	Location: ServerScriptService/Services/ShopService (ModuleScript)
	Depends on: DataService, Shared/{Config, Net, Guard, RateLimiter}

	Client sends INTENT only: RequestPurchase(itemId). Price and ownership are decided here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Guard = require(Shared:WaitForChild("Guard"))
local Net = require(Shared:WaitForChild("Net"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local MAX_ID_LENGTH = 40
local EQUIP_SLOT = "Cosmetic"

local purchaseLimiter = RateLimiter.new(3, 1)
local equipLimiter = RateLimiter.new(5, 3)

local ShopService = {}

local function notify(player: Player, kind: "success" | "error", text: string)
	Net.event("Notify"):FireClient(player, { kind = kind, text = text })
end

local function onRequestPurchase(player: Player, itemId: unknown)
	if not Guard.string(itemId, MAX_ID_LENGTH) then
		return
	end
	if not purchaseLimiter:check(player) then
		return
	end
	local item = Config.Shop.Items[itemId :: string]
	if item == nil then
		return
	end

	local profile = DataService.GetProfile(player)
	if profile == nil then
		return
	end
	local data = profile.Data
	if (data.Inventory[item.id] or 0) > 0 then
		notify(player, "error", "You already own this.")
		return
	end
	if data.Coins < item.price then
		notify(player, "error", `Need {item.price - data.Coins} more coins`)
		return
	end

	-- Deduct and grant in one synchronous block (no yields between check and mutation).
	DataService.Update(player, function(d)
		d.Coins -= item.price
		d.Inventory[item.id] = 1
	end)
	notify(player, "success", `{item.displayName} unlocked`)
end

local function onRequestEquip(player: Player, itemId: unknown)
	if not Guard.string(itemId, MAX_ID_LENGTH) then
		return
	end
	if not equipLimiter:check(player) then
		return
	end
	local profile = DataService.GetProfile(player)
	if profile == nil or (profile.Data.Inventory[itemId :: string] or 0) <= 0 then
		return
	end
	DataService.Update(player, function(d)
		d.Equipped[EQUIP_SLOT] = itemId :: string
	end)
end

function ShopService.Init() end

function ShopService.Start()
	Net.event("RequestPurchase").OnServerEvent:Connect(onRequestPurchase)
	Net.event("RequestEquip").OnServerEvent:Connect(onRequestEquip)

	-- Read-only catalog for the UI. Fast, no yields, no client input used.
	Net.func("GetShopCatalog").OnServerInvoke = function(_player: Player)
		local list = {}
		for _, item in Config.Shop.Items do
			table.insert(list, {
				id = item.id,
				displayName = item.displayName,
				description = item.description,
				price = item.price,
				rarity = item.rarity,
				icon = item.icon,
				layoutOrder = item.layoutOrder,
			})
		end
		return list
	end
end

return ShopService
