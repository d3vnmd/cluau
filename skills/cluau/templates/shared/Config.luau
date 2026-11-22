--!strict
--[[
	Config — read-only game tuning shared by server and client.
	Location: ReplicatedStorage/Shared/Config (ModuleScript)

	The client may READ this to display prices; the server ALWAYS re-reads prices from here
	and never trusts a price sent by a client.
]]

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"

export type ShopItem = {
	id: string,
	displayName: string,
	description: string,
	price: number,
	rarity: Rarity,
	icon: string, -- rbxassetid://...
	layoutOrder: number,
}

local function freezeDeep<T>(value: T): T
	if type(value) == "table" and not table.isfrozen(value :: any) then
		for _, child in value :: any do
			freezeDeep(child)
		end
		table.freeze(value :: any)
	end
	return value
end

local Config = {
	Currency = {
		StartingCoins = 100,
		MaxCoins = 1_000_000_000,
	},

	Data = {
		StoreName = "PlayerData_v1", -- change suffix (not the data) to wipe in development only
		AutosaveSeconds = 120,
	},

	Shop = {
		-- Replace icons with your own uploaded images. Keep ids stable: they are saved in player data.
		Items = {
			TrailEmber = {
				id = "TrailEmber",
				displayName = "Ember Trail",
				description = "Leaves a short ribbon of warm sparks.",
				price = 250,
				rarity = "Rare",
				icon = "rbxassetid://0",
				layoutOrder = 1,
			},
			HatLantern = {
				id = "HatLantern",
				displayName = "Lantern Cap",
				description = "Lights the way in dark caves.",
				price = 120,
				rarity = "Common",
				icon = "rbxassetid://0",
				layoutOrder = 2,
			},
		} :: { [string]: ShopItem },
	},

	Monetization = {
		-- Fill in your real ids from the Creator Dashboard.
		GamePasses = {
			DoubleCoins = 0,
		},
		Products = {
			Coins500 = 0,
		},
	},
}

return freezeDeep(Config)
