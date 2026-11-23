--!strict
--[[
	Theme — design tokens for every screen. Components read ONLY from here.
	Location: ReplicatedStorage/Shared/UI/Theme (ModuleScript). Needs ThemePresets next to it.

	1. Pick the preset that matches the game's art direction (preview them first:
	   `python3 scripts/style_tile.py` renders all presets as a style tile):
	     lantern  — warm adventure, amber accent, raised buttons, calm
	     meadow   — cozy farming/pets, cream paper, chunky outlined buttons, bouncy
	     candy    — simulator/obby arcade, thick outlines, hard shadows, snappy
	     orbit    — clean sci-fi/shooter, hairline outlines, monospace numbers, precise
	     grimoire — fantasy RPG, parchment panels on a dark world, serif headings, measured
	     hush     — horror, text on darkness, no boxes, slow
	     arena    — competitive/sports, flat team colors, condensed caps, instant
	2. Then make it YOURS: change the accent, the display font, or a radius so the game doesn't look like
	   every other game using the same preset. Edit assets/themes/<preset>.json and run
	   tools/build_themes.py (it re-checks contrast), or set COLOR_OVERRIDES below and re-render the style
	   tile with your values to check contrast.

	Never add colors inline in components — add a token here, named by ROLE (not by hue).
]]

local ThemePresets = require(script.Parent:WaitForChild("ThemePresets"))

local PRESET = "lantern"

-- "Make it yours": replace preset roles for this game only. Keys are role names (Accent, Surface, …).
local COLOR_OVERRIDES: { [string]: Color3 } = {
	-- Accent = Color3.fromHex("#2F8F6B"),
	-- AccentHover = Color3.fromHex("#33996F"),
}

local preset = ThemePresets[PRESET]
assert(preset, `[Theme] unknown preset "{PRESET}"`)

local color = table.clone(preset.Color)
local writableColor = color :: any
for role, value in COLOR_OVERRIDES do
	assert(writableColor[role] ~= nil, `[Theme] COLOR_OVERRIDES: unknown color role "{role}"`)
	writableColor[role] = value
end

-- Motion personality → timing scale and easing for tweens (springs use Theme.Spring directly).
local PERSONALITY: { [string]: { scale: number, style: Enum.EasingStyle } } = {
	instant = { scale = 0.6, style = Enum.EasingStyle.Quad },
	precise = { scale = 0.8, style = Enum.EasingStyle.Quad },
	snappy = { scale = 0.8, style = Enum.EasingStyle.Back },
	bouncy = { scale = 1.0, style = Enum.EasingStyle.Back },
	calm = { scale = 1.1, style = Enum.EasingStyle.Quint },
	measured = { scale = 1.25, style = Enum.EasingStyle.Quint },
	slow = { scale = 1.6, style = Enum.EasingStyle.Sine },
}
local personality = PERSONALITY[preset.Motion.Personality] or PERSONALITY.calm

local function timing(seconds: number, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): TweenInfo
	return TweenInfo.new(seconds * personality.scale, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
end

local Theme = {}

Theme.Name = preset.Name
Theme.Mood = preset.Mood
Theme.Color = color
Theme.Rarity = preset.Rarity

-- Two families (+ an optional numbers face). Numbers that change (coins, timers) use Font.Numbers.
Theme.Font = {
	Display = preset.Font.Display,
	Heading = preset.Font.Heading,
	Body = preset.Font.Body,
	BodyBold = preset.Font.BodyBold,
	Numbers = preset.Font.Numbers,
}

-- Shape language: how buttons and panels are built (see Components.button).
--   ButtonStyle: "chunky" (outlined, hard bottom shadow, squishes), "raised" (soft shadow),
--                "flat" (solid, caps), "outline" (hairline, caps), "text" (label + underline)
--   Shadow: "hard" | "soft" | "none"; ShadowOffset in reference px; Gloss: top highlight on colored faces
Theme.Shape = preset.Shape

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
	SM = UDim.new(0, preset.Shape.RadiusSM),
	MD = UDim.new(0, preset.Shape.RadiusMD),
	Pill = UDim.new(0.5, 0),
}

Theme.Stroke = {
	Thin = preset.Shape.StrokeThin,
	Bold = preset.Shape.StrokeBold,
}

-- Minimum interactive size (touch target) in reference pixels.
Theme.HitTarget = 44

-- Spring personality for interactive motion (press, hover, pop). See Spring.luau.
Theme.Spring = {
	Frequency = preset.Motion.SpringFrequency,
	Damping = preset.Motion.SpringDamping,
}

Theme.Motion = {
	Instant = timing(0.08),
	Press = timing(0.12),
	Hover = timing(0.18, Enum.EasingStyle.Quint),
	PanelIn = timing(0.3, personality.style),
	PanelOut = timing(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), -- exits are faster than entrances
	Count = timing(0.45, Enum.EasingStyle.Quart),
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
	if type(group) == "table" and not table.isfrozen(group) then
		table.freeze(group)
	end
end

return table.freeze(Theme)
