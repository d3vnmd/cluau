--!strict
local H = require("./harness")
local TradeLogic = require("../../skills/cluau/templates/server/TradeLogic")
local describe, it, expect = H.describe, H.it, H.expect

local TRADEABLE = { Sword = true, Shield = true, Pet = true }

local function count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

describe("TradeLogic.sanitizeOffer", function()
	it("accepts a clean whitelisted offer", function()
		local offer = TradeLogic.sanitizeOffer({ Sword = 1, Pet = 3 }, TRADEABLE, 8, 99) :: TradeLogic.Offer
		expect(offer.Sword).toBe(1)
		expect(offer.Pet).toBe(3)
	end)

	it("rejects non-whitelisted ids, NaN, negative, zero, fractional and huge counts", function()
		for _, bad in {
			{ Admin = 1 },
			{ Sword = 0 / 0 },
			{ Sword = -1 },
			{ Sword = 0 },
			{ Sword = 1.5 },
			{ Sword = 1000 },
			{ Sword = math.huge },
			{ Sword = "1" },
			{ [1] = 1 },
		} do
			expect(TradeLogic.sanitizeOffer(bad, TRADEABLE, 8, 999)).toBeNil()
		end
	end)

	it("rejects non-table payloads and oversized offers", function()
		expect(TradeLogic.sanitizeOffer("Sword", TRADEABLE, 8, 99)).toBeNil()
		expect(TradeLogic.sanitizeOffer({ Sword = 1, Shield = 1, Pet = 1 }, TRADEABLE, 2, 99)).toBeNil()
	end)

	it("an empty offer is allowed (gift / one-sided trade)", function()
		local offer = TradeLogic.sanitizeOffer({}, TRADEABLE, 8, 99) :: TradeLogic.Offer
		expect(count(offer)).toBe(0)
	end)
end)

describe("TradeLogic.apply", function()
	it("swaps items and removes zero entries", function()
		local a = { Sword = 1, Shield = 2 }
		local b = { Pet = 1 }
		expect(TradeLogic.apply(a, b, { Sword = 1 }, { Pet = 1 })).toBe(true)
		expect(a.Sword).toBeNil()
		expect(a.Pet).toBe(1)
		expect(a.Shield).toBe(2)
		expect(b.Sword).toBe(1)
		expect(b.Pet).toBeNil()
	end)

	it("is all-or-nothing when either side lacks items (no partial transfer)", function()
		local a = { Sword = 1 }
		local b = { Pet = 0 }
		expect(TradeLogic.apply(a, b, { Sword = 1 }, { Pet = 1 })).toBe(false)
		expect(a.Sword).toBe(1)
		expect(b.Sword).toBeNil()
	end)

	it("refuses trading with the same inventory (self-trade dupe)", function()
		local a = { Sword = 1 }
		expect(TradeLogic.apply(a, a, { Sword = 1 }, {})).toBe(false)
		expect(a.Sword).toBe(1)
	end)

	it("total item count is conserved", function()
		local a = { Sword = 3, Shield = 1 }
		local b = { Pet = 2, Sword = 1 }
		local before = a.Sword + a.Shield + b.Pet + b.Sword
		TradeLogic.apply(a, b, { Sword = 2 }, { Pet = 2 })
		local after = 0
		for _, inv in { a, b } do
			for _, n in inv do
				after += n
			end
		end
		expect(after).toBe(before)
	end)
end)

describe("TradeLogic sessions", function()
	it("cannot open a session with yourself", function()
		expect(TradeLogic.newSession("t", 1, 1, 0)).toBeNil()
	end)

	it("changing an offer clears BOTH ready flags and bumps the version", function()
		local s = TradeLogic.newSession("t", 1, 2, 0) :: TradeLogic.Session
		expect(TradeLogic.setReady(s, 1, s.version)).toBe(true)
		expect(TradeLogic.setReady(s, 2, s.version)).toBe(true)
		TradeLogic.setOffer(s, 2, { Pet = 1 }, 5)
		expect(s.ready[1]).toBe(false)
		expect(s.ready[2]).toBe(false)
		expect(s.version).toBe(1)
	end)

	it("ready for a stale version is rejected (bait-and-switch)", function()
		local s = TradeLogic.newSession("t", 1, 2, 0) :: TradeLogic.Session
		local seen = s.version
		TradeLogic.setOffer(s, 2, { Pet = 1 }, 1)
		expect(TradeLogic.setReady(s, 1, seen)).toBe(false)
		expect(TradeLogic.setReady(s, 1, "0")).toBe(false)
		expect(TradeLogic.setReady(s, 1, s.version)).toBe(true)
	end)

	it("non-members can't change offers or ready up", function()
		local s = TradeLogic.newSession("t", 1, 2, 0) :: TradeLogic.Session
		expect(TradeLogic.setOffer(s, 3, { Sword = 1 }, 1)).toBe(false)
		expect(TradeLogic.setReady(s, 3, s.version)).toBe(false)
	end)

	it("executes only after both are ready AND the quiet period has passed", function()
		local s = TradeLogic.newSession("t", 1, 2, 0) :: TradeLogic.Session
		TradeLogic.setOffer(s, 1, { Sword = 1 }, 10)
		TradeLogic.setReady(s, 1, s.version)
		expect(TradeLogic.canExecute(s, 20, 3)).toBe(false) -- partner not ready
		TradeLogic.setReady(s, 2, s.version)
		expect(TradeLogic.canExecute(s, 11, 3)).toBe(false) -- changed 1s ago
		expect(TradeLogic.canExecute(s, 13, 3)).toBe(true)
	end)

	it("partner() resolves the other member", function()
		local s = TradeLogic.newSession("t", 10, 20, 0) :: TradeLogic.Session
		expect(TradeLogic.partner(s, 10)).toBe(20)
		expect(TradeLogic.partner(s, 20)).toBe(10)
		expect(TradeLogic.partner(s, 30)).toBeNil()
	end)
end)

return nil
