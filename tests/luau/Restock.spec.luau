--!strict
local H = require("./harness")
local Restock = require("../../skills/cluau/templates/shared/Restock")
local describe, it, expect = H.describe, H.it, H.expect

local ENTRIES = {
	{ id = "Carrot", chance = 1.0, minQty = 5, maxQty = 25 },
	{ id = "Corn", chance = 0.5, minQty = 1, maxQty = 6 },
	{ id = "Mango", chance = 0.1, minQty = 1, maxQty = 2 },
}

describe("Restock", function()
	it("slot and countdown math", function()
		expect(Restock.slot(1000, 300)).toBe(3)
		expect(Restock.secondsUntilNext(1000, 300)).toBe(200)
		expect(Restock.secondsUntilNext(900, 300)).toBe(300)
	end)

	it("is deterministic: same slot + salt => same stock (every server agrees)", function()
		for slot = 1, 50 do
			local a = Restock.stockFor(slot, 7, ENTRIES)
			local b = Restock.stockFor(slot, 7, ENTRIES)
			for _, e in ENTRIES do
				expect(a[e.id]).toBe(b[e.id])
			end
		end
	end)

	it("different slots or salts give different rotations", function()
		local differences = 0
		for slot = 1, 40 do
			local a = Restock.stockFor(slot, 7, ENTRIES)
			local b = Restock.stockFor(slot + 1, 7, ENTRIES)
			local c = Restock.stockFor(slot, 8, ENTRIES)
			if a.Corn ~= b.Corn or a.Carrot ~= b.Carrot then
				differences += 1
			end
			if a.Corn ~= c.Corn or a.Carrot ~= c.Carrot then
				differences += 1
			end
		end
		expect(differences > 60).toBe(true)
	end)

	it("respects chance and quantity bounds over many slots", function()
		local carrots, corns, mangos = 0, 0, 0
		for slot = 1, 2000 do
			local s = Restock.stockFor(slot, 3, ENTRIES)
			if s.Carrot then
				carrots += 1
				expect(s.Carrot >= 5 and s.Carrot <= 25).toBe(true)
			end
			if s.Corn then
				corns += 1
				expect(s.Corn >= 1 and s.Corn <= 6).toBe(true)
			end
			if s.Mango then
				mangos += 1
			end
		end
		expect(carrots).toBe(2000) -- chance 1.0 always appears
		expect(corns > 850 and corns < 1150).toBe(true) -- ~50%
		expect(mangos > 120 and mangos < 290).toBe(true) -- ~10%
	end)

	it("appending a new entry never reshuffles existing items", function()
		local extended = table.clone(ENTRIES)
		table.insert(extended, { id = "Dragonfruit", chance = 0.05, minQty = 1, maxQty = 1 })
		for slot = 1, 30 do
			local before = Restock.stockFor(slot, 7, ENTRIES)
			local after = Restock.stockFor(slot, 7, extended)
			for _, e in ENTRIES do
				expect(after[e.id]).toBe(before[e.id])
			end
		end
	end)

	it("generator outputs are in [0, 1)", function()
		local random = Restock.generator(123, 4)
		for _ = 1, 1000 do
			local v = random()
			expect(v >= 0 and v < 1).toBe(true)
		end
	end)
end)

return nil
