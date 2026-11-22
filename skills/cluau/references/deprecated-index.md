# Deprecated API Index (generated)

Generated from the official Roblox docs source (`Roblox/creator-docs` @ `a23352b27af917e55e165e4d42583580700d1fbf 2026-11-21`, CC BY 4.0 by Roblox)
by `tools/sync_deprecations.py`.
Do not edit by hand — re-run the tool. Hand-written migration advice lives in `deprecated-apis.md`.

Never emit anything in this file in new code. `lint` = flagged automatically by `scripts/luau_lint.py`.

## Deprecated classes / enums

| Name | Kind | Replacement / note |
|---|---|---|
| `BevelMesh` | class | This object serves no purpose other than being an abstract class that `BlockMesh` and `CylinderMesh` inherit from. |
| `BodyAngularVelocity` | class | This object is deprecated and should not be used for new work. |
| `BodyForce` | class | This object is deprecated and should not be used for new work. |
| `BodyGyro` | class | This object is deprecated and should not be used for new work. |
| `BodyMover` | class | This class has been deprecated. |
| `BodyPosition` | class | This object is deprecated and should not be used for new work. |
| `BodyThrust` | class | This object is deprecated and should not be used for new work. |
| `BodyVelocity` | class | This object is deprecated and should not be used for new work. |
| `CustomEvent` | class | `CustomEvents` have been superseded by `BindableEvents` and should not be used in new work. |
| `CustomEventReceiver` | class | `CustomEvents` have been superseded by `BindableEvents` and should not be used in new work. |
| `CylinderMesh` | class | This class is deprecated, and `CylinderMeshes` are no longer supported. |
| `DoubleConstrainedValue` | class | The DoubleConstrainedValue object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `Flag` | class | The `Flag` and `FlagStand` objects were created to allow developers to make 'capture the flag' style games quickly. |
| `FlagStand` | class | The FlagStand and Flag are deprecated objects that were used to make 'capture the flag' style games. |
| `FloorWire` | class | The FloorWire object has been deprecated and should not be used in new work. |
| `FunctionalTest` | class | FunctionalTest has been deprecated, developers are advised to use `TestService` instead. |
| `Glue` | class | This joint type has been deprecated and should not be used in new work. |
| `GuiMain` | class | This deprecated class is the original name of the `ScreenGui`. |
| `Hat` | class | This class has been superseded by the `Accessory` class. |
| `Hint` | class | With the introduction of Roblox's GUI features hints have been deprecated and `TextLabels` should be used instead for new work. |
| `Hole` | class | A Hole is an unused type of surface joint. |
| `Hopper` | class | `Hopper` has been replaced by `StarterPack` and should not be used in new work. |
| `HopperBin` | class | This deprecated class has been replaced by `Tool`. |
| `IntConstrainedValue` | class | The IntConstrainedValue object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `JointsService` | class | This service has been deprecated in favor of constraints which should be used for surface connections instead |
| `ManualGlue` | class | — |
| `ManualSurfaceJointInstance` | class | — |
| `ManualWeld` | class | — |
| `Message` | class | With the introduction of Roblox's GUI features hints have been deprecated and `TextLabels` should be used instead for new work. |
| `MotorFeature` | class | A MotorFeature is an unused type of surface joint. |
| `OpenCloudApiV1` | class | This class is deprecated and should not be used for new work. |
| `OpenCloudService` | class | This class is deprecated and should not be used for new work. |
| `Plane` | class | — |
| `PointsService` | class | This class was once used to control an ancient achievement system since removed and deprecated. |
| `RocketPropulsion` | class | This object is deprecated and should not be used for new work. |
| `Rotate` | class | This class works alongside the deprecated `SurfaceType` and should not be used for future work; use `HingeConstraint` instead. |
| `RotateP` | class | This class works alongside the deprecated `SurfaceType` and should not be used for future work; use `HingeConstraint` instead. |
| `RotateV` | class | This class works alongside the deprecated `SurfaceType` and should not be used for future work; use `HingeConstraint` instead. |
| `SelectionPartLasso` | class | SelectionPartLasso has been deprecated. |
| `SelectionPointLasso` | class | The SelectionPointLasso class is deprecated. |
| `SkateboardPlatform` | class | The SkateboardPlatform object has been deprecated and is no longer supported by Roblox. |
| `Skin` | class | This object has been deprecated and superseded by `BodyColors`. |
| `Snap` | class | — |
| `Status` | class | Status is an unfinished object designed to store custom `Humanoid` statuses. |
| `GearGenreSetting` | enum | This enum is deprecated as it is used by deprecated properties that are no longer functional. |
| `GearType` | enum | This enum is deprecated because it's used by deprecated properties. |
| `Genre` | enum | — |
| `SaveFilter` | enum | This deprecated enum is used by `DataModel.SavePlace` which has also been deprecated. |
| `Status` | enum | This enum is deprecated as it was only used by deprecated methods and events. |

## Deprecated members

| Member | Kind | Lint | Replacement / note |
|---|---|---|---|
| `AccessoryDescription.Puffiness` | property |  | — |
| `AdGui.OnAdEvent` | callback | yes | This callback has been deprecated and will never be called. |
| `AdService:ShowVideoAd` | method | yes | `ShowVideoAd` has been decommissioned and is no longer operational. |
| `AdService.VideoAdClosed` | event | yes | `VideoAdClosed` has been decommissioned and is no longer operational. |
| `AlignOrientation.PrimaryAxisOnly` | property | yes | This property is deprecated. |
| `AnalyticsService.ApiKey` | property |  | This property is deprecated. |
| `AnalyticsService:FireCustomEvent` | method | yes | This deprecated function is a variant of `Class.AnalyticsService:LogCustomEvent()` which should be used instead. |
| `AnalyticsService:FireEvent` | method | yes | This function has been deprecated in favor of more descriptive methods, including `Class.AnalyticsService:LogCustomEvent()`, `Class.AnalyticsService:LogEconomyEvent()`, and `Class.AnalyticsService:LogProgressionEvent()`. |
| `AnalyticsService:FireInGameEconomyEvent` | method | yes | This deprecated function is a variant of `Class.AnalyticsService:LogEconomyEvent()` which should be used instead. |
| `AnalyticsService:FireLogEvent` | method | yes | This method is deprecated. |
| `AnalyticsService:FirePlayerProgressionEvent` | method | yes | This deprecated function is a variant of `Class.AnalyticsService:LogProgressionEvent()` which should be used instead. |
| `AnimationClipProvider:GetAnimationClip` | method | yes | This function is deprecated and can lead to the game freezing until the animation is loaded. |
| `AnimationClipProvider:GetAnimationClipById` | method | yes | This function is deprecated and can lead to the game freezing until the animation is loaded. |
| `AnimationClipProvider:GetAnimations` | method | yes | — |
| `AnimationController.AnimationPlayed` | event |  | — |
| `AnimationController:GetPlayingAnimationTracks` | method |  | — |
| `AnimationController:LoadAnimation` | method |  | This function is deprecated in favor of using `Class.Animator:LoadAnimation()` directly (the `Animator` may be created while editing or at runtime). |
| `AnimationTrack.KeyframeReached` | event | yes | This event has been superseded by the `Class.AnimationTrack:GetMarkerReachedSignal()` method. |
| `AssetService:CreatePlaceInPlayerInventoryAsync` | method | yes | This method has been removed and is no longer functional. |
| `AssetService:GetAssetIdsForPackage` | method | yes | Use `Class.AssetService:GetAssetIdsForPackageAsync()|GetAssetIdsForPackageAsync()` instead. |
| `AssetService:GetCreatorAssetID` | method | yes | This item is deprecated and no longer functions correctly. |
| `AssetService:SearchAudio` | method | yes | Use `Class.AssetService:SearchAudioAsync()|SearchAudioAsync()` instead. |
| `Attachment:GetAxis` | method | yes | This method is deprecated and should not be used in new work. |
| `Attachment:GetSecondaryAxis` | method | yes | This method is deprecated and should not be used in new work. |
| `Attachment.Rotation` | property |  | This property is deprecated and should not be used in new work. |
| `Attachment:SetAxis` | method | yes | This method is deprecated and should not be used in new work. |
| `Attachment:SetSecondaryAxis` | method | yes | This method is deprecated and should not be used in new work. |
| `Attachment.WorldRotation` | property | yes | This item has been superseded by `WorldOrientation` which should be used in new work. |
| `AudioEmitter.SimulationFidelity` | property | yes | — |
| `AudioListener.SimulationFidelity` | property |  | — |
| `AudioPlayer.AssetId` | property |  | This property is deprecated; use `Asset` instead. |
| `AudioSearchParams.AudioSubtype` | property | yes | Use `AudioSubType` instead. |
| `AvatarCreationService.AvatarModerationCompleted` | event | yes | This event is deprecated. |
| `AvatarEditorService:CheckApplyDefaultClothing` | method | yes | — |
| `AvatarEditorService:ConformToAvatarRules` | method | yes | — |
| `AvatarEditorService:GetAvatarRules` | method | yes | — |
| `AvatarEditorService:GetBatchItemDetails` | method | yes | — |
| `AvatarEditorService:GetFavorite` | method | yes | — |
| `AvatarEditorService:GetInventory` | method | yes | — |
| `AvatarEditorService:GetItemDetails` | method | yes | — |
| `AvatarEditorService:GetOutfitDetails` | method | yes | — |
| `AvatarEditorService:GetOutfits` | method | yes | — |
| `AvatarEditorService:GetRecommendedAssets` | method | yes | — |
| `AvatarEditorService:GetRecommendedBundles` | method | yes | — |
| `AvatarEditorService:SearchCatalog` | method | yes | — |
| `BadgeService:AwardBadge` | method | yes | Use `Class.BadgeService:AwardBadgeAsync()|AwardBadgeAsync()` instead. |
| `BadgeService:IsDisabled` | method | yes | This function is deprecated. |
| `BadgeService:IsLegal` | method | yes | This function is deprecated and will always return true. |
| `BadgeService:UserHasBadge` | method | yes | This method has been superseded by `Class.BadgeService:UserHasBadgeAsync()` which should be used for new work instead. |
| `BasePart.BackParamA` | property | yes | — |
| `BasePart.BackParamB` | property | yes | — |
| `BasePart.BackSurfaceInput` | property | yes | — |
| `BasePart.BottomParamA` | property | yes | — |
| `BasePart.BottomParamB` | property | yes | — |
| `BasePart.BottomSurfaceInput` | property | yes | — |
| `BasePart:BreakJoints` | method | yes | This method is deprecated. |
| `BasePart.CollisionGroupId` | property | yes | — |
| `BasePart.Elasticity` | property |  | This is only one of multiple physics-related properties. |
| `BasePart.Friction` | property |  | This is only one of multiple physics-related properties. |
| `BasePart.FrontParamA` | property | yes | — |
| `BasePart.FrontParamB` | property | yes | — |
| `BasePart.FrontSurfaceInput` | property | yes | — |
| `BasePart:GetRenderCFrame` | method |  | This item is been deprecated since interpolation is now applied to the `CFrame` directly. |
| `BasePart:GetRootPart` | method | yes | — |
| `BasePart.LeftParamA` | property | yes | — |
| `BasePart.LeftParamB` | property | yes | — |
| `BasePart.LeftSurfaceInput` | property | yes | — |
| `BasePart.LocalSimulationTouched` | event | yes | This event is deprecated in favor of `BasePart.Touched`. |
| `BasePart:MakeJoints` | method | yes | SurfaceType based joining is deprecated, do not use MakeJoints for new projects. |
| `BasePart.OutfitChanged` | event | yes | This event is deprecated. |
| `BasePart.RightParamA` | property | yes | — |
| `BasePart.RightParamB` | property | yes | — |
| `BasePart.RightSurfaceInput` | property | yes | — |
| `BasePart.RotVelocity` | property | yes | This property is deprecated. |
| `BasePart.SpecificGravity` | property |  | This item is deprecated. |
| `BasePart.StoppedTouching` | event | yes | This event is deprecated in favor of `BasePart.TouchEnded`, which should be used instead. |
| `BasePart.TopParamA` | property | yes | — |
| `BasePart.TopParamB` | property | yes | — |
| `BasePart.TopSurfaceInput` | property | yes | — |
| `BasePart.Velocity` | property |  | This property is deprecated. |
| `BasePart:breakJoints` | method | yes | This deprecated function is a variant of `Class.BasePart:BreakJoints()` which should be used instead. |
| `BasePart.brickColor` | property | yes | This deprecated property is an old Camel Case variant of the Pascal Case `BasePart.BrickColor`, which should be used instead. |
| `BasePart:getMass` | method | yes | This Camel Case property has been deprecated in favor of its Pascal Case variant, `Class.BasePart:GetMass()`. |
| `BasePart:makeJoints` | method | yes | This deprecated function is a variant of `Class.BasePart:MakeJoints()` which should be used instead. |
| `BasePart:resize` | method |  | This deprecated function is a variant of `Class.BasePart:Resize()` which should be used instead. |
| `BaseScript.LinkedSource` | property | yes | This property is now replaced by packages which has greater functionality. |
| `BillboardGui.DistanceLowerLimit` | property | yes | — |
| `BillboardGui.DistanceUpperLimit` | property | yes | — |
| `BodyAngularVelocity.AngularVelocity` | property |  | — |
| `BodyAngularVelocity.MaxTorque` | property |  | — |
| `BodyAngularVelocity.P` | property |  | — |
| `BodyAngularVelocity.angularvelocity` | property |  | This deprecated property is a variant of `BodyAngularVelocity.AngularVelocity` which should be used instead. |
| `BodyAngularVelocity.maxTorque` | property |  | This deprecated property is a variant of `BodyAngularVelocity.MaxTorque` which should be used instead. |
| `BodyForce.Force` | property |  | — |
| `BodyForce.force` | property |  | This deprecated property is a variant of `BodyForce.Force` which should be used instead. |
| `BodyGyro.CFrame` | property |  | — |
| `BodyGyro.D` | property |  | — |
| `BodyGyro.MaxTorque` | property |  | — |
| `BodyGyro.P` | property |  | — |
| `BodyGyro.cframe` | property |  | This property is a deprecated variant of `BodyGyro.CFrame` which should be used instead. |
| `BodyGyro.maxTorque` | property |  | This property is a deprecated variant of `BodyGyro.MaxTorque` which should be used instead. |
| `BodyPosition.D` | property |  | — |
| `BodyPosition:GetLastForce` | method | yes | — |
| `BodyPosition.MaxForce` | property |  | — |
| `BodyPosition.P` | property |  | — |
| `BodyPosition.Position` | property |  | — |
| `BodyPosition.ReachedTarget` | event | yes | — |
| `BodyPosition:lastForce` | method | yes | This property has been superseded by `Class.BodyPosition:GetLastForce()` which should be used in new work instead, |
| `BodyPosition.maxForce` | property |  | This property is a deprecated variant of `BodyPosition.MaxForce` which should be used instead. |
| `BodyPosition.position` | property |  | This is a deprecated variant of `BodyPosition.Position` which should be used instead. |
| `BodyThrust.Force` | property |  | — |
| `BodyThrust.Location` | property | yes | — |
| `BodyThrust.force` | property |  | This property is a deprecated variant of `Force` which should be used instead. |
| `BodyThrust.location` | property |  | This property is a deprecated variant of `BodyThrust.Location` which should be used instead. |
| `BodyVelocity:GetLastForce` | method |  | — |
| `BodyVelocity.MaxForce` | property |  | — |
| `BodyVelocity.P` | property |  | — |
| `BodyVelocity.Velocity` | property |  | — |
| `BodyVelocity:lastForce` | method |  | — |
| `BodyVelocity.maxForce` | property |  | This property is a deprecated variant of `BodyVelocity.MaxForce` which should be used instead. |
| `BodyVelocity.velocity` | property |  | This property is a deprecated variant of `BodyVelocity.Velocity` which should be used instead. |
| `BoolValue.changed` | event |  | This event is a deprecated variant of `BoolValue.Changed` which should be used instead. |
| `BrickColorValue.changed` | event |  | This event is a deprecated variant of `BrickColorValue.Changed` which should be used instead. |
| `CFrameValue.changed` | event |  | This event is a deprecated variant of `CFrameValue.Changed` which should be used instead. |
| `Camera.CoordinateFrame` | property | yes | This item has been superseded by `Camera.CFrame` which should be used in all new work. |
| `Camera:GetLargestCutoffDistance` | method | yes | This method is deprecated. |
| `Camera:GetPanSpeed` | method | yes | This method has been deprecated and no longer works. |
| `Camera:GetRoll` | method | yes | This method has been deprecated. |
| `Camera:GetTiltSpeed` | method | yes | This method has been deprecated and no longer works. |
| `Camera:Interpolate` | method |  | This method has been deprecated. |
| `Camera.InterpolationFinished` | event | yes | This event has been deprecated. |
| `Camera:PanUnits` | method | yes | This method was used for legacy camera controls and has since been deprecated. |
| `Camera:SetCameraPanMode` | method | yes | This method has been deprecated and should not be used in new work. |
| `Camera:SetRoll` | method | yes | This method has been deprecated. |
| `Camera:TiltUnits` | method | yes | This method was used for legacy camera controls and has been deprecated. |
| `Camera.focus` | property |  | This property is a deprecated variant of `Focus` which should be used instead. |
| `CaptureService.CaptureSaved` | event | yes | This event has been superseded by the `UserCaptureSaved` event. |
| `Chat:FilterStringForPlayerAsync` | method | yes | This item has been superseded by `Class.Chat:FilterStringAsync()` and `Class.Chat:FilterStringForBroadcast()` which should be used in all new work |
| `ClickDetector.mouseClick` | event | yes | This deprecated event is a variant of `ClickDetector.MouseClick`, which should be used instead. |
| `CollectionService:GetCollection` | method | yes | This item has been superseded by a `CollectionService` tagging method. |
| `CollectionService.ItemAdded` | event | yes | This item has been superseded by a `CollectionService` tagging method. |
| `CollectionService.ItemRemoved` | event | yes | This item has been superseded by a `CollectionService` tagging method. |
| `Color3.toHSV` | function | yes | This function is functionally equivalent to `Datatype.Color3:ToHSV()`. |
| `Color3Value.changed` | event |  | This deprecated event is a variant of `Color3Value.Changed` which should be used instead. |
| `Constraint:GetDebugAppliedForce` | method | yes | This method should not be used in new work. |
| `Constraint:GetDebugAppliedTorque` | method | yes | This method should not be used in new work. |
| `ContentProvider:Preload` | method | yes | This item has been superseded by `Class.ContentProvider:PreloadAsync()` which should be used in all new work. |
| `ContextActionService:BindActionToInputTypes` | method | yes | This item has been superseded by `Class.ContextActionService:BindAction()` which should be used in all new work. |
| `Controller:bindButton` | method | yes | This function is a deprecated variant of `Class.Controller:BindButton()` which should be used instead. |
| `Controller:getButton` | method | yes | This function is a deprecated variant of `Class.Controller:GetButton()` which should be used instead. |
| `CustomEvent:GetAttachedReceivers` | method | yes | CustomEvents have been superseded by `BindableEvents` and should not be used in new work. |
| `CustomEvent.ReceiverConnected` | event | yes | `CustomEvents` have been superseded by `BindableEvents` and should not be used in new work. |
| `CustomEvent.ReceiverDisconnected` | event | yes | `CustomEvents` have been superseded by `BindableEvents` and should not be used in new work. |
| `CustomEvent:SetValue` | method | yes | `CustomEvents` have been superseded by `BindableEvents` and should not be used in new work. |
| `CustomEventReceiver.EventConnected` | event | yes | `CustomEvents` have been superseded by `BindableEvents` and should not be used in new work. |
| `CustomEventReceiver.EventDisconnected` | event | yes | `CustomEvents` have been superseded by `BindableEvents` and should not be used in new work. |
| `CustomEventReceiver:GetCurrentValue` | method | yes | `CustomEvents` have been superseded by `BindableEvents` and should not be used in new work. |
| `CustomEventReceiver.Source` | property |  | `CustomEvents` have been superseded by `BindableEvents` and should not be used in new work. |
| `CustomEventReceiver.SourceValueChanged` | event | yes | `CustomEvents` have been superseded by `BindableEvents` and should not be used in new work. |
| `CylindricalConstraint.SoftlockAngularServoUponReachingTarget` | property | yes | This property should not be used in new work. |
| `DataModel.AllowedGearTypeChanged` | event | yes | This item is deprecated . |
| `DataModel.GearGenreSetting` | property | yes | This property is deprecated and is no longer functional. |
| `DataModel.Genre` | property | yes | This property is deprecated and is no longer functional. |
| `DataModel:GetMessage` | method | yes | This item is deprecated since the system was phased out a very long time ago, and recently the APIs for setting this message were removed. |
| `DataModel:GetObjects` | method | yes | This item is deprecated. |
| `DataModel:GetRemoteBuildMode` | method | yes | This item is deprecated. |
| `DataModel:IsGearTypeAllowed` | method | yes | This property is deprecated and is no longer functional. |
| `DataModel.ItemChanged` | event | yes | This function has been superseded by `Object.Changed`, which should be used in new work instead. |
| `DataModel.OnClose` | callback |  | This function is deprecated. |
| `DataModel:SavePlace` | method | yes | This item is deprecated. |
| `DataModel.VIPServerId` | property | yes | This property has been deprecated. |
| `DataModel.VIPServerOwnerId` | property | yes | This property has been deprecated. |
| `DataModel.lighting` | property |  | This item has been superseded by `Class.ServiceProvider:GetService()|game:GetService("Lighting")`, which should be used instead. |
| `DataModel.workspace` | property |  | This deprecated property is a variant of `DataModel.Workspace` which should be used instead. |
| `DataStore:RemoveVersionAsync` | method | yes | This method is deprecated. |
| `Debris.MaxItems` | property | yes | This property is deprecated and should not be used in new work. |
| `Debris:addItem` | method | yes | This function is a deprecated variant of `Class.Debris:AddItem()` which should be used instead. |
| `Decal.Shiny` | property |  | This non-functional property is deprecated and should not be used in new work. |
| `Decal.Specular` | property |  | This property no longer functions correctly and is deprecated. |
| `Decal.Texture` | property |  | This property has been deprecated. |
| `Decal.TextureContent` | property |  | This property has been deprecated. |
| `DoubleConstrainedValue.Changed` | event |  | The `DoubleConstrainedValue` object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `DoubleConstrainedValue.ConstrainedValue` | property | yes | The `DoubleConstrainedValue` object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `DoubleConstrainedValue.MaxValue` | property | yes | The `DoubleConstrainedValue` object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `DoubleConstrainedValue.MinValue` | property | yes | The `DoubleConstrainedValue` object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `DoubleConstrainedValue.Value` | property |  | The `DoubleConstrainedValue` object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `DoubleConstrainedValue.changed` | event |  | This event is a deprecated variant of `DoubleConstrainedValue.Changed` which has also been deprecated. |
| `EditableMesh:GetFacesWithAttribute` | method | yes | This method is deprecated. |
| `EditableMesh:GetVerticesWithAttribute` | method | yes | This method is deprecated. |
| `Fire.size` | property |  | This property is a deprecated variant of `Fire.Size` which should be used instead. |
| `Flag.TeamColor` | property |  | This property was a part of the now deprecated `Flag` service. |
| `FlagStand.FlagCaptured` | event | yes | This event was a part of the now deprecated `Flag` service. |
| `FlagStand.TeamColor` | property |  | This property was a part of the now deprecated `Flag` service. |
| `FloorWire.CycleOffset` | property | yes | The FloorWire object has been deprecated and should not be used in new work. |
| `FloorWire.From` | property | yes | The FloorWire object has been deprecated and should not be used in new work. |
| `FloorWire.StudsBetweenTextures` | property | yes | The FloorWire object has been deprecated and should not be used in new work. |
| `FloorWire.Texture` | property |  | The FloorWire object has been deprecated and should not be used in new work. |
| `FloorWire.TextureSize` | property | yes | The FloorWire object has been deprecated and should not be used in new work. |
| `FloorWire.To` | property |  | The FloorWire object has been deprecated and should not be used in new work. |
| `FloorWire.Velocity` | property |  | The FloorWire object has been deprecated and should not be used in new work. |
| `FloorWire.WireRadius` | property | yes | The FloorWire object has been deprecated and should not be used in new work. |
| `FormFactorPart.FormFactor` | property | yes | This property has been deprecated and should not be used in new work. |
| `FormFactorPart.formFactor` | property | yes | This property has been deprecated and should not be used in new work. |
| `FunctionalTest.Description` | property | yes | FunctionalTest has been deprecated, developers are advised to use `TestService` instead. |
| `FunctionalTest:Error` | method |  | FunctionalTest has been deprecated, developers are advised to use `TestService` instead. |
| `FunctionalTest:Failed` | method |  | FunctionalTest has been deprecated, developers are advised to use `TestService` instead. |
| `FunctionalTest:Pass` | method | yes | FunctionalTest has been deprecated, developers are advised to use `TestService` instead. |
| `FunctionalTest:Passed` | method |  | FunctionalTest has been deprecated, developers are advised to use `TestService` instead. |
| `FunctionalTest:Warn` | method |  | FunctionalTest has been deprecated, developers are advised to use `TestService` instead. |
| `GamePassService:PlayerHasPass` | method | yes | — |
| `GameSettings.VideoCaptureEnabled` | property | yes | This property is deprecated. |
| `GenerationService:GenerateMeshAsync` | method | yes | This method is scheduled for future deprecation. |
| `GlobalDataStore:OnUpdate` | method | yes | This function has been deprecated and should not be used in new work. |
| `Glue.F0` | property |  | — |
| `Glue.F1` | property |  | — |
| `Glue.F2` | property |  | — |
| `Glue.F3` | property |  | — |
| `GuiBase2d.Localize` | property |  | This item is deprecated. |
| `GuiBase3d.Color` | property |  | This property has been deprecated in favor of `GuiBase3d.Color3`, which allows for greater color customization and should be used in new work instead. |
| `GuiObject.BackgroundColor` | property | yes | This property is deprecated in favor of the `Color3` property `GuiObject.BackgroundColor3`, which should be used in new work instead. |
| `GuiObject.BorderColor` | property | yes | This property is deprecated in favor of the `Color3` property BorderColor3, which should be used in new work instead. |
| `GuiObject.DragBegin` | event | yes | This property is deprecated. |
| `GuiObject.DragStopped` | event | yes | This property is deprecated. |
| `GuiObject.Draggable` | property | yes | This property is deprecated. |
| `GuiObject.Transparency` | property |  | This property is deprecated and indexing it will return `BackgroundTransparency`. |
| `GuiObject:TweenPosition` | method | yes | This function is deprecated in favor of using `TweenService`, which allows for better customization using an object-oriented and event-based approach. |
| `GuiObject:TweenSize` | method | yes | This function is deprecated in favor of using `TweenService`, which allows for better customization using an object-oriented and event-based approach. |
| `GuiObject:TweenSizeAndPosition` | method | yes | This function is deprecated in favor of using `TweenService`, which allows for better customization using an object-oriented and event-based approach. |
| `GuiService:AddSelectionParent` | method | yes | — |
| `GuiService:AddSelectionTuple` | method | yes | — |
| `GuiService.IsModalDialog` | property | yes | This item is deprecated. |
| `GuiService:IsTenFootInterface` | method | yes | This method has been superseded by the `ViewportDisplaySize` property which represents the internally‑categorized rendering size of the viewport. |
| `GuiService.IsWindows` | property | yes | This item is deprecated. |
| `GuiService:RemoveSelectionGroup` | method | yes | — |
| `HingeConstraint.SoftlockServoUponReachingTarget` | property | yes | This property should not be used in new work. |
| `HopperBin.Active` | property |  | The `HopperBin` object has been superseded by the `Tool` object which should be used for all new work. |
| `HopperBin.BinType` | property | yes | The `HopperBin` object has been superseded by the `Tool` object which should be used for all new work. |
| `HopperBin.Deselected` | event | yes | The `HopperBin` object has been superseded by the `Tool` object which should be used for all new work. |
| `HopperBin.Selected` | event |  | The `HopperBin` object has been superseded by the `Tool` object which should be used for all new work. |
| `Humanoid:AddCustomStatus` | method | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid:AddStatus` | method | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid.AnimationPlayed` | event |  | — |
| `Humanoid:ApplyDescription` | method | yes | This method has been superseded by `Class.Humanoid:ApplyDescriptionAsync()|ApplyDescriptionAsync()`. |
| `Humanoid:ApplyDescriptionReset` | method | yes | This method has been superseded by `Class.Humanoid:ApplyDescriptionResetAsync()|ApplyDescriptionResetAsync()`. |
| `Humanoid.CollisionType` | property | yes | — |
| `Humanoid.CustomStatusAdded` | event | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid.CustomStatusRemoved` | event | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid:GetPlayingAnimationTracks` | method |  | — |
| `Humanoid:GetStatuses` | method | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid:HasCustomStatus` | method | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid:HasStatus` | method | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid.LeftLeg` | property |  | This instance only works with the old R6 rig. |
| `Humanoid:LoadAnimation` | method |  | This function is deprecated in favor of using `Class.Animator:LoadAnimation()` directly (the `Animator` may be created while editing or at runtime). |
| `Humanoid:PlayEmote` | method | yes | This method has been superseded by `Class.Humanoid:PlayEmoteAsync()|PlayEmoteAsync()`. |
| `Humanoid:RemoveCustomStatus` | method | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid:RemoveStatus` | method | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid.RightLeg` | property |  | This instance only works with the old R6 rig. |
| `Humanoid.StatusAdded` | event | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid.StatusRemoved` | event | yes | This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. |
| `Humanoid.Torso` | property |  | This instance only works with the old R6 rig. |
| `Humanoid:loadAnimation` | method | yes | This deprecated method is a variant of `Class.Humanoid:LoadAnimation()`. |
| `Humanoid.maxHealth` | property | yes | This deprecated property is a variant of `Humanoid.MaxHealth` which should be used instead. |
| `Humanoid:takeDamage` | method | yes | This deprecated method is a variant of `Class.Humanoid:TakeDamage()`, which should be used instead. |
| `InputAction:Fire` | method |  | Use `Class.InputBinding:Fire()` with a `Scriptable` binding instead. |
| `InsertService.AllowInsertFreeModels` | property | yes | This item was never released. |
| `InsertService:ApproveAssetId` | method | yes | This item is deprecated. |
| `InsertService:ApproveAssetVersionId` | method | yes | This item is deprecated. |
| `InsertService:GetBaseCategories` | method | yes | This item is deprecated. |
| `InsertService:GetBaseSets` | method | yes | Sets have been removed from Roblox. |
| `InsertService:GetCollection` | method |  | Sets have been removed from Roblox. |
| `InsertService:GetFreeDecals` | method | yes | Use `Class.InsertService:GetFreeDecalsAsync()|GetFreeDecalsAsync()` instead. |
| `InsertService:GetFreeModels` | method | yes | Use `Class.InsertService:GetFreeModelsAsync()|GetFreeModelsAsync()` instead. |
| `InsertService:GetUserCategories` | method | yes | This item is deprecated. |
| `InsertService:GetUserSets` | method | yes | Sets have been removed from Roblox. |
| `InsertService:Insert` | method |  | This function has been superseded by `Class.InsertService:LoadAsset()` which should be used in all new work. |
| `InsertService:loadAsset` | method | yes | This function is a deprecated variant of `Class.InsertService:LoadAsset()` which should be used instead. |
| `Instance:Remove` | method |  | This item is deprecated in favor of `Class.Instance:Destroy()` and `Class.Instance:ClearAllChildren()`. |
| `Instance.RobloxLocked` | property | yes | This property is deprecated and does not do anything. |
| `Instance.archivable` | property | yes | This deprecated property is a variant of `Instance.Archivable` which should be used instead. |
| `Instance.childAdded` | event | yes | This deprecated event is a variant of `Instance.ChildAdded` which should be used instead. |
| `Instance:children` | method | yes | This item has been superseded by `Class.Instance:GetChildren()` which should be used in all new work. |
| `Instance:clone` | method |  | This deprecated function is a variant of `Class.Instance:Clone()` which should be used instead. |
| `Instance:destroy` | method | yes | This deprecated function is a variant of `Class.Instance:Destroy()` which should be used instead. |
| `Instance:findFirstChild` | method | yes | This deprecated function is a variant of `Class.Instance:FindFirstChild()` which should be used instead. |
| `Instance:getChildren` | method | yes | This deprecated function is a variant of `Class.Instance:GetChildren()` which should be used instead. |
| `Instance:isDescendantOf` | method | yes | This deprecated function is a variant of `Class.Instance:IsDescendantOf()` which should be used instead. |
| `Instance:remove` | method |  | This deprecated function is a variant of `Class.Instance:Remove()` which has also been deprecated. |
| `IntConstrainedValue.Changed` | event |  | The IntConstrainedValue object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `IntConstrainedValue.ConstrainedValue` | property |  | The IntConstrainedValue object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `IntConstrainedValue.MaxValue` | property |  | The IntConstrainedValue object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `IntConstrainedValue.MinValue` | property |  | The IntConstrainedValue object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `IntConstrainedValue.Value` | property |  | The IntConstrainedValue object has been deprecated as developers can now use the `Library.math.clamp()` function to constrain values. |
| `IntConstrainedValue.changed` | event |  | This deprecated event is a variant of `IntConstrainedValue.Changed` which has also been deprecated. |
| `IntValue.changed` | event |  | This deprecated event is a variant of `IntValue.Changed` which should be used instead. |
| `JointInstance.part1` | property |  | This deprecated property is a variant of `Part1` which should be used instead. |
| `JointsService:ClearJoinAfterMoveJoints` | method | yes | — |
| `JointsService:CreateJoinAfterMoveJoints` | method | yes | — |
| `JointsService:SetJoinAfterMoveInstance` | method | yes | — |
| `JointsService:SetJoinAfterMoveTarget` | method | yes | — |
| `JointsService:ShowPermissibleJoints` | method | yes | — |
| `KeyframeSequenceProvider:GetAnimations` | method |  | — |
| `KeyframeSequenceProvider:GetKeyframeSequence` | method | yes | This function is deprecated and can lead to the game freezing until the animation is loaded. |
| `KeyframeSequenceProvider:GetKeyframeSequenceById` | method | yes | This function is deprecated and can lead to the game freezing until the animation is loaded. |
| `LayerCollector:GetLayoutNodeTree` | method | yes | This method should not be used for new work. |
| `Lighting:GetMoonPhase` | method | yes | There is currently no way to change the moon's phase, and thus this method should not be used. |
| `Lighting.Outlines` | property | yes | This item is no longer supported as the outlines feature was removed from the Roblox platform. |
| `Lighting.ShadowColor` | property | yes | This item is deprecated and has no current functionality. |
| `Lighting.Technology` | property | yes | This property has been superseded by `LightingStyle` which determines the artistic intent behind lighting, and `PrioritizeLightingQuality` which indicates whether you prefer lighting/shading quality or view distance to s |
| `Lighting:getMinutesAfterMidnight` | method | yes | This method is a deprecated variant of `Class.Lighting:GetMinutesAfterMidnight()` which should be used instead. |
| `Lighting:setMinutesAfterMidnight` | method | yes | This method is a deprecated variant of `Class.Lighting:SetMinutesAfterMidnight()` which should be used instead. |
| `LocalizationService:GetTranslatorForPlayer` | method | yes | This function has been deprecated by `Class.LocalizationService:GetTranslatorForPlayerAsync()`, which functions similarly except that it yields until the cloud table has loaded. |
| `LocalizationTable.DevelopmentLanguage` | property | yes | This item has been superseded by `LocalizationTable.SourceLocaleId` which should be used in all new work. |
| `LocalizationTable:GetContents` | method | yes | This item has been superseded by `Class.LocalizationTable:GetEntries()` which should be used in all new work. |
| `LocalizationTable:GetString` | method | yes | This item has been superseded by `Class.LocalizationTable:GetTranslator()` which should be used in all new work. |
| `LocalizationTable:RemoveKey` | method | yes | This item has been superseded by `Class.LocalizationTable:RemoveEntry()` which should be used in all new work |
| `LocalizationTable.Root` | property |  | This item is deprecated. |
| `LocalizationTable:SetContents` | method | yes | This item has been superseded by `Class.LocalizationTable:SetEntries()` which should be used in all new work |
| `LocalizationTable:SetEntry` | method | yes | This item has been superseded by `Class.LocalizationTable:SetEntries()` which should be used in all new work. |
| `collectgarbage` | global | yes | — |
| `getfenv` | global | yes | This function allows uncontrolled change of the global/function environment and disables script optimizations. |
| `setfenv` | global | yes | This function allows uncontrolled change of the global/function environment and disables script optimizations. |
| `MarketplaceService:GetProductInfo` | method | yes | This method has been superseded by `GetProductInfoAsync()`. |
| `MarketplaceService:PlayerOwnsAsset` | method | yes | This method has been superseded by `Class.MarketplaceService:PlayerOwnsAssetAsync()|PlayerOwnsAssetAsync()`. |
| `MarketplaceService:PlayerOwnsBundle` | method | yes | This method has been superseded by `Class.MarketplaceService:PlayerOwnsBundleAsync()|PlayerOwnsBundleAsync()`. |
| `MarketplaceService:PromptPremiumPurchase` | method | yes | This method has been superseded by `Class.MarketplaceService:PromptRobloxSubscriptionPurchase()|PromptRobloxSubscriptionPurchase()`. |
| `MeshPart.HasJointOffset` | property | yes | This property is deprecated and should not be used in new work. |
| `MeshPart.JointOffset` | property | yes | This property is deprecated and should not be used in new work. |
| `Message.Text` | property |  | `Messages` and `Hints` have been deprecated; `TextLabels` should be used instead in new work. |
| `Model:BreakJoints` | method |  | — |
| `Model:GetModelCFrame` | method | yes | This function has been deprecated as it did not provide reliable results. |
| `Model:GetModelSize` | method | yes | This item is deprecated. |
| `Model:GetPrimaryPartCFrame` | method | yes | — |
| `Model:MakeJoints` | method |  | This joint type has been deprecated. |
| `Model:ResetOrientationToIdentity` | method | yes | This function has been deprecated; it remains to prevent legacy scripts from throwing errors, but it does nothing when called. |
| `Model:SetIdentityOrientation` | method | yes | This function has been deprecated; it remains to prevent legacy scripts from throwing errors, but it does nothing when called. |
| `Model:SetPrimaryPartCFrame` | method | yes | — |
| `Model:breakJoints` | method |  | This deprecated function is a variant of `Class.Model:BreakJoints()` which should be used instead. |
| `Model:makeJoints` | method |  | This deprecated function is a variant of `Class.Model:MakeJoints()` which should be used instead. |
| `Model:move` | method |  | This item has been superseded by `Class.Model:MoveTo()` which should be used in all new work |
| `Model:moveTo` | method |  | This deprecated function is a variant of `Class.Model:MoveTo()` which should be used instead. |
| `ModuleScript.LinkedSource` | property |  | This property is now replaced by packages which has greater functionality. |
| `Mouse.KeyDown` | event | yes | Mouse events have been superseded by `UserInputService` which should be used in all new work. |
| `Mouse.KeyUp` | event | yes | Mouse events have been superseded by `UserInputService` which should be used in all new work. |
| `Mouse.hit` | property |  | This property is a deprecated variant of `Mouse.Hit` which should be used instead. |
| `Mouse.keyDown` | event | yes | This event is a deprecated variant of `Mouse.KeyDown` which has also been deprecated. |
| `Mouse.target` | property |  | This property is a deprecated variant of `Mouse.Target` which should be used instead. |
| `NumberValue.changed` | event |  | This event is a deprecated variant of `NumberValue.Changed` which should be used instead. |
| `Object.className` | property | yes | This deprecated property is a variant of `Object.ClassName` which should be used instead. |
| `Object:isA` | method |  | This deprecated function is a variant of `Class.Object:IsA()` which should be used instead. |
| `ObjectValue.changed` | event |  | This event is a deprecated variant of `ObjectValue.Changed` which should be used instead. |
| `OpenCloudApiV1:CreateModel` | method | yes | This method is deprecated. |
| `OpenCloudApiV1:CreateUserNotificationAsync` | method | yes | This method is deprecated. |
| `OpenCloudService:GetApiV1` | method | yes | This method is deprecated. |
| `OpenCloudService:InvokeAsync` | method | yes | This method is deprecated. |
| `ParticleEmitter.VelocitySpread` | property | yes | This property has been superseded by `ParticleEmitter.SpreadAngle` which should be used in all new work. |
| `Path:CheckOcclusionAsync` | method | yes | This function has been superseded by the `Blocked` event which you can connect to a `Path` object and should be used instead. |
| `Path:GetPointCoordinates` | method | yes | This item has been superseded by `Class.Path:GetWaypoints()|GetWaypoints()` which should be used in all new work instead. |
| `PathfindingService:ComputeRawPathAsync` | method | yes | This item has been superseded by `Class.PathfindingService:FindPathAsync()` which should be used in all new work instead. |
| `PathfindingService:ComputeSmoothPathAsync` | method | yes | This item has been superseded by `Class.PathfindingService:FindPathAsync()` which should be used in all new work instead. |
| `PathfindingService.EmptyCutoff` | property | yes | This property is deprecated, since the legacy pathfinding system using it has since been removed. |
| `PathfindingService:FindPathAsync` | method | yes | This function has been superseded by the sequential method of calling `Class.PathfindingService:CreatePath()` followed by `Class.Path:ComputeAsync()|Path`. |
| `PhysicsService:CollisionGroupContainsPart` | method | yes | This method has been deprecated. |
| `PhysicsService:CollisionGroupSetCollidable` | method |  | This method has been superseded by `Class.WorldRoot:CollisionGroupSetCollidable()` which should be used for all new work. |
| `PhysicsService:CollisionGroupsAreCollidable` | method |  | This method has been superseded by `Class.WorldRoot:CollisionGroupsAreCollidable()` which should be used for all new work. |
| `PhysicsService:CreateCollisionGroup` | method | yes | This method has been superseded by `Class.WorldRoot:RegisterCollisionGroup()|RegisterCollisionGroup()` which should be used for all new work. |
| `PhysicsService:GetCollisionGroupId` | method | yes | This method has been deprecated. |
| `PhysicsService:GetCollisionGroupName` | method | yes | This method has been deprecated. |
| `PhysicsService:GetCollisionGroups` | method | yes | This method has been superseded by `Class.WorldRoot:GetRegisteredCollisionGroups()|GetRegisteredCollisionGroups()` which should be used for all new work. |
| `PhysicsService:GetMaxCollisionGroups` | method |  | This method has been superseded by `Class.WorldRoot:GetMaxCollisionGroups()` which should be used for all new work. |
| `PhysicsService:GetRegisteredCollisionGroups` | method |  | This method has been superseded by `Class.WorldRoot:GetRegisteredCollisionGroups()` which should be used for all new work. |
| `PhysicsService:IsCollisionGroupRegistered` | method |  | This method has been superseded by `Class.WorldRoot:IsCollisionGroupRegistered()` which should be used for all new work. |
| `PhysicsService:RegisterCollisionGroup` | method |  | This method has been superseded by `Class.WorldRoot:RegisterCollisionGroup()` which should be used for all new work. |
| `PhysicsService:RemoveCollisionGroup` | method | yes | This method has been superseded by `Class.WorldRoot:UnregisterCollisionGroup()|UnregisterCollisionGroup()` which should be used for all new work. |
| `PhysicsService:RenameCollisionGroup` | method |  | This method has been superseded by `Class.WorldRoot:RenameCollisionGroup()` which should be used for all new work. |
| `PhysicsService:SetPartCollisionGroup` | method | yes | This method has been deprecated. |
| `PhysicsService:UnregisterCollisionGroup` | method |  | This method has been superseded by `Class.WorldRoot:UnregisterCollisionGroup()` which should be used for all new work. |
| `Player.CharacterAppearance` | property | yes | This item is deprecated. |
| `Player.DataComplexity` | property | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player.DataReady` | property | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player:GetFriendsOnline` | method | yes | This method has been superseded by `Class.Player:GetFriendsOnlineAsync()|GetFriendsOnlineAsync()`. |
| `Player:GetRankInGroup` | method | yes | This method has been superseded by `Class.Player:GetRankInGroupAsync()|GetRankInGroupAsync()`. |
| `Player:GetRankInGroupAsync` | method | yes | This method returns only the rank value of the member's highest public role. |
| `Player:GetRoleInGroup` | method | yes | This method has been superseded by `GetRoleInGroup()`. |
| `Player:GetRoleInGroupAsync` | method | yes | This method returns only the member's highest public role. |
| `Player:IsBestFriendsWith` | method | yes | This function is obsolete because the "best friends" feature was removed. |
| `Player:IsFriendsWith` | method | yes | This method has been superseded by the `Class.Player:IsFriendsWithAsync()` method which should be used for new work. |
| `Player:IsInGroup` | method | yes | This method has been superseded by `IsInGroupAsync()`. |
| `Player:LoadBoolean` | method | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player:LoadCharacter` | method | yes | This method has been superseded by `Class.Player:LoadCharacterAsync()|LoadCharacterAsync()`. |
| `Player:LoadCharacterAppearance` | method |  | This method is deprecated. |
| `Player:LoadCharacterWithHumanoidDescription` | method | yes | This method has been superseded by `Class.Player:LoadCharacterWithHumanoidDescriptionAsync()|LoadCharacterWithHumanoidDescriptionAsync()`. |
| `Player:LoadInstance` | method | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player:LoadNumber` | method | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player:LoadString` | method | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player.MembershipType` | property | yes | This property is deprecated. |
| `Player:SaveBoolean` | method | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player:SaveInstance` | method | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player:SaveNumber` | method | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player:SaveString` | method | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player:WaitForDataReady` | method | yes | This item is deprecated, as it may have been used for a now obsolete data persistence method. |
| `Player:isFriendsWith` | method | yes | This method has been superseded by the `Class.Player:IsFriendsWithAsync()` method which should be used for new work. |
| `Player:loadBoolean` | method | yes | This deprecated function is a variant of `Class.Player:LoadBoolean()` which has also been deprecated. |
| `Player:loadInstance` | method | yes | This deprecated function is a variant of `Class.Player:LoadInstance()` which has also been deprecated. |
| `Player:loadNumber` | method | yes | This deprecated function is a variant of `Class.Player:LoadNumber()` which has also been deprecated. |
| `Player:loadString` | method | yes | This function is a deprecated variant of `Class.Player:LoadString()` which has also been deprecated. |
| `Player:saveBoolean` | method | yes | This function is a deprecated variant of `Class.Player:SaveBoolean()` which has also been deprecated. |
| `Player:saveInstance` | method | yes | This function is a deprecated variant of `Class.Player:SaveInstance()` which has also been deprecated. |
| `Player:saveNumber` | method | yes | This function is a deprecated variant of `Class.Player:SaveNumber()` which has also been deprecated. |
| `Player:saveString` | method | yes | This function is a deprecated variant of `Class.Player:SaveString()` which has also been deprecated. |
| `Player.userId` | property | yes | This property is a deprecated variant of `Player.UserId` which should be used instead. |
| `Player:waitForDataReady` | method | yes | This function is a deprecated variant of `Class.Player:WaitForDataReady()` which has also been deprecated. |
| `PlayerGui:GetTopbarTransparency` | method | yes | — |
| `PlayerGui:SetTopbarTransparency` | method | yes | — |
| `PlayerGui.TopbarTransparencyChangedSignal` | event | yes | — |
| `Players:CreateHumanoidModelFromDescription` | method | yes | This method has been superseded by `Class.Players:CreateHumanoidModelFromDescriptionAsync()|CreateHumanoidModelFromDescriptionAsync()`. |
| `Players:CreateHumanoidModelFromUserId` | method | yes | This method has been superseded by `Class.Players:CreateHumanoidModelFromUserIdAsync()|CreateHumanoidModelFromUserIdAsync()`. |
| `Players:GetCharacterAppearanceAsync` | method | yes | This method is deprecated. |
| `Players:GetHumanoidDescriptionFromOutfitId` | method | yes | This method has been superseded by `Class.Players:GetHumanoidDescriptionFromOutfitIdAsync()|GetHumanoidDescriptionFromOutfitIdAsync()`. |
| `Players:GetHumanoidDescriptionFromUserId` | method | yes | This method has been superseded by `GetHumanoidDescriptionFromUserIdAsync()`. |
| `Players.NumPlayers` | property | yes | This item is deprecated. |
| `Players:getPlayers` | method | yes | This function is a deprecated variant of `Class.Players:GetPlayers()` which should be used instead. |
| `Players.localPlayer` | property | yes | This property is a deprecated variant of `Players.LocalPlayer` which should be used instead. |
| `Players.numPlayers` | property | yes | This property is a deprecated variant of `Players.NumPlayers` which has also been deprecated. |
| `Players:playerFromCharacter` | method | yes | This function is a deprecated variant of `Class.Players:GetPlayerFromCharacter()` which should be used in new work. |
| `Players:players` | method | yes | This item has been superseded by `Class.Players:GetPlayers()` which should be used in all new work. |
| `PointsService:AwardPoints` | method | yes | This function was once part of the `PointService` class used to control an ancient achievement system since removed and deprecated. |
| `PointsService:GetAwardablePoints` | method | yes | This function was once part of the `PointService` class used to control an ancient achievement system since removed and deprecated. |
| `PointsService:GetGamePointBalance` | method | yes | This function was once part of the `PointService` class used to control an ancient achievement system since removed and deprecated. |
| `PointsService:GetPointBalance` | method | yes | This function was once part of the `PointService` class used to control an ancient achievement system since removed and deprecated. |
| `PointsService.PointsAwarded` | event | yes | This function was once part of the `PointService` class used to control an ancient achievement system since removed and deprecated. |
| `Pose.MaskWeight` | property | yes | This property is deprecated. |
| `PoseBase.Weight` | property |  | This property is deprecated. |
| `RayValue.changed` | event |  | This event is a deprecated variant of `RayValue.Changed` which should be used instead. |
| `DebuggerManager` | global | yes | The `DebuggerManager` is obsolete and serves little to no use case for developers. |
| `delay` | global |  | This method has been superseded by `Library.task.delay()` and should not be used for future work. |
| `elapsedTime` | global | yes | — |
| `printidentity` | global | yes | — |
| `spawn` | global |  | This method has been superseded by `Library.task.spawn()` and should not be used for future work. |
| `stats` | global | yes | — |
| `version` | global | yes | — |
| `wait` | global |  | This method has been superseded by `Library.task.wait()` and should not be used for future work. |
| `ypcall` | global | yes | — |
| `RocketPropulsion:Abort` | method | yes | — |
| `RocketPropulsion.CartoonFactor` | property | yes | — |
| `RocketPropulsion:Fire` | method |  | — |
| `RocketPropulsion.MaxSpeed` | property |  | — |
| `RocketPropulsion.MaxThrust` | property | yes | — |
| `RocketPropulsion.MaxTorque` | property |  | — |
| `RocketPropulsion.ReachedTarget` | event |  | — |
| `RocketPropulsion.Target` | property |  | — |
| `RocketPropulsion.TargetOffset` | property | yes | — |
| `RocketPropulsion.TargetRadius` | property | yes | — |
| `RocketPropulsion.ThrustD` | property | yes | — |
| `RocketPropulsion.ThrustP` | property | yes | — |
| `RocketPropulsion.TurnD` | property | yes | — |
| `RocketPropulsion.TurnP` | property | yes | — |
| `RocketPropulsion:fire` | method |  | This function is a deprecated variant of `Class.RocketPropulsion:Fire()` which should be used instead. |
| `RunService:Reset` | method |  | This item is deprecated and should not be used in new work. |
| `ScreenshotHud.ExperienceNameOverlayEnabled` | property | yes | This property is deprecated. |
| `ScreenshotHud.OverlayFont` | property | yes | This property is deprecated. |
| `ScreenshotHud.UsernameOverlayEnabled` | property | yes | This property is deprecated. |
| `SensorBase:Sense` | method |  | This method should not be used in new work. |
| `ServiceProvider:getService` | method | yes | This deprecated function is a variant of `Class.ServiceProvider:GetService()` which should be used instead. |
| `ServiceProvider:service` | method | yes | This item has been superseded by `Class.ServiceProvider:GetService()` which should be used in all new work. |
| `SkateboardPlatform:ApplySpecificImpulse` | method | yes | The SkateboardPlatform object has been deprecated and is no longer supported by Roblox. |
| `SkateboardPlatform.Controller` | property | yes | The SkateboardPlatform object has been deprecated and is no longer supported by Roblox. |
| `SkateboardPlatform.ControllingHumanoid` | property | yes | The SkateboardPlatform object has been deprecated and is no longer supported by Roblox. |
| `SkateboardPlatform.Equipped` | event |  | The SkateboardPlatform object has been deprecated and is no longer supported by Roblox. |
| `SkateboardPlatform.MoveStateChanged` | event | yes | The SkateboardPlatform object has been deprecated and is no longer supported by Roblox. |
| `SkateboardPlatform.Steer` | property |  | The SkateboardPlatform object has been deprecated and is no longer supported by Roblox. |
| `SkateboardPlatform.StickyWheels` | property | yes | The SkateboardPlatform object has been deprecated and is no longer supported by Roblox. |
| `SkateboardPlatform.Throttle` | property |  | The SkateboardPlatform object has been deprecated and is no longer supported by Roblox. |
| `SkateboardPlatform.Unequipped` | event |  | The SkateboardPlatform object has been deprecated and is no longer supported by Roblox. |
| `SkateboardPlatform.equipped` | event |  | This deprecated event is a variant of `SkateboardPlatform.Equipped` which has also been deprecated. |
| `SkateboardPlatform.unequipped` | event |  | This deprecated event is a variant of `SkateboardPlatform.Unequipped` which has also been deprecated. |
| `Skin.SkinColor` | property | yes | This object has been deprecated and superseded by `BodyColors`. |
| `SlidingBallConstraint.SoftlockServoUponReachingTarget` | property |  | This property should not be used in new work. |
| `SocialService:PromptLinkSharing` | method | yes | Use `Class.SocialService:PromptLinkSharingAsync()|PromptLinkSharingAsync()` instead. |
| `Sound.EmitterSize` | property | yes | This property has deprecated in favor of `Sound.RollOffMinDistance` and `Sound.RollOffMaxDistance` which should be used instead in new work. |
| `Sound.MaxDistance` | property |  | This property has deprecated in favor of `Sound.RollOffMinDistance` and `Sound.RollOffMaxDistance` which should be used instead in new work. |
| `Sound.MinDistance` | property | yes | MinDistance has been superseded by `Sound.EmitterSize`, whose name better describes this properties behavior. |
| `Sound.Pitch` | property |  | This property has been deprecated in favor of `Sound.PlaybackSpeed` whose name suits the behavior better. |
| `Sound.isPlaying` | property | yes | This deprecated property is a variant of `Sound.IsPlaying` which should be used instead. |
| `Sound:pause` | method | yes | This deprecated function is a variant of `Class.Sound:Pause()` which should be used instead. |
| `Sound:play` | method | yes | This deprecated function is a variant of `Class.Sound:Play()` which should be used instead. |
| `Sound:stop` | method | yes | This deprecated function is a variant of `Class.Sound:Stop()` which should be used instead. |
| `Sparkles.Color` | property |  | This property is deprecated in favor of `Sparkles.SparkleColor`, which does the exact same thing. |
| `StarterGui.ResetPlayerGuiOnSpawn` | property | yes | This property is deprecated. |
| `Stats.HeartbeatTimeMs` | property | yes | Use `Stats.HeartbeatTime` instead. |
| `Stats.PhysicsStepTimeMs` | property | yes | Use `Stats.PhysicsStepTime` instead. |
| `StringValue.changed` | event |  | This deprecated event is a variant of `StringValue.Changed` which should be used instead. |
| `Team.AutoColorCharacters` | property | yes | This property is deprecated and no longer functions, it should not be used for new work. |
| `Team.Score` | property |  | This property is deprecated and should not be used in new work. |
| `Teams:RebalanceTeams` | method | yes | This function has been deprecated and no longer functions correctly. |
| `TeleportOptions.ReservedServerAccessCode` | property |  | Use `TeleportOptions.ReservedServerId` with a developer-generated GUID and `Class.TeleportService:TeleportAsync()` instead. |
| `TeleportOptions.ShouldReserveServer` | property | yes | Use `TeleportOptions.ReservedServerId` with a developer-generated GUID and `Class.TeleportService:TeleportAsync()` instead. |
| `TeleportService.CustomizedTeleportUI` | property | yes | This item is deprecated since the default message it controls has been removed. |
| `TeleportService:ReserveServer` | method | yes | Use `Class.TeleportService:TeleportAsync()|TeleportAsync()` with `TeleportOptions.ReservedServerId` instead. |
| `TeleportService:ReserveServerAsync` | method | yes | Use `Class.TeleportService:TeleportAsync()|TeleportAsync()` with `TeleportOptions.ReservedServerId` instead. |
| `TeleportService:Teleport` | method | yes | Use `Class.TeleportService:TeleportAsync()|TeleportAsync()` for server-side teleports. |
| `TeleportService:TeleportPartyAsync` | method | yes | Use `Class.TeleportService:TeleportAsync()|TeleportAsync()` instead. |
| `TeleportService:TeleportToPlaceInstance` | method | yes | Use `Class.TeleportService:TeleportAsync()|TeleportAsync()` instead. |
| `TeleportService:TeleportToPrivateServer` | method | yes | Use `Class.TeleportService:TeleportAsync()|TeleportAsync()` with `TeleportOptions.ReservedServerId` instead. |
| `TeleportService:TeleportToSpawnByName` | method | yes | Use `Class.TeleportService:TeleportAsync()|TeleportAsync()` instead. |
| `Terrain:AutowedgeCell` | method | yes | This item is a deprecated function of a legacy `Terrain` engine that has been removed. |
| `Terrain:AutowedgeCells` | method | yes | This item is a deprecated function of a legacy `Terrain` engine that has been removed. |
| `Terrain:ConvertToSmooth` | method | yes | Since all places now automatically use the new terrain engine, this method is obsolete. |
| `Terrain:GetCell` | method | yes | This item is a deprecated function of a legacy `Terrain` engine that has been removed. |
| `Terrain:GetWaterCell` | method | yes | This item is a deprecated function of a legacy `Terrain` engine that has been removed. |
| `Terrain.IsSmooth` | property | yes | The legacy terrain engine has been removed, so this property will always be `true`. |
| `Terrain:SetCell` | method | yes | This item is a deprecated function of a legacy `Terrain` engine that has been removed. |
| `Terrain:SetCells` | method | yes | This item is a deprecated function of a legacy `Terrain` engine that has been removed. |
| `Terrain:SetWaterCell` | method | yes | This item is a deprecated function of a legacy `Terrain` engine that has been removed. |
| `TerrainRegion:ConvertToSmooth` | method |  | This item is a deprecated function of a legacy `Terrain` engine that has been removed. |
| `TerrainRegion.IsSmooth` | property |  | This item is a deprecated function of a legacy `Terrain` engine that has been removed. |
| `TextBox.FontSize` | property | yes | This item has been superseded by `TextBox.TextSize` which should be used in all new work. |
| `TextBox.TextColor` | property | yes | This item has been superseded by `TextBox.TextColor3` which should be used in all new work. |
| `TextBox.TextWrap` | property | yes | This item has been superseded by `TextBox.TextWrapped` which should be used in all new work. |
| `TextButton.FontSize` | property |  | This property is deprecated in favor of `TextSize` which is an integer and not an enum and thus offers far more options for sizes. |
| `TextButton.TextColor` | property |  | This item has been superseded by `TextButton.TextColor3` which should be used in all new work. |
| `TextButton.TextWrap` | property |  | This item has been superseded by `TextButton.TextWrapped` which should be used in all new work. |
| `TextChatService.ChatVersion` | property | yes | This property has been deprecated in newly created Studio experiences. |
| `TextFilterResult:GetChatForUserAsync` | method | yes | This method is deprecated and returns an empty string. |
| `TextLabel.FontSize` | property |  | This property is deprecated in favor of `TextSize` which is an integer and not an enum and thus offers far more options for sizes. |
| `TextLabel.TextColor` | property |  | This item has been superseded by `TextLabel.TextColor3` which should be used in all new work. |
| `TextLabel.TextWrap` | property |  | This property is simply an alias for `TextWrapped`. |
| `TextService:FilterAndTranslateStringAsync` | method | yes | This method is no longer supported and should not be used. |
| `TorsionSpringConstraint.LimitEnabled` | property | yes | This property is deprecated. |
| `UIGridStyleLayout:ApplyLayout` | method | yes | — |
| `UIGridStyleLayout:SetCustomSortFunction` | method | yes | This method is deprecated in favor of using other SortOrder means, such as by Name or LayoutOrder. |
| `UserGameSettings.ControlMode` | property | yes | This property has been deprecated. |
| `UserInputService:GetUserCFrame` | method |  | Use `Class.VRService:GetUserCFrame()` instead. |
| `UserInputService.ModalEnabled` | property | yes | This item has been superseded by `GuiService.TouchControlsEnabled` which should be used in all new work. |
| `UserInputService.UserCFrameChanged` | event |  | Use `VRService.UserCFrameChanged` instead. |
| `UserInputService.UserHeadCFrame` | property | yes | This item has been superseded by `Class.UserInputService:GetUserCFrame()` which should be used in all new work. |
| `UserInputService.VREnabled` | property |  | This property has been superseded by `VRService.VREnabled` which should be used in all new work. |
| `Vector3Value.changed` | event |  | This deprecated event is a variant of `Vector3Value.Changed` which should be used instead. |
| `VehicleSeat.Steer` | property |  | This property is no longer replicated and has been deprecated in favor of `SteerFloat` which is a float variant and should be used instead. |
| `VehicleSeat.Throttle` | property |  | This property is not longer replicated and has been deprecated in favor of `ThrottleFloat` which is a float variant and should be used instead. |
| `Workspace:BreakJoints` | method |  | This method is deprecated. |
| `Workspace.FilteringEnabled` | property | yes | This property is discontinued. |
| `Workspace.InterpolationThrottling` | property | yes | This property should not be used for new work. |
| `Workspace:MakeJoints` | method |  | This method is deprecated. |
| `WorldRoot:FindPartOnRay` | method | yes | This function has been deprecated. |
| `WorldRoot:FindPartOnRayWithIgnoreList` | method | yes | This function has been deprecated. |
| `WorldRoot:FindPartOnRayWithWhitelist` | method | yes | This function has been deprecated. |
| `WorldRoot:FindPartsInRegion3` | method | yes | This function has been deprecated. |
| `WorldRoot:FindPartsInRegion3WithIgnoreList` | method | yes | This function has been deprecated. |
| `WorldRoot:FindPartsInRegion3WithWhiteList` | method | yes | This function has been deprecated. |
| `WorldRoot:IsRegion3Empty` | method | yes | This function has been deprecated. |
| `WorldRoot:IsRegion3EmptyWithIgnoreList` | method | yes | This function has been deprecated. |
| `WorldRoot:findPartOnRay` | method | yes | This deprecated function is a variant of `Class.WorldRoot:FindPartOnRay()` which should be used instead. |
| `WorldRoot:findPartsInRegion3` | method | yes | This deprecated function is a variant of `Class.WorldRoot:FindPartsInRegion3()` which should be used instead. |
| `WrapLayer.Puffiness` | property |  | — |
| `WrapLayer.ShrinkFactor` | property |  | — |
| `WrapTarget.Stiffness` | property |  | — |
| `table.foreach` | function | yes | — |
| `table.foreachi` | function | yes | — |
| `table.getn` | function | yes | — |
