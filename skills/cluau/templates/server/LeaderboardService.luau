--!strict
--[[
	LeaderboardService — cross-server leaderboards that stay inside DataStore/MemoryStore budgets.
	Location: ServerScriptService/Services/LeaderboardService (ModuleScript)

	Two layers:
	  1. LIVE (minutes): MemoryStoreSortedMap "LiveWins_<week>". Each server batches its players' gains and
	     flushes them every FLUSH_SECONDS with one UpdateAsync per player that changed.
	  2. PERSISTENT (all-time): OrderedDataStore "Wins_AllTime", incremented on the SAME slow cadence and on
	     leave/shutdown — never per win.
	Every server reads the live top list every READ_SECONDS and pushes it to clients via
	Net "LeaderboardUpdated" (also sent once to each joining player).

	Usage:  LeaderboardService.AddWins(player, 1)   -- e.g. from RoundService.WinnerDeclared

	Budget math (per server): flush ≤ players × (1 MemoryStore + 1 OrderedDataStore) calls per FLUSH_SECONDS,
	1 GetRangeAsync per READ_SECONDS, 1 GetUserInfosByUserIdsAsync batch per refresh. Names are cached.
]]

local MemoryStoreService = game:GetService("MemoryStoreService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local TOP_COUNT = 50
local FLUSH_SECONDS = 60
local READ_SECONDS = 45
local LIVE_EXPIRATION = 8 * 24 * 60 * 60 -- a little over a week (max allowed is 45 days)
local SECONDS_PER_WEEK = 7 * 24 * 60 * 60

export type Entry = { userId: number, name: string, value: number }

-- Tracked separately so a failure in one store never re-adds (double counts) into the other.
local pendingLive: { [number]: number } = {} -- userId -> wins not yet in the MemoryStore board
local pendingAllTime: { [number]: number } = {} -- userId -> wins not yet in the OrderedDataStore
local nameCache: { [number]: string } = {}
local lastTop: { Entry } = {}

local allTime = DataStoreService:GetOrderedDataStore("Wins_AllTime")

local LeaderboardService = {}

local function weekKey(): string
	return `LiveWins_{math.floor(os.time() / SECONDS_PER_WEEK)}`
end

local function liveMap(): MemoryStoreSortedMap
	return MemoryStoreService:GetSortedMap(weekKey())
end

--- Records wins in memory only (cheap). Flushed in batches.
function LeaderboardService.AddWins(player: Player, amount: number)
	if amount ~= amount or amount <= 0 or amount % 1 ~= 0 then
		return
	end
	pendingLive[player.UserId] = (pendingLive[player.UserId] or 0) + amount
	pendingAllTime[player.UserId] = (pendingAllTime[player.UserId] or 0) + amount
end

local function flushLive(userId: number, amount: number): boolean
	local ok, err = pcall(function()
		liveMap():UpdateAsync(tostring(userId), function(oldValue: any, _oldSortKey: any)
			local value = (if typeof(oldValue) == "number" then oldValue else 0) + amount
			return value, value -- value and sort key are both the score
		end, LIVE_EXPIRATION)
	end)
	if not ok then
		warn(`[Leaderboard] live update failed for {userId}: {err}`)
	end
	return ok
end

local function flushAllTime(userId: number, amount: number): boolean
	local ok, err = pcall(function()
		allTime:IncrementAsync(tostring(userId), amount)
	end)
	if not ok then
		warn(`[Leaderboard] all-time update failed for {userId}: {err}`)
	end
	return ok
end

-- Flushes one pending table. Entries are removed only AFTER a successful write (minus what was written),
-- so a shutdown mid-flush or a failed write never loses or double-counts wins.
local inFlight: { [any]: { [number]: boolean } } = {} -- per pending table: userIds currently being written

local function flushTable(pendingTable: { [number]: number }, write: (number, number) -> boolean, onlyUserId: number?)
	local busy = inFlight[pendingTable]
	if busy == nil then
		busy = {}
		inFlight[pendingTable] = busy
	end
	local userIds = {}
	for userId in pendingTable do
		if onlyUserId == nil or userId == onlyUserId then
			table.insert(userIds, userId)
		end
	end
	for _, userId in userIds do
		local amount = pendingTable[userId]
		if amount and amount > 0 and not busy[userId] then
			busy[userId] = true -- the periodic flush and a leave flush must never write the same amount twice
			local ok = write(userId, amount)
			busy[userId] = nil
			if ok then
				local remaining = (pendingTable[userId] or 0) - amount
				pendingTable[userId] = if remaining > 0 then remaining else nil
			end
		end
		if onlyUserId == nil then
			task.wait(0.1) -- spread requests across the interval
		end
	end
end

local function flushAll(onlyUserId: number?)
	flushTable(pendingLive, flushLive, onlyUserId)
	flushTable(pendingAllTime, flushAllTime, onlyUserId)
end

local function resolveNames(userIds: { number })
	local missing = {}
	for _, userId in userIds do
		if nameCache[userId] == nil then
			table.insert(missing, userId)
		end
	end
	if #missing == 0 then
		return
	end
	local ok, infos = pcall(UserService.GetUserInfosByUserIdsAsync, UserService, missing)
	if ok and typeof(infos) == "table" then
		for _, info in infos :: { any } do
			nameCache[info.Id] = info.DisplayName
		end
	end
end

local function refreshTop()
	local ok, items = pcall(function()
		return liveMap():GetRangeAsync(Enum.SortDirection.Descending, TOP_COUNT)
	end)
	if not ok or typeof(items) ~= "table" then
		warn(`[Leaderboard] read failed: {items}`)
		return
	end
	local ids = {}
	for _, item in items :: { any } do
		local userId = tonumber(item.key)
		if userId then
			table.insert(ids, userId)
		end
	end
	resolveNames(ids)
	local top: { Entry } = {}
	for _, item in items :: { any } do
		local userId = tonumber(item.key)
		if userId and typeof(item.value) == "number" then
			table.insert(top, { userId = userId, name = nameCache[userId] or "Player", value = item.value })
		end
	end
	lastTop = top
	Net.event("LeaderboardUpdated"):FireAllClients(top)
end

function LeaderboardService.GetTop(): { Entry }
	return table.clone(lastTop)
end

function LeaderboardService.Init() end

function LeaderboardService.Start()
	task.spawn(function()
		while true do
			task.wait(FLUSH_SECONDS)
			flushAll(nil)
		end
	end)
	task.spawn(function()
		while true do
			refreshTop()
			task.wait(READ_SECONDS)
		end
	end)
	local function sendSnapshot(player: Player)
		Net.event("LeaderboardUpdated"):FireClient(player, lastTop)
	end
	Players.PlayerAdded:Connect(sendSnapshot)
	for _, player in Players:GetPlayers() do
		sendSnapshot(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		-- Flush this player now; anything that fails stays pending for the next cycle / shutdown.
		task.spawn(flushAll, player.UserId)
	end)
	game:BindToClose(function()
		flushAll()
	end)

	-- Wire round winners into the board when RoundService exists in the same folder.
	local roundModule = script.Parent:FindFirstChild("RoundService")
	if roundModule and roundModule:IsA("ModuleScript") then
		local RoundService = require(roundModule) :: any
		RoundService.WinnerDeclared.Event:Connect(function(winner: Player)
			LeaderboardService.AddWins(winner, 1)
		end)
	end
end

return LeaderboardService
