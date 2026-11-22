--!strict
--[[
	TradeLogic — pure, engine-free trade rules (unit-tested with Lune: tests/luau/TradeLogic.spec.luau).
	Location: ServerScriptService/Services/TradeLogic (ModuleScript). Used by TradeService.

	Why a separate pure module: item duplication bugs live in trade code. Keeping the rules free of
	Instances, yields and remotes means every edge case (NaN counts, stale versions, partial transfers,
	last-second offer swaps) can be tested without Studio.

	Invariants enforced here:
	  • An offer is a whitelist-filtered map itemId -> positive integer count, bounded in size.
	  • Any offer change bumps `version` and clears BOTH players' ready flags (anti bait-and-switch).
	  • Ready only counts for the exact version the player saw.
	  • Execution requires both ready, a quiet period since the last change, and re-validated
	    inventories; it mutates both inventories or neither.
]]

export type Inventory = { [string]: number }
export type Offer = { [string]: number }

export type Session = {
	id: string,
	users: { number }, -- exactly two userIds
	offers: { [number]: Offer },
	ready: { [number]: boolean },
	version: number,
	changedAt: number,
}

local TradeLogic = {}

local function isPositiveInteger(n: unknown, max: number): boolean
	if typeof(n) ~= "number" then
		return false
	end
	local v = n :: number
	return v == v and v % 1 == 0 and v >= 1 and v <= max
end

--- Validates an untrusted client offer. Returns a clean Offer or nil.
--- `tradeable` is a server-side whitelist (itemId -> anything truthy).
function TradeLogic.sanitizeOffer(raw: unknown, tradeable: { [string]: any }, maxDistinct: number, maxCount: number): Offer?
	if typeof(raw) ~= "table" then
		return nil
	end
	local clean: Offer = {}
	local distinct = 0
	for key, value in raw :: { [any]: any } do
		distinct += 1
		if distinct > maxDistinct then
			return nil -- oversized payload: reject before doing more work
		end
		if typeof(key) ~= "string" or #key > 64 or tradeable[key] == nil then
			return nil
		end
		if not isPositiveInteger(value, maxCount) then
			return nil
		end
		clean[key :: string] = value :: number
	end
	return clean
end

--- True if `inventory` holds at least every count in `offer`.
function TradeLogic.hasItems(inventory: Inventory, offer: Offer): boolean
	for itemId, count in offer do
		if (inventory[itemId] or 0) < count then
			return false
		end
	end
	return true
end

local function move(from: Inventory, to: Inventory, offer: Offer)
	for itemId, count in offer do
		local remaining = (from[itemId] or 0) - count
		from[itemId] = if remaining > 0 then remaining else nil
		to[itemId] = (to[itemId] or 0) + count
	end
end

--- Atomically swaps offers between two inventories. Validates first; mutates both or neither.
--- Must be called with no yields between the caller's checks and this call.
function TradeLogic.apply(inventoryA: Inventory, inventoryB: Inventory, offerA: Offer, offerB: Offer): boolean
	if inventoryA == inventoryB then
		return false -- trading with yourself
	end
	if not TradeLogic.hasItems(inventoryA, offerA) or not TradeLogic.hasItems(inventoryB, offerB) then
		return false
	end
	move(inventoryA, inventoryB, offerA)
	move(inventoryB, inventoryA, offerB)
	return true
end

function TradeLogic.newSession(id: string, userA: number, userB: number, now: number): Session?
	if userA == userB then
		return nil
	end
	return {
		id = id,
		users = { userA, userB },
		offers = { [userA] = {}, [userB] = {} },
		ready = { [userA] = false, [userB] = false },
		version = 0,
		changedAt = now,
	}
end

function TradeLogic.isMember(session: Session, userId: number): boolean
	return session.users[1] == userId or session.users[2] == userId
end

function TradeLogic.partner(session: Session, userId: number): number?
	if session.users[1] == userId then
		return session.users[2]
	elseif session.users[2] == userId then
		return session.users[1]
	end
	return nil
end

--- Replaces a member's offer. Clears both ready flags and bumps the version.
function TradeLogic.setOffer(session: Session, userId: number, offer: Offer, now: number): boolean
	if not TradeLogic.isMember(session, userId) then
		return false
	end
	session.offers[userId] = offer
	session.version += 1
	session.changedAt = now
	for _, member in session.users do
		session.ready[member] = false
	end
	return true
end

--- Marks a member ready for the exact `version` they were shown. Stale versions are rejected.
function TradeLogic.setReady(session: Session, userId: number, version: unknown): boolean
	if not TradeLogic.isMember(session, userId) then
		return false
	end
	if typeof(version) ~= "number" or version ~= session.version then
		return false
	end
	session.ready[userId] = true
	return true
end

--- Both ready, and the offers have been unchanged for at least `quietSeconds`.
function TradeLogic.canExecute(session: Session, now: number, quietSeconds: number): boolean
	local a, b = session.users[1], session.users[2]
	return session.ready[a] == true and session.ready[b] == true and now - session.changedAt >= quietSeconds
end

return table.freeze(TradeLogic)
