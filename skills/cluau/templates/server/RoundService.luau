--!strict
--[[
	RoundService — server-authoritative round loop: Lobby → Intermission → Round → Results → …
	Location: ServerScriptService/Services/RoundService (ModuleScript)
	Depends on: DataService (rewards); ServerStorage/Maps (Folder of Models, each with a "Spawns" folder of parts)

	Replication (cheap, no per-second remotes): attributes on ReplicatedStorage.GameState
	  Phase   : "Lobby" | "Intermission" | "Round" | "Results"
	  EndsAt  : number   -- workspace:GetServerTimeNow() timestamp; 0 when no timer
	  RoundId : number
	  Winner  : string   -- display name or ""
	Client countdown (in any LocalScript/controller):
		local state = ReplicatedStorage:WaitForChild("GameState")
		local remaining = math.max(0, state:GetAttribute("EndsAt") - workspace:GetServerTimeNow())

	Edge cases handled (sharp-edges CX-41..CX-44):
	  • Players joining mid-round spectate; only participants can win.
	  • Leaving or dying removes a participant; the round ends early when ≤ 1 (or 0) remain.
	  • Not enough players during intermission → back to Lobby (no empty rounds).
	  • All round connections live in one cleanup list and are disconnected when the round ends,
	    so respawns and old characters can't leak handlers into the next round.
	  • Maps are cloned from ServerStorage and destroyed after the round.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataService = require(script.Parent:WaitForChild("DataService"))

local MIN_PLAYERS = 2
local INTERMISSION_SECONDS = 20
local ROUND_SECONDS = 180
local RESULTS_SECONDS = 8
local WIN_REWARD = 50
local PARTICIPATION_REWARD = 10

export type Phase = "Lobby" | "Intermission" | "Round" | "Results"

local RoundService = {}

local state: Folder
local rng = Random.new()
local roundId = 0
local participants: { [Player]: boolean } = {}

local function setPhase(phase: Phase, duration: number?)
	state:SetAttribute("Phase", phase)
	state:SetAttribute("EndsAt", if duration then workspace:GetServerTimeNow() + duration else 0)
end

local function countParticipants(): number
	local count = 0
	for player in participants do
		if player.Parent == Players then
			count += 1
		else
			participants[player] = nil
		end
	end
	return count
end

local function eligiblePlayers(): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if DataService.IsActive(player) and humanoid and humanoid.Health > 0 then
			table.insert(list, player)
		end
	end
	return list
end

-- Waits up to `seconds`, returning early when `shouldStop()` becomes true. Checks 4×/s.
local function waitUnless(seconds: number, shouldStop: () -> boolean)
	local deadline = os.clock() + seconds
	while os.clock() < deadline do
		if shouldStop() then
			return
		end
		task.wait(0.25)
	end
end

local function pickMap(): Model?
	local maps = ServerStorage:FindFirstChild("Maps")
	if maps == nil then
		warn("[RoundService] Missing ServerStorage.Maps")
		return nil
	end
	local options = {}
	for _, child in maps:GetChildren() do
		if child:IsA("Model") and child:FindFirstChild("Spawns") then
			table.insert(options, child)
		end
	end
	if #options == 0 then
		warn("[RoundService] ServerStorage.Maps has no Model with a Spawns folder")
		return nil
	end
	return options[rng:NextInteger(1, #options)]
end

local function spawnPoints(map: Model): { BasePart }
	local points = {}
	for _, spawn in (map:FindFirstChild("Spawns") :: Instance):GetChildren() do
		if spawn:IsA("BasePart") then
			table.insert(points, spawn)
		end
	end
	return points
end

local function runRound()
	local template = pickMap()
	if template == nil then
		setPhase("Lobby")
		task.wait(5)
		return
	end
	local map = template:Clone()
	map.Name = "ActiveMap"
	map.Parent = workspace

	roundId += 1
	state:SetAttribute("RoundId", roundId)
	state:SetAttribute("Winner", "")
	table.clear(participants)

	local connections: { RBXScriptConnection } = {}
	local points = spawnPoints(map)
	for index, player in eligiblePlayers() do
		local character = player.Character :: Model
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		participants[player] = true
		if #points > 0 then
			local point = points[(index - 1) % #points + 1]
			character:PivotTo(point.CFrame + Vector3.new(0, 4, 0))
		end
		-- Death eliminates. Connection is per character and cleaned at round end.
		table.insert(connections, humanoid.Died:Connect(function()
			participants[player] = nil
		end))
		-- A respawned character is not a participant (prevents "die and come back" exploits).
		table.insert(connections, player.CharacterAdded:Connect(function()
			participants[player] = nil
		end))
	end

	setPhase("Round", ROUND_SECONDS)
	local startedWith = countParticipants()
	waitUnless(ROUND_SECONDS, function()
		local alive = countParticipants()
		return alive == 0 or (startedWith >= 2 and alive <= 1)
	end)

	for _, connection in connections do
		connection:Disconnect()
	end

	-- Results: last one standing wins; everyone who started gets participation.
	local survivors = {}
	for player in participants do
		if player.Parent == Players then
			table.insert(survivors, player)
		end
	end
	local winner = if #survivors == 1 then survivors[1] else nil
	state:SetAttribute("Winner", if winner then winner.DisplayName else "")
	for _, player in Players:GetPlayers() do
		if participants[player] or player == winner then
			DataService.AddCoins(player, if player == winner then WIN_REWARD else PARTICIPATION_REWARD)
		end
	end
	if winner then
		RoundService.WinnerDeclared:Fire(winner)
	end

	setPhase("Results", RESULTS_SECONDS)
	task.wait(RESULTS_SECONDS)

	table.clear(participants)
	map:Destroy()
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			local ok, err = pcall(player.LoadCharacterAsync, player)
			if not ok then
				warn(`[RoundService] respawn failed for {player.Name}: {err}`)
			end
		end)
	end
end

local function loop()
	while true do
		setPhase("Lobby")
		while #eligiblePlayers() < MIN_PLAYERS do
			task.wait(1)
		end

		setPhase("Intermission", INTERMISSION_SECONDS)
		local cancelled = false
		waitUnless(INTERMISSION_SECONDS, function()
			cancelled = #eligiblePlayers() < MIN_PLAYERS
			return cancelled
		end)
		if not cancelled then
			local ok, err = xpcall(runRound, debug.traceback)
			if not ok then
				warn(`[RoundService] round crashed: {err}`)
				local leftover = workspace:FindFirstChild("ActiveMap")
				if leftover then
					leftover:Destroy()
				end
				table.clear(participants)
			end
		end
	end
end

-- Other services can listen: RoundService.WinnerDeclared.Event:Connect(function(player) ... end)
RoundService.WinnerDeclared = Instance.new("BindableEvent")

function RoundService.GetPhase(): Phase
	return state:GetAttribute("Phase") :: Phase
end

function RoundService.IsParticipant(player: Player): boolean
	return participants[player] == true
end

function RoundService.Init()
	local existing = ReplicatedStorage:FindFirstChild("GameState")
	if existing and existing:IsA("Folder") then
		state = existing :: Folder
	else
		state = Instance.new("Folder")
		state.Name = "GameState"
		state:SetAttribute("Phase", "Lobby")
		state:SetAttribute("EndsAt", 0)
		state:SetAttribute("RoundId", 0)
		state:SetAttribute("Winner", "")
		state.Parent = ReplicatedStorage -- attributes set BEFORE parenting replicate in one go
	end
end

function RoundService.Start()
	Players.PlayerRemoving:Connect(function(player)
		participants[player] = nil
	end)
	task.spawn(loop)
end

return RoundService
