--!strict
-- Remote handlers that trust the client.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage.Remotes.Buy
remote.OnServerEvent:Connect(function(player, itemId, price) end) -- expect CL114
remote:FireServer("Sword", price) -- expect CL115
remote:FireServer("Sword", damage) -- expect CL115
Players.PlayerAdded:Connect(function(player) end) -- expect CL116
