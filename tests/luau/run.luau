--!strict
-- Runs every Luau spec with Lune:  lune run tests/luau/run.luau
local process = require("@lune/process")
local Harness = require("./harness")

local SPECS = {
	"./RateLimiter.spec",
	"./Guard.spec",
	"./BufferCodec.spec",
	"./Trove.spec",
	"./TradeLogic.spec",
	"./Restock.spec",
	"./Spring.spec",
	"./Compile.spec",
}

for _, path in SPECS do
	print(`\n{path}`)
	local ok, err = pcall(require, path)
	if not ok then
		Harness.it(`load {path}`, function()
			error(err)
		end)
	end
end

local failed = Harness.report()
process.exit(if failed > 0 then 1 else 0)
