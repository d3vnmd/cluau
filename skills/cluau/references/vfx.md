# VFX — Particles, Beams, Trails That Read Well and Run on Phones

> Last verified: 2026-11-23 against Roblox/creator-docs (ParticleEmitter, Beam, Trail, Highlight).

## Contents
1. Principles
2. ParticleEmitter essentials
3. Flipbooks
4. Beams, trails, highlights, light
5. Replication: who emits?
6. Performance budget
7. Recipes

---

## 1. Principles

- VFX communicate: a hit, a pickup, danger, rarity. If an effect doesn't explain something, cut it.
- Match the art direction (stylized games: chunky shapes and solid colors; realistic: soft alpha, subtle light).
- Anticipation → impact → dissipation: a short build-up, a strong 1–3 frame peak, a fading tail.
- Always gate camera shake and flashing on the player's Reduced Motion setting (`GuiService.ReducedMotionEnabled`).

## 2. ParticleEmitter essentials

| Property | Use |
|---|---|
| `Rate` / `:Emit(count)` | continuous vs burst. For impacts: `Enabled = false` and call `Emit(n)` |
| `Lifetime` (NumberRange) | keep short (0.2–1.5 s) for gameplay feedback |
| `Speed`, `SpreadAngle`, `Acceleration`, `Drag` | motion and gravity feel |
| `Size`, `Transparency` (NumberSequence) | grow/shrink and fade over life — fade out instead of popping |
| `Color` (ColorSequence) | use the game's palette tokens |
| `LightEmission` (0–1) | additive glow for magic/fire; 0 for smoke/dust |
| `LightInfluence` | 0 = unaffected by scene lighting (UI-like pop), 1 = lit like the world |
| `Brightness` | HDR-style intensity for glowy effects |
| `Squash`, `Rotation`/`RotSpeed`, `Orientation` | motion stretch and facing |
| `ZOffset` | draw order relative to other effects |
| `Shape`, `ShapeStyle`, `ShapeInOut`, `ShapePartial` | emit from volume/surface of box/sphere/cylinder/disc |
| `TimeScale` | slow-motion / hit-stop on effects |
| `LockedToPart`, `VelocityInheritance` | effects that follow a moving source |

## 3. Flipbooks

Animated textures over a particle's life: `FlipbookLayout` (grid size), `FlipbookMode` (Loop/OneShot/PingPong/Random), `FlipbookFramerate`, `FlipbookStartRandom`. One flipbook sheet replaces several emitters — cheaper and more readable (explosions, smoke puffs, sparks).

## 4. Beams, trails, highlights, light

- `Beam` between two Attachments: lasers, tethers, auras; `TextureSpeed` for flow, `Segments` + `CurveSize0`/`CurveSize1` for arcs.
- `Trail` on a moving Attachment pair: weapon swings, dashes, cosmetics (great monetizable cosmetic).
- `Highlight`: outline/fill for interactables and targets. **Toggle `Enabled`** instead of creating/destroying (rebuild spikes); keep the count small.
- `PointLight`/`SpotLight` flashes for impacts — very short, few at a time, `Shadows = false` on mobile-heavy scenes.

## 5. Replication: who emits?

- Cosmetic effects run on **clients**. The server sends one event ("HitAt", position, kind) or sets an attribute; each client spawns the effect locally. This saves bandwidth and server CPU and lets clients skip distant effects.
- The client that caused the action can play its effect immediately (prediction) and ignore the server echo for itself.
- Never let clients decide gameplay through effects (a client-fired "explosion" remote must not deal damage).

## 6. Performance budget

- Every ParticleEmitter is its own draw call; many overlapping transparent particles = overdraw (worst on phones).
- Pool emitters for frequent effects (one emitter per effect type, `Emit(n)` at a moved attachment) instead of cloning parts.
- Cull by distance on the client (skip effects > ~150 studs away, reduce `Emit` counts at medium range).
- Keep textures small (64–256 px) and shared across effects.
- Destroy transient emitters after `Lifetime.Max` (or reuse them).

## 7. Recipes (starting values)

| Effect | Recipe |
|---|---|
| Coin pickup | burst `Emit(8)`, Lifetime 0.3–0.5, Speed 6–10, Size 0.4→0, LightEmission 0.6, gold palette + UI number pop |
| Melee hit | burst `Emit(12)` sparks (Squash 1, Lifetime 0.15–0.3) + 2-frame flash light + hit-stop 0.05 s |
| Level up | ring burst (Shape Disc, outward), Beam column 1 s, music sting, UI banner |
| Danger zone | slow `Rate` 4–8 smoke, LightInfluence 1, red-tinted, ground decal pulse |
| Rarity aura (Legendary) | low-rate sparkles (Rate 3–6) with rarity color; never on every common item |
