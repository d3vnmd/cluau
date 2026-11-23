--!strict
-- Every template, fixture-free: must parse and compile (catches ambiguous-call syntax, typos in keywords,
-- unbalanced blocks) — things the regex linter cannot see. Engine APIs are not executed.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local H = require("./harness")
local describe, it = H.describe, H.it

local ROOT = "skills/cluau/templates"

local function collect(dir: string, out: { string })
	for _, name in fs.readDir(dir) do
		local path = `{dir}/{name}`
		if fs.isDir(path) then
			collect(path, out)
		elseif string.match(name, "%.luau$") then
			table.insert(out, path)
		end
	end
end

describe("templates compile", function()
	local files: { string } = {}
	collect(ROOT, files)
	table.sort(files)
	it("finds the templates", function()
		assert(#files >= 25, `expected ≥ 25 templates under {ROOT}, found {#files} (run from the repo root)`)
	end)
	for _, path in files do
		it(path, function()
			luau.compile(fs.readFile(path))
		end)
	end
end)
