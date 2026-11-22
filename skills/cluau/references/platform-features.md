# Current Platform Features (generated)

Source: Roblox `latest-features.json` (updated 2026-11-20) from `Roblox/creator-docs` @ `a23352b27af917e55e165e4d42583580700d1fbf 2026-11-21`,
licensed CC BY 4.0 by Roblox. Regenerate with `tools/sync_deprecations.py`; do not edit by hand.

Roblox publishes this feed for AI agents: each entry is the *current* way to build something and lists what it
replaces. When a request touches one of these areas, follow the guidance here over older habits.

## TextChatService for all player-to-player text — stable (2026-10-21)

All player-to-player text must go through TextChatService, which applies filtering, privacy settings, and age checks. Legacy Chat is gone, and by May 2027 scripts can't read message text, so build on native channels, commands, and windows.

- **Use:** `TextChatService`, `TextChannel`, `TextChatCommand`, `TextChannelWindow`, `TextFilterResult:GetNonChatStringForBroadcastAsync()`
- **Replaces:** Chat service and ChatService modules; Player.Chatted command parsing; RemoteEvents that relay player messages; Custom chat UIs that read TextChatMessage.Text
- **Guidance:** Don't relay player text via RemoteEvents or the deprecated Chat service. Make commands with a TextChatCommand under TextChatService (PrimaryAlias, Triggered), not Chatted. For custom UI, use a TextChannelWindow with Target set. On private channels, call SetDirectChatRequester (server) before AddUserAsync. Announce via DisplaySystemMessage on each client. Filter sign text; allow one edit a minute.
- **Docs:** https://create.roblox.com/docs/chat/in-experience-text-chat.md

## Packages for content reused across places — stable (2026-10-15)

A package is a published model or script tree whose copies, in any place, update from one source. Suggest one when a model or script is reused across places. The Package Overrides beta keeps per-copy edits through updates.

- **Use:** `PackageLink`, `Instance:GetAttribute`
- **Replaces:** Pasting the same model or script into each place; BaseScript.LinkedSource and ModuleScript.LinkedSource; Breaking a package link to customize one copy
- **Guidance:** A PackageLink marks a package copy; never delete or move it. When you edit a copy, tell the user that the edit changes only that copy and, without the Package Overrides beta, stops its auto-updates. Other copies change only after the user right-clicks it > Publish to Package. Scripts can't create packages or set AutoUpdate; ask the user. For per-copy settings, have package scripts read root attributes; per-copy values survive updates.
- **Docs:** https://create.roblox.com/docs/projects/assets/packages.md

## Saving player data with data stores — stable (2026-07-15)

Data store requests from game servers and Open Cloud share one per-experience budget. Save player data with one key per player, an in-memory session copy, UpdateAsync writes, pcall retries with backoff, and saves on leave and shutdown.

- **Use:** `GlobalDataStore:UpdateAsync()`, `Players.PlayerRemoving`, `DataModel:BindToClose()`, `DataStoreService:GetRequestBudgetForRequestType()`, `Enum.DataStoreRequestType.StandardWrite`, `DataStoreGetOptions.UseCache`, `DataStore:GetVersionAtTimeAsync()`
- **Replaces:** SetAsync for read-modify-write saves; Saving only on PlayerRemoving; Instant retries or parsing SetAsyncThrottle; DataStore2 or one key per stat
- **Guidance:** Load once per session into a server table; if loading fails, use defaults but never save them. Write with UpdateAsync (its callback can't yield). Retry in order per key with capped exponential backoff and jitter. Save on PlayerRemoving, in BindToClose (30 s, in parallel), and on a staggered autosave. Add a session lock if players trade. Studio tests need Studio API access and hit live data.
- **Docs:** https://create.roblox.com/docs/cloud-services/data-stores/best-practices.md

## Server Authority (server-run game with client prediction) — stable (2026-07-09)

Runs the game authoritatively on the server while clients predict input instantly and roll back on mispredictions. Blocks speed and fly hacks for default characters without custom anti-cheat, and keeps competitive physics fair.

- **Use:** `Workspace.AuthorityMode`, `RunService:BindToSimulation()`, `InputAction:GetState()`, `Instance:SetAttribute()`, `Animator:GetTrackByAnimationId()`, `Player:GetCameraState()`, `RunService:SetPredictionMode()`, `RunService.PostSimulation`
- **Replaces:** BasePart:SetNetworkOwner() for anti-cheat; Server-side speed and teleport checks; Gameplay loops on Heartbeat or RenderStepped; UserInputService events in gameplay simulation
- **Guidance:** Ask the user to set Workspace AuthorityMode to Server in Properties; it turns on five prerequisites that execute_luau mostly can't write. Put gameplay in a ReplicatedStorage ModuleScript that a Script and a LocalScript both require, bound with BindToSimulation. Keep state in attributes, read InputActions cloned under each Player, use time(), and play effects in RenderStepped.
- **Docs:** https://create.roblox.com/docs/projects/server-authority.md

## Script Sync for editing scripts as local files — stable (2026-06-17)

Built-in two-way sync between Studio's scripts and folders and .luau files on disk. It lets creators use an external editor, Git, linters, and AI coding tools on any place, including Team Create, with no conversion step.

- **Use:** `InstanceFileSyncService:GetAllInstances()`, `InstanceFileSyncService:GetStatus()`, `InstanceFileSyncService:GetSyncedInstance()`, `Enum.InstanceFileSyncStatus`
- **Replaces:** Copying script source between Studio and files by hand; Adopting Rojo only to use an external editor
- **Guidance:** For Git or an external editor, have the creator right-click a Folder or service, choose Sync to..., and pick a directory; no tool starts sync. Check with InstanceFileSyncService:GetAllInstances() in execute_luau (Edit). Edit synced scripts as files or with multi_edit, not both at once. On disk, x.server.luau is a server Script and x.luau a ModuleScript. With Rojo, edit files only.
- **Docs:** https://create.roblox.com/docs/scripting/sync.md

## Input Action System (InputContext, InputAction) — stable (2026-06-11)

Cross-platform input: an InputContext groups InputActions, each with InputBindings for keyboard, gamepad, and touch, so one handler works on every device. Default player scripts now use it, and ContextActionService is being sunset.

- **Use:** `InputContext`, `InputAction`, `InputBinding`
- **Replaces:** ContextActionService:BindAction(); UserInputService.InputBegan for gameplay actions; Per-device key and touch-button code; PlayerModule internals such as GetControls()
- **Guidance:** Put InputContexts in ReplicatedStorage, each InputAction with one InputBinding per device (a binding with a KeyCode ignores its UIButton). Handle Pressed or StateChanged in a client Script; poll GetState() for analog. To override default controls, or block keys while a menu is open, enable a higher-Priority InputContext with Sink that binds those keys. Ask the user to set Workspace.PlayerScriptsUseInputActionSystem to Enabled; scripts can't. Avoid deprecated InputAction:Fire().
- **Docs:** https://create.roblox.com/docs/input/input-action-system.md

## SLIM distant models and avatars — beta (2026-05-12)

SLIM renders cloud-built, multi-LOD stand-ins for models and R15 player avatars that have streamed out, so distant scenery and crowds stay visible at a fraction of the cost. It needs StreamingEnabled.

- **Use:** `Model.LevelOfDetail`, `Enum.ModelLevelOfDetail.SLIM`, `Workspace.EnableSLIMAvatars`, `Enum.RolloutState.Enabled`
- **Replaces:** Enum.ModelLevelOfDetail.StreamingMesh; Distant models vanishing when streamed out; Raising StreamingTargetRadius so scenery stays visible; Hand-made low-poly LOD swaps in scripts
- **Guidance:** With execute_luau in Edit, set LevelOfDetail = SLIM on Models of static parts (group them in Models, not Folders). Skip models with a Humanoid, animations, or runtime changes; put changing parts in their own Model and add or remove it whole. Set Workspace.EnableSLIMAvatars to Enabled, or ask the user to if that errors. SLIM needs a published place with Team Create on; only the user can do that.
- **Docs:** https://create.roblox.com/docs/workspace/streaming/slim.md

## User IDs in data store keys for automated RTBF — beta (2026-04-10)

When a player files a right-to-be-forgotten request, Roblox can delete their data automatically, but only from data stores, scopes, or keys whose names contain the user ID in a fixed pattern, such as User_{UserId}, that the creator registers.

- **Use:** `Player.UserId`, `GlobalDataStore:SetAsync()`, `GlobalDataStore:UpdateAsync()`, `DataStoreKeyInfo:GetUserIds()`, `GlobalDataStore:IncrementAsync()`
- **Replaces:** Keys built from names or random IDs; One shared key holding many players' data; Deleting each requester's keys by hand
- **Guidance:** Key per-player data as a fixed prefix plus the numeric ID, such as "User_" .. player.UserId, not names or GUIDs. Pass {player.UserId} as SetAsync's userIds argument and return it as the second value of UpdateAsync callbacks, or they're cleared. Nothing is deleted until the user adds a template, such as User_{UserId} (scope global), in Creator Hub > Data Stores Manager > RTBF Deletion.
- **Docs:** https://create.roblox.com/docs/cloud-services/data-stores/right-to-be-forgotten.md

## Character Controller Library (Luau abilities) — stable (2026-04-08)

Luau character controller on ControllerManager that replaces Humanoid movement with configurable abilities (run, jump, climb, swim, sit). Roblox recommends it for all new games; custom abilities like a dash plug into the same system.

- **Use:** `AvatarAbilities.getAbilityConfigurationForCharacter()`, `AvatarAbilities.waitForAbilityManager()`, `AbilityManager:AddAbility()`, `ControllerManager`, `GroundController`, `AirController`, `Player.DevEnableMouseLock`
- **Replaces:** Humanoid.WalkSpeed and JumpPower tweaks; Humanoid:ChangeState() movement hacks; UserInputService sprint, crouch, or dash scripts; AvatarAbilities.addAbilityForCharacter
- **Guidance:** The user must save, then select Character Controller Library in Avatar Settings > Movement. Tune it with ability attributes (getAbilityConfigurationForCharacter) and controller properties. Custom abilities need the AvatarAbilities Studio beta: write AbilityDefinition modules, add them on the server with waitForAbilityManager, bind input with Input.Mode and ActionSlot, and never yield in callbacks.
- **Docs:** https://create.roblox.com/docs/characters/character-controller-library.md

## Configs and experiments (live values, A/B tests) — stable (2025-11-06)

ConfigService reads game values and feature flags that the creator changes in Creator Hub or Studio, live, without publishing or restarting servers. Experiments A/B test a config's values; conditional configs vary them by player segment.

- **Use:** `ConfigService:GetConfigAsync`, `ConfigService:GetConfigForPlayerAsync`, `ConfigSnapshot:GetValue`, `ConfigSnapshot.UpdateAvailable`, `ConfigSnapshot:Refresh`, `ConfigSnapshot:GetValueChangedSignal`, `ConfigService:SetTestingValue`
- **Replaces:** Hard-coded tuning constants that need a publish; Flags polled from DataStores, MessagingService, or HttpService; Hand-rolled A/B buckets such as UserId % 2
- **Guidance:** Server scripts only. pcall GetConfigAsync and keep a code default for when GetValue returns nil. Use GetConfigForPlayerAsync(player) for experiments and targeted values, and call GetValue only when the player reaches the feature, because that enrolls them. Snapshots don't update: connect UpdateAvailable to Refresh. Ask the user to create keys in File > Open Configs; test with SetTestingValue.
- **Docs:** https://create.roblox.com/docs/production/configs.md

## Audio API: AudioPlayer, AudioEmitter, AudioListener, Wire — stable (2024-09-10)

Modular audio: an AudioPlayer stream travels over Wires to AudioEmitters (3D), an AudioDeviceOutput (2D), and effects; an AudioListener hears 3D audio. One AudioPlayer can feed many emitters; acoustic simulation and voice routing need these objects.

- **Use:** `AudioPlayer`, `Wire`, `AudioEmitter`, `AudioListener`, `AudioDeviceOutput`, `AudioDeviceInput`, `SoundService.DefaultListenerLocation`, `VoiceChatService.UseAudioApi`
- **Replaces:** Sound; SoundGroup and SoundEffect; Sound.RollOffMinDistance and RollOffMaxDistance; A duplicate Sound per speaker
- **Guidance:** For new audio, wire an AudioPlayer (set Asset, not AssetId) to an AudioDeviceOutput for 2D or an AudioEmitter for 3D. 3D needs a listener: set SoundService.DefaultListenerLocation to Camera or Character. Set rolloff with AudioEmitter.DistanceAttenuationMode. For voice, set UseAudioApi to Enabled. Sound isn't deprecated, so keep working Sound code unless asked, but it gets no acoustic simulation.
- **Docs:** https://create.roblox.com/docs/audio/objects.md
