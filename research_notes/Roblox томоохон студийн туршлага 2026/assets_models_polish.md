# Roblox 3D Asset Pipeline & Game Quality/Polish Practices (as of Nov 2026)

Source note: Nearly all facts below were read from the official Roblox creator-docs GitHub mirror (https://github.com/Roblox/creator-docs, `content/en-us/`, shallow clone of commit dated **2026-11-21**). Each file maps to a create.roblox.com URL (`content/en-us/X.md` → `https://create.roblox.com/docs/X`). about.roblox.com, create.roblox.com and devforum.roblox.com could not be fetched directly in this session (DNS blocked); DevForum and newsroom material came only through web-search snippets and is flagged as such.

## 1. Asset pipeline: Blender → Studio export/import, mesh/texture limits, PBR, LOD, collision, draw calls, reuse, Creator Store vetting, permissions, audio rules

### Takeaway
The 2026 hard limits are still **20,000 triangles per mesh**. Texture uploads are documented as **up to 4096×4096**, but several other doc pages still say 1024 is the maximum, so that point conflicts. Blender FBX export should use **Apply Scalings = FBX Unit Scale**, Y-up, no leaf bones, and embedded textures; glTF needs no scale fix. Performance depends mainly on draw calls: reuse the same MeshId plus the same SurfaceAppearance/texture so the engine can instance, keep below about 1,000 draw calls and 1M triangles on a baseline device, and use SLIM LOD, Box/Hull collision and few Precise meshes.

### Cited Findings

**Geometry and rig specs**
- Individual meshes **cannot exceed 20,000 triangles**. Geometry must be watertight (no exposed holes or backfaces), quads where possible (no N-gons), and must have volume (not 0 thickness) — [General specifications](https://create.roblox.com/docs/art/modeling/specifications)
- The 20,000-triangle cap is repeated for Creator Store models ("Each mesh dependency contains no more than 20,000 triangles") — [Models](https://create.roblox.com/docs/parts/models). Solid-modeling (CSG) results over 20,000 triangles are simplified to 20,000, or the operation errors — [Solid modeling](https://create.roblox.com/docs/parts/solid-modeling)
- Avatar item budgets: rigid accessories and layered accessories are 4k triangles each; eye accessories 4k; Avatar Auto Setup bodies 10,742 triangles in total — [Rigid accessory specs](https://create.roblox.com/docs/avatar/rigid-accessories/specifications), [Layered specs](https://create.roblox.com/docs/avatar/layered-accessories/specifications), [Auto-setup requirements](https://create.roblox.com/docs/avatar-setup/auto-setup-requirements)
- DevForum (snippets only): a staff member said the limit is a hard rendering limitation tied to the vertex limit ("20K triangles, actually 21K I think"). One recap says 21k via the 3D Importer vs 10k via the Asset Manager. A recent feature-request thread asks for 60k–200k, and no increase has been announced — [DevForum glTF importer thread](https://devforum.roblox.com/t/3d-importer-support-for-gltf-files-beta/2320761/15), [Increase the max triangle limit](https://devforum.roblox.com/t/increase-the-max-triangle-limit/4650221), [Why no >20k import](https://devforum.roblox.com/t/any-explanation-why-roblox-wont-allow-us-to-import-more-than-20k-triangle-meshes/2957940)
- Rigging rules:
  - Bones are frozen at scale 1,1,1 and rotation 0,0,0.
  - The root bone sits at 0,0,0 and gets no influences.
  - At most **4 bone influences per vertex**.
  - Keep symmetry where possible.
  - Only **one animation track per FBX export**.
  - Cage meshes are named `<Mesh>_InnerCage` / `<Mesh>_OuterCage`; don't delete their vertices or alter their UVs.
  - Source: [General specifications](https://create.roblox.com/docs/art/modeling/specifications)
- Importer naming conventions auto-convert objects: `_Att` → Attachment, `_OuterCage` → WrapTarget, `_InnerCage`+`_OuterCage` → WrapLayer, and FACS heads → FaceControls. The Asset Manager bulk import does NOT support rigged/skinned/animated meshes — [Meshes](https://create.roblox.com/docs/parts/meshes)

**Blender ↔ Studio settings**
- Blender scene setup: Scene Properties > Units > **Unit System = None** (so 1 Blender unit is treated like 1 stud). Blender is Z-up and Studio is Y-up — [Blender guide](https://create.roblox.com/docs/art/blender)
- Blender export (.obj/.fbx/.glTF): FBX **Apply Scalings = FBX Unit Scale**, **Forward = Z Forward, Up = Y Up**. Alternatives are Transform Scale 0.01 or Scene Unit Scale 0.01, but the 0.01 scene scale can break the camera and modifiers. **glTF does not need these scale fixes**. The docs warn that many older tutorials and reference files use inconsistent scale settings — [Blender guide: Adjust scale (FBX)](https://create.roblox.com/docs/art/blender)
- Official FBX checklist (Blender): Path Mode = **Copy** + **Embed Textures**; Apply Scalings = FBX Unit Scale; Armature: **disable Add Leaf Bones**; **disable Bake Animation** unless exporting keyframes or FACS. For Maya, set Units = Automatic and Up Axis = Y — [Export settings](https://create.roblox.com/docs/art/modeling/export-requirements)
- Importing in Studio from Blender: World Forward = Front, World Up = Top, Scale Unit = Stud. Importing Studio content into Blender: Scale 1, Forward Z, Up Y — [Blender guide](https://create.roblox.com/docs/art/blender)

**3D Importer options**
- Supported formats: **.fbx, .gltf, .obj** for meshes (fbx and gltf carry hierarchies, PBR, cages, rigs, animation and vertex colors); images in png/jpg/gif/tga/bmp; audio in ogg/mp3/flac/wav; video in mp4/mov — [Importer](https://create.roblox.com/docs/studio/importer)
- Importer settings and their defaults:
  - Import Only As Model (on)
  - Upload to Roblox (on); turn it off while iterating to avoid inventory clutter
  - Import as Package (off)
  - Add to Workspace (on); this also grants the game permission to use the restricted asset
  - Insert Using Scene Position (off)
  - Keep Zero Influence Bones (off)
  - **Set Pivot to Scene Origin (on)**
  - Anchored (off)
  - Uses Cage
  - Rig Type R15/Custom/No Rig, with Rig Scale Default/Rthro/Rthro Narrow
  - World Forward/Up
  - Scale Unit (Studs)
  - **Merge Meshes** (off), Invert Negative Faces
  - Per object: Use Imported Pivot (on), **Make Double Sided (off; more expensive)**, Ignore Vertex Colors
  - Presets can be saved and set as the default
  - Source: [Importer](https://create.roblox.com/docs/studio/importer)
- glTF **export** from Studio is in beta. It supports meshes, textures, rigging and skinning, vertex colors, cages and FACS, but **no animation data**. Export is blocked for Marketplace assets, acquired Creator Store assets and unshared Open Use assets — [3D Export](https://create.roblox.com/docs/art/modeling/gltf-export)

**Textures and UVs**
- Texture upload formats: png/jpg/tga/bmp. "Roblox supports up to **4096×4096** (4K)". The engine streams lower mips first and may downsample when many textures render at once.
- Size guidance: about 256² for 5×5-stud objects, 512² for 10×10, 1024² for 20×20.
- PBR budget: 256² per 2×2×2-stud volume; "1024×1024 (maximum)" for an 8×8×8 object.
- Non-albedo maps are capped at 256² on rigid accessories.
- Default materials: 1024² per 8×8-stud part face; terrain 512² over 8×8 studs.
- Source: [Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)
- **Conflict:** the same page's UV section says "Maximum Texture Resolution — Roblox supports up to 1024×1024", and the Environmental Art curriculum says tileable textures and trim sheets "can be as large as 1024x1024" — [Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications), [Develop polished assets](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/develop-polished-assets). By contrast, Studio's Texture Generator "Quality" mode outputs **4K PBR** textures (Fast mode gives 1K diffuse) — [Texture Generator](https://create.roblox.com/docs/studio/texture-generator)
- UV rules: **a single UV set** (no multiple UV sets), all UVs in 0–1 space, overlapping UVs allowed, and **one material per mesh** — [Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)
- PBR map formats:
  - Albedo: RGB 24-bit
  - Normal: RGB 24-bit, **OpenGL tangent-space only**
  - Roughness, Metalness, Emissive mask: single-channel 8-bit grayscale
  - Source: [Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)

**SurfaceAppearance, MaterialVariant, trim sheets**
- SurfaceAppearance now supports **5 maps**: color, normal, roughness, metalness and **emissive** (EmissiveMaskContent + EmissiveStrength + EmissiveTint). AlphaMode options:
  - **Overlay (default)**: transparent areas reveal MeshPart.Color
  - **Opaque**: ignores alpha
  - **Transparency**: see-through
  - **TintMask**: tinted blend
  - Source: [Surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance)
- PBR comes from either a SurfaceAppearance child, or a MaterialVariant in MaterialService set via MeshPart.MaterialVariant (the latter also carries physical properties). If both are present, the SurfaceAppearance maps win, but the MaterialVariant's physics still apply. Setting TextureID cannot override PBR — [Meshes](https://create.roblox.com/docs/parts/meshes)
- Material overrides replace a base material place-wide (terrain included). Use "Expanded Terrain" plus custom terrain materials to paint multiple variants. TerrainDetail customizes the top, side and bottom faces. Studs Per Tile and Pattern (incl. Organic) reduce visible tiling — [Materials](https://create.roblox.com/docs/parts/materials)
- Trim sheets tile on one axis and must be square. Tileable textures must be seamless and avoid standout features. The curriculum's workflow is MaterialVariants for tileables plus SurfaceAppearance *packages* for trim-sheet assets — [Develop polished assets](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/develop-polished-assets), [Assemble an asset library](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/assemble-an-asset-library)
- Built-in materials use "far less memory than custom textures"; save texture budget for hero assets — [Design for performance](https://create.roblox.com/docs/performance-optimization/design)

**LOD, collision, draw calls, instancing**
- RenderFidelity Automatic: Highest under 250 studs, Medium at 250–500, Lowest at 500+. Setting **Precise** on many meshes is called out as a common cause of slow frames; use Automatic or Performance — [Meshes](https://create.roblox.com/docs/parts/meshes), [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Model LOD: **`Model.LevelOfDetail = SLIM`** (Scalable Lightweight Interactive Models), with instance streaming enabled, replaces legacy **StreamingMesh**; a batch-convert script is provided.
  - SLIM uses cloud-generated composite meshes that "dramatically reduce draw calls, triangle counts, and memory", and all parts of a model switch together.
  - SLIM only works on static models (no runtime-modified or animated ones).
  - Keep each model under about **64 cubic studs** extent.
  - `Workspace.EnableSLIMAvatars` does the same for avatars.
  - Unsupported platforms fall back to Disabled.
  - Source: [SLIM](https://create.roblox.com/docs/workspace/streaming/slim), [Streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques), [Characters](https://create.roblox.com/docs/characters)
- CollisionFidelity options:
  - **Box** for small or non-interactive objects
  - **Hull**
  - **Default** (approximate, supports concavity)
  - **PreciseConvexDecomposition**: the most precise and most expensive, slow to compute
  - **Tunable**: a new CollisionPrecision slider
  - Default and Precise use "significantly more memory". Small anchored parts are safe as Box. Set CanCollide/CanTouch/CanQuery to false on decorative parts.
  - For big complex meshes, build custom collision from Box primitives.
  - An Explorer filter `CollisionFidelity=PreciseConvexDecomposition` counts the offending meshes.
  - Source: [Meshes](https://create.roblox.com/docs/parts/meshes), [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- **Instancing:** meshes with the same MeshContent collapse into one draw call when their SurfaceAppearances are identical (or their TextureContent is identical, or their Materials are identical when there is no texture).
  - Importing a whole scene at once gives duplicate meshes different IDs and breaks instancing. Instead, import each asset once and duplicate it in Studio; **Packages** help.
  - Decals, textures and particles batch poorly. ParticleEmitter property changes are expensive.
  - Other costs: transparency overdraw, excessive shadow casters, and moving skinned MeshParts outside a Humanoid model (FastCluster rebuilds).
  - Shadows auto-disable at graphics quality levels below 4; use CastShadow=false selectively.
  - Source: [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Example baseline-device budget: "stay below **1,000 draw calls and 1,000,000 triangles**" (read via Shift+F2 Render stats). 60 FPS = 16.67 ms per frame. Don't put everything in ReplicatedStorage. Streaming improves join time and memory — [Design for performance](https://create.roblox.com/docs/performance-optimization/design)
- New **Scene Analysis** tool (Window > Performance Summary > Scene Analysis): treemaps for script memory, unparented instances, audio memory, animation memory, instance composition, and an extended scene-triangle breakdown (terrain, grass, particles, shadows). An April 2026 Roblox video demoed an AI "scene health" command over MCP using it — [Scene Analysis](https://create.roblox.com/docs/performance-optimization/scene-analysis), [Next-gen workflows video captions (2026-04-30)](https://create.roblox.com/docs/videos/next-gen-workflows-on-roblox)
- Packages: auto-update, mass-update copies, version history and restore, shown with a chain-link icon plus a PackageLink. ProceduralModels cannot be converted to packages — [Packages](https://create.roblox.com/docs/projects/assets/packages), [Procedural models](https://create.roblox.com/docs/parts/procedural-models)

**Creator Store vetting and safety**
- The Creator Store lists triangle, vertex and **script counts**, ratings and reviews on asset pages. Right-click > **Disable Scripts** inserts an asset with its scripts inactive — [Creator Store](https://create.roblox.com/docs/production/creator-store)
- Restricted practices, which double as **backdoor red flags** to check in free models:
  - `getfenv`/`setfenv` and Lua VMs
  - `require(assetId)`, `loadstring`, `InsertService:LoadAsset`, `AssetService:LoadAssetAsync`, `ModuleScript.LinkedSource`
  - obfuscated code
  - extremely large scripts
  - Source: [Creator Store](https://create.roblox.com/docs/production/creator-store)
- Distribution limits per 30 days for verified (age check or government ID; phone does not count) vs unverified accounts: meshes 200/10, images 200/10, models 200/10, audio 100/10, plugins 10/2 — [Creator Store](https://create.roblox.com/docs/production/creator-store)
- Inserted Creator Store ProceduralModels get `Sandboxed = true` on their generator automatically — [Procedural models](https://create.roblox.com/docs/parts/procedural-models)

**Asset privacy and permissions**
- Asset privacy uses two states, **Restricted** and **Open Use**. The Asset Privacy toggle only affects the creation default for **Images, Decals, Meshes**; audio, video, models, MeshParts, animations and packages have their own defaults.
  - **Open Use is irreversible**, and **game grants are permanent**.
  - Revoking a collaborator does not remove access from games that already use the asset.
  - Bulk grants can be made in the Revamped Asset Manager.
  - Source: [Asset privacy](https://create.roblox.com/docs/projects/assets/privacy)
- Animations used in a **group-owned game must be published with the group as Creator** — [Animation Editor](https://create.roblox.com/docs/animation/editor)

**Audio asset rules**
- Each file must be a single track in mp3/ogg/wav/flac, **under 20 MB and under 7 minutes**, at most 48 kHz, mono/stereo/3.0/5.1.
- Import quota is **2,000 per 30 days if ID-verified, 100 if unverified**; the monthly limit replaced any daily limit.
- Audio is private to the uploader and shared through asset privacy.
- Uploads are auto-classified as sound effect or song; songs can appear on the game page if the uploader is ID-verified and play thresholds are met.
- A Creator-Store audio child of a distributed model must itself be distributed first.
- Source: [Audio assets](https://create.roblox.com/docs/audio/assets), [Models](https://create.roblox.com/docs/parts/models)
- The Creator Store offers **100,000+ professionally produced SFX and music tracks** — [Audio](https://create.roblox.com/docs/audio)

### Inferences
- The texture-size conflict probably reflects a recent 4K support rollout. For general props, advising ≤1024² (with 2048–4096 only for hero assets) is safe until the docs are reconciled.
- A practical "pro" import workflow: model at stud scale with Unit System None; export glTF (no scale hacks) or FBX with FBX Unit Scale; import each kit piece once; set Box/Hull collision; leave RenderFidelity on Automatic; share one trim-sheet SurfaceAppearance across a kit; convert kits into Packages; group static set dressing into ≤64-stud models with LevelOfDetail = SLIM.

### Gaps
- No official 2025–2026 announcement of a triangle limit above 20k was found (DevForum and newsroom were not directly accessible).
- No official per-platform draw-call budget for mobile exists beyond the "example" figure of 1,000 draw calls / 1M triangles.
- Details of the 2024–2025 audio/animation permission rollout (e.g., cross-experience animation permission UI) were not found in the docs beyond the points above.

## 2. Rigging & animation (R15, custom rigs, editor vs external tools, priorities, IK, AnimationConstraints, FACS, graph editor)

### Takeaway
Standard R15 has 15 joints, and advanced R15 adds up to 37 optional joints. Custom skinned rigs follow the bone rules above. The 2026 additions are the **Animation Graph Editor** (node-based blend trees and state machines), **AvatarJointUpgrade** (physics-driven AnimationConstraints replacing Motor6D), IKControl, and MCP `generate_animation`.

### Cited Findings
- Standard R15 rigs have 15 poseable joints. **Advanced R15 rigs add up to 37 optional joints** for hands, shoulders and spine — [Characters](https://create.roblox.com/docs/characters)
- `StarterPlayer.AvatarJointUpgrade` replaces Motor6D with force- and torque-limited **AnimationConstraints**, enabling physics-driven motion. An AnimationConstraint can be kinematic (IsKinematic: snaps to its Transform) or force-based (MaxForce/MaxTorque) — [Characters](https://create.roblox.com/docs/characters), [AnimationConstraint](https://create.roblox.com/docs/physics/constraints/animation)
- The Character Controller Library (CCL), opt-in via Avatar Settings, provides tunable movement controllers — [Characters](https://create.roblox.com/docs/characters)
- `Enum.AnimationPriority` values: Idle, Movement, Action, Action2, Action3, Action4, Core — [AnimationPriority enum](https://create.roblox.com/docs/reference/engine/enums/AnimationPriority)
- Default Animate-script variations are weighted by `weight / total weight` (e.g., idle Animation1 at Weight 5 and Animation2 at Weight 10 play ⅓ and ⅔ of the time) — [Using animations](https://create.roblox.com/docs/animation/using)
- IKControl requires Type (e.g., Position/Transform), EndEffector (a part or bone), Target and ChainRoot — [Inverse kinematics](https://create.roblox.com/docs/animation/inverse-kinematics)
- Animation events: define markers in the editor and listen with `AnimationTrack:GetMarkerReachedSignal()` — [Animation](https://create.roblox.com/docs/animation)
- The **Animation Graph Editor** (Avatar tab) is a node-based tool for blend trees and logic. The Animation Editor stays the clip-authoring tool. Graph nodes are scriptable, and a reference place exists — [Animation Graph Editor](https://create.roblox.com/docs/animation/graph-editor)
- Facial animation: FACS poses per region (Brows, Eyes, Jaw, Mouth, Tongue) are animated in the Animation Editor. FBX imports with FACS data become FaceControls. Bake Animation must be enabled when exporting FACS — [Animate heads](https://create.roblox.com/docs/art/characters/facial-animation/animate-heads), [Export settings](https://create.roblox.com/docs/art/modeling/export-requirements)
- Studio MCP `generate_animation` generates an R15 animation from text, or converts R6→R15, at **up to 10 s** — [Studio MCP](https://create.roblox.com/docs/studio/mcp)

### Inferences
- The docs suggest a division of labor: author clips in Blender (FBX, one take per file) or the Animation Editor, and wire states in the Graph Editor. For action games, use Action–Action4 priorities for layered upper-body actions over Movement.

### Gaps
- Moon Animator (a third-party plugin) was not covered by the official docs; no current version or feature data was gathered.
- AnimationClip/CurveAnimation specifics were not researched in depth.

## 3. AI / procedural asset generation in Studio (Cube, GenerationService, Assistant, MCP)

### Takeaway
Roblox's Cube 3D foundation model powers in-game `GenerationService` (GenerateMeshAsync, GenerateModelAsync with "Car5"/"Body1" schemas, SegmentMeshAsync), Assistant `/generate_mesh` (default cap 10k triangles), segmentation into up to 8 parts, procedural models (50 per 24 h in Assistant), the Texture/Material Generators, and MCP `generate_*` tools. These tools work well for props and prototypes, but outputs need cleanup: scale, anchoring, collision and moderation.

### Cited Findings
- GenerationService uses "Roblox's **Cube 3D** foundation model".
  - `GenerateMeshAsync` must be called from the server; it takes `Prompt`, an optional `SuggestedSize` (no guarantee on output size) and an intermediate callback for the untextured mesh. `LoadGeneratedMeshAsync` loads the result.
  - Error codes cover a per-minute rate limit, moderation failure, prompt character limit, and service overload.
  - Source: [GenerationService API](https://create.roblox.com/docs/reference/engine/classes/GenerationService)
- `GenerateModelAsync`:
  - Multi-mesh, schema-based generation; only two predefined schemas today: **`Car5`** (body plus four wheels) and **`Body1`** (a single MeshPart).
  - Optional max triangle count and bounding box.
  - "Retargetable" behavior scripts (Behaviors.rbxm) make the generated cars and planes functional.
  - Results must be scaled (`ScaleTo`) and anchored after generation.
  - Source: [Model generation](https://create.roblox.com/docs/parts/model-generation)
- Assistant mesh generation:
  - `/generate_mesh` accepts a text **or** an image prompt (not both). A selected Part acts as a bounding box. Optional max triangle count, **default 10,000**; lower values look more faceted.
  - Segmentation splits a model into **up to 8 named parts** and shows four previews.
  - `/segment_mesh` on imported meshes is in early preview and topology-dependent.
  - Procedural model generation is limited to **50 per rolling 24 h**.
  - Source: [Assistant guide](https://create.roblox.com/docs/assistant/guide)
- ProceduralModel: a parameter-driven Model with an `OnGenerate(params, targetContainer)` generator module that regenerates on attribute or size changes. It works at edit time and runtime, but not inside Actors, cannot be a package, and doesn't preserve dragger joints — [Procedural models](https://create.roblox.com/docs/parts/procedural-models)
- Studio MCP server (built into Studio) tools:
  - `generate_mesh`
  - `generate_material` (returns a base material plus variant name)
  - `generate_procedural_model` (primitive parts, reference images) plus `wait_job_finished`
  - `generate_avatar` (rigged R15 body, head and clothing)
  - `generate_animation`
  - `search_asset` / `insert_asset`
  - `upload_image` / `store_image`
  - Every call takes a `studio_id`.
  - Source: [Studio MCP](https://create.roblox.com/docs/studio/mcp)
- Texture Generator: works on a mesh or a coherent model. Fast mode gives a **1K diffuse** texture; Quality mode gives **4K PBR** in a couple of minutes, but artifacts are more visible. Detailed prompts work better. Don't describe reflectivity or transparency in the prompt, and don't texture scattered or duplicate meshes in one operation — [Texture Generator](https://create.roblox.com/docs/studio/texture-generator)
- Newsroom (via search snippet only): "Introducing Roblox Cube" (March 2025) open-sourced Cube 3D. A **Feb 2026** post introduced a **4D generation beta** (functional objects such as drivable cars). In "Wish Master", players generated more than 160,000 objects, and players using 4D generation showed **+64% playtime** — [Introducing Roblox Cube](https://about.roblox.com/newsroom/2025/03/introducing-roblox-cube), [Accelerating creation powered by Cube (Feb 2026)](https://about.roblox.com/newsroom/2026/02/accelerating-creation-powered-roblox-cube-foundation-model). A secondary outlet claims 1.8M Cube assets since March 2025; this is unverified — [Outlook Respawn](https://respawn.outlookindia.com/gaming/gaming-news/cube-3d-powers-robloxs-new-4d-interactive-object-tools)

### Inferences
- AI meshes are best for background props, blockout and player-generated content. Hero assets still benefit from hand retopology, UVs and trim-sheet texturing, plus explicit collision settings and RenderFidelity review. Treat the generation tools' triangle caps (default 10k) as a quality/performance knob.

### Gaps
- Exact rate limits (per minute or per day) for GenerateMeshAsync are not documented numerically.
- The full text of the Feb 2026 newsroom post could not be fetched (about.roblox.com is blocked).

## 4. Environment art & lighting (Lighting tech, Atmosphere, Sky, post-processing, terrain)

### Takeaway
`Lighting.Technology` (Voxel/ShadowMap/Future) is now **superseded by `LightingStyle` (Realistic/Soft) plus `PrioritizeLightingQuality`**. Legacy and Compatibility can no longer be selected, and the retro look is achieved with Voxel plus ColorGradingEffect "Retro". Post-processing covers Bloom, Blur, ColorCorrection, DepthOfField, SunRays and the new ColorGradingEffect.

### Cited Findings
- Technology enum values:
  - Legacy and Compatibility are deprecated and "cannot be selected in Studio".
  - Voxel uses a 4×4×4 voxel light grid.
  - ShadowMap gives crisp sun shadows.
  - Future is the highest fidelity.
  - A new `Unified` value (5) exists but is undocumented.
  - The whole property "has been superseded by LightingStyle … and PrioritizeLightingQuality".
  - Source: [Technology enum](https://create.roblox.com/docs/reference/engine/enums/Technology)
- LightingStyle Realistic gives the most advanced lights and shadows; Soft gives a flat retro look. ShadowSoftness (0–1) only applies with Realistic. With **PrioritizeLightingQuality = true**, shadows and shaders are kept at close range as quality drops; with false, view distance is kept — [Lighting](https://create.roblox.com/docs/environment/lighting)
- Other Lighting levers: Ambient, OutdoorAmbient, Brightness, ExposureCompensation, EnvironmentDiffuseScale/SpecularScale, GlobalShadows, ClockTime — [Lighting](https://create.roblox.com/docs/environment/lighting)
- ColorGradingEffect.TonemapperPreset: Default (post-2019 vivid look) or **Retro** (pre-2019; also cap lights at brightness 1.0) — [Post-processing](https://create.roblox.com/docs/environment/post-processing-effects)
- Typical post-processing uses: Blur behind menus; ColorCorrection tinting red at low health; DepthOfField to focus shop items; SunRays tied to ClockTime — [Post-processing](https://create.roblox.com/docs/environment/post-processing-effects)
- Atmosphere: Density obscures objects and terrain; Offset creates a horizon silhouette (higher) or blends distance into the sky (lower); Haze and Glare are also available — [Atmosphere](https://create.roblox.com/docs/environment/atmosphere)
- Terrain is built from **4×4×4-stud voxels** and supports heightmap/colormap import. Expanded Terrain enables custom terrain materials. Terrain textures display at 512² per 8×8 studs — [Terrain](https://create.roblox.com/docs/parts/terrain), [Texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)
- Mobile cost: shadows auto-disable below quality level 4. Light-heavy, shadow-dense scenes and transparency overdraw (foliage, glass) are major costs; disable CastShadow on edge foliage — [Improve performance](https://create.roblox.com/docs/performance-optimization/improve), [Optimize your experience](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/optimize-your-experience)

### Inferences
- Mood recipes (synthesized, not from an official table):
  - Bright cartoon simulator: Soft or Realistic with Default tonemapper and mild Bloom.
  - Horror: low Brightness and Ambient, high Atmosphere Density, desaturating ColorCorrection.
  - Retro: Voxel plus Retro preset.

### Gaps
- There is no official per-effect mobile GPU cost table.
- The semantics of `Technology.Unified` are undocumented.
- No official "recommended setups per mood" doc was found.

## 5. Polish / game feel, audio design, accessibility, QA/playtesting, A/B testing, launch checklist, what distinguishes front-page games

### Takeaway
Roblox's docs emphasize data-driven polish:
- FTUE/D1-retention funnels
- Experiments (A/B tests running 14–60 days with up to 2 variants)
- thumbnail personalization (+8.5% average play-through)
- low-end Android device testing (about 65% of players are on Android, and about 60% of those have 2–4 GB RAM)
- accessibility hooks (PreferredTransparency, PreferredTextSize, ReducedMotion)
- the new Audio API (AudioPlayer/Emitter/Listener/Wires; SoundGroups are now discouraged)

Front-page ranking rewards low first-play bounce, playtime (capped at 60 min/day), qualified plays, retention (D1, D2–7, D8–28) and unique metadata.

### Cited Findings

**Audio**
- New audio graph: AudioPlayer → AudioEmitter (a 3D "virtual speaker") → AudioListener (a "virtual mic") → AudioDeviceOutput, connected by **Wires**, with effects such as AudioEqualizer, AudioCompressor (caps max volume) and AudioReverb. Text-to-speech and speech-to-text objects also exist — [Audio](https://create.roblox.com/docs/audio)
- ListenerLocation can be Character or Camera; this automatically creates an AudioDeviceOutput. AudioEmitter.DistanceAttenuation sets a volume-over-distance curve — [Audio objects](https://create.roblox.com/docs/audio/objects)
- `SoundGroup` is described as "legacy … now discouraged in favor of audio objects". Its classic use is SoundEffects/BackgroundMusic buses for balancing — [Sound groups](https://create.roblox.com/docs/sound/groups)

**Accessibility**
- Text size, color contrast, color non-reliance and sound non-reliance.
- `GuiService.PreferredTransparency`: multiply BackgroundTransparency by it.
- `PreferredTextSize`: Medium by default, up to Large, Larger, etc.
- **Reduced motion**, plus in-game volume controls.
- Source: [Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)

**Device testing / QA**
- Android is about **65%** of a typical game's players. Of those, about **60% have 2–4 GB RAM**, 35% have 4–8 GB and 5% have more than 8 GB. More than 50% of players' devices score **10,000–20,000 on Passmark**.
- Suggested test devices: Infinix Smart 9, Moto G05, Oppo A18, Fire HD 10 (2023), Galaxy S22 Ultra.
- The emulator is inaccurate for memory; test frame rate, memory and load time on real hardware.
- Source: [Test on hardware](https://create.roblox.com/docs/performance-optimization/test-on-hardware)
- Studio "Server & Clients" multi-client testing supports up to 8 clients (1–2 is usually enough), with pause and step at 60 Hz — [Testing modes](https://create.roblox.com/docs/studio/testing-modes). Prototyping guidance: run several team playtest sessions, then share with friends and social media — [Prototyping](https://create.roblox.com/docs/production/game-design/prototyping)
- A community QA guide exists on DevForum (not read) — [Effectively QA testing your Roblox experience](https://devforum.roblox.com/t/guide-effectively-qa-testing-your-roblox-experience/2199838)

**Experiments / analytics**
- Experiments come in two types: in-game (on Configs values) and matchmaking (only one at a time; 100% rollout recommended; up to 3 variants).
- Duration is **14–60 days**; in-game tests have up to **2 variants plus control**.
- Metric sets: Default (ARPU, session time, new-user retention), Rewarded Video, or Custom (up to 3 custom metrics from custom, economy and funnel events).
- Audience targeting is available. Configuration is locked after scheduling. Simple 50/50 tests on large rollouts are recommended.
- Source: [Experiments](https://create.roblox.com/docs/production/experiments)
- FTUE: D1 retention is measured as a player funnel; A/B test tutorial steps and starting currency, then push winners globally through Configs — [Onboarding](https://create.roblox.com/docs/production/game-design/onboarding)

**Discovery / what front-page games do**
- Recommended-for-You signals:
  - **first-play bounce rate** (negative)
  - **playtime per user** (max 60 min per user, per game, per day)
  - qualified play sessions per user
  - spend days per user and Robux per user
  - all measured only on users who arrived organically from Recommended for You, broken into D1, D2–7 and D8–28 windows
  - Source: [Discovery](https://create.roblox.com/docs/discovery)
- Discovery rules:
  - A custom thumbnail is required to get home recommendations.
  - Use original metadata.
  - Avoid giveaway or Robux-reward metadata.
  - Mismatched metadata and content is not recommended.
  - Near-duplicate games are deprioritized.
  - Source: [Discovery](https://create.roblox.com/docs/discovery)

**Launch checklist items**
- Icon: square, at least **512×512** (scaled down as small as 150×150) — [Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons)
- Thumbnails and video:
  - Up to **10 images or videos**; 16:9 at **1920×1080**, under 3 MB.
  - Authentic gameplay videos only, with a quota of **3 video uploads per month** (rejected ones count). No video on Xbox, PlayStation or VR.
  - Freecam (Left Shift+P) helps capture footage.
  - **Thumbnail personalization** needs 2 or more active thumbnails; the average gain is **+8.5%** qualified play-through rate, and some games gained +50%.
  - Source: [Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails)
- Content ratings:
  - A **Content Ratings Questionnaire** (IARC-based) is required; unrated games have restricted playability.
  - Minimal/Mild ratings are eligible for **Roblox Kids (5–8)** and Roblox Select (9–15).
  - Moderate is eligible for Select (9+) and standard Roblox (16+).
  - Restricted is 18+ and age-verified only.
  - Games for under-16s must pass an evaluation process.
  - Source: [Content ratings](https://create.roblox.com/docs/production/promotion/content-ratings), [Roblox Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select)
- Localization: automatic translation covers names, descriptions and in-game text for users who opt in, and manual translations always take precedence — [Localization](https://create.roblox.com/docs/production/localization)

**Game feel / juice**
- Only general (non-Roblox) sources were found:
  - short decaying screen shake (about 0.1–0.3 s, trauma-based)
  - a few frames of hit-stop on big impacts
  - Back/overshoot easing for UI
  - FOV kicks
  - add juice after the core loop works, and reserve big effects for important actions
  - offer reduced-motion options
  - Source: [Game feel checklist (Godot forum)](https://forum.godotengine.org/t/game-feel-checklist-for-godot-4-hit-stop-trauma-shake-coyote-time-and-more/145340), [Tweens, Shake, and Feedback](https://bjamba.github.io/teach-me-engineering/learn-godot/module-06-juice-polish/lesson-01-tweens-feedback.html)
  - A DevForum thread asking for Roblox-specific game-feel advice had no answers — [Real game feel on Roblox](https://devforum.roblox.com/t/real-game-feel-and-execution-on-roblox/4199862)

### Inferences
- Roblox-specific juice implementation (synthesized):
  - TweenService for UI pops
  - a Camera offset/CFrame shake on RenderStepped, gated by a reduced-motion setting
  - ParticleEmitter:Emit bursts (avoid constant property changes, which are expensive)
  - Highlight property toggles rather than add/remove (add/remove causes rebuild spikes; per [Highlighting](https://create.roblox.com/docs/effects/highlighting))
  - AudioPlayer plus Emitter with AudioCompressor for loudness control
- "Front-page vs amateur" in measurable terms: low first-session bounce (strong FTUE within minutes), stable performance on 2–4 GB Android, original thumbnail and icon art with personalization, iterating with Experiments rather than guesses, plus consistent art direction (trim sheets and modular kits) and coherent lighting.

### Gaps
- No primary-source accounts were found of specific top studios' internal QA or playtest processes. Web results were job postings and generic guides, and no RDC 2025/2026 talk transcripts on studio QA were found in the docs repo.
- No official Roblox loudness or LUFS normalization guidance was found.
- No official Roblox screen-shake, hit-stop or spring-module guidance was found; community libraries (e.g., spring modules) were not vetted.
