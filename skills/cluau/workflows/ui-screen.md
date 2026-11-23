# Workflow: design or rebuild a UI screen

1. **Mood line** from the game (ui-design-system.md §1–1b) — never default to purple gradients.
2. **Preset → make it yours:** pick the closest `assets/themes/*.json` (lantern, meadow, candy, orbit, grimoire,
   hush, arena), copy it, change the accent / one font / radius for *this* game; `python3 tools/build_themes.py`
   (repo) or edit Theme.luau's `PRESET`. Each preset is a shape language (button style, shadow, gloss, motion
   spring), not just colors.
3. **Style tile:** `python3 scripts/style_tile.py <preset or theme.json> -o tile.html` — look at palette contrast,
   buttons in every state, a HUD/shop mock. Show the user; adjust before writing any Frame.
4. **Wireframe** from `references/ui-screen-recipes.md` (HUD per genre, shop, inventory, rewards, settings,
   results, trade, loading): the one primary action, secondary actions, information; mobile-first. Squint test:
   blur your eyes — the primary action and the key number must still read.
5. **Build from components** (Components.luau): Button/Panel/Modal/Toast/ItemCard — real states (hover, pressed,
   disabled, selected, loading). No raw `Color3` in screen code (lint CL097); every color is a `Theme.Color` role.
6. **Input parity:** touch targets ≥ 44 px, gamepad selection + B to close, Input Action System contexts switched
   while the menu is open (InputController.SetMenuOpen).
7. **Safe areas & scale:** `CoreUISafeInsets`, UIScale from viewport, console 1.5×.
8. **Accessibility:** PreferredTransparency, ReducedMotion, PreferredTextSize; contrast ≥ 4.5:1; no color-only info.
9. **Audit** with the anti-slop checklist (§12) and, if MCP is connected, `screen_capture` at phone and desktop
   sizes.
