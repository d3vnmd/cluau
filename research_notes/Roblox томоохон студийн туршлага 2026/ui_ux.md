# Roblox UI/UX design and UI engineering: professional practice (as of Nov 2026)

> Method note: In this session, devforum.roblox.com and create.roblox.com could not be fetched directly (the network blocked both hosts). Findings from those domains come from search-engine summaries of the pages, not full reads, so they carry somewhat less certainty. github.com pages were fetched directly. Items marked **[training knowledge, unverified]** come from background knowledge with no source retrieved this session. The report writer should label them that way or leave them out.

## 1. UI frameworks and state management used professionally (2025-2026)

### Takeaway
The professional code-driven stacks are React-Luau (Roblox-maintained, with the public fork jsdotlua/react-lua), Fusion 0.3, and Vide. Roact has been superseded by React-Luau. On the state side, littensy's Charm (atomic signals plus CharmSync for server-to-client replication) is the modern choice, Reflex is the batteries-included Rodux successor, and Rodux is legacy. No source documents which framework specific top studios use, so per-studio claims stay unverified.

### Cited Findings
- **React-Luau / react-lua:** It is maintained by Roblox. "Most studio plugins and the Roblox Universal App are all written in react-lua" (community DevForum guide, anecdotal). — [How To: React + Roblox (DevForum)](https://devforum.roblox.com/t/how-to-react-roblox/2964543)
- The jsdotlua repo is the community-contributable fork. Roblox's own repository is "a read-only mirror of their internal project". The fork targets ReactJS 17.x, its status reads "Partially Ported", and its last push was listed as May 2025. — [jsdotlua/react-lua](https://github.com/jsdotlua/react-lua); [ecosyste.ms listing](https://awesome.ecosyste.ms/projects/github.com%2Fjsdotlua%2Freact-lua)
- Roact "has been superseded by react-lua as of 2025". React-lua offers an experience much closer to mainline React. — [How To: React + Roblox](https://devforum.roblox.com/t/2964543); [Roact crash course marked Deprecated](https://devforum.roblox.com/t/roact-ui-framework-crash-course-deprecated/796618)
- `ReactRoblox.act` is not available in production builds. The react-luau test renderer is "unstable… not for production." — [react-roblox API docs](https://jsdotlua.github.io/react-lua/api-reference/react-roblox)
- **Fusion:** The latest release on GitHub is **v0.3-beta, released 30 Aug**. The page shows no year; it is 2024 per training knowledge [unverified]. No 0.4 appears. The 0.3 changes:
  - `use` functions replace `:get()`, and `peek()` reads a value without tracking it.
  - **Scopes** take over memory management from Maids, with `possiblyOutlives` warnings.
  - **Contextuals** pass values through a tree without prop drilling.
  - **Safe expressions** supply fallback values when logic fails.
  - **Hybrid execution** makes reads pull-based and observers eager, and skips computations whose results nobody uses.
  - [dphfox/Fusion releases](https://github.com/dphfox/Fusion/releases)
- The Fusion 0.3 ecosystem is active: the OnyxUI component library upgraded to 0.3, FFusion (GUI-to-Fusion converter) bundles v0.3.0, and the PluginEssentials port migrated to 0.3. — [OnyxUI](https://devforum.roblox.com/t/3145229); [FFusion](https://devforum.roblox.com/t/ffusion-convert-your-roblox-guis-into-fusion-components-free/4810694); [PluginEssentials](https://devforum.roblox.com/t/pluginessentials-fusion-components-meant-to-speed-up-the-development-of-roblox-plugins/3503805)
- **Vide (centau):** "A reactive Luau library for creating UI", inspired by SolidJS. It is fully typecheckable in Luau and uses declarative syntax with `source()` reactive values. It is MIT-licensed, actively maintained (218 commits, CI), and has about 364 stars at fetch time. No public "used by" list exists. littensy/vide adds JSX for roblox-ts. — [centau/vide](https://github.com/centau/vide); [docs](https://centau.github.io/vide/); [littensy/vide](https://github.com/littensy/vide)
- **Charm (littensy):** "Fine-grained reactivity for Roblox", an atomic library inspired by Jotai and Nanostores.
  - Core APIs: `atom`, `signal`, `computed`, `effect`, `subscribe`, `observe`, `batch`, `untracked`, `mapped` and `effectScope`.
  - **CharmSync** handles delta-compressed server-to-client sync: the server calls `server.addSignalsToClient` and `server.connect`, and the client calls `client.addSignals` and `client.patch`.
  - Bindings: `react-charm` and `vide-charm` (`useSignalState`).
  - v0.11 introduced breaking changes, so check the migration section.
  - [littensy/charm](https://github.com/littensy/charm)
- The Charm README pitches itself as a more composable alternative to Reflex and Rodux-style containers. Its selectors can be subscribed to directly, with memoization handled automatically. — [Charm README (unpkg)](https://app.unpkg.com/@rbxts/charm@0.6.0/files/README.md)
- **Reflex:** Inspired by Rodux and Silo, built on actions and producers rather than stores and reducers. It ships server-to-client sync, observers and memoized selectors out of the box. — [Reflex docs](https://littensy.github.io/reflex/docs); [GitHub](https://github.com/littensy/reflex)
- **Rodux:** Roblox's Redux-inspired library. — [Roblox/rodux](https://github.com/Roblox/rodux)

### Inferences
- For a Claude skill, sensible defaults are:
  - React-Luau when a team wants React idioms or hiring familiarity, and it is the most "industry-standard" option because Roblox's own app uses it.
  - Vide or Fusion 0.3 for lighter fine-grained reactivity.
  - Plain Instances plus a small controller layer for small games or Studio-built UI, which is still common in simulators whose UI is largely image-based.
- Charm pairs naturally with all three frameworks, so it is a reasonable default state layer for new projects. Reflex suits teams already invested in it, and Rodux should be treated as legacy.
- React-lua is pinned to React 17 semantics: no concurrent-era React 18/19 APIs.

### Gaps
- No source confirms which framework a specific top studio uses (BIG Games, Gamer Robot, Grow a Garden's team, and others). Studios rarely publish this.
- No exact date was found for the Fusion 0.3 "final" (non-beta) release. Whether Fusion 0.4 exists by late 2026 is unconfirmed; none appears on GitHub releases.
- No independent benchmarks comparing React-lua, Fusion and Vide were found.

## 2. Roblox UI engine features, pitfalls and platform specifics

### Takeaway
By 2026 the engine supports a CSS-like workflow: flex layouts (UIListLayout flex plus UIFlexItem), **UI Styling** (StyleSheet, StyleRule, StyleLink and StyleDerive, fully released, with **StyleQuery** added May 2026 and **Styling Transitions** fully released July 2026), and the **Input Action System** (InputContext, InputAction, InputBinding, plus the Input Action Manager editor and InputActionLabel hotkey hints). The main pitfalls are:
- CanvasGroup texture memory.
- AutomaticSize combined with flex.
- TopbarSafeInsets and console inset bugs.
- Leaving room for the Roblox topbar and the mobile touch controls.

### Cited Findings
**Flex layouts**
- Flex-enabled UIListLayouts do extra work to calculate flex basis sizes, flexed sizes and line wrapping. Don't enable flex without a purpose, since it adds cost when layouts resize or items are added or removed. — [List and Flex Layouts docs](https://create.roblox.com/docs/ui/list-flex-layouts)
- Roblox suggests keeping fewer than 1000 items in a flex layout. The release post lists unsupported AutomaticSize and UIFlexItem combinations: non-zero AnchorPoint, scale-sized items, scaled padding, and TextScaled. — [Flex features client release (DevForum)](https://devforum.roblox.com/t/flex-features-for-uilistlayout-client-release/3096190)
- AutomaticSize on a child along the fill direction becomes an "automatic flex basis". AutomaticSize is not supported on nested flex-enabled UIListLayouts. UIFlexItem GrowRatio and ShrinkRatio apply only when FlexMode is Custom. — [UIFlexItem reference](https://create.roblox.com/docs/reference/engine/classes/UIFlexItem); [list-flex-layouts](https://create.roblox.com/docs/ui/list-flex-layouts)

**UI Styling (CSS-like design tokens)**
- UI Styling is fully released. The Styling APIs (StyleRule, StyleSheet, StyleLink, StyleDerive) and the no-code Style Editor can be used in published experiences. StyleRule overrides properties on instances matched by its Selector. — [Full Release: UI Styling (DevForum)](https://devforum.roblox.com/t/full-release-ui-styling-is-officially-released/4275082); [Styling docs](https://create.roblox.com/docs/ui/styling); [StyleRule reference](https://create.roblox.com/docs/reference/engine/classes/StyleRule)
- The original Studio Beta for UI Styling was announced around May 2025. — [Studio Beta: Introducing UI Styling](https://devforum.roblox.com/t/studio-beta-introducing-ui-styling/3660722)
- **StyleQuery** (post dated May 11, 2026) adds input-based conditions and styling of multiple or nested pseudo-instances in one rule. **Styling Transitions** reached full release (update dated July 27, 2026), adding TweenInfo support and transition methods on StyleRule. — [StyleQuery full release](https://devforum.roblox.com/t/full-release-stylequery-more-styling-features/4566519); [Styling Transitions full release](https://devforum.roblox.com/t/full-release-styling-transitions/4646870)

**CanvasGroup**
- CanvasGroup uses extra texture memory, capped by the client's QualityLevel. Over the cap, the group renders as a blank texture. Prefer static sizes, because each resize creates a new texture. — [CanvasGroup reference](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup)
- Further CanvasGroup pitfalls:
  - Tweening a CanvasGroup's size creates a new texture size every frame.
  - Groups drop to lower resolution under memory pressure.
  - Hidden CanvasGroups keep their memory; only destroying them reliably frees it.
  - Nested groups multiply the cost.
  - Some mobile devices have rendered them black or not at all.
  - [CanvasGroup Performance Concerns](https://devforum.roblox.com/t/canvasgroup-performance-concerns/3556937); [Using many CanvasGroups is unworkable…](https://devforum.roblox.com/t/using-many-canvasgroups-is-unworkable-until-proper-memory-management-methods-are-implemented/3502537); [Low quality at graphics ≤3](https://devforum.roblox.com/t/canvasgroup-makes-its-content-low-quality-at-certain-sizes-and-graphics-level-3-or-below/2946471); [Black on mobile](https://devforum.roblox.com/t/canvas-group-filled-with-black-for-mobile-devices/2208465)

**Topbar and safe areas**
- `ScreenInsets.TopbarSafeInsets` is a region guaranteed not to be covered by device cutouts or Roblox core UI (Experience Controls). It arrived with the Experience Controls redesign (beta late 2023, rolled out in 2024).
  - Roblox's guidance is to listen to AbsoluteSize changes on a TopbarSafeInsets ScreenGui.
  - Developers report the inset excludes the padding around Roblox's buttons, and that if core controls fill the reserved space, no room is left for game UI.
  - [ScreenInsets enum](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets); [How to produce a topbar based on TopbarSafeInsets](https://devforum.roblox.com/t/how-to-produce-a-topbar-based-on-topbarsafeinsets/2914413); [Experience Controls beta](https://devforum.roblox.com/t/studio-beta-for-experience-controls-available-now/2567355); [Updated in-experience controls](https://devforum.roblox.com/t/updated-in-experience-controls-on-roblox/3028958?page=3)
- **Console bugs:** TopbarSafeInsets is reported wrong on Xbox and PS4 with the new controls, and content can size itself to only part of the screen on consoles. — [TopbarSafeInsets wrong on Xbox/PS4](https://devforum.roblox.com/t/topbarsafeinsets-is-wrong-on-xbox-and-ps4-with-new-experience-controls/2848042/2); [Incorrect on consoles](https://devforum.roblox.com/t/screenguiscreeninsets-topbarsafeinsets-is-incorrect-on-consoles/4111410)
- Topbar height: one older thread says the topbar inset is still 36 px, but a separate thread ("What are the new topbar inset dimensions?") shows the redesign changed this. Treat 36 px as outdated. — [New topbar inset dimensions thread](https://devforum.roblox.com/t/what-are-the-new-topbar-inset-dimensions/3237388)
- A Roblox Engine UI designer's post says UI is placed below the top bar by default unless the ScreenGui setting is changed, so layouts should account for that space. — [Designing UI - Tips and Best Practices (DevForum)](https://devforum.roblox.com/t/3074034)
- On mobile, the default controls occupy the bottom-left (thumbstick) and bottom-right (jump) corners, so keep important UI out of those zones. A doc sample sizes custom buttons relative to the jump button. — [Position and size UI objects](https://create.roblox.com/docs/ui/cross-platform-design)
- Use `ViewportDisplaySize` to estimate the physical screen class; guessing from pixel counts misleads. — [Cross-platform development](https://create.roblox.com/docs/projects/cross-platform)
- In the core touch-control scripts, a short screen axis of 500 px or less makes the jump button 70 px instead of 120 px (community reading of the core scripts). — [The correct way to design mobile buttons](https://devforum.roblox.com/t/the-correct-way-to-design-mobile-buttons/2494558)
- **Touch target minimum:** Roblox docs give no hard number. The closest guide is Apple's HIG: 44×44 pt. — [Packt Unity UI book citing Apple HIG](https://packtpub.com/en-br/product/mastering-ui-development-with-unity-9781803235394/chapter/chapter-2-designing-mobile-user-interfaces-3/section/recommended-button-sizes-ch03lvl1sec12)

**Input Action System (IAS)**
- IAS adds InputContext, InputAction, InputBinding and the InputActionType enum.
  - Studio Beta: May 2025.
  - Client beta (publishable) from about Aug 2025, with updates Nov 21, 2025 and Feb 11, 2026.
  - A "[Full Release] Input Action System (IAS) + newly converted player scripts" thread exists, with the release in 2026.
  - [Studio Beta IAS](https://devforum.roblox.com/t/studio-beta-new-input-action-system/3656214); [Client Beta](https://devforum.roblox.com/t/client-beta-input-action-system-is-now-available-to-publish-in-experiences/3890979); [Full Release IAS](https://devforum.roblox.com/t/full-release-input-action-system-ias-newly-converted-player-scripts/4678416?page=4); [IAS docs](https://create.roblox.com/docs/input/input-action-system)
- **Input Action Manager** (a no-code editor) reached full release. A third-party blog dates it to Oct 29, 2026 (unverified against Roblox). **InputActionLabel** gives no-code hotkey and button hints (Studio beta). — [Full Release Input Action Manager](https://devforum.roblox.com/t/full-release-input-action-manager/4965021/1); [gamineai blog](https://gamineai.com/blog/what-roblox-input-action-manager-full-release-changed-2026); [InputActionLabel beta](https://devforum.roblox.com/t/studio-beta-no-code-hotkey-hints-with-inputactionlabel/4779420)

**Console**
- Players sit 8 to 10 ft from the screen. The Xbox guide suggests a 1.5x UI scale factor for legibility.
- Use relative (Scale) sizing, keep key UI inside the TV-safe area, and consider custom controller navigation rather than relying only on the built-in directional selection or virtual cursor.
- `UserInputService:GetImageForKeyCode()` returns the default Xbox and PlayStation button glyphs.
- [Console guidelines](https://create.roblox.com/docs/production/publishing/console-guidelines); [Xbox guidelines](https://create.roblox.com/docs/production/publishing/xbox-guidelines)

**9-slice**
- 9-slice keeps the corners unscaled. SliceCenter is pixel distances from the source image edges, and those values differ from the 9-Slice Editor's offsets. The Studio 9-Slice Editor is the recommended tool. — [UI 9-slice design](https://create.roblox.com/docs/ui/9-slice); [How to use SliceCenter](https://devforum.roblox.com/t/how-to-use-slicecenter-robloxs-9-slice-gui-property/18313)

### Inferences
- Modern best practice is design tokens via StyleSheets (colors, corner radii, stroke, fonts, with theme switching through StyleDerive), with flex layouts for responsiveness. Hand-placed Offset positions and per-instance property copies are the older approach. Styling Transitions can replace many hover and press tweens.
- Use CanvasGroup only for short-lived, fixed-size fade or group-transparency effects. Destroy it rather than hiding it, and avoid nesting or size tweens.
- For a skill: put HUD in a ScreenGui with ScreenInsets = CoreUISafeInsets (the default) or DeviceSafeInsets, and put topbar-row buttons in a TopbarSafeInsets ScreenGui. Respond to AbsoluteSize changes and test on console.
- Bind input through IAS (InputContext per UI mode, such as gameplay or menu), so keyboard, gamepad and touch share one action graph. Use InputActionLabel or GetImageForKeyCode for glyphs.

### Gaps (with training-knowledge notes, unverified this session)
- **Not retrieved:** exact new topbar height in px, the full Roblox doc text on SelectionGroup and SelectionImageObject, UIDragDetector docs, Font API and BuilderSans docs, LocalizationService and auto-translation docs, ProximityPrompt custom styles, ViewportFrame icons, image upload limits, VR UI guidance, and the PlayStation-specific requirements.
- **[training knowledge, unverified]** API facts:
  - Gamepad selection uses `GuiService.SelectedObject`, `GuiObject.NextSelectionUp/Down/Left/Right`, `GuiObject.SelectionGroup` with `SelectionBehaviorUp/Down/...`, `GuiService:Select(parent)`, and `SelectionImageObject` to style the focus ring.
  - `UIDragDetector` (GA 2024) replaces deprecated `GuiObject.Draggable`.
  - `Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)` with `TextLabel.FontFace`. BuilderSans is Roblox's brand font and is used in the topbar and core UI.
  - Images uploaded above 1024×1024 are downscaled. Sprite sheets use ImageRectOffset and ImageRectSize. `TextService:GetTextBoundsAsync` or `GetTextSize` measures text, and `TextBounds` and `TextFits` are available at runtime.
  - Roblox VR renders ScreenGuis on a curved panel in front of the player, so SurfaceGuis in world space are preferred for VR.
  - ProximityPrompt `Style = Custom` plus the `ProximityPromptService.PromptShown` event lets you draw your own prompt UI.
  - ViewportFrames are costly when many render at once. Studios pre-render pet and item icons to images or update ViewportFrames only when they become visible.

## 3. Visual design patterns of top Roblox games; what reads as amateur or "AI-made"

### Takeaway
Hit Roblox games (Pet Simulator 99, Pls Donate, Sol's RNG, Grow a Garden) use custom image-based UI (hand-drawn buttons and panels) rather than default Frames. Roblox's own guidance stresses information hierarchy, emphasis through art style, and mobile-first wireframing. Amateur tells include missing padding, overused borders, small hit targets, weak contrast and screen-hogging menus. No source was found that explicitly defines "AI-generated-looking" Roblox UI.

### Cited Findings
- Most UI in games like Pls Donate and Pet Simulator 99 is image-based, meaning custom art rather than default elements. Developers often cite PS99, Pls Donate and Sol's RNG as targets for good-looking UI. — [Unique or good looking UI (DevForum)](https://devforum.roblox.com/t/unique-or-good-looking-ui/2914121); [UI Inventory look? (PS99-inspired)](https://devforum.roblox.com/t/ui-inventory-look/3580465)
- Pet Simulator 99's look is described (by a parent's guide, not a design analysis) as "high-gloss, neon-soaked". — [Screenwise parent's guide](https://screenwiseapp.com/guides/parent-s-guide-to-roblox-pet-simulator-99)
- Grow a Garden-style UI packs are marketed as "playful" and "casual, quirky", with tags such as "simulator ui" and "studs design". This is marketing copy, not an analysis. — [GAG UI pack (itch.io)](https://adrianart.itch.io/gag-ui-pack); [BuiltByBit GAG-style pack](https://builtbybit.com/resources/ui-pack-grow-a-garden-style.102616/)
- **Roblox official UI/UX doc:**
  - Surface the most significant information first (the Hierarchy of Information).
  - Use art style to emphasize the ideal interaction order. A Dragon Adventures example gives the highest-value coin pack visual priority with a larger size and extra padding.
  - Most users are on mobile, so design mobile-first and leave room for the default touch controls.
  - [UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design); [Wireframe your layouts](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/wireframe-your-layouts)
- **Amateur tells from community guides:**
  - Little or no padding (fix with UIPadding).
  - Overused borders.
  - Small click targets.
  - Large menus that create PvP blind spots.
  - Poor contrast; advice is to keep backgrounds darker than content and use neutral background colors.
  - [Become a better UI designer](https://devforum.roblox.com/t/become-a-better-ui-designer/1804608); [5 Tricks to improve your UIs](https://devforum.roblox.com/t/5-tricks-to-improve-your-uis/1416491); [The Guide to UI Designing](https://devforum.roblox.com/t/the-guide-to-ui-designing/606984); [(hopefully) The last UI tutorial you'll ever need](https://devforum.roblox.com/t/hopefully-the-last-ui-tutorial-youll-ever-need/1788203)
- **Design frameworks from community guides:** the "4 C's" (including Coherent: users must know where to go), keeping the user journey from landing screen to goal as short as possible, and tweening for polish. — [UI Designing Tips](https://devforum.roblox.com/t/ui-designing-tips/2423307); [UI design for beginners](https://devforum.roblox.com/t/ui-design-for-beginners/2170858)

### Inferences
- **What "hand-crafted" means on Roblox, synthesized from the sources above:**
  - One consistent custom icon set and a 9-sliced panel and button kit made from art assets.
  - A limited palette with semantic accent colors (currency, rarity tiers, CTA).
  - Thick UIStroke outlines and drop shadows on chunky, toy-like buttons for the simulator genre.
  - Deliberate padding and spacing rhythm.
  - Clear hierarchy, with the biggest and brightest element being the main action.
  - Juice on every interaction: press squash, hover scale and spring overshoot.
- **What reads as generic or "AI-made", inferred by applying the amateur tells above:**
  - Default Roblox Frames with uniform UICorner and gradient on everything.
  - Emoji or mismatched icon sources.
  - Centered, text-heavy panels with no hierarchy.
  - Identical spacing and sizes everywhere.
  - Default fonts (Arial/SourceSans), or many fonts mixed together.
  - Placeholder copy.
  - No motion or feedback.
  - Ignoring the topbar and touch-control zones.
- Per-genre conventions differ. Simulators favor bright, glossy, outlined art. Horror games such as Doors favor minimal, diegetic, desaturated UI. Shooters such as Arsenal and Bedwars favor compact HUDs that keep the center clear. These genre descriptions are **[training knowledge, unverified]**.

### Gaps
- Found no published breakdowns by professional Roblox UI designers (portfolios, X/Twitter threads, RDC talks) with concrete specs. Studio art directors rarely publish them, and the DevForum could not be fetched to search showcases in depth.
- Found no sourced analysis of shop layouts that convert without dark patterns, onboarding UI, reward-fly or number-pop patterns, or notification systems in specific named games (Adopt Me, Blox Fruits, Doors, Dress to Impress, Fisch, Bedwars, Arsenal, Jailbreak, Brookhaven).
- Found no source defining "AI-generated-looking" Roblox UI. The list above is an inference.

## 4. Accessibility and Roblox platform UI guidelines

### Takeaway
Roblox exposes player accessibility settings that UI should respect: `GuiService.PreferredTextSize`, `GuiService.ReducedMotionEnabled` and `GuiService.PreferredTransparency`. The official guidelines cover enlarging small text, adequate contrast, and not relying on color alone. There is no official numeric minimum text size or contrast ratio in what was retrieved.

### Cited Findings
- **Text size:** The guidelines say to enlarge small labels for low-vision players. The player Text Size setting maps to `GuiService.PreferredTextSize` (default Medium, up to Large, Larger and Largest). A UITextSizeConstraint caps text at its min and max regardless of that setting. — [Accessibility guidelines](https://create.roblox.com/docs/production/publishing/accessibility)
- **Color and contrast:** Choose text and background colors with sufficient contrast, and don't convey meaning by color alone. — [Accessibility guidelines](https://create.roblox.com/docs/production/publishing/accessibility)
- **Reduce Motion:** The setting maps to `GuiService.ReducedMotionEnabled`. The docs suggest setting tween time to 0 when it is on, or swapping positional motion for a fade. — [Accessibility guidelines](https://create.roblox.com/docs/production/publishing/accessibility)
- **Background Transparency:** The setting maps to `GuiService.PreferredTransparency`. Tagged UI should interpolate between its default transparency and fully opaque. — [Accessibility guidelines](https://create.roblox.com/docs/production/publishing/accessibility); [Introducing Accessibility Settings](https://devforum.roblox.com/t/introducing-accessibility-settings/2723187/47)
- Community feedback says the guidelines page once failed to cover these client settings. That may predate the current page. — [Feedback on "Accessibility guidelines"](https://devforum.roblox.com/t/feedback-on-accessibility-guidelines/3819039)
- The adaptive design guidelines call for responsive layouts and dynamic sizing so elements stay at the right size on every screen. — [Adaptive design guidelines](https://create.roblox.com/docs/production/publishing/adaptive-design)

### Inferences
- A skill should do the following by default:
  - Multiply panel or background transparency by `PreferredTransparency`.
  - Skip or replace motion when `ReducedMotionEnabled` is on.
  - Avoid TextScaled-only text. Use fixed TextSize with UITextSizeConstraint at sensible bounds so PreferredTextSize still works.
  - Pair rarity and state colors with icons or labels for colorblind players.
  - Target WCAG 4.5:1 for body text. This is a borrowed web standard, not a Roblox rule.

### Gaps
- No official Roblox numeric minimum text size or contrast ratio was found.
- Colorblind-mode guidance specific to Roblox was not found.
- Localization practices (LocalizationService, automatic translation, text expansion headroom) were not retrieved this session.

## 5. Spring-based animation libraries and motion practice

### Takeaway
The common spring libraries are Fraktality's **spr** (imperative, single module, damping plus frequency), littensy's **Ripple** (react-spring-inspired, switches between spring and tween, with roblox-ts and Wally builds), and **roact-spring** (React/Roact hooks). Fusion has built-in `Spring` and `Tween` state objects. Styling Transitions (2026) now covers simple property tweens natively.

### Cited Findings
- **spr:** "a high-performance and user-friendly motion library for Roblox based on springs". You animate by giving a target plus damping ratio and frequency. It is a single module under the MIT license. — [Fraktality/spr](https://www.github.com/Fraktality/spr); [spr DevForum](https://devforum.roblox.com/t/spring-driven-motion-spr/714728)
- **Ripple:** Inspired by react-spring, with an imperative general-purpose API. `createMotion` switches between spring and tween. Available as npm `@rbxts/ripple` and on Wally. — [littensy/ripple](https://github.com/littensy/ripple); [README](https://unpkg.com/@rbxts/ripple@0.10.2/README.md)
- **roact-spring:** A react-spring-style library for Roact and React-lua (`@rbxts/roact-spring`). — [roact-spring DevForum](https://devforum.roblox.com/t/bring-ui-animations-to-life-with-roact-spring-a-modern-spring-based-animation-library/1670138)
- **Flipper:** An older spring library, available as `@rbxts/flipper`. — [npm flipper](https://www.npmjs.com/package/@rbxts/flipper)
- Styling Transitions add TweenInfo-driven transitions on StyleRule. — [Styling Transitions full release](https://devforum.roblox.com/t/full-release-styling-transitions/4646870)
- Gate motion on `ReducedMotionEnabled`. — [Accessibility guidelines](https://create.roblox.com/docs/production/publishing/accessibility)

### Inferences
- Use springs for interactive responses that can be interrupted (hover and press scale, panel open and close, number counters), because they retarget smoothly mid-animation. Use tweens for fixed-duration choreography.
- Typical button juice is a press scale to about 0.9–0.95 and a release overshoot to about 1.05 with an underdamped spring (damping about 0.5–0.7). These are practitioner heuristics, not sourced figures.
- Animate a UIScale child rather than Size, so layouts don't reflow and CanvasGroups don't re-texture.

### Gaps
- No sourced motion-timing standards from Roblox or top studios (for example, standard durations) were found.
- No sources were found on reward-fly-to-counter or number-pop implementations in named games.
- Fusion 0.3's built-in Spring API details were not re-fetched this session.
