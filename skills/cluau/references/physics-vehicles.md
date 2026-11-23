# Physics & Vehicles — Constraints, Ownership, Stability

> Last verified: 2026-11-23 against Roblox/creator-docs (Workspace physics properties, constraint classes, VehicleSeat).

## Contents
1. Assemblies, anchoring, sleep
2. Mover constraints (replace BodyMovers)
3. Mechanical constraints
4. Network ownership & Server Authority
5. Stepping and performance
6. Vehicles
7. Common mistakes

---

## 1. Assemblies, anchoring, sleep

- An **assembly** is parts rigidly joined (WeldConstraint/Motor6D); it moves as one body. `AssemblyMass`, `AssemblyLinearVelocity`, `AssemblyAngularVelocity`, `AssemblyRootPart`.
- Anchor everything static. Unanchored decoration costs simulation and replication.
- Resting assemblies sleep; waking many at once (explosions) spikes CPU — pool debris and clean it up.
- Mass: `CustomPhysicalProperties = PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)`; `Massless = true` on visual welded parts so they don't change handling.

## 2. Mover constraints (BodyMovers are deprecated)

| Goal | Constraint | Key properties |
|---|---|---|
| Hold a velocity | `LinearVelocity` | `VelocityConstraintMode` (Line/Plane/Vector), `VectorVelocity`, `MaxForce`, `RelativeTo` |
| Push with a force | `VectorForce` | `Force`, `RelativeTo`, `ApplyAtCenterOfMass` |
| Pull toward a point | `LineForce` | magnitude, `ReactionForceEnabled` |
| Reach a position | `AlignPosition` | `Mode` (OneAttachment for world target), `Responsiveness`, `MaxForce`, `MaxVelocity` |
| Reach an orientation | `AlignOrientation` | `Mode`, `Responsiveness`, `MaxTorque`, `PrimaryAxisOnly` |
| Spin | `AngularVelocity` | `AngularVelocity`, `MaxTorque`, `RelativeTo` |
| Torque | `Torque` | `Torque`, `RelativeTo` |

All need an `Attachment` (Attachment0). For one-off impulses use `BasePart:ApplyImpulse(impulse)` / `ApplyAngularImpulse` (on the owner's side).

## 3. Mechanical constraints

| Use | Constraint |
|---|---|
| Doors, wheels, flaps | `HingeConstraint` (`ActuatorType` None/Motor/Servo, `TargetAngle`, `AngularSpeed`, `ServoMaxTorque`, limits) |
| Pistons, elevators | `PrismaticConstraint` / `CylindricalConstraint` |
| Suspension | `SpringConstraint` (`Stiffness`, `Damping`, `FreeLength`) + `CylindricalConstraint` |
| Ropes, chains | `RopeConstraint`, `RodConstraint` |
| Ball joints, ragdolls | `BallSocketConstraint` |
| Characters (2026) | `AnimationConstraint` joints via `StarterPlayer.AvatarJointUpgrade` |

Weld static attachments with `WeldConstraint` (not `Weld` unless you need C0/C1).

## 4. Network ownership & Server Authority

- By default the engine gives ownership of unanchored assemblies near a player to that player — their client simulates it, and **an exploiter can move it anywhere**.
- `part:SetNetworkOwner(nil)` = server simulates (secure, adds input latency); `SetNetworkOwner(player)` for that player's own vehicle (responsive, server must sanity-check speed/position); `SetNetworkOwnershipAuto()` to restore defaults.
- Ownership can't be set on anchored parts; set it on the assembly root.
- Competitive physics games (sports balls, racing, combat movement): use **Server Authority** (`server-authority.md`) instead of hand-tuned ownership.

## 5. Stepping and performance

- `Workspace.PhysicsSteppingMethod`: `Fixed` (stable, highest rate) or `Adaptive` (assigns assemblies to lower rates when safe — often large CPU savings for big worlds). Choose per experience and profile.
- Collision cost: `CollisionFidelity` Box/Hull for small props; `CanCollide/CanTouch/CanQuery = false` on decoration; collision groups (`workspace:RegisterCollisionGroup`, `part.CollisionGroup`) to skip irrelevant pairs.
- Budget ~40–60 moving replicated assemblies per player view; beyond that, move visuals on clients.
- Moving many anchored parts: `workspace:BulkMoveTo` (or animate bone/Motor6D `Transform`).

## 6. Vehicles

Two proven builds:
1. **VehicleSeat + HingeConstraint motors**: read `Throttle`/`Steer` (or `ThrottleFloat`/`SteerFloat`) from the seat on the **owner's** side; drive wheel hinges (`ActuatorType = Motor`, `AngularVelocity`, `MotorMaxTorque`); steer with servo hinges. `MaxSpeed`, `Torque`, `TurnSpeed` on the seat for simple cars.
2. **Raycast/constraint controller**: a chassis with `VectorForce`/`LinearVelocity` + `AlignOrientation`, suspension from raycasts — more control, more code.

Ownership: give the driver network ownership when they sit (`Occupant` changed → owner = driver) for responsive handling, and validate on the server (speed, position deltas) — or use Server Authority. Remove ownership when they leave.

## 7. Common mistakes

| Mistake | Fix |
|---|---|
| BodyVelocity/BodyGyro/BodyPosition | Mover constraints (§2) |
| Setting `Velocity` / `RotVelocity` | `AssemblyLinearVelocity` / `AssemblyAngularVelocity` or `ApplyImpulse` |
| Physics-critical shared object client-owned | `SetNetworkOwner(nil)` or Server Authority |
| Constraint without Attachment | Add `Attachment0` (and `Attachment1` where needed) |
| Moving welded models with `CFrame` per part | `Model:PivotTo` once |
| Cosmetic parts unanchored and colliding | Anchor / weld + `Massless`, disable collisions/queries |
