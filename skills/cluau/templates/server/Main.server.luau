--!strict
--[[
	Server bootstrap — the ONLY Script on the server.
	Location: ServerScriptService/Main (Script)

	Requires services in an explicit order, calls Init() (non-yielding) on all, then Start() on all.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Requiring Net on the server creates every declared remote before any client looks for them.
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local SERVICE_ORDER = {
	"ModerationService",
	"DataService",
	"MonetizationService",
	"ShopService",
	"MovementService",
	"TradeService",
	"LeaderboardService",
	"RoundService", -- needs ServerStorage.Maps (Models with a Spawns folder); remove if your game has no rounds
}

type Service = {
	Init: (() -> ())?,
	Start: (() -> ())?,
}

local servicesFolder = ServerScriptService:WaitForChild("Services")
local services: { { name: string, module: Service } } = {}

for _, name in SERVICE_ORDER do
	local moduleScript = servicesFolder:FindFirstChild(name)
	if moduleScript == nil or not moduleScript:IsA("ModuleScript") then
		warn(`[Main] Service "{name}" not found in ServerScriptService.Services`)
		continue
	end
	local ok, result = pcall(require, moduleScript)
	if not ok then
		warn(`[Main] Failed to require {name}: {result}`)
		continue
	end
	table.insert(services, { name = name, module = result :: Service })
end

for _, entry in services do
	local init = entry.module.Init
	if init then
		local ok, err = pcall(init)
		if not ok then
			warn(`[Main] {entry.name}.Init failed: {err}`)
		end
	end
end

for _, entry in services do
	local start = entry.module.Start
	if start then
		task.spawn(function()
			local ok, err = xpcall(start, debug.traceback)
			if not ok then
				warn(`[Main] {entry.name}.Start failed: {err}`)
			end
		end)
	end
end
