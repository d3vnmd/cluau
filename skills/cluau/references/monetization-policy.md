# Monetization & Platform Policy

> Last verified: 2026-11-22 against Roblox/creator-docs @ a23352b (docs snapshot 2026-11-21). Re-verify with `tools/verify_api_refs.py`.

Cluau builds monetization that is **correct** (never loses or duplicates purchases), **compliant** (Roblox Terms, Community Standards, regional laws via PolicyService), and **fair** (no manipulative dark patterns). Fair monetization also retains players better.

## Contents
1. Product types
2. Developer products — ProcessReceipt
3. Game passes
4. Paid random items (loot boxes)
5. Subscriptions, Roblox Plus, private servers
6. Ads, rewarded video, external links
7. Dark patterns to refuse
8. Pricing guidance
9. Testing purchases

---

## 1. Product types

| Type | Bought | Use for | Grant on |
|---|---|---|---|
| Game Pass | once | permanent perks (VIP, 2× coins, extra slot) | join (ownership check) + purchase finished event |
| Developer Product | repeatable | currency packs, boosts, revives, skips | `ProcessReceipt` |
| Subscription | monthly | ongoing benefits | `MarketplaceService:GetUserSubscriptionStatusAsync` / `UserSubscriptionStatusChanged` |
| Avatar items / UGC | Marketplace | cosmetics outside game | – |
| Private servers | monthly | small groups | configured in Creator Dashboard |

## 2. Developer products — ProcessReceipt

Rules (all mandatory):

1. Assign `MarketplaceService.ProcessReceipt` **exactly once**, in **one server script**. Assigning it again replaces the previous handler.
2. Look up the player by `receiptInfo.PlayerId`. If not in server → `NotProcessedYet` (Roblox will retry when they rejoin).
3. Wait for the player's data to be loaded (bounded); if it isn't → `NotProcessedYet`.
4. **Idempotency**: if `receiptInfo.PurchaseId` is already recorded in the player's data → `PurchaseGranted` (already given).
5. Grant the product via a handler table keyed by `ProductId`. If the handler errors → `NotProcessedYet`.
6. Record `PurchaseId` in the **same session-locked profile** as the grant, then save immediately (yielding inside `ProcessReceipt` is allowed). Return `PurchaseGranted` only when that save succeeded. If it failed, return `NotProcessedYet`: the grant and receipt id are still together in the live profile, and when Roblox retries, the idempotency check in step 4 returns `PurchaseGranted` without granting twice. If the session was lost entirely, both the grant and the record are gone, so the retry correctly grants again.
7. Never grant from client calls like `PromptProductPurchaseFinished` — that event is informational only.
8. **Roblox sells listed developer products outside your game** (home page, search, after Robux purchases) and **audits ProcessReceipt continuously** — products whose handling fails are removed from those surfaces. The callback also fires on join, has no timeout, and the same purchase can be processed on two servers at once (the session lock + recorded PurchaseId makes that safe). If no callback is set, receipts are auto-acknowledged and lost.
9. Block purchase prompts while a player's data failed to load. Read prices with `GetProductInfoAsync` (hard-coded prices break price optimization, which needs ~60k transactions / 30 days).

Template: `templates/server/MonetizationService.luau`.

## 3. Game passes

- On join: `MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)` in `pcall` (retry once), cache result in a session table/attribute.
- On purchase in-game: `MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased) ... end)` on the server → grant if `wasPurchased`.
- Perks must be applied server-side (e.g. coin multiplier read by the server when awarding coins).
- Gifting a pass isn't possible; design gift flows with developer products.
- Prompt from the client with `MarketplaceService:PromptGamePassPurchase(player, passId)` after an explicit button press.

## 4. Paid random items

Applies to any random reward obtainable directly or indirectly with Robux (eggs/crates/spins bought with Robux or Robux-purchased currency).

- **Show exact odds** for every possible item before purchase, in the purchase UI.
- Call `PolicyService:GetPolicyInfoForPlayerAsync(player)` (server, pcall) and if `ArePaidRandomItemsRestricted` is true → hide/disable paid random purchases for that player (offer direct purchase alternatives or free-currency-only versions).
- Implement weighted randomness on the server with `Random.new()`; publish the same weights the server uses (single source of truth in config).
- Pity systems are optional but disclose them if used.

```lua
local function rollWeighted(rng: Random, entries: { { id: string, weight: number } }): string
	local total = 0
	for _, entry in entries do
		total += entry.weight
	end
	local roll = rng:NextNumber(0, total)
	local acc = 0
	for _, entry in entries do
		acc += entry.weight
		if roll <= acc then
			return entry.id
		end
	end
	return entries[#entries].id
end
```

## 5. Subscriptions, Roblox Plus, private servers

- **Roblox Plus** (launched 2026-04-30, $4.99/month) replaced new Premium sign-ups. Check `player.HasRobloxSubscription` (not the deprecated `MembershipType`) for small subscriber perks; prompt with `MarketplaceService:PromptRobloxSubscriptionPurchase(player)` only from explicit UI. Roblox funds the subscriber discount on your products (creator share rises to 78% / 88% at 10% / 20% discount) and pays up to 750 Robux per sign-up through your game.
- Engagement-based payouts reward real session quality — never pad sessions artificially.
- Experience subscriptions: Robux subscriptions ≥ 49 R$/month (70% share); local-currency tiers $2.99–$14.99. Check status on join (`GetUserSubscriptionStatusAsync`, pcall) and handle lapsing gracefully.

## 6. Ads, rewarded video, external links

- Use Roblox's official ad products and follow their placement rules. **Rewarded video ads must grant a developer product through ProcessReceipt** (never Robux as the reward). Check `PolicyInfo` fields (`AreAdsAllowed`, `IsSubjectToChinaPolicies`, `IsPaidItemTradingAllowed`) before showing such features; `AllowedExternalLinkReferences` is legacy and always empty.
- `IsPaidItemTradingAllowed == false` → block trading of paid items for that player. Gate gifting/trading value with `MarketplaceService:GetUsersPriceLevelsAsync` (regional prices are 30–100% of the default).
- Don't link off-platform except to allowed references.
- No fake ad billboards impersonating brands.

## 7. Dark patterns — refuse to build, offer a fair alternative

| Request | Why not | Alternative |
|---|---|---|
| Fake countdown "offer ends in 00:59" that resets | Deceptive | Real limited-time offers with server-time end dates |
| Purchase prompt on join / on death without intent | Pressure, policy risk | Shop button highlight, end-of-round summary with optional offer |
| "FREE" button that opens a Robux prompt | Deceptive | Clear price on every purchase button |
| Hiding the close button / tiny X | Coercive | Equal-weight close/"Not now" |
| Pay-to-skip a wait you made punitive | Exploitative | Reasonable base timers; skips as convenience |
| Unclear real-money value via confusing currency ratios | Obfuscation | Round, consistent bundles; show Robux price |
| Targeting kids with guilt copy ("Your pet is sad, buy food!") | Manipulative | Positive, optional framing |
| Pay-to-win in competitive PvP | Hurts retention | Cosmetics, convenience, side-grades |
| Unfiltered trade chat or off-platform trading | Policy | Server-side trades, filtered text |

## 8. Pricing guidance (starting points; tune with analytics)

- Game passes: 2× currency ~ 199–499 R$, VIP ~ 149–399 R$, small perks 25–99 R$.
- Developer products: currency ladder with bonus on bigger packs (e.g. 49 / 99 / 249 / 499 / 999 R$, bonus +0% / +5% / +10% / +15% / +25%).
- Starter pack (one-time via data flag): high value, 49–99 R$.
- Revive/continue: 15–49 R$, with free alternatives (watch-a-moment, spend soft currency).
- Use Creator Dashboard analytics + price testing tools where available.

## 9. Testing purchases

- In Studio, purchases are simulated (no Robux spent); `ProcessReceipt` still fires — test idempotency by returning `NotProcessedYet` and rejoining.
- Test with the player leaving mid-purchase, data failing to load, and repeat purchases.
- Log purchases (PurchaseId, ProductId, time) server-side to a separate DataStore if you need an audit trail.
