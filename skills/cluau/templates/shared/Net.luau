--!strict
--[[
	Net — single source of truth for remote names.
	Location: ReplicatedStorage/Shared/Net (ModuleScript)

	The SERVER creates every remote listed below at require-time (inside ReplicatedStorage/Remotes).
	The CLIENT waits for them. Clients never create remotes.

	Server:
		local Net = require(ReplicatedStorage.Shared.Net)
		Net.event("RequestPurchase").OnServerEvent:Connect(function(player, itemId: unknown) ... end)

	Client:
		Net.event("RequestPurchase"):FireServer("Sword")
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Declare every remote here. Name = intent (verb-noun). Server→client names describe what changed.
local EVENTS = table.freeze({
	"RequestPurchase", -- client → server: itemId: string
	"RequestEquip", -- client → server: itemId: string
	"DataSnapshot", -- server → client: full player state on join
	"DataChanged", -- server → client: { [path]: value } deltas
	"Notify", -- server → client: { kind: string, text: string }
})

local UNRELIABLE_EVENTS = table.freeze({
	"LookDirection", -- client → server, cosmetic, throttled
})

local FUNCTIONS = table.freeze({
	-- Keep RemoteFunctions rare, fast and validated. Never use InvokeClient.
	"GetShopCatalog",
})

local FOLDER_NAME = "Remotes"
local CLIENT_TIMEOUT = 15

local isServer = RunService:IsServer()
local folder: Folder

if isServer then
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		folder = existing :: Folder
	else
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	local function ensure(className: string, name: string)
		local current = folder:FindFirstChild(name)
		if current and current.ClassName == className then
			return
		end
		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
	end

	for _, name in EVENTS do
		ensure("RemoteEvent", name)
	end
	for _, name in UNRELIABLE_EVENTS do
		ensure("UnreliableRemoteEvent", name)
	end
	for _, name in FUNCTIONS do
		ensure("RemoteFunction", name)
	end
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local function lookup(name: string, className: string, declared: { string }): Instance
	if table.find(declared, name) == nil then
		error(`[Net] "{name}" is not declared as a {className} in Net.luau`, 3)
	end
	local remote = if isServer then folder:FindFirstChild(name) else folder:WaitForChild(name, CLIENT_TIMEOUT)
	if remote == nil or remote.ClassName ~= className then
		error(`[Net] {className} "{name}" was not found in ReplicatedStorage.{FOLDER_NAME}`, 3)
	end
	return remote
end

local Net = {}

function Net.event(name: string): RemoteEvent
	return lookup(name, "RemoteEvent", EVENTS) :: RemoteEvent
end

function Net.unreliable(name: string): UnreliableRemoteEvent
	return lookup(name, "UnreliableRemoteEvent", UNRELIABLE_EVENTS) :: UnreliableRemoteEvent
end

function Net.func(name: string): RemoteFunction
	return lookup(name, "RemoteFunction", FUNCTIONS) :: RemoteFunction
end

return table.freeze(Net)
