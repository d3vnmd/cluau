--!strict
local H = require("./harness")
local RateLimiter = require("../../skills/cluau/templates/shared/RateLimiter")
local describe, it, expect = H.describe, H.it, H.expect

describe("RateLimiter", function()
	local now = 0
	local function clock()
		return now
	end

	it("allows a burst up to capacity, then blocks", function()
		now = 0
		local limiter = RateLimiter.new(3, 1, clock)
		expect(limiter:check("p")).toBe(true)
		expect(limiter:check("p")).toBe(true)
		expect(limiter:check("p")).toBe(true)
		expect(limiter:check("p")).toBe(false)
	end)

	it("refills at the configured rate", function()
		now = 0
		local limiter = RateLimiter.new(2, 2, clock) -- 2 tokens/second
		expect(limiter:check("p")).toBe(true)
		expect(limiter:check("p")).toBe(true)
		expect(limiter:check("p")).toBe(false)
		now = 0.5 -- +1 token
		expect(limiter:check("p")).toBe(true)
		expect(limiter:check("p")).toBe(false)
	end)

	it("never refills above capacity after a long idle", function()
		now = 0
		local limiter = RateLimiter.new(2, 10, clock)
		limiter:check("p")
		now = 1000
		expect(limiter:check("p")).toBe(true)
		expect(limiter:check("p")).toBe(true)
		expect(limiter:check("p")).toBe(false)
	end)

	it("keeps separate buckets per key", function()
		now = 0
		local limiter = RateLimiter.new(1, 1, clock)
		expect(limiter:check("a")).toBe(true)
		expect(limiter:check("a")).toBe(false)
		expect(limiter:check("b")).toBe(true)
	end)

	it("rejects NaN and negative costs (they would mint tokens)", function()
		now = 0
		local limiter = RateLimiter.new(1, 1, clock)
		expect(limiter:check("p", 0 / 0)).toBe(false)
		expect(limiter:check("p", -5)).toBe(false)
		expect(limiter:check("p")).toBe(true)
		expect(limiter:check("p")).toBe(false)
	end)

	it("charges multi-token costs and refuses when short", function()
		now = 0
		local limiter = RateLimiter.new(5, 1, clock)
		expect(limiter:check("p", 4)).toBe(true)
		expect(limiter:check("p", 2)).toBe(false)
		expect(limiter:check("p", 1)).toBe(true)
	end)

	it("reset() restores a full bucket", function()
		now = 0
		local limiter = RateLimiter.new(1, 1, clock)
		limiter:check("p")
		limiter:reset("p")
		expect(limiter:check("p")).toBe(true)
	end)

	it("rejects invalid construction", function()
		expect(function()
			RateLimiter.new(0, 1)
		end).toThrow()
		expect(function()
			RateLimiter.new(1, 0)
		end).toThrow()
	end)
end)

return nil
