--!strict
--[[
	InputController — gameplay & menu input on the Input Action System (InputContext / InputAction /
	InputBinding), the 2026 default that unifies keyboard, gamepad and touch.
	Location: StarterPlayer/StarterPlayerScripts/Controllers/InputController (ModuleScript)

	Recommended Studio setting: Workspace.PlayerScriptsUseInputActionSystem = Enabled
	(required anyway by Server Authority).

	Design:
	  • Actions are declared once in ACTIONS (data, not code). Each gets keyboard + gamepad bindings;
	    touch buttons are attached with InputController.BindTouchButton(actionName, guiButton).
	  • Two contexts: "Gameplay" and "Menu". Opening a menu disables Gameplay so abilities can't fire
	    behind UI, and enables Menu (higher priority, Sink on).
	  • Other controllers subscribe by name; they never read raw KeyCodes.
	  • Contexts live in ReplicatedStorage.Inputs (Roblox's recommended location). If you built them in
	    Studio they are reused; otherwise this module creates them locally on the client.

	Usage:
		InputController.Pressed("Interact"):Connect(function() Net.event("RequestInteract"):FireServer() end)
		InputController.SetMenuOpen(true)
		InputController.BindTouchButton("Sprint", sprintButton)
		local glyph = InputController.GlyphFor("Interact") -- image for the current device, or nil
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

export type ContextName = "Gameplay" | "Menu"

type ActionSpec = {
	name: string,
	displayName: string,
	context: ContextName,
	keys: { Enum.KeyCode },
}

-- Escape is reserved by Roblox's own menu; close UI with B / Backspace (plus an on-screen close button).
local ACTIONS: { ActionSpec } = {
	{ name = "Sprint", displayName = "Sprint", context = "Gameplay", keys = { Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3 } },
	{ name = "Interact", displayName = "Interact", context = "Gameplay", keys = { Enum.KeyCode.E, Enum.KeyCode.ButtonX } },
	{ name = "ToggleMenu", displayName = "Menu", context = "Gameplay", keys = { Enum.KeyCode.M, Enum.KeyCode.ButtonY } },
	{ name = "CloseMenu", displayName = "Close", context = "Menu", keys = { Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB } },
}

local CONTEXT_PRIORITY: { [ContextName]: number } = { Gameplay = 1000, Menu = 2000 }

local SPRINT_MULTIPLIER = 1.6

local InputController = {}

local contexts: { [ContextName]: InputContext } = {}
local actions: { [string]: InputAction } = {}

local function getOrCreate(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = parent
	return created
end

local function build()
	local folder = getOrCreate(ReplicatedStorage, "Folder", "Inputs")
	for contextName, priority in CONTEXT_PRIORITY do
		local context = getOrCreate(folder, "InputContext", contextName) :: InputContext
		context.Priority = priority
		context.Sink = contextName == "Menu"
		context.Enabled = contextName == "Gameplay"
		contexts[contextName] = context
	end
	for _, spec in ACTIONS do
		local context = contexts[spec.context]
		local action = context:FindFirstChild(spec.name) :: InputAction?
		if action == nil then
			local newAction = Instance.new("InputAction")
			newAction.Name = spec.name
			newAction.Type = Enum.InputActionType.Bool
			newAction.DisplayName = spec.displayName
			for index, keyCode in spec.keys do
				local binding = Instance.new("InputBinding")
				binding.Name = `Key{index}`
				binding.KeyCode = keyCode
				binding.Parent = newAction
			end
			newAction.Parent = context -- parent last: properties first
			action = newAction
		end
		actions[spec.name] = action :: InputAction
	end
end

local function getAction(name: string): InputAction
	local action = actions[name]
	if action == nil then
		error(`[InputController] Unknown action "{name}" — declare it in ACTIONS`, 3)
	end
	return action
end

--- Fires when a Bool action goes false → true.
function InputController.Pressed(name: string): RBXScriptSignal
	return getAction(name).Pressed
end

--- Fires when a Bool action goes true → false.
function InputController.Released(name: string): RBXScriptSignal
	return getAction(name).Released
end

--- Current state (boolean for Bool actions). Poll this each frame for analog actions.
function InputController.GetState(name: string): any
	return getAction(name):GetState()
end

--- Switches between gameplay and menu input. Call from your UI controller when a modal opens/closes.
function InputController.SetMenuOpen(open: boolean)
	contexts.Gameplay.Enabled = not open
	contexts.Menu.Enabled = open
end

--- Lets an on-screen GuiButton drive an action on touch devices.
function InputController.BindTouchButton(name: string, button: GuiButton)
	local binding = Instance.new("InputBinding")
	binding.Name = `Touch_{button.Name}`
	binding.UIButton = button
	binding.Parent = getAction(name)
end

--- Device-appropriate glyph image for an action's preferred binding (nil if none available).
function InputController.GlyphFor(name: string): string?
	local binding = getAction(name).PreferredBinding
	if binding == nil or binding.KeyCode == Enum.KeyCode.None then
		return nil
	end
	local image = UserInputService:GetImageForKeyCode(binding.KeyCode)
	return if image ~= "" then image else nil
end

function InputController.Init()
	build()
end

function InputController.Start()
	-- Example gameplay binding: local sprint. The client owns its character's movement, so the SERVER
	-- must still sanity-check speed (networking-security.md §6). Under Server Authority, move this logic
	-- into a RunService:BindToSimulation module instead (server-authority.md).
	local player = Players.LocalPlayer
	local baseSpeed: number? = nil
	local function humanoid(): Humanoid?
		local character = player.Character
		return if character then character:FindFirstChildOfClass("Humanoid") else nil
	end
	InputController.Pressed("Sprint"):Connect(function()
		local h = humanoid()
		if h then
			baseSpeed = baseSpeed or h.WalkSpeed
			h.WalkSpeed = (baseSpeed :: number) * SPRINT_MULTIPLIER
		end
	end)
	InputController.Released("Sprint"):Connect(function()
		local h = humanoid()
		if h and baseSpeed then
			h.WalkSpeed = baseSpeed
		end
	end)
	player.CharacterAdded:Connect(function()
		baseSpeed = nil
	end)
end

return InputController
