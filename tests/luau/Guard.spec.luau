--!strict
local H = require("./harness")
local Guard = require("../../skills/cluau/templates/shared/Guard")
local describe, it, expect = H.describe, H.it, H.expect

describe("Guard", function()
	it("finite() rejects NaN, ±inf and non-numbers", function()
		expect(Guard.finite(1.5)).toBe(true)
		expect(Guard.finite(0 / 0)).toBe(false)
		expect(Guard.finite(math.huge)).toBe(false)
		expect(Guard.finite(-math.huge)).toBe(false)
		expect(Guard.finite("1")).toBe(false)
		expect(Guard.finite(nil)).toBe(false)
	end)

	it("number() enforces inclusive bounds", function()
		expect(Guard.number(5, 0, 5)).toBe(true)
		expect(Guard.number(5.0001, 0, 5)).toBe(false)
		expect(Guard.number(-1, 0, 5)).toBe(false)
		expect(Guard.number(0 / 0, 0, 5)).toBe(false)
	end)

	it("integer() rejects fractions", function()
		expect(Guard.integer(3, 1, 10)).toBe(true)
		expect(Guard.integer(3.5, 1, 10)).toBe(false)
		expect(Guard.integer(2 ^ 60, 1, 10)).toBe(false)
	end)

	it("boolean() only accepts booleans", function()
		expect(Guard.boolean(true)).toBe(true)
		expect(Guard.boolean(false)).toBe(true)
		expect(Guard.boolean(0)).toBe(false)
		expect(Guard.boolean("true")).toBe(false)
	end)

	it("string() counts UTF-8 characters, rejects empty, long and invalid UTF-8", function()
		expect(Guard.string("Sword", 8)).toBe(true)
		expect(Guard.string("", 8)).toBe(false)
		expect(Guard.string("Сэлэм", 5)).toBe(true) -- 5 Cyrillic chars = 10 bytes
		expect(Guard.string("Сэлэмүү", 5)).toBe(false)
		expect(Guard.string("\255\254", 8)).toBe(false)
		expect(Guard.string(42, 8)).toBe(false)
	end)

	it("oneOf() checks membership in a server whitelist", function()
		local allowed = { Sword = true, Shield = true }
		expect(Guard.oneOf("Sword", allowed)).toBe(true)
		expect(Guard.oneOf("Admin", allowed)).toBe(false)
		expect(Guard.oneOf(1, allowed)).toBe(false)
	end)

	it("aliveRoot()/near() handle missing characters and dead humanoids", function()
		local function part(pos: { X: number, Y: number, Z: number })
			return {
				IsA = function(_, className)
					return className == "BasePart"
				end,
				Position = pos,
			}
		end
		local humanoid = { Health = 100 }
		local character = {
			FindFirstChildOfClass = function(_, className)
				return if className == "Humanoid" then humanoid else nil
			end,
			FindFirstChild = function(_, name)
				return if name == "HumanoidRootPart" then part({ X = 0, Y = 0, Z = 0 }) else nil
			end,
		}
		local player: any = { Character = character }
		expect(Guard.aliveRoot(player)).never().toBeNil()
		humanoid.Health = 0
		expect(Guard.aliveRoot(player)).toBeNil()
		local noCharacter: any = { Character = nil }
		expect(Guard.aliveRoot(noCharacter)).toBeNil()
	end)

	it("the module is frozen (can't be monkey-patched at runtime)", function()
		expect(table.isfrozen(Guard)).toBe(true)
	end)
end)

return nil
