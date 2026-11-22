--!strict
-- Minimal test harness for Lune (no dependencies). Specs call describe/it/expect from this module.
local Harness = {}

type Result = { name: string, ok: boolean, err: string? }

local results: { Result } = {}
local prefix: { string } = {}

function Harness.describe(name: string, body: () -> ())
	table.insert(prefix, name)
	body()
	table.remove(prefix)
end

function Harness.it(name: string, body: () -> ())
	local full = table.concat(prefix, " › ") .. " › " .. name
	local ok, err = xpcall(body, function(e)
		return tostring(e) .. "\n" .. debug.traceback()
	end)
	table.insert(results, { name = full, ok = ok, err = if ok then nil else err })
end

local function fmt(v: any): string
	if typeof(v) == "string" then
		return string.format("%q", v)
	end
	return tostring(v)
end

function Harness.expect(actual: any)
	local api = {}
	function api.toBe(expected: any)
		if actual ~= expected then
			error(`expected {fmt(expected)}, got {fmt(actual)}`, 2)
		end
	end
	function api.toBeNil()
		if actual ~= nil then
			error(`expected nil, got {fmt(actual)}`, 2)
		end
	end
	function api.never()
		return {
			toBeNil = function()
				if actual == nil then
					error("expected a value, got nil", 2)
				end
			end,
		}
	end
	function api.toBeCloseTo(expected: number, epsilon: number?)
		if math.abs(actual - expected) > (epsilon or 1e-6) then
			error(`expected ≈{expected}, got {fmt(actual)}`, 2)
		end
	end
	function api.toThrow()
		local ok = pcall(actual)
		if ok then
			error("expected function to throw", 2)
		end
	end
	return api
end

--- Prints a summary; returns the number of failures.
function Harness.report(): number
	local failed = 0
	for _, r in results do
		if r.ok then
			print(`  ✓ {r.name}`)
		else
			failed += 1
			print(`  ✗ {r.name}\n      {r.err}`)
		end
	end
	print(`\n{#results - failed} passed, {failed} failed, {#results} total`)
	return failed
end

return Harness
