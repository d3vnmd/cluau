--!strict
--[[
	Theme — design tokens. Every color, size, font and timing in the UI comes from here.
	Location: ReplicatedStorage/Shared/UI/Theme (ModuleScript)

	Art direction (rewrite this line for YOUR game, then retune the tokens):
	  "Lantern-lit explorer's kit: warm charcoal leather neutrals, one amber lantern accent,
	   sturdy rounded shapes, quiet confident motion."

	Do not add colors inline in components. Add a token here, named by ROLE (not by hue).
]]

local function hex(value: string): Color3
	return Color3.fromHex(value)
end

local Theme = {}

Theme.Color = {
	-- Neutrals, tinted warm toward the accent (pure grey looks unfinished).
	Background = hex("#15120E"),
	Surface = hex("#1E1A15"),
	SurfaceRaised = hex("#29231C"),
	SurfaceSunken = hex("#110F0C"),
	Border = hex("#3B3329"),
	BorderStrong = hex("#56493A"),
	TextMuted = hex("#A39786"),
	Text = hex("#F3EBDF"),

	-- Single accent.
	Accent = hex("#E8A23B"),
	AccentHover = hex("#F2B65C"),
	AccentPressed = hex("#C7862A"),
	AccentShadow = hex("#8A5A17"),
	OnAccent = hex("#23170A"),

	-- Semantic (muted to sit inside the palette).
	Success = hex("#7FB26B"),
	Warning = hex("#E2B44A"),
	Danger = hex("#D7654F"),
	OnDanger = hex("#2A0E08"),

	Scrim = hex("#000000"),
	Currency = hex("#F2C14E"),
}

Theme.Rarity = {
	Common = hex("#B9AE9F"),
	Uncommon = hex("#8DBB6F"),
	Rare = hex("#6FA6D6"),
	Epic = hex("#B48AD8"),
	Legendary = hex("#F0B548"),
}

-- Two families max: one display, one UI.
Theme.Font = {
	Display = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal),
	Heading = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	Body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	BodyBold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
}

-- Text sizes in reference pixels (1080p). Components scale with UIScale, not TextScaled.
Theme.TextSize = {
	Display = 44,
	Title = 30,
	Heading = 21,
	Body = 17,
	Caption = 14,
}

-- 4 px grid.
Theme.Space = {
	XXS = 2,
	XS = 4,
	SM = 8,
	MD = 12,
	LG = 16,
	XL = 24,
	XXL = 32,
	XXXL = 48,
}

Theme.Radius = {
	SM = UDim.new(0, 6),
	MD = UDim.new(0, 10),
	Pill = UDim.new(0.5, 0),
}

Theme.Stroke = {
	Thin = 1,
	Bold = 2,
}

-- Minimum interactive size (touch target) in reference pixels.
Theme.HitTarget = 44

Theme.Motion = {
	Instant = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Press = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Hover = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	PanelIn = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	PanelOut = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	Count = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

-- ScreenGui layering. Use DisplayOrder between ScreenGuis instead of giant ZIndex values.
Theme.Layer = {
	Hud = 0,
	Menu = 10,
	Modal = 20,
	Toast = 30,
}

-- Reference resolution the sizes above were designed for.
Theme.ReferenceHeight = 1080
Theme.MinScale = 0.62
Theme.MaxScale = 1.2

for _, group in Theme do
	if type(group) == "table" then
		table.freeze(group)
	end
end

return table.freeze(Theme)
