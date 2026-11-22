--!strict
--[[
	TradeService — player-to-player item trading without duplication.
	Location: ServerScriptService/Services/TradeService (ModuleScript)
	Depends on: DataService, TradeLogic (same folder); Shared/{Config, Guard, Net, RateLimiter}

	Flow:   TradeRequest(targetUserId) → target gets an invite → TradeRespond(fromUserId, true)
	        → both TradeSetOffer({ [itemId] = count }) → both TradeSetReady(version)
	        → after QUIET_SECONDS without changes the server executes atomically.

	Anti-dupe design (see references/sharp-edges.md CX-02, CX-36..CX-40):
	  • The server owns the session; clients only send intents. Offers are whitelisted and bounded.
	  • Any change clears both ready flags; ready is tied to the version the client saw.
	  • Execution re-validates BOTH inventories at execution time and mutates both inside one
	    synchronous block (nested DataService.Update) — no yields between check and mutate.
	  • One session per player; a per-session `executing` flag stops double execution.
	  • Leaving, data loss or policy restrictions cancel the trade.

	Crash safety (two profiles = two DataStore keys that can't be written atomically):
	  1. Before applying, the trade is written to a journal (TradeJournal_v1: "Trade_<id>" + a per-user index).
	  2. The swap and an `AppliedTrades[id]` marker are written into BOTH profiles in one synchronous block.
	  3. On every load, a profile missing the marker for a journaled trade reads the PARTNER's last saved data:
	       partner has the marker  → the trade committed; apply this player's side now (no dupe, no loss)
	       partner lacks it too    → neither side persisted; the trade never happened (consistent)
	  A player can't load elsewhere while the old server still holds their session lock, so the partner's
	  save (autosave/leave) lands before the reconciliation read.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Guard = require(Shared:WaitForChild("Guard"))
local Net = require(Shared:WaitForChild("Net"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local TradeLogic = require(script.Parent:WaitForChild("TradeLogic"))

local MAX_DISTINCT_ITEMS = 8
local MAX_COUNT_PER_ITEM = 999
local QUIET_SECONDS = 3 -- offers must be unchanged this long before execution (stops last-second swaps)
local INVITE_TTL_SECONDS = 30
local SAVE_EQUIP_SLOT = "Cosmetic"
local TRADE_COOLDOWN_SECONDS = 15 -- per player, after a completed trade (also caps DataStore writes)
local USER_INDEX_LENGTH = 20

-- Written synchronously before each trade (nothing buffered), so no BindToClose flush is needed.
local journal = DataStoreService:GetDataStore("TradeJournal_v1") -- cluau-ignore CL117

-- Server-side whitelist of tradeable items. Here: every shop item. Exclude untradeable ids explicitly.
local TRADEABLE: { [string]: boolean } = {}
for itemId in Config.Shop.Items do
	TRADEABLE[itemId] = true
end

local requestLimiter = RateLimiter.new(3, 0.2)
local actionLimiter = RateLimiter.new(8, 4)

local sessionsByUser: { [number]: TradeLogic.Session } = {}
local invites: { [number]: { [number]: number } } = {} -- targetUserId -> fromUserId -> expiresAt (os.clock)
local executing: { [string]: boolean } = {}
local tradingAllowed: { [Player]: boolean } = {}
local lastTradeAt: { [number]: number } = {} -- userId -> os.clock() of last completed trade

local TradeService = {}

local function notify(player: Player, kind: "success" | "error" | "info", text: string)
	Net.event("Notify"):FireClient(player, { kind = kind, text = text })
end

local function playerFor(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function viewFor(session: TradeLogic.Session, userId: number): { [string]: any }
	local partnerId = TradeLogic.partner(session, userId) :: number
	local partner = playerFor(partnerId)
	return {
		id = session.id,
		version = session.version,
		partnerName = if partner then partner.DisplayName else "?",
		yourOffer = session.offers[userId],
		theirOffer = session.offers[partnerId],
		youReady = session.ready[userId],
		theyReady = session.ready[partnerId],
		quietSeconds = QUIET_SECONDS,
	}
end

local function push(session: TradeLogic.Session)
	for _, userId in session.users do
		local player = playerFor(userId)
		if player then
			Net.event("TradeUpdated"):FireClient(player, viewFor(session, userId))
		end
	end
end

local function close(session: TradeLogic.Session, message: string?, kind: ("success" | "error" | "info")?)
	for _, userId in session.users do
		if sessionsByUser[userId] == session then
			sessionsByUser[userId] = nil
		end
		local player = playerFor(userId)
		if player then
			Net.event("TradeUpdated"):FireClient(player, nil)
			if message then
				notify(player, kind or "info", message)
			end
		end
	end
end

local function canTrade(player: Player): boolean
	local last = lastTradeAt[player.UserId]
	local coolingDown = last ~= nil and os.clock() - last < TRADE_COOLDOWN_SECONDS
	return tradingAllowed[player] == true and DataService.IsActive(player) and not coolingDown
end

-- Phase 1: journal the trade BEFORE any inventory changes. Returns false if any write failed.
local function writeJournal(session: TradeLogic.Session): boolean
	local userA, userB = session.users[1], session.users[2]
	local record = {
		Users = { userA, userB },
		Offers = { [tostring(userA)] = session.offers[userA], [tostring(userB)] = session.offers[userB] },
		Time = os.time(),
	}
	local ok = pcall(function()
		journal:UpdateAsync(`Trade_{session.id}`, function()
			return record
		end)
	end)
	if not ok then
		return false
	end
	for _, userId in session.users do
		local okIndex = pcall(function()
			journal:UpdateAsync(`UserTrades_{userId}`, function(old: any)
				local list = if type(old) == "table" then old else {}
				table.insert(list, session.id)
				while #list > USER_INDEX_LENGTH do
					table.remove(list, 1)
				end
				return list
			end)
		end)
		if not okIndex then
			return false
		end
	end
	return true
end

-- Load step: finish this player's side of any journaled trade that committed on the partner's side.
local function reconcile(player: Player, data: DataService.PlayerData)
	local ok, list = pcall(journal.GetAsync, journal, `UserTrades_{player.UserId}`)
	if not ok or type(list) ~= "table" then
		return
	end
	for _, tradeId in list :: { any } do
		if typeof(tradeId) ~= "string" or data.AppliedTrades[tradeId] ~= nil then
			continue
		end
		local okRecord, record = pcall(journal.GetAsync, journal, `Trade_{tradeId}`)
		if not okRecord or type(record) ~= "table" or type(record.Users) ~= "table" then
			continue
		end
		local partnerId = if record.Users[1] == player.UserId then record.Users[2] else record.Users[1]
		local partnerData = DataService.ReadSavedAsync(partnerId)
		local committed = partnerData ~= nil and type(partnerData.AppliedTrades) == "table" and partnerData.AppliedTrades[tradeId] ~= nil
		if committed then
			local give = record.Offers[tostring(player.UserId)] or {}
			local receive = record.Offers[tostring(partnerId)] or {}
			if TradeLogic.applyOneSide(data.Inventory, give, receive) then
				data.AppliedTrades[tradeId] = os.time()
				warn(`[Trade] reconciled half-saved trade {tradeId} for {player.UserId}`)
			else
				warn(`[Trade] CONFLICT reconciling {tradeId} for {player.UserId}: items missing — review manually`)
			end
		end
	end
end

-- Executes only if the session is still current, unchanged since `expectedVersion`, and both are ready.
local function tryExecute(session: TradeLogic.Session, expectedVersion: number)
	local userA, userB = session.users[1], session.users[2]
	if sessionsByUser[userA] ~= session or sessionsByUser[userB] ~= session then
		return
	end
	if session.version ~= expectedVersion or not TradeLogic.canExecute(session, os.clock(), QUIET_SECONDS) then
		return
	end
	if executing[session.id] then
		return
	end
	executing[session.id] = true

	local playerA, playerB = playerFor(userA), playerFor(userB)
	if playerA == nil or playerB == nil or not canTrade(playerA) or not canTrade(playerB) then
		executing[session.id] = nil
		close(session, "Trade cancelled.", "error")
		return
	end

	-- Phase 1 (yields): journal. Offers can't change meanwhile (`executing` blocks TradeSetOffer).
	if not writeJournal(session) then
		executing[session.id] = nil
		close(session, "Trade couldn't be saved safely. Nothing was exchanged — try again.", "error")
		return
	end
	-- Re-check everything after the yield: players may have left or lost their data session.
	playerA, playerB = playerFor(userA), playerFor(userB)
	if playerA == nil or playerB == nil or sessionsByUser[userA] ~= session or sessionsByUser[userB] ~= session
		or not DataService.IsActive(playerA) or not DataService.IsActive(playerB) then
		executing[session.id] = nil
		close(session, "Trade cancelled.", "error")
		return
	end

	-- ── synchronous section: NO yields from here until both inventories are updated ──
	local swapped = false
	DataService.Update(playerA, function(dataA)
		DataService.Update(playerB, function(dataB)
			swapped = TradeLogic.apply(dataA.Inventory, dataB.Inventory, session.offers[userA], session.offers[userB])
			if swapped then
				-- Phase 2: commit markers travel with each profile's own save.
				local now = os.time()
				dataA.AppliedTrades[session.id] = now
				dataB.AppliedTrades[session.id] = now
				-- Unequip anything that was traded away.
				for _, data in { dataA, dataB } do
					local equipped = data.Equipped[SAVE_EQUIP_SLOT]
					if equipped and (data.Inventory[equipped] or 0) <= 0 then
						data.Equipped[SAVE_EQUIP_SLOT] = nil
					end
				end
			end
		end)
	end)
	-- ── end synchronous section ──

	executing[session.id] = nil
	if not swapped then
		close(session, "Trade failed: items changed. Nothing was exchanged.", "error")
		return
	end
	lastTradeAt[userA] = os.clock()
	lastTradeAt[userB] = os.clock()
	close(session, "Trade complete!", "success")
	print(`[Trade] {session.id} {userA}<->{userB} completed`)
	task.spawn(DataService.SaveNow, playerA)
	task.spawn(DataService.SaveNow, playerB)
end

local function onRequest(player: Player, targetUserId: unknown)
	if not Guard.integer(targetUserId, 1, 2 ^ 53) or not requestLimiter:check(player) then
		return
	end
	local target = playerFor(targetUserId :: number)
	if target == nil or target == player then
		return
	end
	if not canTrade(player) or not canTrade(target) then
		notify(player, "error", "Trading isn't available for one of you right now.")
		return
	end
	if sessionsByUser[player.UserId] or sessionsByUser[target.UserId] then
		notify(player, "error", "One of you is already trading.")
		return
	end
	local pending = invites[target.UserId]
	if pending == nil then
		pending = {}
		invites[target.UserId] = pending
	end
	pending[player.UserId] = os.clock() + INVITE_TTL_SECONDS
	Net.event("TradeUpdated"):FireClient(target, { invite = { fromUserId = player.UserId, fromName = player.DisplayName } })
	notify(player, "info", `Trade request sent to {target.DisplayName}.`)
end

local function onRespond(player: Player, fromUserId: unknown, accept: unknown)
	if not Guard.integer(fromUserId, 1, 2 ^ 53) or not Guard.boolean(accept) or not actionLimiter:check(player) then
		return
	end
	local pending = invites[player.UserId]
	local expiresAt = if pending then pending[fromUserId :: number] else nil
	if pending == nil or expiresAt == nil then
		return
	end
	pending[fromUserId :: number] = nil
	local requester = playerFor(fromUserId :: number)
	if requester == nil or os.clock() > expiresAt then
		notify(player, "error", "That trade request expired.")
		return
	end
	if accept ~= true then
		notify(requester, "info", `{player.DisplayName} declined the trade.`)
		return
	end
	if sessionsByUser[player.UserId] or sessionsByUser[requester.UserId] or not canTrade(player) or not canTrade(requester) then
		notify(player, "error", "Trade could not start.")
		return
	end
	local session = TradeLogic.newSession(HttpService:GenerateGUID(false), requester.UserId, player.UserId, os.clock())
	if session == nil then
		return
	end
	sessionsByUser[requester.UserId] = session
	sessionsByUser[player.UserId] = session
	push(session)
end

local function onSetOffer(player: Player, rawOffer: unknown)
	if not actionLimiter:check(player) then
		return
	end
	local session = sessionsByUser[player.UserId]
	local profile = DataService.GetProfile(player)
	if session == nil or profile == nil or executing[session.id] then
		return
	end
	local offer = TradeLogic.sanitizeOffer(rawOffer, TRADEABLE, MAX_DISTINCT_ITEMS, MAX_COUNT_PER_ITEM)
	if offer == nil or not TradeLogic.hasItems(profile.Data.Inventory, offer) then
		notify(player, "error", "You don't have those items.")
		return
	end
	TradeLogic.setOffer(session, player.UserId, offer, os.clock())
	push(session)
end

local function onSetReady(player: Player, version: unknown)
	if not actionLimiter:check(player) then
		return
	end
	local session = sessionsByUser[player.UserId]
	if session == nil or not TradeLogic.setReady(session, player.UserId, version) then
		return
	end
	push(session)
	local expectedVersion = session.version
	local delaySeconds = QUIET_SECONDS - (os.clock() - session.changedAt)
	if delaySeconds > 0 then
		task.delay(delaySeconds + 0.05, tryExecute, session, expectedVersion)
	else
		tryExecute(session, expectedVersion)
	end
end

local function onCancel(player: Player)
	local session = sessionsByUser[player.UserId]
	if session and not executing[session.id] then
		close(session, `{player.DisplayName} cancelled the trade.`, "info")
	end
end

local function loadPolicy(player: Player)
	-- Conservative: if the policy can't be read, trading stays disabled for this player.
	local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	if ok and typeof(info) == "table" and player.Parent == Players then
		tradingAllowed[player] = (info :: any).IsPaidItemTradingAllowed ~= false
	end
end

function TradeService.Init()
	DataService.AddLoadStep(reconcile)
end

function TradeService.Start()
	Net.event("TradeRequest").OnServerEvent:Connect(onRequest)
	Net.event("TradeRespond").OnServerEvent:Connect(onRespond)
	Net.event("TradeSetOffer").OnServerEvent:Connect(onSetOffer)
	Net.event("TradeSetReady").OnServerEvent:Connect(onSetReady)
	Net.event("TradeCancel").OnServerEvent:Connect(onCancel)

	Players.PlayerAdded:Connect(loadPolicy)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPolicy, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		onCancel(player)
		local session = sessionsByUser[player.UserId]
		if session then
			close(session, "Your trade partner left.", "info")
		end
		invites[player.UserId] = nil
		tradingAllowed[player] = nil
	end)
end

return TradeService
