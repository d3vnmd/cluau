--!strict
--[[
	MovementService — server-owned WalkSpeed. The client only asks to sprint; the server composes
	base speed × sprint × status effects, so slows can't be escaped and anti-cheat sees the real limit.
	Location: ServerScriptService/Services/MovementService (ModuleScript)
	Client side: InputController fires Net "RequestSprint"(boolean) on press/release.

	Status effects: set a multiplier from any server code — MovementService.SetSpeedMultiplier(player, 0.5)
	Anti-cheat: read character attribute "MaxLegitSpeed" (studs/s) in your speed sanity check.
	Under Server Authority, move this into a RunService:BindToSimulation module (server-authority.md).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Guard = require(Shared:WaitForChild("Guard"))
local Net = require(Shared:WaitForChild("Net"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))

local SPRINT_MULTIPLIER = 1.6
local MAX_STATUS_MULTIPLIER = 2

local sprintLimiter = RateLimiter.new(6, 3)
local sprinting: { [Player]: boolean } = {}

local MovementService = {}

local function apply(player: Player)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if character == nil or humanoid == nil then
		return
	end
	local status = character:GetAttribute("SpeedMultiplier")
	local statusMultiplier = if typeof(status) == "number" and status == status
		then math.clamp(status, 0, MAX_STATUS_MULTIPLIER)
		else 1
	local speed = StarterPlayer.CharacterWalkSpeed * (if sprinting[player] then SPRINT_MULTIPLIER else 1) * statusMultiplier
	humanoid.WalkSpeed = speed
	character:SetAttribute("MaxLegitSpeed", speed)
end

--- Server-only: apply a status effect (0.5 = half speed, 1 = normal). Persists until changed or respawn.
function MovementService.SetSpeedMultiplier(player: Player, multiplier: number)
	local character = player.Character
	if character and multiplier == multiplier then
		character:SetAttribute("SpeedMultiplier", math.clamp(multiplier, 0, MAX_STATUS_MULTIPLIER))
	end
end

local function onRequestSprint(player: Player, wants: unknown)
	if not Guard.boolean(wants) or not sprintLimiter:check(player) then
		return
	end
	sprinting[player] = wants == true
	apply(player)
end

local function onCharacter(player: Player, character: Model)
	sprinting[player] = false
	-- This connection belongs to the character instance and is disconnected when it is destroyed.
	character:GetAttributeChangedSignal("SpeedMultiplier"):Connect(function()
		apply(player)
	end)
	character:WaitForChild("Humanoid", 10)
	apply(player)
end

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

function MovementService.Init() end

function MovementService.Start()
	Net.event("RequestSprint").OnServerEvent:Connect(onRequestSprint)
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		sprinting[player] = nil
	end)
end

return MovementService
