--!strict
local H = require("./harness")
local Trove = require("../../skills/cluau/templates/shared/Trove")
local describe, it, expect = H.describe, H.it, H.expect

describe("Trove", function()
	it("runs cleanup functions in reverse order", function()
		local order = {}
		local trove = Trove.new()
		trove:Add(function()
			table.insert(order, 1)
		end)
		trove:Add(function()
			table.insert(order, 2)
		end)
		trove:Clean()
		expect(table.concat(order, ",")).toBe("2,1")
	end)

	it("calls Destroy on objects and empties itself", function()
		local destroyed = 0
		local obj = {
			Destroy = function()
				destroyed += 1
			end,
		}
		local trove = Trove.new()
		trove:Add(obj)
		trove:Clean()
		trove:Clean() -- second clean is a no-op
		expect(destroyed).toBe(1)
	end)

	it("Add returns the item for chaining", function()
		local trove = Trove.new()
		local fn = function() end
		expect(trove:Add(fn)).toBe(fn)
		trove:Clean()
	end)

	it("a failing cleanup doesn't stop the others", function()
		local ran = false
		local trove = Trove.new()
		trove:Add(function()
			ran = true
		end)
		trove:Add(function()
			error("boom")
		end)
		trove:Clean()
		expect(ran).toBe(true)
	end)

	it("Extend() children are cleaned with the parent", function()
		local ran = false
		local parent = Trove.new()
		local child = parent:Extend()
		child:Add(function()
			ran = true
		end)
		parent:Clean()
		expect(ran).toBe(true)
	end)

	it("Destroy is an alias of Clean", function()
		local ran = false
		local trove = Trove.new()
		trove:Add(function()
			ran = true
		end)
		trove:Destroy()
		expect(ran).toBe(true)
	end)
end)

return nil
