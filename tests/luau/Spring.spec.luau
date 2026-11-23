--!strict
local H = require("./harness")
local Spring = require("../../skills/cluau/templates/shared/Spring")
local describe, it, expect = H.describe, H.it, H.expect

local function run(s: Spring.Spring, seconds: number): (number, number)
	local peak = s.position
	local t = 0
	while t < seconds do
		local v = s:step(1 / 60)
		if math.abs(v - s.target) > math.abs(peak - s.target) or (v > peak and s.target > s.position - 1) then
			peak = math.max(peak, v)
		end
		t += 1 / 60
	end
	return s.position, peak
end

describe("Spring", function()
	it("settles on the target", function()
		local s = Spring.new(0, 5, 0.8)
		s:setTarget(1)
		run(s, 2)
		expect(s.position).toBeCloseTo(1, 1e-3)
		expect(s:isSettled()).toBe(true)
	end)

	it("critically damped (1.0) never overshoots", function()
		local s = Spring.new(0, 6, 1.0)
		s:setTarget(1)
		local maxSeen = 0
		for _ = 1, 240 do
			maxSeen = math.max(maxSeen, s:step(1 / 60))
		end
		expect(maxSeen <= 1.0001).toBe(true)
	end)

	it("bouncy (0.5) overshoots — that's the personality", function()
		local s = Spring.new(0, 4, 0.5)
		s:setTarget(1)
		local maxSeen = 0
		for _ = 1, 240 do
			maxSeen = math.max(maxSeen, s:step(1 / 60))
		end
		expect(maxSeen > 1.05).toBe(true)
	end)

	it("keeps velocity when the target changes mid-motion (continuous feel)", function()
		local s = Spring.new(0, 4, 0.7)
		s:setTarget(1)
		for _ = 1, 6 do
			s:step(1 / 60)
		end
		local velocityBefore = s.velocity
		s:setTarget(-1)
		expect(s.velocity).toBe(velocityBefore)
	end)

	it("is stable on a long frame hitch", function()
		local s = Spring.new(0, 8, 0.5)
		s:setTarget(1)
		local v = s:step(0.5)
		expect(v == v and math.abs(v) < 10).toBe(true)
	end)

	it("snap() jumps with no motion", function()
		local s = Spring.new(0, 5, 0.6)
		s:setTarget(1)
		s:step(1 / 60)
		s:snap(0.5)
		expect(s.position).toBe(0.5)
		expect(s.velocity).toBe(0)
		expect(s:isSettled()).toBe(true)
	end)
end)

return nil
