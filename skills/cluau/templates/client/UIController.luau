--!strict
--[[
	UIController — HUD (currency pill + menu rail) and a Shop modal, built only from Theme/Components.
	Location: StarterPlayer/StarterPlayerScripts/Controllers/UIController (ModuleScript)
	Depends on: ReplicatedStorage/Shared/{Net, UI/Theme, UI/Components}

	The client never decides prices or ownership. It renders the server's snapshot, sends intents,
	and shows pending → result feedback.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local UI = Shared:WaitForChild("UI")
local Theme = require(UI:WaitForChild("Theme"))
local Components = require(UI:WaitForChild("Components"))

type CatalogItem = {
	id: string,
	displayName: string,
	description: string,
	price: number,
	rarity: string,
	icon: string,
	layoutOrder: number,
}

type Snapshot = {
	Coins: number,
	Inventory: { [string]: number },
	Equipped: { [string]: string },
}

local CARD_WIDTH = 196
local CARD_HEIGHT = 248

local UIController = {}

local state: Snapshot = { Coins = 0, Inventory = {}, Equipped = {} }
local coinsLabel: TextLabel
local displayedCoins = Instance.new("NumberValue") -- tweened for count-up animation
local shopModal: Components.Modal
local cardRefreshers: { () -> () } = {}
local pendingPurchase: { [string]: boolean } = {}

-- ─── HUD ──────────────────────────────────────────────────────────────────

local function buildCurrencyPill(parent: Instance)
	local pill = Instance.new("Frame")
	pill.BorderSizePixel = 0
	pill.Name = "CoinsPill"
	pill.AnchorPoint = Vector2.new(0.5, 0)
	pill.Position = UDim2.new(0.5, 0, 0, Theme.Space.SM)
	pill.Size = UDim2.new(0, 0, 0, 44)
	pill.AutomaticSize = Enum.AutomaticSize.X
	pill.BackgroundColor3 = Theme.Color.Surface
	pill.BackgroundTransparency = 0.06
	Components.corner(pill, Theme.Radius.Pill)
	Components.stroke(pill, Theme.Color.Border, Theme.Stroke.Thin)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, Theme.Space.SM)
	pad.PaddingRight = UDim.new(0, Theme.Space.LG)
	pad.Parent = pill
	local layout = Components.listLayout(pill, Enum.FillDirection.Horizontal, Theme.Space.SM)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	-- Coin mark drawn from shapes (swap for your own uploaded coin icon).
	local coin = Instance.new("Frame")
	coin.BorderSizePixel = 0
	coin.Name = "CoinMark"
	coin.Size = UDim2.new(0, 26, 0, 26)
	coin.BackgroundColor3 = Theme.Color.Currency
	coin.LayoutOrder = 1
	Components.corner(coin, Theme.Radius.Pill)
	Components.stroke(coin, Theme.Color.AccentShadow, Theme.Stroke.Bold)
	coin.Parent = pill

	coinsLabel = Components.label({
		text = "0",
		font = Theme.Font.BodyBold,
		size = Theme.TextSize.Heading,
		layoutOrder = 2,
		parent = pill,
	})
	-- Fixed minimum width so the pill doesn't jitter as digits change.
	local minWidth = Instance.new("UISizeConstraint")
	minWidth.MinSize = Vector2.new(64, 0)
	minWidth.Parent = coinsLabel
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Right

	Components.autoScale(pill)
	pill.Parent = parent
end

local function buildMenuRail(parent: Instance)
	local rail = Instance.new("Frame")
	rail.BorderSizePixel = 0
	rail.Name = "MenuRail"
	rail.BackgroundTransparency = 1
	rail.AnchorPoint = Vector2.new(0, 0.5)
	rail.Position = UDim2.new(0, Theme.Space.LG, 0.5, 0)
	rail.Size = UDim2.new(0, 0, 0, 0)
	rail.AutomaticSize = Enum.AutomaticSize.XY
	Components.listLayout(rail, Enum.FillDirection.Vertical, Theme.Space.SM)
	Components.autoScale(rail)
	rail.Parent = parent

	local shopButton = Components.button({ text = "Shop", variant = "secondary", width = 132, layoutOrder = 1, parent = rail })
	shopButton.instance.Activated:Connect(function()
		if shopModal.isOpen() then
			shopModal.close()
		else
			shopModal.open()
		end
	end)
end

local function animateCoins(target: number)
	Components.tween(displayedCoins, Theme.Motion.Count, { Value = target }, "count")
end

-- ─── Shop ─────────────────────────────────────────────────────────────────

local function buildItemCard(item: CatalogItem, parent: Instance)
	local rarityColor = (Theme.Rarity :: any)[item.rarity] or Theme.Color.TextMuted

	local card = Instance.new("Frame")
	card.BorderSizePixel = 0
	card.Name = item.id
	card.LayoutOrder = item.layoutOrder
	card.BackgroundColor3 = Theme.Color.SurfaceRaised
	card.Size = UDim2.new(0, CARD_WIDTH, 0, CARD_HEIGHT)
	Components.corner(card, Theme.Radius.MD)
	Components.stroke(card, Theme.Color.Border, Theme.Stroke.Thin)
	Components.padding(card, Theme.Space.MD, Theme.Space.MD)
	Components.listLayout(card, Enum.FillDirection.Vertical, Theme.Space.SM)

	-- Rarity is shown by color AND by text (never color alone).
	local art = Instance.new("Frame")
	art.BorderSizePixel = 0
	art.Name = "Art"
	art.BackgroundColor3 = Theme.Color.SurfaceSunken
	art.Size = UDim2.new(1, 0, 0, 104)
	art.LayoutOrder = 1
	Components.corner(art, Theme.Radius.SM)
	art.Parent = card

	local strip = Instance.new("Frame")
	strip.Name = "RarityStrip"
	strip.BackgroundColor3 = rarityColor
	strip.BorderSizePixel = 0
	strip.Size = UDim2.new(1, 0, 0, 3)
	strip.Position = UDim2.new(0, 0, 1, -3)
	strip.Parent = art

	local icon = Instance.new("ImageLabel")
	icon.BorderSizePixel = 0
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Image = item.icon
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(72, 72)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = art

	Components.label({ text = item.displayName, font = Theme.Font.BodyBold, size = Theme.TextSize.Body, layoutOrder = 2, parent = card })
	Components.label({
		text = item.rarity:upper(),
		font = Theme.Font.BodyBold,
		size = Theme.TextSize.Caption - 1,
		color = rarityColor,
		layoutOrder = 3,
		parent = card,
	})
	local description = Components.label({
		text = item.description,
		size = Theme.TextSize.Caption,
		color = Theme.Color.TextMuted,
		wrap = true,
		layoutOrder = 4,
		parent = card,
	})
	description.Size = UDim2.new(1, 0, 0, 34)
	description.AutomaticSize = Enum.AutomaticSize.None
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.TextTruncate = Enum.TextTruncate.AtEnd

	local action = Components.button({
		text = `Buy  {Components.formatNumber(item.price)}`,
		variant = "primary",
		size = "sm",
		layoutOrder = 5,
		parent = card,
	})
	action.instance.AutomaticSize = Enum.AutomaticSize.None
	action.instance.Size = UDim2.new(1, 0, 0, Theme.HitTarget)

	local function refresh()
		local owned = (state.Inventory[item.id] or 0) > 0
		local equipped = state.Equipped.Cosmetic == item.id
		if pendingPurchase[item.id] then
			action.setLoading("Buying…")
			return
		end
		action.setLoading(nil)
		if equipped then
			action.setText("Equipped")
			action.setEnabled(false)
		elseif owned then
			action.setText("Equip")
			action.setEnabled(true)
		else
			action.setText(`Buy  {Components.formatNumber(item.price)}`)
			action.setEnabled(state.Coins >= item.price)
		end
	end
	table.insert(cardRefreshers, refresh)

	action.instance.Activated:Connect(function()
		local owned = (state.Inventory[item.id] or 0) > 0
		if owned then
			Net.event("RequestEquip"):FireServer(item.id)
			return
		end
		if pendingPurchase[item.id] then
			return
		end
		pendingPurchase[item.id] = true
		refresh()
		Net.event("RequestPurchase"):FireServer(item.id)
		-- The server's snapshot/notify clears the pending state; time out just in case.
		task.delay(4, function()
			if pendingPurchase[item.id] then
				pendingPurchase[item.id] = nil
				refresh()
			end
		end)
	end)

	refresh()
	card.Parent = parent
end

local function buildShop()
	shopModal = Components.modal("Shop", {
		width = CARD_WIDTH * 3 + Theme.Space.MD * 2 + Theme.Space.XL * 2,
		title = "Outfitter",
		subtitle = "Gear for the deep caves. Earn coins by exploring.",
	})

	local grid = Instance.new("ScrollingFrame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.Size = UDim2.new(1, 0, 0, CARD_HEIGHT * 2 + Theme.Space.MD + Theme.Space.SM)
	grid.CanvasSize = UDim2.new()
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.ScrollingDirection = Enum.ScrollingDirection.Y
	grid.ScrollBarThickness = 4
	grid.ScrollBarImageColor3 = Theme.Color.BorderStrong
	grid.Selectable = false
	grid.Parent = shopModal.panel.body

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
	layout.CellPadding = UDim2.fromOffset(Theme.Space.MD, Theme.Space.MD)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	task.spawn(function()
		local ok, catalog = pcall(function()
			return Net.func("GetShopCatalog"):InvokeServer()
		end)
		if not ok or type(catalog) ~= "table" then
			Components.toast("The shop is restocking. Try again in a moment.", "error")
			return
		end
		for _, item in catalog :: { CatalogItem } do
			buildItemCard(item, grid)
		end
	end)
end

-- ─── lifecycle ────────────────────────────────────────────────────────────

local function refreshAll()
	for _, refresh in cardRefreshers do
		refresh()
	end
end

function UIController.Init()
	local hud = Components.screen("Hud", Theme.Layer.Hud)
	buildCurrencyPill(hud)
	buildShop()
	buildMenuRail(hud)

	displayedCoins.Changed:Connect(function(value: number)
		coinsLabel.Text = Components.formatNumber(math.floor(value + 0.5))
	end)
end

function UIController.Start()
	Net.event("DataSnapshot").OnClientEvent:Connect(function(snapshot: Snapshot)
		state = snapshot
		table.clear(pendingPurchase)
		animateCoins(snapshot.Coins)
		refreshAll()
	end)

	Net.event("Notify").OnClientEvent:Connect(function(payload: { kind: string, text: string })
		if payload.kind == "error" then
			table.clear(pendingPurchase)
			refreshAll()
		end
		Components.toast(payload.text, if payload.kind == "success" then "success" elseif payload.kind == "error" then "error" else "info")
	end)
end

return UIController
