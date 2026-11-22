--!strict
-- Player data written with SetAsync, no shutdown save.
local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("PlayerData") -- expect CL117
local function save(player: Player, data: any)
	store:SetAsync("Player_" .. player.UserId, data) -- expect CL110 CL060
end
