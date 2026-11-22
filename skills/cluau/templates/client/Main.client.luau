--!strict
--[[
	Client bootstrap — the ONLY LocalScript you need.
	Location: StarterPlayer/StarterPlayerScripts/Main (LocalScript)
	Controllers live in StarterPlayer/StarterPlayerScripts/Controllers (ModuleScripts).

	StarterPlayerScripts persist across respawns, so controllers keep their state;
	re-bind character-specific things on Players.LocalPlayer.CharacterAdded.
]]

local CONTROLLER_ORDER = {
	"UIController",
}

type Controller = {
	Init: (() -> ())?,
	Start: (() -> ())?,
}

local controllersFolder = script.Parent:WaitForChild("Controllers")
local controllers: { { name: string, module: Controller } } = {}

for _, name in CONTROLLER_ORDER do
	local moduleScript = controllersFolder:WaitForChild(name, 10)
	if moduleScript == nil or not moduleScript:IsA("ModuleScript") then
		warn(`[Main.client] Controller "{name}" not found`)
		continue
	end
	local ok, result = pcall(require, moduleScript)
	if not ok then
		warn(`[Main.client] Failed to require {name}: {result}`)
		continue
	end
	table.insert(controllers, { name = name, module = result :: Controller })
end

for _, entry in controllers do
	local init = entry.module.Init
	if init then
		local ok, err = pcall(init)
		if not ok then
			warn(`[Main.client] {entry.name}.Init failed: {err}`)
		end
	end
end

for _, entry in controllers do
	local start = entry.module.Start
	if start then
		task.spawn(function()
			local ok, err = xpcall(start, debug.traceback)
			if not ok then
				warn(`[Main.client] {entry.name}.Start failed: {err}`)
			end
		end)
	end
end
