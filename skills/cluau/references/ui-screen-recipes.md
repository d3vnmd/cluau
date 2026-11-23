# UI Screen Recipes — Layouts Designers Reuse

> Last verified: 2026-11-23. Sizes are reference pixels at 1080p (scale with `Components.autoScale`). Components:
> `templates/ui/Components.luau`. Tokens: `Theme.luau` (pick a preset first — ui-design-system.md §1b).

Each recipe: purpose → layout → hierarchy → states → mobile/gamepad notes → common mistakes.

## Contents
1. HUD (by genre)
2. Shop / store
3. Inventory / collection
4. Item detail / equip
5. Daily rewards
6. Quest / objective tracker
7. Settings
8. Round results / end screen
9. Trade window
10. Loading / first-time screen

---

## 1. HUD

| Genre | Top-center | Left rail | Bottom | Right |
|---|---|---|---|---|
| Simulator | currency pills (max 2–3), big numbers | 4–6 menu buttons (Shop, Pets, Rebirth, Quests) | backpack/capacity bar | boosts (timers), notifications |
| Obby | stage "12 / 50", timer | skip / settings | — | checkpoint toast |
| Round-based | phase + countdown from `EndsAt`, alive count | — | abilities | kill feed |
| Shooter | — (keep clear) | — | health/ammo bottom-left/right corners away from thumbsticks | minimap/score top-right under the topbar |
| Horror | nothing persistent; objective fades in, fades out | — | stamina only when draining | — |

Rules: center screen belongs to gameplay; HUD lives on edges; `CoreUISafeInsets`; touch zones bottom-left
(thumbstick) and bottom-right (jump) stay clear. Every value change animates (count-up, pop) — the HUD is the
game's heartbeat.

## 2. Shop / store

- **Layout:** modal 3 columns × N cards (`ItemCard` 196×248), category tabs on top, currency pill in the header.
- **Hierarchy:** item art > name > price button. One featured row/banner at most.
- **Card:** art on `SurfaceSunken` with a rarity bottom strip (color + rarity text), name `BodyBold`, price as the
  primary button ("Buy  250"); owned → "Equip"; equipped → disabled "Equipped".
- **States:** can't afford → disabled with the gap ("Need 40 more"), loading "Buying…", restock timer in the
  header if rotating (LiveOpsService / `NextRestockAt`).
- **Robux items:** separate tab or section, clear R$ price, odds button for any random item.
- **Mistakes:** 20 items visible at once, red "SALE!!!" everywhere, prices without currency icons.

## 3. Inventory / collection

- **Layout:** grid of square slots (UIGridLayout, 96–112 px cells), filters/sort row, detail panel on the right
  (desktop) or bottom sheet (phone).
- **Collection index:** silhouettes for undiscovered items (completion pull), "23 / 40" progress bar.
- **Reuse rows/cells** on refresh — never destroy and rebuild 200 frames.
- **Gamepad:** grid is a `SelectionGroup`; `NextSelection*` set at edges; detail updates on selection.

## 4. Item detail / equip

Big art (ViewportFrame with consistent camera), name + rarity, 2–4 stats with bars, primary action
(Equip/Use), secondary (Sell/Trade) as ghost buttons. Compare vs equipped with ▲/▼ and green/red **plus**
arrows (not color alone).

## 5. Daily rewards

7-day strip or 4×7 calendar; today highlighted with the accent and a gentle idle bounce; claimed days dimmed
with a check; tomorrow's reward visible (anticipation). Missing a day pauses, doesn't wipe (retention-design.md).
Claim → reward flies to the currency pill.

## 6. Quest / objective tracker

Collapsed: 1–3 lines at the right edge, current objective + progress "7 / 10". Expanded: list with rewards.
Completed quest: check + reward pop, auto-collapse after 2 s. Never cover the center.

## 7. Settings

Grouped sections (Audio, Graphics, Accessibility, Controls). Sliders for Music/SFX (wired to
`AudioController.SetVolume` + saved data), toggles for Reduced Motion, camera shake, damage numbers. Changes
apply live; no "Save" button needed (autosave). Show key/gamepad bindings with glyphs from the Input Action
System.

## 8. Round results / end screen

Hero line ("Victory" / "Round Over") in `Display`; podium or ranked list; personal stats; rewards counting up
one by one (0.15 s stagger); two buttons: "Play again" (primary) and "Lobby" (secondary). Respect the next
intermission timer.

## 9. Trade window

Two columns (You | Them) with offer grids, each with a ready indicator; offer changes flash the changed slot
and reset both ready states (TradeService does this server-side); confirm button shows the quiet-period
countdown; big warning line if values look lopsided. Never let the confirm button be in the same spot as "add
item" (misclick scams).

## 10. Loading / first-time screen

ReplicatedFirst loading screen: game logo, one tip line, progress that actually means something
(`ContentProvider:PreloadAsync` count), skip after ~5 s. First-time: one goal instruction, not a tutorial wall.
