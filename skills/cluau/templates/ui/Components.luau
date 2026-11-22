--!strict
--[[
	Components — UI primitives built from Theme tokens.
	Location: ReplicatedStorage/Shared/UI/Components (ModuleScript) — client only.

	Every interactive component has real states: default, hover (mouse only), pressed,
	gamepad-selected, disabled, loading. No AutoButtonColor, no TextScaled, no inline colors.

	local Components = require(ReplicatedStorage.Shared.UI.Components)
	local gui = Components.screen("Hud", Theme.Layer.Hud)
	local buy = Components.button({ text = "Buy for 250", variant = "primary", parent = panel })
	buy.instance.Activated:Connect(function() ... end)
]]

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent:WaitForChild("Theme"))

local Components = {}

export type InputKind = "KeyboardMouse" | "Touch" | "Gamepad"
export type ButtonVariant = "primary" | "secondary" | "ghost" | "danger"
export type ButtonSize = "sm" | "md" | "lg"

-- ─── tween helper: one active tween per (instance, key) ────────────────────

local activeTweens: { [Instance]: { [string]: Tween } } = setmetatable({}, { __mode = "k" }) :: any

-- Motion slots that are skipped (applied instantly) when the player enables Reduced Motion.
local MOTION_SLOTS = { scale = true, move = true }

function Components.tween(instance: Instance, info: TweenInfo, goal: { [string]: any }, key: string?): Tween
	local slot = key or "default"
	if MOTION_SLOTS[slot] and GuiService.ReducedMotionEnabled then
		info = TweenInfo.new(0)
	end
	local perInstance = activeTweens[instance]
	if perInstance == nil then
		perInstance = {}
		activeTweens[instance] = perInstance
	end
	local previous = perInstance[slot]
	if previous then
		previous:Cancel()
	end
	local tween = TweenService:Create(instance, info, goal)
	perInstance[slot] = tween
	tween:Play()
	return tween
end

-- ─── input kind ────────────────────────────────────────────────────────────

local function classify(inputType: Enum.UserInputType): InputKind?
	if inputType == Enum.UserInputType.Touch then
		return "Touch"
	elseif inputType.Name:sub(1, 7) == "Gamepad" then
		return "Gamepad"
	elseif
		inputType == Enum.UserInputType.Keyboard
		or inputType == Enum.UserInputType.MouseButton1
		or inputType == Enum.UserInputType.MouseButton2
		or inputType == Enum.UserInputType.MouseMovement
		or inputType == Enum.UserInputType.MouseWheel
	then
		return "KeyboardMouse"
	end
	return nil
end

local currentInput: InputKind = classify(UserInputService:GetLastInputType())
	or (if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then "Touch" else "KeyboardMouse")
local inputChanged = Instance.new("BindableEvent")

UserInputService.LastInputTypeChanged:Connect(function(inputType)
	local kind = classify(inputType)
	if kind and kind ~= currentInput then
		currentInput = kind
		inputChanged:Fire(kind)
	end
end)

function Components.inputKind(): InputKind
	return currentInput
end

Components.InputKindChanged = inputChanged.Event

-- ─── primitives ────────────────────────────────────────────────────────────

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
	return s
end

local function padding(parent: Instance, x: number, y: number)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, x)
	p.PaddingRight = UDim.new(0, x)
	p.PaddingTop = UDim.new(0, y)
	p.PaddingBottom = UDim.new(0, y)
	p.Parent = parent
end

local function listLayout(parent: Instance, direction: Enum.FillDirection, gap: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.Padding = UDim.new(0, gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

Components.corner = corner
Components.stroke = stroke
Components.padding = padding
Components.listLayout = listLayout

--- Creates a ScreenGui in PlayerGui that survives respawn and respects device safe areas.
function Components.screen(name: string, displayOrder: number): ScreenGui
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	-- CoreUISafeInsets keeps interactive UI clear of notches AND Roblox's core buttons.
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = displayOrder
	gui.Parent = playerGui
	return gui
end

--- Applies the player's Preferred Transparency setting (Roblox accessibility) to a background.
--- `base` is the design transparency; the player's preference scales it (0 = fully opaque preference).
function Components.bindPreferredTransparency(target: GuiObject, base: number)
	local function apply()
		target.BackgroundTransparency = base * GuiService.PreferredTransparency
	end
	apply()
	local connection = GuiService:GetPropertyChangedSignal("PreferredTransparency"):Connect(apply)
	target.Destroying:Connect(function()
		connection:Disconnect()
	end)
end

--- Adds a UIScale to `target` that follows the viewport height (design in 1080p reference pixels).
function Components.autoScale(target: GuiObject): UIScale
	local scale = Instance.new("UIScale")
	scale.Parent = target
	local camera = workspace.CurrentCamera
	local function update()
		local viewport = camera.ViewportSize
		scale.Scale = math.clamp(viewport.Y / Theme.ReferenceHeight, Theme.MinScale, Theme.MaxScale)
	end
	update()
	local connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	target.Destroying:Connect(function()
		connection:Disconnect()
	end)
	return scale
end

export type LabelProps = {
	text: string,
	size: number?, -- Theme.TextSize.*
	font: Font?,
	color: Color3?,
	wrap: boolean?,
	alignX: Enum.TextXAlignment?,
	richText: boolean?,
	layoutOrder: number?,
	parent: Instance?,
}

function Components.label(props: LabelProps): TextLabel
	local label = Instance.new("TextLabel")
	label.BorderSizePixel = 0
	label.BackgroundTransparency = 1
	label.Text = props.text
	label.FontFace = props.font or Theme.Font.Body
	label.TextSize = props.size or Theme.TextSize.Body
	label.TextColor3 = props.color or Theme.Color.Text
	label.TextXAlignment = props.alignX or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = props.wrap == true
	label.RichText = props.richText == true
	label.LineHeight = 1.1
	label.LayoutOrder = props.layoutOrder or 0
	if props.wrap then
		label.Size = UDim2.new(1, 0, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
	else
		label.Size = UDim2.new(0, 0, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.XY
	end
	label.Parent = props.parent
	return label
end

-- ─── button ────────────────────────────────────────────────────────────────

export type ButtonProps = {
	text: string,
	variant: ButtonVariant?,
	size: ButtonSize?,
	width: number?, -- fixed width in reference px; omit to hug content
	icon: string?, -- rbxassetid:// (white icon, tinted by tokens)
	layoutOrder: number?,
	parent: Instance?,
}

export type Button = {
	instance: TextButton,
	setEnabled: (enabled: boolean) -> (),
	setLoading: (loadingText: string?) -> (),
	setText: (text: string) -> (),
}

type Palette = { bg: Color3, hover: Color3, pressed: Color3, text: Color3, border: Color3, bgTransparency: number }

local function paletteFor(variant: ButtonVariant): Palette
	local C = Theme.Color
	if variant == "primary" then
		return { bg = C.Accent, hover = C.AccentHover, pressed = C.AccentPressed, text = C.OnAccent, border = C.AccentShadow, bgTransparency = 0 }
	elseif variant == "danger" then
		return { bg = C.Danger, hover = C.Danger:Lerp(C.Text, 0.12), pressed = C.Danger:Lerp(C.Background, 0.2), text = C.OnDanger, border = C.Danger:Lerp(C.Background, 0.45), bgTransparency = 0 }
	elseif variant == "ghost" then
		return { bg = C.Surface, hover = C.SurfaceRaised, pressed = C.SurfaceSunken, text = C.Text, border = C.Border, bgTransparency = 1 }
	end
	return { bg = C.SurfaceRaised, hover = C.SurfaceRaised:Lerp(C.Text, 0.06), pressed = C.Surface, text = C.Text, border = C.BorderStrong, bgTransparency = 0 }
end

local HEIGHTS: { [ButtonSize]: number } = { sm = Theme.HitTarget, md = 52, lg = 60 }
local TEXT_SIZES: { [ButtonSize]: number } = { sm = Theme.TextSize.Caption + 1, md = Theme.TextSize.Body, lg = Theme.TextSize.Heading }

local selectionTemplate: Frame? = nil
local function getSelectionImage(): Frame
	-- A custom gamepad selection ring (replaces the default blue box). Not parented on purpose.
	if selectionTemplate then
		return selectionTemplate
	end
	local ring = Instance.new("Frame")
	ring.BorderSizePixel = 0
	ring.Name = "SelectionRing"
	ring.BackgroundTransparency = 1
	ring.Size = UDim2.new(1, 8, 1, 8)
	ring.Position = UDim2.new(0, -4, 0, -4)
	corner(ring, UDim.new(0, Theme.Radius.MD.Offset + 4))
	stroke(ring, Theme.Color.Text, 2)
	selectionTemplate = ring
	return ring
end

function Components.button(props: ButtonProps): Button
	local variant: ButtonVariant = props.variant or "secondary"
	local size: ButtonSize = props.size or "md"
	local palette = paletteFor(variant)
	local height = HEIGHTS[size]

	local button = Instance.new("TextButton")
	button.BorderSizePixel = 0
	button.Name = props.text:gsub("%W", "") .. "Button"
	button.AutoButtonColor = false
	button.BackgroundColor3 = palette.bg
	button.BackgroundTransparency = palette.bgTransparency
	button.Text = props.text
	button.FontFace = Theme.Font.BodyBold
	button.TextSize = TEXT_SIZES[size]
	button.TextColor3 = palette.text
	button.LayoutOrder = props.layoutOrder or 0
	button.Selectable = true
	button.SelectionImageObject = getSelectionImage()
	if props.width then
		button.Size = UDim2.new(0, props.width, 0, height)
	else
		button.Size = UDim2.new(0, 0, 0, height)
		button.AutomaticSize = Enum.AutomaticSize.X
	end
	corner(button, Theme.Radius.MD)
	local border = stroke(button, palette.border, if variant == "primary" then Theme.Stroke.Bold else Theme.Stroke.Thin)
	padding(button, Theme.Space.XL, 0)

	local scale = Instance.new("UIScale")
	scale.Parent = button

	if props.icon then
		-- Icon + text: let a horizontal layout place them; text moves into its own label.
		button.Text = ""
		listLayout(button, Enum.FillDirection.Horizontal, Theme.Space.SM)
		local layout = button:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		local icon = Instance.new("ImageLabel")
		icon.BorderSizePixel = 0
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.Image = props.icon
		icon.ImageColor3 = palette.text
		icon.Size = UDim2.new(0, TEXT_SIZES[size] + 6, 0, TEXT_SIZES[size] + 6)
		icon.LayoutOrder = 1
		icon.Parent = button
		Components.label({
			text = props.text,
			font = Theme.Font.BodyBold,
			size = TEXT_SIZES[size],
			color = palette.text,
			layoutOrder = 2,
			parent = button,
		}).Name = "Text"
	end

	local enabled = true
	local loading = false
	local hovered = false
	local pressed = false
	local label = props.text

	local function render()
		local interactive = enabled and not loading
		local bg = palette.bg
		local bgTransparency = palette.bgTransparency
		if interactive and pressed then
			bg = palette.pressed
		elseif interactive and hovered then
			bg = palette.hover
		end
		if variant == "ghost" and interactive and (hovered or pressed) then
			bgTransparency = 0 -- ghost buttons only show a surface while engaged
		end
		Components.tween(button, Theme.Motion.Hover, {
			BackgroundColor3 = bg,
			TextTransparency = if interactive then 0 else 0.45,
			BackgroundTransparency = if interactive then bgTransparency else math.max(bgTransparency, 0.35),
		}, "color")
		Components.tween(border, Theme.Motion.Hover, { Transparency = if interactive then 0 else 0.5 }, "stroke")
		local targetScale = if not interactive then 1 elseif pressed then 0.96 elseif hovered then 1.02 else 1
		Components.tween(scale, if pressed then Theme.Motion.Press else Theme.Motion.Hover, { Scale = targetScale }, "scale")
	end

	button.MouseEnter:Connect(function()
		if currentInput == "KeyboardMouse" then
			hovered = true
			render()
		end
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		pressed = false
		render()
	end)
	button.SelectionGained:Connect(function()
		hovered = true
		render()
	end)
	button.SelectionLost:Connect(function()
		hovered = false
		pressed = false
		render()
	end)
	button.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonA then
			pressed = true
			render()
		end
	end)
	button.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonA then
			pressed = false
			render()
		end
	end)

	local function applyInteractable()
		local interactive = enabled and not loading
		button.Active = interactive
		button.Interactable = interactive
	end

	local api: Button = {
		instance = button,
		setEnabled = function(value: boolean)
			enabled = value
			applyInteractable()
			render()
		end,
		setLoading = function(loadingText: string?)
			loading = loadingText ~= nil
			local shown = loadingText or label
			local textLabel = button:FindFirstChild("Text")
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = shown
			else
				button.Text = shown
			end
			applyInteractable()
			render()
		end,
		setText = function(text: string)
			label = text
			local textLabel = button:FindFirstChild("Text")
			if textLabel and textLabel:IsA("TextLabel") then
				textLabel.Text = text
			else
				button.Text = text
			end
		end,
	}

	button.Parent = props.parent
	return api
end

-- ─── panel ─────────────────────────────────────────────────────────────────

export type PanelProps = {
	width: number, -- reference px
	title: string?,
	subtitle: string?,
	onClose: (() -> ())?,
	parent: Instance?,
}

export type Panel = {
	instance: Frame,
	body: Frame, -- put content here (vertical list)
	closeButton: TextButton?,
}

function Components.panel(props: PanelProps): Panel
	local frame = Instance.new("Frame")
	frame.BorderSizePixel = 0
	frame.Name = "Panel"
	frame.BackgroundColor3 = Theme.Color.Surface
	frame.Size = UDim2.new(0, props.width, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.SelectionGroup = true
	corner(frame, Theme.Radius.MD)
	stroke(frame, Theme.Color.Border, Theme.Stroke.Thin)
	padding(frame, Theme.Space.XL, Theme.Space.XL)
	listLayout(frame, Enum.FillDirection.Vertical, Theme.Space.LG)

	local closeButton: TextButton? = nil
	if props.title then
		local header = Instance.new("Frame")
		header.BorderSizePixel = 0
		header.Name = "Header"
		header.BackgroundTransparency = 1
		header.Size = UDim2.new(1, 0, 0, Theme.HitTarget)
		header.LayoutOrder = 0
		header.Parent = frame

		local titles = Instance.new("Frame")
		titles.BorderSizePixel = 0
		titles.Name = "Titles"
		titles.BackgroundTransparency = 1
		titles.Size = UDim2.new(1, -(Theme.HitTarget + Theme.Space.SM), 1, 0)
		titles.Parent = header
		local titleLayout = listLayout(titles, Enum.FillDirection.Vertical, Theme.Space.XXS)
		titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center

		Components.label({ text = props.title, font = Theme.Font.Heading, size = Theme.TextSize.Title, layoutOrder = 1, parent = titles })
		if props.subtitle then
			Components.label({
				text = props.subtitle,
				size = Theme.TextSize.Caption,
				color = Theme.Color.TextMuted,
				layoutOrder = 2,
				parent = titles,
			})
		end

		if props.onClose then
			local close = Components.button({ text = "Close", variant = "ghost", size = "sm", parent = header })
			local inst = close.instance
			inst.AutomaticSize = Enum.AutomaticSize.None
			inst.Size = UDim2.new(0, Theme.HitTarget, 0, Theme.HitTarget)
			inst.AnchorPoint = Vector2.new(1, 0.5)
			inst.Position = UDim2.new(1, 0, 0.5, 0)
			inst.Text = ""
			-- Draw the "X" from two bars so it never depends on a font glyph (swap for your icon set's image).
			for index, rotation in { 45, -45 } do
				local bar = Instance.new("Frame")
				bar.BorderSizePixel = 0
				bar.Name = `CloseBar{index}`
				bar.BackgroundColor3 = Theme.Color.Text
				bar.AnchorPoint = Vector2.new(0.5, 0.5)
				bar.Position = UDim2.fromScale(0.5, 0.5)
				bar.Size = UDim2.new(0, 18, 0, 2)
				bar.Rotation = rotation
				corner(bar, Theme.Radius.Pill)
				bar.Parent = inst
			end
			local uiPadding = inst:FindFirstChildOfClass("UIPadding")
			if uiPadding then
				uiPadding:Destroy()
			end
			local onClose = props.onClose
			inst.Activated:Connect(function()
				onClose()
			end)
			closeButton = inst
		end
	end

	local body = Instance.new("Frame")
	body.BorderSizePixel = 0
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.LayoutOrder = 1
	body.Parent = frame
	listLayout(body, Enum.FillDirection.Vertical, Theme.Space.MD)

	frame.Parent = props.parent
	return { instance = frame, body = body, closeButton = closeButton }
end

-- ─── modal ─────────────────────────────────────────────────────────────────

export type Modal = {
	gui: ScreenGui,
	panel: Panel,
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
}

local modalCount = 0

function Components.modal(name: string, props: { width: number, title: string, subtitle: string? }): Modal
	modalCount += 1
	local actionName = `CloseModal_{name}_{modalCount}`
	local gui = Components.screen(name, Theme.Layer.Modal)
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.IgnoreGuiInset = true
	gui.Enabled = false

	local scrim = Instance.new("TextButton") -- clicking outside closes
	scrim.BorderSizePixel = 0
	scrim.Name = "Scrim"
	scrim.Text = ""
	scrim.AutoButtonColor = false
	scrim.Selectable = false
	scrim.BackgroundColor3 = Theme.Color.Scrim
	scrim.BackgroundTransparency = 1
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.Parent = gui

	local isOpen = false
	local previousSelection: GuiObject? = nil
	local modal: Modal

	local panel = Components.panel({
		width = props.width,
		title = props.title,
		subtitle = props.subtitle,
		onClose = function()
			modal.close()
		end,
		parent = gui,
	})
	local panelScale = Components.autoScale(panel.instance) -- also follows viewport resizes while open
	local baseScale = panelScale.Scale

	-- Gamepad focus goes to the first real action in the body, falling back to the close button.
	local function firstSelectable(): GuiObject?
		for _, descendant in panel.body:GetDescendants() do
			if descendant:IsA("GuiButton") and descendant.Selectable and descendant.Visible then
				return descendant
			end
		end
		return panel.closeButton
	end

	modal = {
		gui = gui,
		panel = panel,
		isOpen = function()
			return isOpen
		end,
		open = function()
			if isOpen then
				return
			end
			isOpen = true
			gui.Enabled = true
			baseScale = math.clamp(workspace.CurrentCamera.ViewportSize.Y / Theme.ReferenceHeight, Theme.MinScale, Theme.MaxScale)
			panelScale.Scale = baseScale * 0.94
			panel.instance.Position = UDim2.new(0.5, 0, 0.5, 16)
			Components.tween(scrim, Theme.Motion.PanelIn, { BackgroundTransparency = 0.45 }, "fade")
			Components.tween(panel.instance, Theme.Motion.PanelIn, { Position = UDim2.fromScale(0.5, 0.5) }, "move")
			Components.tween(panelScale, Theme.Motion.PanelIn, { Scale = baseScale }, "scale")

			previousSelection = GuiService.SelectedObject
			if currentInput == "Gamepad" then
				GuiService.SelectedObject = firstSelectable()
			end
			ContextActionService:BindActionAtPriority(actionName, function(_, state)
				if state == Enum.UserInputState.Begin then
					modal.close()
				end
				return Enum.ContextActionResult.Sink
			end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
		end,
		close = function()
			if not isOpen then
				return
			end
			isOpen = false
			ContextActionService:UnbindAction(actionName)
			Components.tween(scrim, Theme.Motion.PanelOut, { BackgroundTransparency = 1 }, "fade")
			Components.tween(panel.instance, Theme.Motion.PanelOut, { Position = UDim2.new(0.5, 0, 0.5, 12) }, "move")
			local out = Components.tween(panelScale, Theme.Motion.PanelOut, { Scale = baseScale * 0.96 }, "scale")
			out.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed and not isOpen then
					gui.Enabled = false
				end
			end)
			if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then
				GuiService.SelectedObject = if previousSelection and previousSelection.Parent then previousSelection else nil
			end
		end,
	}

	scrim.Activated:Connect(function()
		modal.close()
	end)

	return modal
end

-- ─── toast ─────────────────────────────────────────────────────────────────

local toastGui: ScreenGui? = nil
local toastStack: Frame? = nil
local MAX_TOASTS = 3

local toastCounter = 0

function Components.toast(text: string, kind: ("info" | "success" | "error")?)
	if toastGui == nil then
		local gui = Components.screen("Toasts", Theme.Layer.Toast)
		local stack = Instance.new("Frame")
		stack.BorderSizePixel = 0
		stack.Name = "Stack"
		stack.BackgroundTransparency = 1
		stack.AnchorPoint = Vector2.new(0.5, 0)
		stack.Position = UDim2.new(0.5, 0, 0, Theme.Space.XXXL + Theme.Space.LG)
		stack.Size = UDim2.new(0, 420, 0, 0)
		stack.AutomaticSize = Enum.AutomaticSize.Y
		stack.Parent = gui
		local layout = listLayout(stack, Enum.FillDirection.Vertical, Theme.Space.SM)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		Components.autoScale(stack)
		toastGui = gui
		toastStack = stack
	end
	local stack = toastStack :: Frame

	local count = 0
	local oldest: GuiObject? = nil
	for _, child in stack:GetChildren() do
		if child:IsA("GuiObject") then
			count += 1
			if oldest == nil or child.LayoutOrder < oldest.LayoutOrder then
				oldest = child
			end
		end
	end
	if count >= MAX_TOASTS and oldest then
		oldest:Destroy()
	end

	local accent = if kind == "success" then Theme.Color.Success elseif kind == "error" then Theme.Color.Danger else Theme.Color.Accent

	local toast = Instance.new("CanvasGroup")
	toast.BorderSizePixel = 0
	toast.Name = "Toast"
	toast.BackgroundColor3 = Theme.Color.SurfaceRaised
	toast.Size = UDim2.new(1, 0, 0, 0)
	toast.AutomaticSize = Enum.AutomaticSize.Y
	toastCounter += 1
	toast.LayoutOrder = toastCounter
	toast.GroupTransparency = 1
	corner(toast, Theme.Radius.MD)
	stroke(toast, Theme.Color.Border, Theme.Stroke.Thin)
	padding(toast, Theme.Space.LG, Theme.Space.MD)
	local row = listLayout(toast, Enum.FillDirection.Horizontal, Theme.Space.MD)
	row.VerticalAlignment = Enum.VerticalAlignment.Center

	local bar = Instance.new("Frame")
	bar.BorderSizePixel = 0
	bar.Name = "Accent"
	bar.BackgroundColor3 = accent
	bar.Size = UDim2.new(0, 4, 0, 22)
	bar.LayoutOrder = 1
	corner(bar, Theme.Radius.Pill)
	bar.Parent = toast

	local message = Components.label({ text = text, size = Theme.TextSize.Body, wrap = true, layoutOrder = 2, parent = toast })
	message.Size = UDim2.new(1, -(4 + Theme.Space.MD), 0, 0) -- remaining width after the accent bar

	toast.Parent = stack
	Components.tween(toast, Theme.Motion.PanelIn, { GroupTransparency = 0 }, "fade")
	task.delay(3.2, function()
		if toast.Parent == nil then
			return
		end
		local out = Components.tween(toast, Theme.Motion.PanelOut, { GroupTransparency = 1 }, "fade")
		out.Completed:Wait()
		toast:Destroy()
	end)
end

-- ─── number formatting (tabular-looking, no jitter) ────────────────────────

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Components.formatNumber(n: number): string
	if n < 0 then
		return "-" .. Components.formatNumber(-n)
	end
	if n < 10_000 then
		local whole = tostring(math.floor(n))
		return (whole:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
	end
	local index = 1
	local value = n
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	return string.format(if value < 100 then "%.1f%s" else "%.0f%s", value, SUFFIXES[index])
end

return Components
