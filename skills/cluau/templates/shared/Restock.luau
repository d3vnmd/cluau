--!strict
--[[
	Restock — deterministic global shop rotations (the 2025–26 farming/idle pattern).
	Location: ReplicatedStorage/Shared/Restock (ModuleScript). Pure; unit-tested with Lune.

	Every server computes the SAME stock for the same time slot without any cross-server messaging:
		slot  = floor(unixTime / periodSeconds)
		stock = deterministic roll seeded by (slot, salt)
	Clients may compute it too (to show "next restock in 3:12"), but the SERVER re-computes the stock at
	purchase time and never trusts a client's idea of what is in stock (sharp-edges: buy-from-stale-stock).

	local entries = {
		{ id = "Carrot", chance = 1.0, minQty = 5, maxQty = 25 },
		{ id = "Mango", chance = 0.15, minQty = 1, maxQty = 2 },
	}
	local slot = Restock.slot(os.time(), 300)
	local stock = Restock.stockFor(slot, 7, entries)   -- { Carrot = 12, Mango = 1 } or { Carrot = 9 }
]]

export type Entry = {
	id: string,
	chance: number, -- 0..1 probability this item appears in a slot
	minQty: number,
	maxQty: number,
}

local Restock = {}

local UINT32 = 4294967296

-- xorshift32 on bit32: identical results on every server and in Lune (no engine Random needed).
local function nextState(state: number): number
	state = bit32.bxor(state, bit32.lshift(state, 13))
	state = bit32.bxor(state, bit32.rshift(state, 17))
	state = bit32.bxor(state, bit32.lshift(state, 5))
	return state
end

local function seedFrom(slot: number, salt: number): number
	-- Mix slot and salt into a non-zero 32-bit state.
	local s = bit32.bxor(slot % UINT32, bit32.lrotate((salt * 2654435761) % UINT32, 7))
	s = nextState(if s == 0 then 0x9E3779B9 else s)
	return nextState(s)
end

--- Deterministic generator: returns a function producing floats in [0, 1).
function Restock.generator(slot: number, salt: number): () -> number
	local state = seedFrom(slot, salt)
	return function(): number
		state = nextState(state)
		return state / UINT32
	end
end

--- Current slot index for a unix time and a period in seconds.
function Restock.slot(unixTime: number, periodSeconds: number): number
	assert(periodSeconds > 0, "periodSeconds must be > 0")
	return math.floor(unixTime / periodSeconds)
end

--- Seconds until the next slot begins.
function Restock.secondsUntilNext(unixTime: number, periodSeconds: number): number
	return periodSeconds - (unixTime % periodSeconds)
end

--- The stock for `slot`: itemId -> quantity, for every entry that rolled in. Deterministic.
function Restock.stockFor(slot: number, salt: number, entries: { Entry }): { [string]: number }
	local random = Restock.generator(slot, salt)
	local stock: { [string]: number } = {}
	for _, entry in entries do
		-- Always draw both numbers so adding an item at the end never reshuffles earlier items.
		local appearRoll = random()
		local qtyRoll = random()
		if appearRoll < entry.chance then
			local span = math.max(0, entry.maxQty - entry.minQty)
			stock[entry.id] = entry.minQty + math.floor(qtyRoll * (span + 1))
		end
	end
	return stock
end

return table.freeze(Restock)
