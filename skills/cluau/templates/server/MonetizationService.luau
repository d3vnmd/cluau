--!strict
--[[
	MonetizationService — idempotent developer products + server-side game pass perks.
	Location: ServerScriptService/Services/MonetizationService (ModuleScript)
	Depends on: DataService (same folder)

	Rules implemented:
	  • ProcessReceipt is assigned exactly once, here.
	  • PurchaseId is recorded in the same session-locked profile as the grant (no double grants).
	  • NotProcessedYet whenever we can't safely grant (player gone, data not loaded, handler failed).
	  • Game pass ownership is checked on the server, cached, and exposed as a player attribute.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))

type ProductHandler = (player: Player, data: DataService.PlayerData) -> ()

-- ProductId → grant function. Grants must be synchronous and must not yield.
local PRODUCT_HANDLERS: { [number]: ProductHandler } = {
	[Config.Monetization.Products.Coins500] = function(_player, data)
		data.Coins = math.min(data.Coins + 500, Config.Currency.MaxCoins)
	end,
}

local passCache: { [Player]: { [number]: boolean } } = {}

local MonetizationService = {}

local function ownsPassRemote(player: Player, passId: number): boolean
	for attempt = 1, 2 do
		local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
		if ok then
			return result == true
		end
		warn(`[Monetization] UserOwnsGamePassAsync failed ({attempt}/2): {result}`)
		task.wait(1)
	end
	return false
end

local function setPass(player: Player, passId: number, owned: boolean)
	local cache = passCache[player]
	if cache == nil then
		cache = {}
		passCache[player] = cache
	end
	cache[passId] = owned
	for name, id in Config.Monetization.GamePasses do
		if id == passId then
			player:SetAttribute(`Pass_{name}`, owned)
		end
	end
end

--- Server-side check used by gameplay code (e.g. coin multiplier). Cached per session.
function MonetizationService.HasPass(player: Player, passName: string): boolean
	local passId = Config.Monetization.GamePasses[passName]
	if passId == nil or passId == 0 then
		return false
	end
	local cache = passCache[player]
	if cache and cache[passId] ~= nil then
		return cache[passId]
	end
	local owned = ownsPassRemote(player, passId)
	if player.Parent == Players then
		setPass(player, passId, owned)
	end
	return owned
end

function MonetizationService.CoinMultiplier(player: Player): number
	return if MonetizationService.HasPass(player, "DoubleCoins") then 2 else 1
end

local function processReceipt(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- retried on next join
	end

	local handler = PRODUCT_HANDLERS[receiptInfo.ProductId]
	if handler == nil then
		warn(`[Monetization] No handler for product {receiptInfo.ProductId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = DataService.WaitForProfile(player, 20)
	if profile == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(receiptInfo.PurchaseId)
	if profile.Data.ProcessedReceipts[purchaseId] ~= nil then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted earlier
	end

	local granted = DataService.Update(player, function(data)
		handler(player, data)
		data.ProcessedReceipts[purchaseId] = os.time()
	end)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Persist before confirming. If the save fails, the grant + receipt id are still together in the
	-- live profile (written by the next autosave/leave). Returning NotProcessedYet makes Roblox retry;
	-- the retry sees the recorded PurchaseId and returns PurchaseGranted without granting twice.
	if DataService.SaveNow(player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function onPlayerAdded(player: Player)
	for _, passId in Config.Monetization.GamePasses do
		if passId ~= 0 then
			local owned = ownsPassRemote(player, passId)
			if player.Parent ~= Players then
				return
			end
			setPass(player, passId, owned)
		end
	end
end

function MonetizationService.Init() end

function MonetizationService.Start()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, wasPurchased: boolean)
		if wasPurchased then
			setPass(player, passId, true)
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		passCache[player] = nil
	end)
end

return MonetizationService
