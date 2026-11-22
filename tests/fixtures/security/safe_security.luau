--!strict
-- The validated equivalents of the unsafe fixtures. Must produce ZERO findings.
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local store = DataStoreService:GetDataStore("PlayerData_v1")
local processed: { [string]: boolean } = {}
local MAX_DISTANCE = 12

local function isNearPart(player: Player, part: BasePart): boolean
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return root ~= nil and root:IsA("BasePart") and (root.Position - part.Position).Magnitude <= MAX_DISTANCE
end

local shop = workspace:WaitForChild("Shop") :: BasePart
local prompt = shop:WaitForChild("ProximityPrompt") :: ProximityPrompt
prompt.Triggered:Connect(function(player)
	if not isNearPart(player, shop) then
		return
	end
end)

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestPurchase") :: RemoteEvent
remote.OnServerEvent:Connect(function(player, itemId: unknown)
	if typeof(itemId) ~= "string" then
		return
	end
end)

MarketplaceService.ProcessReceipt = function(info)
	local purchaseId = tostring(info.PurchaseId)
	if processed[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local ok = pcall(function()
		store:UpdateAsync(`Receipt_{purchaseId}`, function()
			return true
		end)
	end)
	if not ok then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	processed[purchaseId] = true
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function onPlayer(player: Player) end
Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayer, player)
end

game:BindToClose(function() end)

local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
