# Polish, QA & Launch — From "Works" to Front-Page Quality

Engine/platform facts verified against Roblox docs (2026-11). Game-feel numbers are cross-engine heuristics (no Roblox-specific standard exists) — present them as starting points.

## Contents
1. What separates front-page games
2. Game feel ("juice") recipes
3. Audio
4. Camera
5. Accessibility settings (required hooks)
6. QA: test matrix & device lab
7. Experiments & analytics-driven iteration
8. FTUE (first 5 minutes)
9. Launch checklist
10. Live-ops cadence

---

## 1. What separates front-page games

Roblox recommendations reward (measured on organically recommended users, D1 / D2–7 / D8–28 windows):
- low **first-play bounce** — the first 60 seconds must be fun, fast and clear;
- **playtime per user** (counted up to 60 min per user per day);
- qualified play sessions, spend days, Robux per user;
- original metadata; a **custom thumbnail is required** for home recommendations; near-duplicate games are deprioritized.

Practical meaning: instant load into play, a reward within 30 s, a clear next goal on screen, satisfying feedback on every action, and a reason to come back tomorrow.

## 2. Game-feel recipes (gate all on reduced motion)

| Effect | Recipe | Use for |
|---|---|---|
| Button press | `UIScale` 1 → 0.96 → 1, 0.08–0.12 s Quad Out | every button |
| Value pop | number scales 1.15 → 1 over 0.2 s + count-up 0.4 s | currency/XP changes |
| Reward fly | icon flies from world/screen source to the currency pill, 0.4–0.6 s, then pill pulses | pickups, purchases |
| Screen shake | trauma-based, decays in 0.1–0.3 s, small amplitude | big hits/explosions only |
| Hit-stop | 2–4 frames slowed animation on heavy impacts | melee, bosses |
| FOV kick | +3–6° for 0.15 s | dash, sprint start |
| Impact VFX | short particle burst + sound + slight light flash | hits, breaks |
| Anticipation | 0.05–0.1 s wind-up before strong actions | attacks, jumps pads |

Rules: add juice **after** the core loop works; one big effect at a time; reserve strong effects for important events; all cosmetic effects on the **client** (server sends one event).

## 3. Audio

- Prefer the **Audio API**: `AudioPlayer` → `Wire` → `AudioEmitter` (3D speaker) / `AudioDeviceOutput`, heard by `AudioListener`; effects `AudioEqualizer`, `AudioCompressor` (caps loudness), `AudioReverb`. `Sound` still works and isn't deprecated; `SoundGroup` is legacy/discouraged.
- Use `Sound.PlaybackSpeed` and `RollOffMinDistance/RollOffMaxDistance` (not deprecated `Pitch`/`MinDistance`/`MaxDistance`).
- Mix: music bus quieter than SFX; one compressor on the master; separate Music/SFX volume settings saved in player data.
- Every action has a sound: UI clicks, purchase success/fail, pickups (pitch-vary 0.95–1.05 to avoid fatigue), footsteps per material.
- Horror: audio carries tension — spatial cues, silence, low drones; jumpscares local to the client.

## 4. Camera

- Don't fight the default camera unless the genre needs it (top-down TD, side-scroller obby, shooters' over-the-shoulder).
- Custom cameras on `RenderStepped`/`BindToRenderStep` (camera is the one legit RenderStepped use), smoothed with springs/lerp, collision-aware via `workspace:Raycast`.
- Shake and FOV kicks respect the reduced-motion setting.

## 5. Accessibility (wire these in every UI)

- `GuiService.PreferredTransparency` — multiply panel `BackgroundTransparency` by it.
- `GuiService.ReducedMotionEnabled` — disable/replace shake, bounces, parallax, flashing.
- `GuiService.PreferredTextSize` — respect it (pure `TextScaled` text defeats it).
- Never rely on color alone; captions/visual cues for important sounds; in-game volume controls; avoid flashing > 3×/s.
- Consoles: 10-foot UI ~1.5× scale, TV-safe area, full gamepad navigation, glyphs via `UserInputService:GetImageForKeyCode` or `InputActionLabel`.

## 6. QA

**Studio:** Test → **Server & Clients** (up to 8 clients; 2–3 usually enough), network lag simulation, device emulator for layout only (memory is inaccurate there).

**Real devices (mandatory before launch):** at least one low-end Android phone (Roblox suggests e.g. Infinix Smart 9, Moto G05, Oppo A18), a tablet, a PC, a gamepad, ideally a console. Measure FPS, memory and load time.

**Per-feature test list:** happy path · 2+ players · die/respawn mid-action · leave mid-action and rejoin · spam the remote with bad args · late join · streaming out/in · low-end phone · gamepad-only.

**Soak test:** 50 join/leave cycles and 30 minutes of play while watching Developer Console → Memory (LuaHeap, Instances). Rising lines = leak.

**Evidence honesty:** say what was actually tested (see `toolchain-workflow.md` evidence levels). Never claim a playtest you didn't run.

## 7. Experiments & analytics

- **Experiments** (Creator Dashboard): in-game experiments on Configs values, 14–60 days, up to 2 variants + control; matchmaking experiments one at a time. Metrics: ARPU, session time, new-user retention, or up to 3 custom metrics.
- **AnalyticsService**: `LogEconomyEvent`, `LogFunnelStepEvent`/`LogOnboardingFunnelStepEvent`, `LogProgressionEvent`, `LogCustomEvent`. Limits: 120 + 20×CCU calls/min; 10 economy resource types, 10 funnels, 100 custom event names, 3 custom fields. Log only after the action succeeded; wrap in a small service that enforces caps.
- Targets (GameAnalytics 2025 medians): D1 10.3%, D7 1.6%, D30 0.5%; top 1% D1 22.2%.

## 8. FTUE

- Spawn facing the first goal; one instruction at a time; teach by doing (beams/arrows/highlight).
- First reward ≤ 30 s, first unlock ≤ 3 min, first "wow" ≤ 10 min.
- Hide shop/codes/settings clutter until relevant; save tutorial progress; skip for returning players.
- Funnel-log every step; A/B test tutorial steps and starting currency via Configs.

## 9. Launch checklist

- [ ] **Icon** square ≥ 512×512, readable at 150×150, no text-heavy designs.
- [ ] **Thumbnails** 16:9 1920×1080 (< 3 MB), 2+ for **thumbnail personalization** (avg +8.5% play-through), authentic gameplay; optional videos (3 uploads/month).
- [ ] **Title & description** original, accurate, no giveaway/Robux-reward bait.
- [ ] **Content Ratings Questionnaire** completed (unrated games have restricted playability). Minimal/Mild → eligible for Roblox Kids (5–8) and Select (9–15); Moderate → Select (9+) and standard (16+). Under-16 reach also needs a verified creator with 2FA and passing the evaluation.
- [ ] Core gameplay **does not depend on chat** (chat requires age checks).
- [ ] Localization: auto-translation on; leave 30–40% room for longer strings.
- [ ] Monetization compliant (odds disclosure, PolicyService paths, ProcessReceipt idempotent) — see `monetization-policy.md`.
- [ ] Real-device performance pass; soak test passed; DataStore join/leave/shutdown tested.
- [ ] Server shutdown/update plan (BindToClose saves; soft shutdown messaging).

## 10. Live-ops cadence

- Fixed weekly update slot announced in-game; an hour-long live event before updates (server-wide weather/spawns/shop changes) drives concurrent spikes.
- Deterministic global restocks/timers from `os.time()`; ConfigService for live values; MessagingService broadcast + MemoryStore flag so servers that start mid-event join it.
- Ship small content often; measure each update's D1/D7 impact.
