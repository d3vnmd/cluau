--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("PlayerData_v1")
local equip = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Equip")
equip.OnServerEvent:Connect(function(player, itemId: unknown)
	if typeof(itemId) ~= "string" or not limiter:check(player) then
		return
	end
	store:UpdateAsync("k", function(old) return old end)
end)
game:BindToClose(function() end)
