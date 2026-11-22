# Deprecated & Legacy APIs → Modern Replacements

> Last verified: 2026-11-22 against Roblox/creator-docs @ a23352b (docs snapshot 2026-11-21). Re-verify with `tools/verify_api_refs.py`.

Cluau never emits the "Avoid" column in new code. When reviewing user code that contains them, point them out and migrate. The `scripts/luau_lint.py` linter detects these automatically (hand rules CL0xx + rules CL2xx generated from the official docs).

**Verified against `Roblox/creator-docs` @ 2026-11-21.** This file is the hand-written migration guide; the complete machine-generated list is `deprecated-index.md`, and the official "use this now" feed is `platform-features.md`.

## NOT deprecated — do not "fix" these

| API / syntax | Status |
|---|---|
| `RunService.Heartbeat`, `RenderStepped`, `Stepped`, `PreRender`, `PreSimulation`, `PostSimulation` | Current. `RenderStepped`/`PreRender` for camera/visuals only |
| `CollectionService:AddTag/GetTagged/GetInstanceAddedSignal`, `Instance:AddTag/HasTag` | Current |
| `BasePart:SetNetworkOwner` | Current outside Server Authority |
| `Sound` | Not deprecated; Audio API preferred for new 3D/voice audio; `SoundGroup` discouraged |
| `ContextActionService` | No deprecation tag, but "being sunset" — prefer the Input Action System for new gameplay input |
| `Debris:AddItem` | Current (lowercase `addItem` is deprecated) |
| `math.pow`, `unpack`, `table.maxn`, `//`, `+=`, `continue`, `const`, string interpolation | Valid Luau |
| `time()` | Required for simulation time inside `RunService:BindToSimulation` |

Status legend: **D** = officially deprecated, **L** = legacy/superseded (still works but there is a better API), **U** = unsafe pattern.

## Scheduling & time

| Avoid | Status | Use | Notes |
|---|---|---|---|
| `wait(n)` | D | `task.wait(n)` | Legacy `wait` is throttled and can resume late. |
| `spawn(fn)` | D | `task.spawn(fn)` / `task.defer(fn)` | Legacy `spawn` delays a frame and swallows errors oddly. |
| `delay(t, fn)` | D | `task.delay(t, fn)` | Returns a cancellable thread. |
| `tick()` | L | `os.clock()` (durations), `os.time()` / `DateTime.now()` (wall clock), `workspace:GetServerTimeNow()` (synced) | `tick` is timezone-dependent and inconsistent across platforms. |
| `elapsedTime()`, `ElapsedTime()`, `time()` for durations | L | `os.clock()` | |
| `Debris:AddItem(x, t)` | L | `task.delay(t, x.Destroy, x)` | Debris is fine for rare use, but hides lifetime logic. |
| `coroutine.wrap` for fire-and-forget | L | `task.spawn` | Errors in `coroutine.wrap` surface poorly. |

## Instances

| Avoid | Status | Use |
|---|---|---|
| `Instance.new("X", parent)` | U | `Instance.new("X")`, set props, `.Parent = parent` last |
| `obj:Remove()` | D | `obj:Destroy()` (or `.Parent = nil` if you will re-parent) |
| `obj:children()`, `obj:getChildren()` | D | `obj:GetChildren()` |
| `obj:findFirstChild()`, `obj:FindFirstChild(name, true)` in hot code | D / perf | `FindFirstChild`, cache references, `CollectionService` |
| `obj:isA()`, `obj:clone()`, `obj:destroy()`, `:connect()`, `:disconnect()`, `:wait()` (lowercase) | D | `IsA`, `Clone`, `Destroy`, `Connect`, `Disconnect`, `Wait` |
| `obj.className` | D | `obj.ClassName` |
| `game.Workspace`, `game.Players` (dot access to services) | L | `game:GetService("Workspace")` / `workspace`, `game:GetService("Players")` |
| `game:service("X")`, `game:GetService("X")` inside loops | D / perf | `local X = game:GetService("X")` once at top |
| `Model:SetPrimaryPartCFrame(cf)` | D | `Model:PivotTo(cf)` |
| `Model:GetPrimaryPartCFrame()` | D | `Model:GetPivot()` |
| `Model:GetModelCFrame()`, `GetModelSize()` | D | `Model:GetBoundingBox()` / `Model:GetExtentsSize()` |
| `Model:MakeJoints()`, `Model:BreakJoints()`, `BasePart:MakeJoints()` | D | `WeldConstraint`s created explicitly |
| `BasePart.Elasticity`, `Friction`, `SpecificGravity` | D | `BasePart.CustomPhysicalProperties = PhysicalProperties.new(...)` |
| `Attachment.Rotation/WorldRotation`, `GetAxis/SetAxis` | D | `Attachment.CFrame` / `Orientation` |
| `Camera.CoordinateFrame`, `Camera.focus`, `Camera:Interpolate` | D | `Camera.CFrame`, `Camera.Focus`, TweenService |
| `JointsService`, `ManualWeld`, `Snap`, `Glue` | D | `WeldConstraint`, `Weld`, `Motor6D` |
| `BasePart.Velocity`, `RotVelocity` | D | `AssemblyLinearVelocity`, `AssemblyAngularVelocity`, or `ApplyImpulse` |
| `BasePart:GetMass()` for assemblies | L | `BasePart.AssemblyMass` |
| `BrickColor` for color | L | `Color3` (`part.Color = Color3.fromRGB(...)`) |
| `Hint`, `Message` | D | Custom UI or `TextChatService` system message |
| `Instance:GetDebugId` in logic | U | Use your own ids / attributes |

## Physics movers (legacy "Body" movers are deprecated)

| Avoid | Use |
|---|---|
| `BodyVelocity` | `LinearVelocity` (Attachment0, `VelocityConstraintMode`, `MaxForce`) |
| `BodyPosition` | `AlignPosition` |
| `BodyGyro` | `AlignOrientation` |
| `BodyForce`, `BodyThrust` | `VectorForce` |
| `BodyAngularVelocity` | `AngularVelocity` |
| `RocketPropulsion` | `LineForce` (official replacement) or `AlignPosition` + `AlignOrientation` |

Constraint movers need an `Attachment` in the part. Remember `RelativeTo` (World/Attachment0) and set `ApplyAtCenterOfMass` on `VectorForce` when you don't want torque.

## Spatial queries

| Avoid | Use |
|---|---|
| `workspace:FindPartOnRay(ray, ignore)` | `workspace:Raycast(origin, direction, params)` |
| `FindPartOnRayWithIgnoreList`, `FindPartOnRayWithWhitelist` | `RaycastParams` with `FilterType = Enum.RaycastFilterType.Exclude` / `Include` |
| `RaycastFilterType` `Blacklist` / `Whitelist` (removed names) | `Enum.RaycastFilterType.Exclude` / `Include` |
| `workspace:FindPartsInRegion3*`, `IsRegion3Empty` | `workspace:GetPartBoundsInBox(cf, size, OverlapParams)`, `GetPartBoundsInRadius`, `GetPartsInPart` |
| `BasePart:GetTouchingParts()` for gameplay checks | `workspace:GetPartsInPart(part, params)` |

`Raycast` returns `RaycastResult?` with `.Instance`, `.Position`, `.Normal`, `.Material`, `.Distance`. Direction **includes length** (`direction = unit * 500`).

## Animation & characters

| Avoid | Use |
|---|---|
| `Humanoid:LoadAnimation(anim)` | `Animator:LoadAnimation(anim)`; get `Animator` via `humanoid:WaitForChild("Animator")` |
| `AnimationController:LoadAnimation` | the `Animator` inside the AnimationController (`:LoadAnimation`) |
| `Humanoid.WalkToPoint` loops | `Humanoid:MoveTo()` + `MoveToFinished` (re-issue every < 8 s) |
| Building NPC avatars by cloning `Shirt`/`Pants`/accessory parts by hand | `HumanoidDescription` + `Players:CreateHumanoidModelFromDescription` |
| `Humanoid:ApplyDescription` / `ApplyDescriptionReset` | Server-side `ApplyDescriptionAsync` / `ApplyDescriptionResetAsync` |
| `player:LoadCharacter()` (and on the client at all) | Server `player:LoadCharacterAsync()` |
| `Humanoid:PlayEmote` | `Humanoid:PlayEmoteAsync` |
| `Players:CreateHumanoidModelFromDescription/FromUserId`, `GetHumanoidDescriptionFromUserId/FromOutfitId` | The `…Async` versions |
| `KeyframeReached` for gameplay events | Animation markers + `AnimationTrack:GetMarkerReachedSignal(name)` |
| New characters built on Motor6D only | `StarterPlayer.AvatarJointUpgrade` (AnimationConstraints) + Character Controller Library (`require("@rbx/AvatarAbilities")`) |

Animation ownership: animations loaded on the client for the local character replicate automatically. NPC animations should be played on the server (or on each client for pure visuals).

## Input

| Avoid | Use |
|---|---|
| `Player:GetMouse()`, `mouse.Hit`, `mouse.Target`, `mouse.Button1Down` | `UserInputService.InputBegan`, `UserInputService:GetMouseLocation()` + `camera:ViewportPointToRay(x, y)` + `workspace:Raycast` |
| `mouse.KeyDown` | Input Action System (`InputAction.Pressed`) / `UserInputService.InputBegan` |
| `ContextActionService:BindActionToInputTypes` | `BindAction` (or the Input Action System) |
| `InputAction:Fire()` | `InputBinding:Fire()` on a Scriptable binding |
| `UserInputService.ModalEnabled` | `GuiService.TouchControlsEnabled` |
| `GuiService:IsTenFootInterface()` for "is console" | `GuiService.ViewportDisplaySize` / `UserInputService.PreferredInput` |
| `Enum.UserInputType` checks via `UserInputService.TouchEnabled` alone for "is mobile" | `UserInputService:GetLastInputType()` / `LastInputTypeChanged`, or `UserInputService.PreferredInput` where available |
| Ignoring `gameProcessedEvent` | `if gameProcessed then return end` so typing in chat doesn't fire abilities |

The **Input Action System** (`InputContext`, `InputAction`, `InputBinding`) is stable (2026-06) and the default for player scripts; use it for new gameplay input — it unifies keyboard/gamepad/touch and is required by Server Authority. `ContextActionService` still works for existing code.

## Chat & text

| Avoid | Use |
|---|---|
| `Player.Chatted` command parsing; relaying chat through RemoteEvents | `TextChatCommand` (PrimaryAlias, Triggered); all player text through TextChatService (legacy chat is gone 2026-10; scripts lose access to message text by May 2027) |
| Legacy `Chat` service, `ChatService` Lua modules, `Chat:Chat()` | `TextChatService` (`TextChannel:DisplaySystemMessage`, `TextChatCommand`, `OnIncomingMessage`, bubble chat config) |
| `Chat:FilterStringAsync`, `FilterStringForBroadcast` | `TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)` → `GetNonChatStringForBroadcastAsync()` / `GetNonChatStringForUserAsync(toUserId)` |
| `StarterGui:SetCore("ChatMakeSystemMessage")` | `TextChannels.RBXGeneral:DisplaySystemMessage(text)` on client |
| Showing unfiltered player text (pet names, signs, plot names) | Always filter; on failure show nothing / default name |

## Teleport, data, social

| Avoid | Use |
|---|---|
| `TeleportService:Teleport`, `TeleportToPlaceInstance`, `TeleportToPrivateServer`, `TeleportPartyAsync`, `TeleportToSpawnByName` | `TeleportService:TeleportAsync(placeId, players, TeleportOptions)` (server) + handle `TeleportInitFailed` |
| `ReserveServer`, `ReserveServerAsync`, `TeleportOptions.ShouldReserveServer`, `ReservedServerAccessCode` (deprecated 2026-10) | `options.ReservedServerId = HttpService:GenerateGUID(false)`; store the GUID (e.g. MemoryStore) so parties can follow |
| `DataStore:SetAsync` for evolving player data | `UpdateAsync` (atomic, session lock) / ProfileStore |
| `DataStore:GetAsync` per-read during gameplay | Load once, cache in memory |
| `DataStoreService:GetGlobalDataStore()` for everything | Named DataStores per domain; versioning via schema field |
| ProfileService, DataStore2 for new games | ProfileStore (modern successor by the ProfileService author) or a custom UpdateAsync session lock |
| `PointsService` | Removed; use badges/your own data |
| `BadgeService:UserHasBadge`, `AwardBadge`, `IsDisabled` | `UserHasBadgeAsync`, `AwardBadgeAsync` (server, pcall), `GetBadgeInfoAsync(id).IsEnabled` |
| `MarketplaceService:PlayerOwnsAsset` / `PlayerOwnsBundle` | `UserOwnsGamePassAsync(userId, passId)` for passes; `PlayerOwnsAssetAsync` / `PlayerOwnsBundleAsync` for assets |
| `MarketplaceService:GetProductInfo` | `GetProductInfoAsync` (read prices dynamically) |
| `PromptPremiumPurchase`, `Player.MembershipType` | `PromptRobloxSubscriptionPurchase`, `Player.HasRobloxSubscription` (Roblox Plus) |
| `Player:IsFriendsWith`, `IsInGroup`, `GetFriendsOnline` | `IsFriendsWithAsync`, `IsInGroupAsync`, `GetFriendsOnlineAsync` |
| `Player:GetRankInGroup(Async)`, `GetRoleInGroup(Async)` | `GroupService:GetRolesInGroupAsync(userId, groupId)` → `{ IsMember, Roles = {{ Id, Name, Rank }} }` (highest first; identify roles by `Id`) |
| `GlobalDataStore:OnUpdate`, `DataStore:RemoveVersionAsync` | MessagingService for cross-server updates; versions expire automatically |
| `AnalyticsService:FireEvent/FireCustomEvent/...` | `LogCustomEvent`, `LogEconomyEvent`, `LogFunnelStepEvent`, `LogProgressionEvent` |
| `ContentProvider:Preload` | `ContentProvider:PreloadAsync` (loading screens only) |
| `PathfindingService:ComputeRawPathAsync/ComputeSmoothPathAsync` | `PathfindingService:CreatePath(agentParams)` → `path:ComputeAsync(a, b)` → `GetWaypoints()`; handle `path.Blocked` |
| **All of `PhysicsService`** (deprecated 2026-09), incl. `RegisterCollisionGroup`/`CollisionGroupSetCollidable` on it; `BasePart.CollisionGroupId` | Per-world methods on `workspace` (WorldRoot): `RegisterCollisionGroup`, `CollisionGroupSetCollidable`, `CollisionGroupsAreCollidable`, `GetRegisteredCollisionGroups`, `UnregisterCollisionGroup`, `RenameCollisionGroup`, `IsCollisionGroupRegistered`; `part.CollisionGroup = "Name"` |
| `Lighting.Outlines` | Removed |
| `Lighting:SetMinutesAfterMidnight` loops every frame | `Lighting.ClockTime` tweened or stepped at low frequency |
| `Lighting.Technology` | `Lighting.LightingStyle` (Realistic/Soft) + `PrioritizeLightingQuality`; retro via `ColorGradingEffect` Retro |
| `HapticService` | `HapticEffect` instances |
| `PathfindingService:FindPathAsync`, `Path:GetPointCoordinates` | `CreatePath(params)` + `path:ComputeAsync` → `GetWaypoints()`; react to `path.Blocked` |
| `Sound.Pitch`, `MinDistance`, `MaxDistance`, `EmitterSize`, lowercase `play/stop/isPlaying` | `PlaybackSpeed`, `RollOffMinDistance`, `RollOffMaxDistance`, `Play/Stop/IsPlaying` |

## UI

| Avoid | Use |
|---|---|
| `TextLabel.Font = Enum.Font.<Name>` for new UI | `TextLabel.FontFace = Font.new("rbxasset://fonts/families/<Family>.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)` — gives weights; `Font.fromEnum` to convert |
| `TextScaled = true` everywhere | Explicit `TextSize` from a type scale; `UITextSizeConstraint` when scaling is needed |
| `BorderSizePixel` borders | `UIStroke` (`ApplyStrokeMode = Border` for frames) |
| `ImageLabel` 9-slice hacks without `SliceCenter` | `ScaleType = Slice` + `SliceCenter` + `SliceScale` |
| `ScreenGui.IgnoreGuiInset` as the only safe-area handling | `ScreenGui.ScreenInsets = CoreUISafeInsets` for interactive HUD (`DeviceSafeInsets` ignores Roblox core buttons; `TopbarSafeInsets` for a topbar row) |
| Manual hide-all-frames visibility juggling | Screen state machine in a UIController |
| `GuiObject.Transparency` | `BackgroundTransparency` / `CanvasGroup.GroupTransparency` |
| `GuiObject:TweenPosition/TweenSize/TweenSizeAndPosition` | `TweenService:Create` (cancel previous tweens) |
| `GuiObject.Draggable`, `DragBegin`, `DragStopped` | `UIDragDetector` |
| `TextLabel.TextWrap`, `TextColor`, `FontSize`, `Font` | `TextWrapped`, `TextColor3`, `TextSize`, `FontFace` |
| `StarterGui.ResetPlayerGuiOnSpawn` | `ScreenGui.ResetOnSpawn` per ScreenGui |
| `Frame.Style` (DropShadow, RobloxRound...) | Custom frames with `UICorner`, `UIStroke`, 9-slice shadow image |
| `GuiService:AddSelectionParent` | `GuiObject.SelectionGroup`, `NextSelection*`, `GuiService.SelectedObject` |

## Security-unsafe patterns

| Pattern | Why | Fix |
|---|---|---|
| `loadstring(...)` / enabling `LoadStringEnabled` | Remote code execution if any input reaches it | Never; data-driven design instead |
| `require(123456789)` third-party asset IDs | Common backdoor vector, can change at any time | Vendor the code into your place, read it |
| Free models with hidden scripts | Backdoors, viruses | Search model for `Script`, `require`, `getfenv`, obfuscated strings; delete unknown scripts |
| `getfenv`/`setfenv` | Disables Luau optimizations, used by obfuscators | Don't |
| `RemoteFunction:InvokeClient` | Client can yield forever or error the server thread | RemoteEvent + server-side timeout state |
| Trusting `remote.OnServerEvent` arguments | Exploiters send anything | Validate type/range/rate/state |
| `HttpService` with secrets in ReplicatedStorage | Clients read ReplicatedStorage | Secrets only in server scripts; use Secrets Store (`HttpService:GetSecret`) |
