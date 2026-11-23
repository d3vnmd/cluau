--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local buy = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuyItem")
buy.OnServerEvent:Connect(function(player, itemId, price)
	task.wait(0.5)
	player.leaderstats.Coins.Value -= price
end)
local camera = workspace.CurrentCamera
