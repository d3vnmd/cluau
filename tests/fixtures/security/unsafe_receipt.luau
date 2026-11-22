--!strict
-- ProcessReceipt that is neither idempotent nor persisted.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
MarketplaceService.ProcessReceipt = function(info) -- expect CL111
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if player then
		player:SetAttribute("Coins", (player:GetAttribute("Coins") or 0) + 500)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted -- expect CL112
end
