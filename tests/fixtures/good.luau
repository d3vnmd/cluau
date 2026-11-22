--!strict
-- Valid, modern Luau that cluau-lint must NOT flag. Guards against false positives.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")

local cube = math.pow(2, 3)
local a, b = unpack({ 1, 2 })
local c, d = table.unpack({ 3, 4 })
local biggest = table.maxn({ 1, 2, 3 })
local half = 7 // 2
local mixed = math.lerp(0, 10, 0.5)
local isBad = math.isnan(0 / 0)
local v = vector.create(1, 2, 3)

for i = 1, 3 do
	if i == 2 then
		continue
	end
end

workspace:RegisterCollisionGroup("Enemies")
workspace:CollisionGroupSetCollidable("Enemies", "Enemies", false)

local function onPlayer(player: Player)
	task.spawn(function()
		local okInfo, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, 123, Enum.InfoType.Product)
		local okFriend, isFriend = pcall(player.IsFriendsWithAsync, player, 1)
		player:LoadCharacterAsync()
		local options = Instance.new("TeleportOptions")
		options.ReservedServerId = HttpService:GenerateGUID(false)
		pcall(TeleportService.TeleportAsync, TeleportService, 123, { player }, options)
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayer, player)
end

local event = Instance.new("BindableEvent")
event:Fire()
local label = Instance.new("TextLabel")
label.TextWrapped = true
label.Rotation = 5
label.BorderSizePixel = 0
RunService.Heartbeat:Connect(function(dt: number) end)
local now = os.clock()
