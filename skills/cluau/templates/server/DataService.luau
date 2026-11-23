--!strict
--[[
	DataService — session-locked player data on top of GlobalDataStore:UpdateAsync.
	Location: ServerScriptService/Services/DataService (ModuleScript)

	Guarantees:
	  • One server owns a player's data at a time (session lock in the saved record).
	  • A failed load kicks the player instead of letting them play on (and later save) blank data.
	  • Retries with exponential backoff; autosave only when dirty; final save on leave and on shutdown.
	  • Versioned schema with ordered migrations; missing fields reconciled from TEMPLATE.

	Public API:
	  DataService.WaitForProfile(player, timeout?) -> Profile?
	  DataService.GetProfile(player) -> Profile?
	  DataService.Update(player, mutator: (data) -> ()) -> boolean   -- marks dirty + replicates
	  DataService.AddCoins(player, amount) -> boolean
	  DataService.SaveNow(player) -> boolean
	  DataService.IsActive(player) -> boolean

	Studio: Game Settings → Security → Enable Studio Access to API Services.
	If you prefer ProfileStore, see references/data-persistence.md — keep this module's public API
	and swap the internals.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

export type PlayerData = {
	Version: number,
	Coins: number,
	Inventory: { [string]: number },
	Equipped: { [string]: string },
	Settings: { Music: number, Sfx: number, ReducedMotion: boolean },
	ProcessedReceipts: { [string]: number },
	AppliedTrades: { [string]: number }, -- tradeId -> os.time(); lets TradeService reconcile half-saved trades
	StockPurchases: { Slot: number, Counts: { [string]: number } }, -- LiveOps per-player stock for the current slot
	Stats: { JoinCount: number, PlaytimeSeconds: number },
}

export type Profile = {
	Data: PlayerData,
	Key: string,
	Dirty: boolean,
	Saving: boolean,
	SaveQueued: boolean,
	QueuedRelease: boolean,
	LastSaveOk: boolean,
	LockRefreshedAt: number, -- os.time() of the last successful write (lock heartbeat)
	Released: boolean,
	JoinedAt: number,
}

type Record = {
	Data: { [string]: any },
	Lock: { SessionId: string, Time: number }?,
}

local CURRENT_VERSION = 2
local LOCK_EXPIRE_SECONDS = 10 * 60 -- a lock older than this is considered abandoned (server crashed)
local LOAD_ATTEMPTS = 6
local SAVE_ATTEMPTS = 3
local SHUTDOWN_BUDGET_SECONDS = 25
local MAX_PROCESSED_RECEIPTS = 100

-- Unique per running server (game.JobId is "" in Studio, so generate our own).
local SESSION_ID = HttpService:GenerateGUID(false)
-- In solo Studio testing, a crashed previous session can leave a lock behind; take it over.
local STEAL_LOCKS_IN_STUDIO = true

local TEMPLATE: PlayerData = {
	Version = CURRENT_VERSION,
	Coins = Config.Currency.StartingCoins,
	Inventory = {},
	Equipped = {},
	Settings = { Music = 0.6, Sfx = 0.8, ReducedMotion = false },
	ProcessedReceipts = {},
	AppliedTrades = {},
	StockPurchases = { Slot = -1, Counts = {} },
	Stats = { JoinCount = 0, PlaytimeSeconds = 0 },
}

-- MIGRATIONS[n] upgrades data from version n to n + 1. Never edit a shipped migration; add a new one.
local MIGRATIONS: { [number]: (data: { [string]: any }) -> () } = {
	[1] = function(data)
		-- v1 stored coins as "Money"
		if data.Money ~= nil and data.Coins == nil then
			data.Coins = data.Money
		end
		data.Money = nil
	end,
}

local store = DataStoreService:GetDataStore(Config.Data.StoreName)

local profiles: { [Player]: Profile } = {}
local loadSteps: { (player: Player, data: PlayerData) -> () } = {}
local waiting: { [Player]: { thread } } = {}
local pendingSaves = 0

local DataService = {}

-- ─── helpers ────────────────────────────────────────────────────────────────

local function deepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value :: any do
		copy[key] = deepCopy(child)
	end
	return copy :: any
end

-- Fills keys missing in `target` from `template` without overwriting existing values.
local function reconcile(target: { [string]: any }, template: { [string]: any })
	for key, templateValue in template do
		local current = target[key]
		if current == nil then
			target[key] = deepCopy(templateValue)
		elseif type(templateValue) == "table" and type(current) == "table" and next(templateValue) ~= nil then
			reconcile(current, templateValue)
		end
	end
end

local function migrate(data: { [string]: any })
	local version = if type(data.Version) == "number" then data.Version else 1
	while version < CURRENT_VERSION do
		local step = MIGRATIONS[version]
		if step then
			step(data)
		end
		version += 1
	end
	data.Version = CURRENT_VERSION
end

-- Key pattern: EXISTING games must keep whatever pattern they already use (changing it orphans every save).
-- NEW games: prefer `User_{UserId}` and pass `{ player.UserId }` as UpdateAsync's userIds metadata so Roblox's
-- automated right-to-be-forgotten templates can find the key.
local function keyForUserId(userId: number): string
	return `Player_{userId}`
end

local function keyFor(player: Player): string
	return keyForUserId(player.UserId)
end

local function isOurs(record: any): boolean
	return type(record) == "table"
		and type(record.Lock) == "table"
		and record.Lock.SessionId == SESSION_ID
end

local function resumeWaiters(player: Player, profile: Profile?)
	local threads = waiting[player]
	waiting[player] = nil
	if threads then
		for _, thread in threads do
			task.spawn(thread, profile)
		end
	end
end

local function replicate(player: Player, profile: Profile)
	local data = profile.Data
	player:SetAttribute("Coins", data.Coins)
	Net.event("DataSnapshot"):FireClient(player, {
		Coins = data.Coins,
		Inventory = data.Inventory,
		Equipped = data.Equipped,
		Settings = data.Settings,
	})
end

-- ─── load ───────────────────────────────────────────────────────────────────

type LoadResult = "ok" | "locked" | "error"

local function tryLoadOnce(key: string): (LoadResult, Record?)
	local loaded: Record? = nil
	local locked = false

	local ok, err = pcall(function()
		store:UpdateAsync(key, function(old: any): any
			-- This callback can run more than once: reset captured state and keep it pure (no yields).
			loaded = nil
			locked = false
			local now = os.time()
			local record: Record? = if type(old) == "table" and type(old.Data) == "table" then old else nil

			if record and record.Lock and record.Lock.SessionId ~= SESSION_ID then
				local age = now - record.Lock.Time
				local mayStealInStudio = STEAL_LOCKS_IN_STUDIO and RunService:IsStudio()
				if age < LOCK_EXPIRE_SECONDS and not mayStealInStudio then
					locked = true
					return nil -- cancel the write; another live server owns this data
				end
			end

			local newRecord: Record = {
				Data = if record then record.Data else deepCopy(TEMPLATE) :: any,
				Lock = { SessionId = SESSION_ID, Time = now },
			}
			loaded = newRecord
			return newRecord
		end)
	end)

	if not ok then
		warn(`[DataService] load error for {key}: {err}`)
		return "error", nil
	end
	if locked then
		return "locked", nil
	end
	return "ok", loaded
end

local function loadRecord(key: string): Record?
	for attempt = 1, LOAD_ATTEMPTS do
		local result, record = tryLoadOnce(key)
		if result == "ok" then
			return record
		end
		-- "locked": the previous server is probably still saving this player's leave. Wait and retry.
		if attempt < LOAD_ATTEMPTS then
			task.wait(math.min(2 ^ attempt, 15))
		end
	end
	return nil
end

-- ─── save ───────────────────────────────────────────────────────────────────

local function trimReceipts(receipts: { [string]: number })
	local list = {}
	for purchaseId, time in receipts do
		table.insert(list, { id = purchaseId, time = time })
	end
	if #list <= MAX_PROCESSED_RECEIPTS then
		return
	end
	table.sort(list, function(a, b)
		return a.time > b.time
	end)
	for index = MAX_PROCESSED_RECEIPTS + 1, #list do
		receipts[list[index].id] = nil
	end
end

local function saveProfile(player: Player, profile: Profile, release: boolean): boolean
	-- Coalesce: while a save is in flight, at most ONE follow-up save is queued; every other caller waits
	-- for that queued save and shares its result. Spamming saves (e.g. rapid trades) can't burn the budget.
	if profile.Saving then
		profile.QueuedRelease = profile.QueuedRelease or release
		if profile.SaveQueued then
			while profile.SaveQueued or profile.Saving do
				task.wait(0.1)
			end
			return profile.LastSaveOk
		end
		profile.SaveQueued = true
		while profile.Saving do
			task.wait(0.1)
		end
		profile.SaveQueued = false
		release = release or profile.QueuedRelease
		profile.QueuedRelease = false
	end
	if profile.Released then
		return false
	end
	profile.Saving = true
	pendingSaves += 1

	trimReceipts(profile.Data.ProcessedReceipts)
	trimReceipts(profile.Data.AppliedTrades)
	local snapshot = deepCopy(profile.Data) -- freeze what we're writing; later edits mark Dirty again
	profile.Dirty = false

	local saved = false
	local lostLock = false
	for attempt = 1, SAVE_ATTEMPTS do
		local ok, err = pcall(function()
			store:UpdateAsync(profile.Key, function(old: any): any
				lostLock = false
				if not isOurs(old) then
					lostLock = true
					return nil -- someone else owns this data now; never overwrite it
				end
				return {
					Data = snapshot,
					Lock = if release then nil else { SessionId = SESSION_ID, Time = os.time() },
				}
			end)
		end)
		if ok then
			saved = not lostLock
			break
		end
		warn(`[DataService] save attempt {attempt}/{SAVE_ATTEMPTS} failed for {profile.Key}: {err}`)
		if attempt < SAVE_ATTEMPTS then
			task.wait(2 ^ attempt)
		end
	end

	if not saved then
		profile.Dirty = true
	else
		profile.LockRefreshedAt = os.time()
	end
	profile.LastSaveOk = saved
	if lostLock then
		profile.Released = true
		if player.Parent == Players then
			player:Kick("Your data was opened on another server. Please rejoin.")
		end
	elseif release and saved then
		profile.Released = true
	end

	profile.Saving = false
	pendingSaves -= 1
	return saved
end

-- ─── lifecycle ──────────────────────────────────────────────────────────────

local function onPlayerAdded(player: Player)
	local key = keyFor(player)
	local record = loadRecord(key)

	if record == nil then
		resumeWaiters(player, nil)
		if player.Parent == Players then
			player:Kick("We couldn't load your save. Your progress is safe — please rejoin in a minute.")
		end
		return
	end

	local data = record.Data
	migrate(data)
	reconcile(data, TEMPLATE :: any)

	local profile: Profile = {
		Data = data :: any,
		Key = key,
		Dirty = false,
		Saving = false,
		SaveQueued = false,
		QueuedRelease = false,
		LastSaveOk = true,
		LockRefreshedAt = os.time(),
		Released = false,
		JoinedAt = os.clock(),
	}
	profile.Data.Stats.JoinCount += 1
	profile.Dirty = true

	-- Load steps (e.g. TradeService reconciliation) may yield; the profile isn't active yet, so nothing
	-- else can read or mutate it meanwhile.
	for _, step in loadSteps do
		local ok, err = pcall(step, player, profile.Data)
		if not ok then
			warn(`[DataService] load step failed for {key}: {err}`)
		end
	end

	if player.Parent ~= Players then
		-- Left while loading: write back and release the lock immediately.
		saveProfile(player, profile, true)
		resumeWaiters(player, nil)
		return
	end

	profiles[player] = profile
	replicate(player, profile)
	resumeWaiters(player, profile)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile == nil then
		resumeWaiters(player, nil)
		return
	end
	profile.Data.Stats.PlaytimeSeconds += math.floor(os.clock() - profile.JoinedAt)
	saveProfile(player, profile, true)
	profiles[player] = nil
end

local function autosaveLoop()
	while true do
		task.wait(Config.Data.AutosaveSeconds)
		local list = {}
		local now = os.time()
		for player, profile in profiles do
			-- Also save idle profiles before their lock looks abandoned (heartbeat), or a server hop after
			-- a long idle period would let another server steal the lock and discard this server's last save.
			local lockAging = now - profile.LockRefreshedAt > LOCK_EXPIRE_SECONDS / 2
			if (profile.Dirty or lockAging) and not profile.Released then
				table.insert(list, player)
			end
		end
		-- Stagger saves across the interval so we don't burst the DataStore budget.
		local gap = if #list > 0 then math.min(1, Config.Data.AutosaveSeconds / (#list * 2)) else 0
		for _, player in list do
			local profile = profiles[player]
			if profile then
				task.spawn(saveProfile, player, profile, false)
				task.wait(gap)
			end
		end
	end
end

local function onShutdown()
	local remaining = 0
	for player, profile in profiles do
		remaining += 1
		task.spawn(function()
			saveProfile(player, profile, true)
			remaining -= 1
		end)
	end
	-- Wait for our release saves AND any in-flight saves (autosave, PlayerRemoving) to finish.
	local deadline = os.clock() + SHUTDOWN_BUDGET_SECONDS
	while (remaining > 0 or pendingSaves > 0) and os.clock() < deadline do
		task.wait(0.1)
	end
end

-- ─── public API ─────────────────────────────────────────────────────────────

function DataService.GetProfile(player: Player): Profile?
	local profile = profiles[player]
	if profile and not profile.Released then
		return profile
	end
	return nil
end

function DataService.IsActive(player: Player): boolean
	return DataService.GetProfile(player) ~= nil
end

--- Yields until the player's data is loaded (or fails / times out). Returns nil on failure.
function DataService.WaitForProfile(player: Player, timeout: number?): Profile?
	local existing = DataService.GetProfile(player)
	if existing then
		return existing
	end
	if player.Parent ~= Players then
		return nil
	end
	local thread = coroutine.running()
	local list = waiting[player]
	if list == nil then
		list = {}
		waiting[player] = list
	end
	table.insert(list, thread)

	local timer = task.delay(timeout or 30, function()
		local current = waiting[player]
		local index = if current then table.find(current, thread) else nil
		if current and index then
			table.remove(current, index)
			task.spawn(thread, nil)
		end
	end)
	local profile = coroutine.yield()
	task.cancel(timer)
	return profile
end

--- Runs `mutator` on the player's data, marks it dirty and replicates. Returns false if no active profile.
function DataService.Update(player: Player, mutator: (data: PlayerData) -> ()): boolean
	local profile = DataService.GetProfile(player)
	if profile == nil then
		return false
	end
	mutator(profile.Data)
	profile.Dirty = true
	replicate(player, profile)
	return true
end

function DataService.AddCoins(player: Player, amount: number): boolean
	if amount ~= amount or math.abs(amount) == math.huge then
		return false
	end
	return DataService.Update(player, function(data)
		data.Coins = math.clamp(math.floor(data.Coins + amount), 0, Config.Currency.MaxCoins)
	end)
end

--- Saves immediately (keeps the lock). Use after purchases. Returns true on success.
function DataService.SaveNow(player: Player): boolean
	local profile = DataService.GetProfile(player)
	if profile == nil then
		return false
	end
	return saveProfile(player, profile, false)
end

--- Reads another player's LAST SAVED data without touching its session lock (fresh read, no 4 s cache).
--- Read-only: never write the result back. Used e.g. to reconcile trades. Returns nil on failure.
function DataService.ReadSavedAsync(userId: number): { [string]: any }?
	local options = Instance.new("DataStoreGetOptions")
	options.UseCache = false
	local ok, record = pcall(store.GetAsync, store, keyForUserId(userId), options)
	if ok and type(record) == "table" and type(record.Data) == "table" then
		return record.Data
	end
	return nil
end

--- Registers a function run on every freshly loaded profile BEFORE it becomes active (may yield).
--- Call during Init. Used for reconciliations/migrations that need other DataStores.
function DataService.AddLoadStep(step: (player: Player, data: PlayerData) -> ())
	table.insert(loadSteps, step)
end

function DataService.Init() end

function DataService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	game:BindToClose(onShutdown)
	task.spawn(autosaveLoop)
end

return DataService
