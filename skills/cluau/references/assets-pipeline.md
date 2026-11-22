# 3D Models & Asset Pipeline — Quality Models That Run on Phones

Verified against Roblox Creator Hub docs (creator-docs, 2026-11). Use this whenever the user asks about models, meshes, Blender, textures, materials, rigs, animations, free models, the Creator Store, or AI-generated assets.

## Contents
1. The quality bar (what "good model" means on Roblox)
2. Mesh & rig specifications
3. Blender → Studio settings
4. 3D Importer options
5. Textures, UVs, PBR (SurfaceAppearance / MaterialVariant)
6. Performance: instancing, LOD (SLIM), collision, budgets
7. Rigging & animation
8. Lighting & environment
9. AI-generated assets (Cube / Assistant / Studio MCP)
10. Creator Store & free-model vetting
11. Asset privacy, permissions, audio rules
12. Asset-compliance gate for agents using Studio MCP

---

## 1. Quality bar

A good Roblox asset is **readable at gameplay distance, consistent with the game's art direction, cheap to render, and legally yours**:
- One art style per game (palette, texel density, bevel size, wear level). Mixed free models are the 3D equivalent of AI-slop UI.
- **Consistent texel density** (see §5 table) so nothing looks blurry next to something crisp.
- Silhouette first: chunky shapes and clear value contrast read better on phones than micro-detail.
- Modular kits (walls, floors, trims) built once and reused → instancing and fast iteration.
- Hero assets (characters, key props) get hand-made topology and textures; background props can be simpler or AI-assisted.

## 2. Mesh & rig specifications

- **≤ 20,000 triangles per mesh** (Creator Store models too; CSG results above 20k are simplified or error). Avatar rigid/layered/eye accessories ≤ 4k each.
- Watertight, quads where possible, no N-gons, no zero-thickness geometry.
- **One UV set**, UVs in 0–1 space (overlaps allowed), **one material per mesh**.
- Rigs: ≤ **4 bone influences per vertex**; bones frozen at scale 1 / rotation 0; root bone at origin with no influences; **one animation per FBX**.
- Importer naming: `_Att` → Attachment, `_OuterCage` → WrapTarget, `_InnerCage`+`_OuterCage` → WrapLayer, FACS heads → FaceControls.

## 3. Blender → Studio

- Scene Properties → Units → **Unit System = None** (1 unit ≈ 1 stud). Blender is Z-up, Studio is Y-up.
- **FBX:** Apply Scalings = **FBX Unit Scale**, Forward = **Z Forward**, Up = **Y Up**, Path Mode = **Copy** + **Embed Textures**, Armature: **Add Leaf Bones off**, **Bake Animation off** unless exporting keyframes/FACS.
- **glTF** needs no scale fixes — often the simplest path.
- Apply transforms and set origins deliberately (the importer can use the scene origin as the pivot).
- Many older tutorials use 0.01 scene scale; it can break camera/modifiers — prefer the settings above.

## 4. 3D Importer (Studio)

Formats: `.fbx`, `.gltf`, `.obj` (fbx/gltf carry hierarchy, PBR, cages, rigs, animation, vertex colors).
- **Upload to Roblox: off while iterating** (avoid inventory clutter), on for the final import.
- **Set Pivot to Scene Origin: on** (default) — keep consistent pivots across a kit.
- **Make Double Sided: off** (more expensive) unless needed for foliage cards.
- **Merge Meshes: off** for kits (keeps instancing); on only for one-off static clusters.
- Anchored is off by default — anchor static props after import.
- Save import presets per asset type.
- Studio glTF export is beta and has no animation data.

## 5. Textures, UVs, PBR

| Object size | Texture size |
|---|---|
| ~5×5 studs | 256² |
| ~10×10 studs | 512² |
| ~20×20 studs | 1024² |
| Hero asset | up to 2048–4096² (docs conflict: one page says 4096 max, others 1024 — default to ≤ 1024 for props) |

- Normal maps: **OpenGL tangent space** only. Roughness/metalness/emissive: single-channel grayscale.
- **SurfaceAppearance** (per mesh): Color, Normal, Roughness, Metalness, **Emissive** (mask + strength + tint). `AlphaMode`: Overlay (default, reveals `MeshPart.Color`), Opaque, Transparency, TintMask (great for player-recolorable items).
- **MaterialVariant** in MaterialService: tileable materials for parts/terrain, carries physical properties. If both exist, SurfaceAppearance maps win but MaterialVariant physics still apply.
- **Trim sheets** (square, tile on one axis) + shared SurfaceAppearance packages = one texture set for a whole kit.
- Built-in materials cost far less memory than custom textures — spend texture budget on hero assets.
- No text baked into textures (use `SurfaceGui`/`TextLabel` — localizable and moderation-friendly).

## 6. Performance

- **Instancing:** identical MeshContent + identical SurfaceAppearance (or texture/material) = one draw call. **Import each kit piece once and duplicate in Studio** (importing a whole scene gives duplicates different IDs and breaks instancing). Manage kits as **Packages**.
- **Budgets:** an average view ~100 draw calls / ~150k triangles is comfortable; stay below **1,000 draw calls and 1M triangles** on a baseline device (Shift+F2 render stats). Each ParticleEmitter is its own draw call; transparency overdraw (foliage, glass) and many shadow casters are expensive.
- **RenderFidelity = Automatic** (Highest < 250 studs, Medium 250–500, Lowest 500+). Many `Precise` meshes = slow frames.
- **LOD:** `Model.LevelOfDetail = SLIM` (beta; replaces StreamingMesh) for **static** models ≤ ~64 studs extent with streaming on — composite meshes cut draw calls, triangles and memory.
- **CollisionFidelity:** Box for small/non-interactive, Hull for simple convex, Default for concave, `PreciseConvexDecomposition` only when truly needed (most expensive), Tunable for a precision slider. Custom Box primitives for huge complex meshes. Decoration: `CanCollide/CanTouch/CanQuery = false`.
- Shadows auto-disable below graphics quality 4; set `CastShadow = false` on small props and edge foliage.
- Profile with **Scene Analysis** (Window → Performance Summary) and on a **real low-end Android** device (≈65% of players are on Android; ~60% of those have 2–4 GB RAM).

## 7. Rigging & animation

- R15 has 15 poseable joints; **Advanced R15** adds up to 37 optional joints (hands, shoulders, spine).
- `StarterPlayer.AvatarJointUpgrade` replaces Motor6D with **AnimationConstraints** (kinematic or force-based) for physics-driven motion. The **Character Controller Library** (`require("@rbx/AvatarAbilities")`) is the recommended controller for new games.
- Play animations via `Animator:LoadAnimation` (never `Humanoid:LoadAnimation`). Priorities: Idle < Movement < Action < Action2–4 < Core.
- Animation events: editor markers + `AnimationTrack:GetMarkerReachedSignal()`.
- **IKControl** (Type, EndEffector, Target, ChainRoot) for look-at, foot planting, hand-on-weapon.
- **Animation Graph Editor** for blend trees; Animation Editor for clips; FACS for faces.
- Animations for a **group-owned game must be published by the group**, or they won't play for others.

## 8. Lighting & environment

- `Lighting.Technology` is superseded by **`Lighting.LightingStyle`** (Realistic / Soft) + **`PrioritizeLightingQuality`**. Retro look: Soft style + `ColorGradingEffect` Retro tonemapper.
- Mood presets (starting points): *cozy* = warm ClockTime 16–17, soft Atmosphere haze, low contrast; *horror* = low ambient, dense Atmosphere, cold ColorCorrection, few shadow-casting lights; *sci-fi* = cool ambient, Bloom on emissives only, crisp shadows.
- Post-processing with purpose: Blur behind menus, ColorCorrection red at low health, DepthOfField for shop focus, SunRays tied to time of day. Keep effects few on mobile.
- Terrain: 4×4×4 voxels; heightmap/colormap import; custom terrain materials via MaterialVariants.

## 9. AI-generated assets

- `GenerationService` (Cube 3D): `GenerateModelAsync` (schemas such as `Car5`, `Body1`), `GenerateMeshAsync` server-only, rate-limited, slated for future deprecation.
- Assistant / Studio MCP: `generate_mesh` (default ~10k tri cap, up to 8 parts), `generate_material`, `generate_procedural_model`, `generate_avatar`, `generate_animation` (≤ 10 s).
- Treat generated meshes as **blockout/background** quality: rescale, anchor, set collision, unify materials to the art direction, review for moderation. Hand-made or retopologized assets for hero items.

## 10. Creator Store & free-model vetting

Before using any inserted model:
1. Insert with **right-click → Disable Scripts** when exploring.
2. Check the asset page: triangle/vertex counts, **script count**, creator, reviews.
3. Search descendants for `Script`/`LocalScript`/`ModuleScript`; grep for numeric `require(`, `loadstring`, `getfenv`/`setfenv`, `InsertService:LoadAsset`, `AssetService:LoadAssetAsync`, `LinkedSource`, `HttpService`, `MarketplaceService` prompts, `TeleportService`, long encoded strings, very large scripts. Delete anything you don't understand.
4. Re-material/re-color to the game's art direction; fix pivots, anchoring and collision.

## 11. Privacy, permissions, audio

- Asset privacy: **Restricted** vs **Open Use** — Open Use is **irreversible**, game grants are permanent.
- Audio: single track, mp3/ogg/wav/flac, **< 20 MB, < 7 min, ≤ 48 kHz**; 2,000 uploads / 30 days if ID-verified, 100 if not. Creator Store has 100k+ licensed SFX/music.
- Use only assets the user owns or has rights to; never "in the style of <franchise>" or brand logos.

## 12. Asset-compliance gate (when an agent drives Studio via MCP)

Adapted from excaldev/ro-engineer (MIT):
- **Preview by default:** stage generated/inserted assets in `ServerStorage/_AssetStaging`; show captures; wait for the user's Approve / Revise / Discard. Failed attempts go to `ServerStorage/_AssetQuarantine`.
- **Hard stops — always ask the user first:** any image upload; inserting a store asset that contains scripts or `require(id)`/`loadstring`/`LinkedSource`; content with unknown rights; saving/publishing the cloud place; deleting user content.
- Report results as PASS / REVISE / DO NOT UPLOAD / NEEDS POLICY CHECK. **Never claim an asset will pass moderation.**
- Prompt hygiene for generation: describe wear as "rust, mud, chipped paint" (not blood/gore), no brands or franchise styles, no text in textures.
