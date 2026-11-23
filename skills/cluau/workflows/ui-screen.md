# Workflow: design or rebuild a UI screen

1. **Art direction line** from the game (ui-design-system.md §1–2) — never default to purple gradients.
2. **Tokens** (Theme.luau / UI Styling): palette roles, type scale, spacing, radius, motion.
3. **Hierarchy:** the one primary action, secondary actions, information; wireframe mobile-first.
4. **Build from components** (Components.luau): Button/Panel/Modal/Toast/ItemCard — real states (hover, pressed,
   disabled, selected, loading).
5. **Input parity:** touch targets ≥ 44 px, gamepad selection + B to close, Input Action System contexts switched
   while the menu is open (InputController.SetMenuOpen).
6. **Safe areas & scale:** `CoreUISafeInsets`, UIScale from viewport, console 1.5×.
7. **Accessibility:** PreferredTransparency, ReducedMotion, PreferredTextSize; contrast ≥ 4.5:1; no color-only info.
8. **Audit** with the anti-slop checklist (§12) and, if MCP is connected, `screen_capture` at phone and desktop
   sizes.
