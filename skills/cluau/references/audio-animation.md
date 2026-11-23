# Audio & Animation — Feel, Mixing, Characters

> Last verified: 2026-11-23 against Roblox/creator-docs (Audio API objects, Animator, AnimationTrack, IKControl). Templates: `templates/client/AudioController.luau`.

## Contents
1. Audio API in one page
2. Mixing rules
3. Animation playback that doesn't break
4. Markers, weights, blending, IK
5. Characters in 2026 (AvatarJointUpgrade, Character Controller Library)
6. Checklist

---

## 1. Audio API in one page

Graph model — sources → processing → outputs, connected by `Wire` (`SourceInstance` → `TargetInstance`):

| Role | Objects |
|---|---|
| Sources | `AudioPlayer` (`Asset`, `Looping`, `PlaybackSpeed`, `TimePosition`, `Volume`, `:Play()`, `:Stop()`, `Ended`), `AudioTextToSpeech`, `AudioDeviceInput` (voice) |
| Processing | `AudioFader` (bus volume), `AudioCompressor` (`Threshold` dB −60..0, `Ratio`, `Attack`/`Release` seconds, `MakeupGain`), `AudioEqualizer`, `AudioReverb`, … |
| 3D | `AudioEmitter` (in a part/attachment; `DistanceAttenuation`) → heard by `AudioListener` (on camera or character) |
| Output | `AudioDeviceOutput` (the player's speakers/headphones) |

- 2D (UI, music): AudioPlayer → Wire → bus fader → … → AudioDeviceOutput.
- 3D: AudioPlayer → Wire → AudioEmitter; AudioListener → Wire → bus → output.
- `SoundService.DefaultListenerLocation`: `Character`/`Camera` makes the engine create a listener + device output for you; set `None` when you build your own graph (AudioController) to avoid hearing 3D audio twice.
- `Sound` is **not deprecated** and fine for simple cases; `SoundGroup` mixing is discouraged — use faders. Deprecated `Sound` members: `Pitch`, `MinDistance`, `MaxDistance`, `EmitterSize` → `PlaybackSpeed`, `RollOffMinDistance`, `RollOffMaxDistance`.

## 2. Mixing rules

- Buses: Music, SFX (and Voice/Ambience if needed) each with a fader; a master compressor to tame peaks.
- Defaults: music ≈ 0.5–0.6, SFX ≈ 0.8; save both in player settings and apply on load.
- Every interaction has a sound (click, hover tick, purchase success/fail, pickup, level up). Vary pitch ±4% on repeated sounds.
- Duck music under big moments (boss roar, round start) by lowering the music fader for 1–2 s.
- Audio uploads: < 20 MB, < 7 min, ≤ 48 kHz; use Creator Store licensed audio or your own — never copyrighted tracks.
- Horror: silence and distance are tools; spatial cues tell players where the threat is.

## 3. Animation playback that doesn't break

```lua
local animator = humanoid:FindFirstChildOfClass("Animator") :: Animator  -- never Humanoid:LoadAnimation
local track = animator:LoadAnimation(animationInstance)                   -- load once per character, reuse
track.Priority = Enum.AnimationPriority.Action
track:Play(0.1, 1, 1)   -- fadeTime, weight, speed
track:Stop(0.15)
```

- Load tracks once per character (cache in a per-character table cleaned on `CharacterRemoving`); don't load every time you play.
- Animations play for everyone only if **owned by the game's owner** (user or group). Group games: publish animations under the group.
- Client-loaded animations on the local character replicate automatically; NPC animations play on the server (or on every client if purely cosmetic).
- Under **Server Authority**, don't cache tracks — query `Animator:GetTrackByAnimationId()` (server-authority.md).
- Preload key animations in the loading screen with `ContentProvider:PreloadAsync`.

## 4. Markers, weights, blending, IK

- Gameplay timing (damage frame, footstep, VFX spawn) via animation **markers**: `track:GetMarkerReachedSignal("Hit"):Connect(...)` — on the client for VFX/SFX; the server keeps its own authoritative timing for damage.
- Priorities: Idle < Movement < Action < Action2 < Action3 < Action4 < Core. Higher overrides lower on shared joints.
- Blend with weights (`AdjustWeight`) and speeds (`AdjustSpeed`) instead of hard swaps; use fade times 0.1–0.2 s.
- `IKControl` (Type, EndEffector, Target, ChainRoot, Weight, SmoothTime) for look-at, aiming, hand-on-object, foot planting.
- The Animation Graph Editor builds blend trees visually; the Animation Editor authors clips; FACS for faces.

## 5. Characters in 2026

- `StarterPlayer.AvatarJointUpgrade` swaps Motor6D for **AnimationConstraint** joints (physics-aware, force-limited).
- The **Character Controller Library** (`require("@rbx/AvatarAbilities")`) is Roblox's recommended controller for new games.
- Custom rigs: bones with ≤ 4 influences per vertex; root at origin (assets-pipeline.md).

## 6. Checklist

- [ ] Animator, not Humanoid, loads tracks; tracks cached per character and cleaned on respawn.
- [ ] Animations owned by the game owner (group for group games).
- [ ] Markers drive client effects; server owns damage timing.
- [ ] Audio buses + compressor; volumes from saved settings; pitch variation on repeated SFX.
- [ ] `DefaultListenerLocation` consistent with how listeners are created.
