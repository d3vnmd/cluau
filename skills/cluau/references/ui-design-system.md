# UI Design System — Human-Crafted, Never Slop

The goal: a player should believe a professional UI artist designed this interface specifically for *this* game. Generic, template-y, AI-looking UI is a bug.

## Contents
1. Process: from game identity to tokens
2. Art-direction presets (starting points, not defaults)
3. Tokens: color, type, space, radius, stroke, elevation, motion
4. Layout & responsiveness
5. Components & states
6. Input parity: mouse, touch, gamepad, VR
7. HUD composition
8. Copywriting
9. Motion
10. Iconography & imagery
11. Accessibility
12. Anti-slop audit (detailed)
13. Studio property recipes

---

## 1. Process

1. **Read the game.** Genre, setting, audience age, mood, camera, pace. A horror game's UI is quiet and diegetic; a simulator's is chunky and celebratory; a competitive shooter's is thin and information-dense.
2. **Write the art direction line** (one sentence, concrete nouns): material, era, palette mood, typographic voice. Example: *"Arcade candy shop — cream paper, cherry-red accent, thick dark outlines, rounded bold display type, bouncy but quick motion."*
3. **Choose tokens** from that line (§3). Write them in `Theme.luau`.
4. **Sketch the screen hierarchy**: what's the one primary action? What's secondary? What can be hidden behind a tab?
5. **Build with components** — every screen uses the same Button/Panel/Label primitives.
6. **Audit** (§12) on three viewport sizes and with a gamepad.

If the user has no direction, propose two distinct directions in one line each and pick the one that best fits the genre — don't default to "dark mode with purple gradient".

## 2. Art-direction presets

Use as seeds; always tint/adjust to the game.

| Direction | Palette idea | Type | Shape | Motion |
|---|---|---|---|---|
| **Cozy/handmade** (farming, cafe, pets) | Warm cream `#F4EBDD`, ink `#3B2F2A`, one accent (sage `#7FA36B` or tomato `#E0603F`) | Rounded display (`FredokaOne`, `Bangers` sparingly) + `BuilderSans`/`Nunito` UI | Radius 8–12, 2–3 px dark outline stroke, paper texture 9-slice | Soft overshoot (Back Out, small amplitude), 0.2–0.3 s |
| **Clean sci-fi** (space, tech, shooters) | Graphite `#14171C`→`#2A2F38`, one cyan or amber accent, desaturated neutrals | `Michroma`/`Oxanium`-like display for headers (sparingly), `BuilderSans` or `RobotoMono` for numbers | Radius 0–4, 1 px strokes, chamfered corners via image | Linear/Quad, 0.12–0.2 s, no bounce |
| **Fantasy/RPG** | Parchment, oxblood `#7A1E22`, gold `#C9A44C` used as trim, deep green | Serif display (`Merriweather`, `Sarpanch`-style) + clean sans | Ornamented 9-slice frames, low radius | Fades and slides, 0.25–0.35 s |
| **Arcade/simulator** | Saturated but limited: one hero color + white + deep shade of the hero hue, gold for currency | Heavy rounded display (`FredokaOne`, `LuckiestGuy`) + bold UI | Radius 10–16, thick bottom "3D" edge, big touch targets | Snappy pop (scale 0.9→1 with Back Out 0.15 s) |
| **Horror/minimal** | Near-black warm `#0E0D0C`, bone `#D8D2C4`, blood accent used once | Thin/condensed sans or typewriter (`SpecialElite`) | No panels; text floats on scrim; diegetic notes | Slow fades 0.4–0.8 s, flicker only for story beats |
| **Competitive/esports** | Neutral dark, team colors as the only saturated hues | Condensed sans, tabular numbers | Sharp, thin dividers, dense | Minimal, instant feedback |

Font availability: Roblox ships many families at `rbxasset://fonts/families/<Name>.json` (e.g. `BuilderSans`, `GothamSSm`, `Montserrat`, `Nunito`, `FredokaOne`, `LuckiestGuy`, `Bangers`, `Oswald`, `Merriweather`, `RobotoMono`, `SourceSansPro`, `Ubuntu`, `SpecialElite`, `Michroma`, `Sarpanch`). Verify with `Font.fromName("Name")` or the Studio font picker; Creator Store fonts can also be used with their asset id. Never use more than two families.

## 3. Tokens

### Color
- **Neutrals**: 6–8 steps from background to strongest text, **tinted** toward the accent hue (pure grey looks unfinished). Example (cool tint): `bg #12151B`, `surface #1A1F27`, `surfaceRaised #232A34`, `border #313A47`, `textMuted #8C97A8`, `text #E6EAF0`.
- **Accent**: one primary brand color with `accent`, `accentHover` (+6–8% lightness), `accentPressed` (−8–10%), `onAccent` (text on accent, contrast ≥ 4.5:1).
- **Semantic**: `success`, `warning`, `danger`, `info` — muted to fit the palette; used only for meaning.
- **Currency/rarity colors** are part of the palette: Common (neutral), Uncommon (green), Rare (blue), Epic (purple), Legendary (gold), Mythic (red/pink). Desaturate to match the art direction. This is the one place purple is often appropriate.
- Gradients: at most a subtle 2-stop gradient on a hero element (e.g. ±6% lightness of the same hue). No rainbow, no purple→blue default.
- Transparency: panels at 0–0.15 transparency; scrims (`#000` at 0.4–0.6) behind modals. Don't layer translucent glass on glass.

### Type scale (TextSize in px at 1080p reference; scale with `UIScale` for small screens)
| Token | Size | Use |
|---|---|---|
| `display` | 40–56 | Big moments (round won, level up) |
| `title` | 28–32 | Screen titles |
| `heading` | 20–22 | Section headers, card titles |
| `body` | 16–18 | Default text |
| `caption` | 13–14 | Secondary info, hints |

Weights: Bold/Heavy for display, SemiBold for headings, Regular/Medium for body. Line height (`LineHeight`) 1.0–1.15 for headings, 1.2 for body.

### Spacing (4 px grid)
`xxs 2, xs 4, sm 8, md 12, lg 16, xl 24, xxl 32, xxxl 48`. Padding inside panels: `lg`–`xl`. Gaps in lists: `sm`–`md`. Separate unrelated groups with ≥ 2× the gap of related items.

### Radius
Pick 2–3: e.g. `sm 4`, `md 8`, `pill 999` (UICorner with `UDim.new(0.5, 0)` or large offset for pills). Nested elements: inner radius = outer radius − padding (never larger than the parent's).

### Stroke
`UIStroke` thickness 1 (sci-fi/clean) or 2–3 (cartoon). `ApplyStrokeMode = Border` for frames. Use `LineJoinMode = Round` for cartoon styles. Text stroke on bright game-world-overlaid text only.

### Elevation
Max 3 levels: flat, raised (subtle shadow/darker bottom edge), overlay (modal with scrim). Shadows via a single 9-slice blurred image (`ImageLabel` behind with `SliceCenter`), consistent offset (0, 4) and transparency ~0.6.

### Motion
| Token | Duration | Easing |
|---|---|---|
| `instant` | 0.08 s | Quad Out |
| `fast` | 0.12 s | Quad Out (press) |
| `normal` | 0.2 s | Quint Out (hover, toggles) |
| `slow` | 0.32 s | Quint Out (panels in) |
| `exit` | 0.18 s | Quad In (panels out — exits faster than entrances) |

## 4. Layout & responsiveness

- Reference resolution 1920×1080; test 1280×720, 1366×768, iPad 1024×768-ish, phone landscape ~ 844×390 and phone portrait if the game supports it.
- **Container-first**: a root Frame per screen with `UIPadding`, children laid out with `UIListLayout` (`FillDirection`, `Padding`, `HorizontalAlignment`, `VerticalAlignment`, `SortOrder = LayoutOrder`) or `UIGridLayout`. `UIFlexItem` (`FlexMode = Fill/Grow/Shrink`) for flexible rows; `UIListLayout.Wraps = true` for chip rows.
- `AutomaticSize = XY` on labels/buttons that should hug content (+ `UIPadding`). Beware: AutomaticSize with Scale sizes can fight — use Offset for the hugging axis.
- **Scale vs Offset**: Scale positions anchors to the screen; Offset sizes make components consistent. Typical: panel `Size = UDim2.new(0, 520, 0, 0)` + `AutomaticSize.Y` + `UISizeConstraint` max, positioned with `AnchorPoint = (0.5, 0.5)`, `Position = (0.5, 0, 0.5, 0)`.
- **Global scale**: one `UIScale` on the ScreenGui root, set from viewport size (e.g. `math.clamp(viewport.Y / 1080, 0.65, 1.25)`), updated on `camera:GetPropertyChangedSignal("ViewportSize")`. Then design in reference pixels. Template: `Components.attachAutoScale`.
- `UIAspectRatioConstraint` for icons, item cards, avatars.
- `ScrollingFrame`: `AutomaticCanvasSize = Y`, `CanvasSize = UDim2.new()`, `ScrollBarThickness` 4–6, `ScrollingDirection = Y`, padding so content doesn't hide under the bar; `ScrollBarImageColor3` from tokens.
- `ZIndexBehavior = Sibling` on ScreenGuis (default for new ones). Layer with `DisplayOrder` between ScreenGuis (HUD 0, menus 10, modals 20, toasts 30), not huge ZIndex numbers.
- Safe areas: interactive HUD uses `ScreenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets` (avoids notches **and** Roblox core buttons); `TopbarSafeInsets` only for a dedicated topbar-row ScreenGui (reported wrong on some consoles — test); full-bleed backgrounds use `None` + `IgnoreGuiInset = true`. Don't hard-code the old 36 px topbar height.
- **UI Styling** (StyleSheet / StyleRule / StyleLink / StyleDerive, StyleQuery, Styling Transitions) can implement the token system natively and enables theme switching; Theme.luau tokens map 1:1 onto style rules.
- Flex (`UIFlexItem`, `UIListLayout.Wraps`) costs layout time: keep < 1,000 items; AutomaticSize + UIFlexItem is unsupported with non-zero AnchorPoint, scale-sized items, scaled padding or TextScaled.
- `CanvasGroup`: texture memory capped by graphics quality — renders blank over the cap, re-textures on resize, keeps memory while hidden, black on some phones. Use only for short fixed-size fades; destroy after.

## 5. Components & states

Every interactive component implements:

| State | Visual |
|---|---|
| Default | token colors |
| Hover (mouse only) | background `accentHover`, `UIScale` 1.02–1.03 |
| Pressed | `accentPressed`, `UIScale` 0.96–0.97, 0.08–0.12 s |
| Selected (gamepad) | `SelectionImageObject` custom ring or stroke color change — never the default blue square |
| Disabled | 40–50% opacity text/background, no hover, `Active = false`, `AutoButtonColor = false`, `Interactable = false` where available |
| Loading | label swapped for "Buying…" / spinner; button locked until server reply |

Always `AutoButtonColor = false` and implement states yourself (default darkening looks cheap).

Core component set (implemented in `templates/ui/Components.luau`):
- `Button` (variants: primary, secondary, ghost, danger; sizes sm/md/lg)
- `IconButton` (square, tooltip on hover/gamepad focus)
- `Panel` (surface, padding, optional title + close)
- `Label` (type token, color token, wrap)
- `Modal` (scrim, focus trap, Escape/ButtonB to close, restores previous selection)
- `ProgressBar` (fill tween, optional segmented)
- `Toast` (stacked, auto-dismiss, max 3 visible)
- `Tabs` (keyboard/gamepad navigable)
- `ItemCard` (icon, name, rarity strip, price/owned state)

## 6. Input parity

- Detect current input: `UserInputService:GetLastInputType()` + `LastInputTypeChanged`; map to `"KeyboardMouse" | "Touch" | "Gamepad"`. Swap prompts ("[E]" / tap icon / "Ⓧ" glyph image) and hide hover-only affordances on touch.
- Input Action System: one `InputContext` per mode (gameplay, menu) in ReplicatedStorage; glyphs via `InputActionLabel` or `UserInputService:GetImageForKeyCode`; switch contexts when menus open so gameplay actions don't fire behind UI.
- Touch: hit areas ≥ 44 px (reference) — enlarge invisible hit frame if the visual is smaller. Keep critical buttons out of the bottom-left (thumbstick) and bottom-right (jump) zones. Use `ContextActionService:BindAction(name, fn, true, ...)` for mobile action buttons, then `SetPosition`/`SetImage`.
- Gamepad: on opening a screen set `GuiService.SelectedObject` to the primary button; `Selectable = true` on interactive elements, `false` on decorative; define `NextSelectionUp/Down/Left/Right` when layouts are irregular; `SelectionGroup = true` on containers; close with `ButtonB`.
- Keyboard: Escape closes modals; number keys for hotbars; show keybinds in tooltips.
- VR: avoid essential text in screen corners; prefer `SurfaceGui` / `BillboardGui` panels in world for VR-specific UI.

## 7. HUD composition

- Corners: top-left (Roblox menu) and top-right (Roblox) are taken — HUD lives at left-middle, bottom-center, top-center under the bar, right-middle.
- Currency: one compact pill per currency, top-center or left; animated count-up on change (0.4 s) with a small `+25` floater.
- Primary menu buttons: vertical rail on the left-middle (icon + optional label), 3–6 items max.
- Objective/round info: top-center.
- Hotbar/abilities: bottom-center, clear of mobile controls.
- Notifications: one stack, top-right under the bar or right-middle.
- Center: crosshair/interaction prompts only.

## 8. Copywriting

- Write in the game's voice and the player's language. Labels are verbs for actions ("Equip", "Buy for 250", "Claim"), nouns for navigation ("Pets", "Shop").
- Prices show currency icon + number, not "Cost: 250 coins!!!".
- Error/feedback messages explain what to do: "Need 40 more coins" not "Error: insufficient funds".
- No "Welcome to the game!", "Awesome", "Epic", "Click here". No ALL CAPS paragraphs (caps only for very short labels in styles that support it, with letter spacing via font choice).
- Localize via `LocalizationService`/translation tables if the game targets multiple languages; leave room for 30–40% longer strings.

## 9. Motion

- Panels enter from the direction of their trigger (shop button on left → slides in from left 24–40 px + fades), exit faster.
- Feedback: buttons press (scale), values pop when they change, rewards fly from source to the currency pill.
- One celebratory animation at a time. No idle pulsing on everything; use idle attention animation only on the single thing the player should do next (and stop after they've done it once).
- Use `TweenService:Create(obj, TweenInfo.new(d, style, dir), goal)`; cancel previous tween on the same property before starting a new one; group-fade via `CanvasGroup.GroupTransparency` (CanvasGroups cost memory — use for panels, not hundreds of rows).

## 10. Iconography & imagery

- One icon family: same stroke weight, corner style, fill style. Upload as decals/images; color via `ImageColor3` with white source icons so tokens control color.
- No emoji, no mixed clipart, no screenshots of other games.
- Item icons: render in a ViewportFrame or pre-rendered images with consistent camera angle and lighting.
- Backgrounds: subtle texture or flat; avoid busy images behind text.

## 11. Accessibility

Wire Roblox's player settings into every component (see `Components.luau`): multiply panel transparency by `GuiService.PreferredTransparency`, replace motion when `GuiService.ReducedMotionEnabled`, respect `GuiService.PreferredTextSize`. Consoles: ~1.5× scale for 10-foot viewing.

**Frameworks** (optional): React-Luau (maintained by Roblox), Fusion 0.3, Vide; state with Charm (+CharmSync). Roact/Rodux are legacy. Plain instances + components (this skill's templates) are fine for most games. Top simulator-style games use **image-based UI kits** (9-slice frames, one icon family) rather than code-drawn boxes — commission or create a kit that matches the art direction.


- Contrast: text ≥ 4.5:1 (small) / ≥ 3:1 (large, ≥ 24 px bold).
- Never rely on color alone (rarity also gets a label or shape).
- Minimum body text 14 px at reference resolution after UIScale on phones.
- Settings: music/SFX volume, reduced motion, camera shake toggle; persist in player data.
- Avoid flashing > 3 times per second.

## 12. Anti-slop audit

Score each; fix anything that fails.

1. Is there a written art direction and do all screens follow it?
2. Every color from Theme tokens? No raw `Color3.fromRGB` in components except theme?
3. ≤ 2 font families? Consistent type scale? No `TextScaled` on body text?
4. One primary action per screen, visually dominant?
5. Consistent radius, stroke, padding across all screens?
6. Zero emoji; one icon family?
7. Copy is specific to the game; no filler or "Welcome!"?
8. Hover/pressed/disabled/selected states exist and look intentional?
9. Works at 1280×720 and phone landscape with notch; nothing overlaps core UI?
10. Fully navigable with gamepad; Escape/B closes; selection restored?
11. Motion durations ≤ 0.35 s, purposeful, no Elastic/Bounce on panels?
12. No gradients-for-decoration, no glass-on-glass, no neon glow unless the art direction calls for it?
13. Feedback for every server action (pending → success/fail)?
14. Numbers don't jitter (fixed widths / right aligned)?
15. Lists reuse rows; no UI leaks on reopen?
16. Every GUI object created in code has `BorderSizePixel = 0` (the `Instance.new` default draws a dark 1 px border)?

## 13. Studio property recipes

**Primary button (cartoon arcade)**
```
TextButton  Size=(0,220,0,56)  BackgroundColor3=accent  AutoButtonColor=false  Text="Buy for 250"
            FontFace=FredokaOne Bold  TextSize=22  TextColor3=onAccent
  UICorner  CornerRadius=(0,12)
  UIStroke  Color=accentShadow  Thickness=3  ApplyStrokeMode=Border  LineJoinMode=Round
  UIPadding Left/Right=(0,16)
  UIScale   Scale=1 (tweened for press/hover)
```

**Panel (clean sci-fi)**
```
Frame      Size=(0,520,0,0) AutomaticSize=Y  BackgroundColor3=surface  BackgroundTransparency=0.04
  UICorner CornerRadius=(0,4)
  UIStroke Color=border Thickness=1 Transparency=0.2
  UIPadding all=(0,24)
  UIListLayout Padding=(0,12) SortOrder=LayoutOrder
```

**Currency pill**
```
Frame  AutomaticSize=X Size=(0,0,0,40)  BackgroundColor3=surfaceRaised
  UICorner (0.5,0)
  UIPadding L=(0,8) R=(0,14)
  UIListLayout Horizontal  Padding=(0,8)  VerticalAlignment=Center
  ImageLabel (icon 28×28, UIAspectRatioConstraint 1)
  TextLabel  AutomaticSize=X  FontFace=BuilderSans Bold  TextSize=20  Text="12,480"
```
