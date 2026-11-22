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
local STREAM_TIMEOUT_SECONDS = 5 -- max wait for clients to receive the map before teleporting

export type Phase = "Lobby" | "Intermission" | "Round" | "Results"

local RoundService = {}

local state: Folder
local rng = Random.new()
local roundId = 0
local participants: { [Player]: Model } = {} -- player -> the character registered at round start
local roundConnections: { RBXScriptConnection } = {} -- module-level so the error path can clean them

local function setPhase(phase: Phase, duration: number?)
	state:SetAttribute("Phase", phase)
	state:SetAttribute("EndsAt", if duration then workspace:GetServerTimeNow() + duration else 0)
end

local function disconnectRound()
	for _, connection in roundConnections do
		connection:Disconnect()
	end
	table.clear(roundConnections)
end

-- A participant stays in only while: still in the server, still on the registered character, and that
-- character has a living Humanoid. (Covers leaving, respawning, and a deleted Humanoid that never fires Died.)
local function stillIn(player: Player, character: Model): boolean
	if player.Parent ~= Players or player.Character ~= character or character.Parent == nil then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function countParticipants(): number
	local count = 0
	for player, character in participants do
		if stillIn(player, character) then
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

	local points = spawnPoints(map)
	local roster = eligiblePlayers()

	-- Streaming: make each client receive the area around its spawn BEFORE teleporting, or characters
	-- (client-owned physics) fall through floors that haven't streamed in yet. In parallel, bounded.
	local pendingStreams = #roster
	for index, player in roster do
		local point = if #points > 0 then points[(index - 1) % #points + 1] else nil
		task.spawn(function()
			if point and workspace.StreamingEnabled then
				pcall(player.RequestStreamAroundAsync, player, point.Position, STREAM_TIMEOUT_SECONDS)
			end
			pendingStreams -= 1
		end)
	end
	local streamDeadline = os.clock() + STREAM_TIMEOUT_SECONDS + 1
	while pendingStreams > 0 and os.clock() < streamDeadline do
		task.wait(0.1)
	end

	for index, player in roster do
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if character == nil or humanoid == nil or humanoid.Health <= 0 or player.Parent ~= Players then
			continue -- left or died while streaming
		end
		participants[player] = character
		if #points > 0 then
			local point = points[(index - 1) % #points + 1]
			character:PivotTo(point.CFrame + Vector3.new(0, 4, 0))
		end
		-- Death eliminates; respawning also eliminates (no "die and come back"). Cleaned at round end.
		table.insert(roundConnections, humanoid.Died:Connect(function()
			participants[player] = nil
		end))
		table.insert(roundConnections, player.CharacterAdded:Connect(function()
			participants[player] = nil
		end))
	end

	local starters: { [Player]: boolean } = {}
	for player in participants do
		starters[player] = true
	end
	local startedWith = countParticipants()
	if startedWith < MIN_PLAYERS then
		-- Someone left/died between intermission and start: abort, no rewards (prevents solo reward farming).
		disconnectRound()
		table.clear(participants)
		map:Destroy()
		return
	end

	setPhase("Round", ROUND_SECONDS)
	waitUnless(ROUND_SECONDS, function()
		return countParticipants() <= 1
	end)
	countParticipants()
	disconnectRound()

	-- Results: last one standing wins; everyone who STARTED (snapshot) gets participation.
	local survivors = {}
	for player in participants do
		if player.Parent == Players then
			table.insert(survivors, player)
		end
	end
	local winner = if #survivors == 1 then survivors[1] else nil
	state:SetAttribute("Winner", if winner then winner.DisplayName else "")
	for player in starters do
		if player.Parent == Players then
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
				disconnectRound()
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
	return participants[player] ~= nil
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
