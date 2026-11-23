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

local RunService = game:GetService("RunService")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Spring = require(script.Parent.Parent:WaitForChild("Spring"))

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
	fill: boolean?, -- stretch to the parent's width (cards, modals)
	icon: string?, -- rbxassetid:// (white icon, tinted by tokens)
	layoutOrder: number?,
	parent: Instance?,
}

export type Button = {
	instance: TextButton, -- the root: connect Activated, set LayoutOrder/Parent here
	face: Frame, -- the visible face: put custom glyphs/icons here
	setEnabled: (enabled: boolean) -> (),
	setLoading: (loadingText: string?) -> (),
	setText: (text: string) -> (),
}

type Palette = { face: Color3, hover: Color3, pressed: Color3, text: Color3, edge: Color3, outline: Color3, faceTransparency: number }

local function paletteFor(variant: ButtonVariant): Palette
	local C = Theme.Color
	if variant == "primary" then
		return { face = C.Accent, hover = C.AccentHover, pressed = C.AccentPressed, text = C.OnAccent, edge = C.AccentShadow, outline = C.BorderStrong, faceTransparency = 0 }
	elseif variant == "danger" then
		return { face = C.Danger, hover = C.Danger:Lerp(C.OnDanger, 0.08), pressed = C.Danger:Lerp(C.SurfaceSunken, 0.2), text = C.OnDanger, edge = C.Danger:Lerp(C.SurfaceSunken, 0.5), outline = C.BorderStrong, faceTransparency = 0 }
	elseif variant == "ghost" then
		return { face = C.Surface, hover = C.SurfaceRaised, pressed = C.SurfaceSunken, text = C.Text, edge = C.Border, outline = C.Border, faceTransparency = 1 }
	end
	return { face = C.SurfaceRaised, hover = C.SurfaceRaised:Lerp(C.Text, 0.06), pressed = C.Surface, text = C.Text, edge = C.BorderStrong, outline = C.BorderStrong, faceTransparency = 0 }
end

local HEIGHTS: { [ButtonSize]: number } = { sm = Theme.HitTarget, md = 52, lg = 60 }
local TEXT_SIZES: { [ButtonSize]: number } = { sm = Theme.TextSize.Caption + 2, md = Theme.TextSize.Body + 1, lg = Theme.TextSize.Heading }

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

-- ─── spring runner: one RenderStepped connection animates every UI spring ────

type SpringJob = { spring: Spring.Spring, apply: (number) -> () }
local springJobs: { [Instance]: { [string]: SpringJob } } = setmetatable({}, { __mode = "k" }) :: any
local springConnection: RBXScriptConnection? = nil

local function ensureSpringRunner()
	if springConnection then
		return
	end
	springConnection = RunService.RenderStepped:Connect(function(dt: number)
		local any = false
		for owner, jobs in springJobs do
			for name, job in jobs do
				job.apply(job.spring:step(dt))
				if job.spring:isSettled(1e-4) then
					job.apply(job.spring.target)
					jobs[name] = nil
				else
					any = true
				end
			end
			if next(jobs) == nil then
				springJobs[owner] = nil
			end
		end
		if not any and next(springJobs) == nil and springConnection then
			springConnection:Disconnect()
			springConnection = nil
		end
	end)
end

--- Springs a number toward `target` using the theme's motion personality. `apply` writes the value.
--- Reduced Motion snaps instantly. Re-targeting keeps velocity (continuous feel).
function Components.springTo(owner: Instance, name: string, current: number, target: number, apply: (number) -> ())
	if GuiService.ReducedMotionEnabled then
		apply(target)
		local jobs = springJobs[owner]
		if jobs then
			jobs[name] = nil
		end
		return
	end
	local jobs = springJobs[owner]
	if jobs == nil then
		jobs = {}
		springJobs[owner] = jobs
	end
	local job = jobs[name]
	if job == nil then
		job = { spring = Spring.new(current, Theme.Spring.Frequency, Theme.Spring.Damping), apply = apply }
		jobs[name] = job
	end
	job.apply = apply
	job.spring:setTarget(target)
	ensureSpringRunner()
end

-- ─── button ────────────────────────────────────────────────────────────────
-- Structure (so depth styles work under ZIndexBehavior.Sibling):
--   Root (TextButton, transparent: input + layout, height = face + shadow offset)
--   ├─ Shadow (Frame: hard/soft depth under the face)
--   └─ Face (Frame: color, stroke, gloss gradient, padding, list layout)
--        ├─ Icon (ImageLabel, optional)   └─ Text (TextLabel)

local function luminance(c: Color3): number
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end

local function buttonShadowKind(): string -- "hard" | "soft" | "none"
	local style = Theme.Shape.ButtonStyle
	return if style == "chunky" then "hard" elseif style == "raised" then "soft" else "none"
end

--- Total height a button occupies (face + depth), for laying out fixed-size cells around it.
function Components.buttonHeight(size: ButtonSize?): number
	return HEIGHTS[size or "md"] + (if buttonShadowKind() == "none" then 0 else Theme.Shape.ShadowOffset)
end

function Components.button(props: ButtonProps): Button
	local variant: ButtonVariant = props.variant or "secondary"
	local size: ButtonSize = props.size or "md"
	local palette = paletteFor(variant)
	local style = Theme.Shape.ButtonStyle
	local shadowKind = buttonShadowKind()
	local offset = if shadowKind == "none" then 0 else Theme.Shape.ShadowOffset
	local height = HEIGHTS[size]
	local uppercase = style == "flat" or style == "outline"
	local transparentFace = style == "outline" or style == "text" or palette.faceTransparency >= 1

	local root = Instance.new("TextButton")
	root.Name = props.text:gsub("%W", "") .. "Button"
	root.BorderSizePixel = 0
	root.AutoButtonColor = false
	root.BackgroundTransparency = 1
	root.Text = ""
	root.LayoutOrder = props.layoutOrder or 0
	root.Selectable = true
	root.SelectionImageObject = getSelectionImage()
	if props.fill then
		root.Size = UDim2.new(1, 0, 0, height + offset)
	elseif props.width then
		root.Size = UDim2.new(0, props.width, 0, height + offset)
	else
		root.Size = UDim2.new(0, 0, 0, height + offset)
		root.AutomaticSize = Enum.AutomaticSize.X
	end

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.new(1, 0, 0, height)
	shadow.Position = UDim2.new(0, 0, 0, offset)
	shadow.BackgroundColor3 = if shadowKind == "soft" then Theme.Color.Scrim else palette.edge
	shadow.BackgroundTransparency = if shadowKind == "hard" then 0 elseif shadowKind == "soft" then 0.65 else 1
	corner(shadow, Theme.Radius.MD)
	shadow.Parent = root

	local face = Instance.new("Frame")
	face.Name = "Face"
	face.BorderSizePixel = 0
	face.Size = if props.fill or props.width then UDim2.new(1, 0, 0, height) else UDim2.new(0, 0, 0, height)
	face.AutomaticSize = if props.fill or props.width then Enum.AutomaticSize.None else Enum.AutomaticSize.X
	corner(face, if style == "text" then UDim.new(0, 0) else Theme.Radius.MD)
	padding(face, if style == "text" then Theme.Space.XS else Theme.Space.XL, 0)
	local row = listLayout(face, Enum.FillDirection.Horizontal, Theme.Space.SM)
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.HorizontalAlignment = Enum.HorizontalAlignment.Center
	face.Parent = root

	-- Outline: chunky = thick dark outline; outline style = hairline in the text color; others = subtle edge.
	local outlineColor = if style == "chunky" then palette.outline
		elseif style == "outline" then (if variant == "primary" then Theme.Color.Accent else Theme.Color.Text)
		else palette.edge
	local outlineWidth = if style == "chunky" then Theme.Stroke.Bold elseif style == "text" or style == "flat" then 0 else Theme.Stroke.Thin
	local border = stroke(face, outlineColor, outlineWidth)
	border.Enabled = outlineWidth > 0

	-- Gloss: a top highlight baked into a UIGradient (face color set to white, gradient carries the color).
	local gloss: UIGradient? = nil
	if Theme.Shape.Gloss and not transparentFace then
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Parent = face
		gloss = g
	end

	local underline: Frame? = nil
	if style == "text" then
		local bar = Instance.new("Frame")
		bar.Name = "Underline"
		bar.BorderSizePixel = 0
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Position = UDim2.new(0, 0, 1, 0)
		bar.Size = UDim2.new(1, 0, 0, 2)
		bar.BackgroundColor3 = if variant == "primary" then Theme.Color.Accent else Theme.Color.BorderStrong
		bar.ZIndex = 2
		bar.Parent = root
		underline = bar
	end

	local textColor = if style == "outline" and variant == "primary" then Theme.Color.Accent
		elseif style == "text" then (if variant == "primary" then Theme.Color.Text else Theme.Color.TextMuted)
		else palette.text
	local label = Components.label({
		text = if uppercase then string.upper(props.text) else props.text,
		font = if style == "chunky" and size ~= "sm" then Theme.Font.Display else Theme.Font.BodyBold,
		size = TEXT_SIZES[size],
		color = textColor,
		layoutOrder = 2,
		parent = face,
	})
	label.Name = "Text"
	-- Cartoon styles outline light text on colored faces (reads on any background, the "sticker" look).
	local textStroke: UIStroke? = nil
	if style == "chunky" and luminance(textColor) > 0.6 then
		local ts = Instance.new("UIStroke")
		ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		ts.Color = palette.edge
		ts.Thickness = 1.5
		ts.Parent = label
		textStroke = ts
	end

	if props.icon then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BorderSizePixel = 0
		icon.BackgroundTransparency = 1
		icon.Image = props.icon
		icon.ImageColor3 = textColor
		icon.Size = UDim2.new(0, TEXT_SIZES[size] + 6, 0, TEXT_SIZES[size] + 6)
		icon.LayoutOrder = 1
		icon.Parent = face
	end

	local scale = Instance.new("UIScale")
	scale.Parent = root

	local enabled, loading, hovered, pressed = true, false, false, false
	local labelText = props.text

	local function setFaceColor(color: Color3, transparency: number, lit: boolean)
		if gloss and not lit then
			-- Disabled faces are matte: drop the highlight but keep the gradient object for re-enable.
			face.BackgroundColor3 = color
			face.BackgroundTransparency = transparency
			gloss.Enabled = false
		elseif gloss then
			gloss.Enabled = true
			face.BackgroundColor3 = Color3.new(1, 1, 1) -- cluau-ignore CL097 (white = gloss light, not a palette color)
			face.BackgroundTransparency = transparency
			gloss.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, color:Lerp(Color3.new(1, 1, 1), 0.18)), -- cluau-ignore CL097
				ColorSequenceKeypoint.new(0.55, color),
				ColorSequenceKeypoint.new(1, color),
			})
		else
			face.BackgroundColor3 = color
			face.BackgroundTransparency = transparency
		end
	end

	local function render()
		local interactive = enabled and not loading
		local color = palette.face
		local transparency = if transparentFace then 1 else palette.faceTransparency
		if not enabled then
			-- Disabled goes NEUTRAL (never "faded accent"): sunken face, muted text, no depth.
			color = Theme.Color.SurfaceSunken
			transparency = if style == "text" then 1 else 0
			label.TextColor3 = Theme.Color.TextMuted
			shadow.Visible = false
			border.Color = Theme.Color.Border
		else
			label.TextColor3 = textColor
			shadow.Visible = shadowKind ~= "none"
			border.Color = outlineColor
			if interactive and pressed then
				color = palette.pressed
			elseif interactive and hovered then
				color = palette.hover
			end
			if transparentFace and interactive and (hovered or pressed) and style ~= "text" then
				transparency = 0.86 -- outline/ghost buttons show a faint fill while engaged
				color = if variant == "primary" then Theme.Color.Accent else Theme.Color.Text
			end
		end
		if textStroke then
			textStroke.Enabled = enabled
		end
		setFaceColor(color, transparency, enabled)
		if underline then
			underline.BackgroundColor3 = if not enabled then Theme.Color.Border
				elseif variant == "primary" or hovered then Theme.Color.Accent
				else Theme.Color.BorderStrong
		end
		-- Motion: chunky faces sink into their shadow; everything else scales slightly.
		if style == "chunky" then
			local sink = if interactive and pressed then offset elseif interactive and hovered then -1 else 0
			Components.springTo(face, "sink", face.Position.Y.Offset, sink, function(v)
				face.Position = UDim2.new(0, 0, 0, v)
			end)
		else
			local target = if not interactive then 1 elseif pressed then 0.96 elseif hovered then 1.02 else 1
			Components.springTo(scale, "scale", scale.Scale, target, function(v)
				scale.Scale = v
			end)
		end
	end

	root.MouseEnter:Connect(function()
		if currentInput == "KeyboardMouse" then
			hovered = true
			render()
		end
	end)
	root.MouseLeave:Connect(function()
		hovered = false
		pressed = false
		render()
	end)
	root.SelectionGained:Connect(function()
		hovered = true
		render()
	end)
	root.SelectionLost:Connect(function()
		hovered = false
		pressed = false
		render()
	end)
	root.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonA then
			pressed = true
			render()
		end
	end)
	root.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonA then
			pressed = false
			render()
		end
	end)

	local function applyInteractable()
		local interactive = enabled and not loading
		root.Active = interactive
		root.Interactable = interactive
	end

	local api: Button = {
		instance = root,
		face = face,
		setEnabled = function(value: boolean)
			enabled = value
			applyInteractable()
			render()
		end,
		setLoading = function(loadingText: string?)
			loading = loadingText ~= nil
			local shown = loadingText or labelText
			label.Text = if uppercase then string.upper(shown) else shown
			applyInteractable()
			render()
		end,
		setText = function(text: string)
			labelText = text
			label.Text = if uppercase then string.upper(text) else text
		end,
	}

	render()
	root.Parent = props.parent
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
	instance: Frame, -- root: position/scale/parent this
	face: Frame, -- the visible surface
	body: Frame, -- put content here (vertical list)
	closeButton: TextButton?,
}

--- Adds the theme's depth under `root` (behind a face that fills it): hard offset shadow, soft drop, or nothing.
function Components.depth(root: GuiObject, radius: UDim): Frame?
	local kind = Theme.Shape.Shadow
	if kind == "none" then
		return nil
	end
	local shadow = Instance.new("Frame")
	shadow.BorderSizePixel = 0
	shadow.Name = "Shadow"
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.new(0, 0, 0, math.max(2, Theme.Shape.ShadowOffset))
	shadow.BackgroundColor3 = if kind == "hard" then Theme.Color.BorderStrong else Theme.Color.Scrim
	shadow.BackgroundTransparency = if kind == "hard" then 0 else 0.7
	shadow.ZIndex = 0
	corner(shadow, radius)
	shadow.Parent = root
	return shadow
end

function Components.panel(props: PanelProps): Panel
	-- Root holds depth + face so the shadow follows the panel when modals move/scale it.
	local root = Instance.new("Frame")
	root.BorderSizePixel = 0
	root.Name = "Panel"
	root.BackgroundTransparency = 1
	root.Size = UDim2.new(0, props.width, 0, 0)
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.SelectionGroup = true
	Components.depth(root, Theme.Radius.MD)

	local frame = Instance.new("Frame")
	frame.BorderSizePixel = 0
	frame.Name = "Face"
	frame.ZIndex = 1
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	Components.bindPreferredTransparency(frame, 0)
	frame.BackgroundColor3 = Theme.Color.Surface
	corner(frame, Theme.Radius.MD)
	local chunky = Theme.Shape.ButtonStyle == "chunky"
	stroke(frame, if chunky then Theme.Color.BorderStrong else Theme.Color.Border, if chunky then Theme.Stroke.Bold else Theme.Stroke.Thin)
	padding(frame, Theme.Space.XL, Theme.Space.XL)
	listLayout(frame, Enum.FillDirection.Vertical, Theme.Space.LG)
	frame.Parent = root

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
			local close = Components.button({ text = "", variant = "secondary", size = "sm", width = Theme.HitTarget, parent = header })
			local inst = close.instance
			inst.Name = "CloseButton"
			inst.AnchorPoint = Vector2.new(1, 0.5)
			inst.Position = UDim2.new(1, 0, 0.5, 0)
			local facePadding = close.face:FindFirstChildOfClass("UIPadding")
			if facePadding then
				facePadding.PaddingLeft = UDim.new(0, 0)
				facePadding.PaddingRight = UDim.new(0, 0)
			end
			-- Draw the "X" from two bars so it never depends on a font glyph (swap for your icon set's image).
			-- The bars live in their own container so the face's list layout doesn't move them.
			local glyph = Instance.new("Frame")
			glyph.BorderSizePixel = 0
			glyph.Name = "XGlyph"
			glyph.BackgroundTransparency = 1
			glyph.Size = UDim2.new(0, 18, 0, 18)
			glyph.LayoutOrder = 3
			glyph.Parent = close.face
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
				bar.Parent = glyph
			end
			local emptyLabel = close.face:FindFirstChild("Text")
			if emptyLabel then
				emptyLabel:Destroy()
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

	root.Parent = props.parent
	return { instance = root, face = frame, body = body, closeButton = closeButton }
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
	panel.instance.ZIndex = 2 -- always above the click-to-close scrim (Sibling ZIndex), never relying on child order
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
		-- Connect, don't Wait: if the toast is evicted mid-fade the tween never completes and a Wait would hang.
		out.Completed:Connect(function()
			toast:Destroy()
		end)
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
