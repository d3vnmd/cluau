# NPC AI — Pathfinding, Behavior, Scale

> Last verified: 2026-11-23 against Roblox/creator-docs (PathfindingService, Path, PathfindingModifier, PathfindingLink, PathWaypoint). Template: `templates/server/NpcService.luau`.

## Contents
1. Choose the right movement model
2. PathfindingService the right way
3. Modifiers, links, costs
4. Behavior: patrol / chase / return / attack
5. Streaming and ownership
6. Scaling to many NPCs
7. Checklist

---

## 1. Choose the movement model

| NPC count / need | Model |
|---|---|
| A few smart NPCs (shopkeepers, bosses, horror monsters) | Humanoid + PathfindingService (NpcService template) |
| 10–30 enemies | Humanoids, one shared update loop at 5–10 Hz, simplified rigs, disabled unused Humanoid states |
| 30–1,000+ (tower defense, hordes, RTS) | **No server Humanoids**: plain server tables (position = f(spawnTime, path, speed)), clients render models (genre-playbooks.md, TD) |
| Vehicles / flying | Constraints (physics-vehicles.md), not Humanoids |

## 2. PathfindingService

```lua
local path = PathfindingService:CreatePath({
	AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentCanClimb = false,
	WaypointSpacing = 4,
	Costs = { Water = 20, DangerZone = math.huge }, -- materials or modifier labels
})
local ok = pcall(path.ComputeAsync, path, startPosition, goalPosition)
if ok and path.Status == Enum.PathStatus.Success then
	local waypoints = path:GetWaypoints() -- PathWaypoint: Position, Action (Walk/Jump/Custom), Label
end
```

Rules:
- `ComputeAsync` yields and can error → `pcall`, and never compute on the same thread as a loop that drives other NPCs (spawn a thread, keep a per-NPC busy flag).
- Check `path.Status`: `Success`, `ClosestNoPath`, `ClosestOutOfRange`, `NoPath`, `FailStartNotEmpty`, `FailFinishNotEmpty`.
- React to `path.Blocked(blockedWaypointIndex)` — repath only if the blocked index is ahead of the current one. Disconnect the old path's connection when you replace it.
- `Humanoid:MoveTo` times out after ~8 s; re-issue per waypoint and don't rely on `MoveToFinished` alone.
- Handle `Enum.PathWaypointAction.Jump` (`humanoid.Jump = true`) and `Custom` (from links — climbing, teleporters, boats).
- Don't recompute every frame: repath on a timer (1–2 s while chasing), when blocked, or when the goal moved far.
- Deprecated: `FindPathAsync`, `ComputeRawPathAsync`, `ComputeSmoothPathAsync`, `Path:GetPointCoordinates`.

## 3. Modifiers, links, costs

- **PathfindingModifier** in a part/region: `Label` (cost key, e.g. "DangerZone"), `PassThrough = true` for doors/foliage the agent may cross.
- **PathfindingLink** between two Attachments (`Attachment0/1`, `IsBidirectional`, `Label`) for jumps, ladders, teleporters; the waypoint arrives with `Action = Custom` and the link's `Label` — your code performs the special move.
- `Costs` lets designers steer AI ("avoid water", "prefer roads") without code changes.

## 4. Behavior

A small state machine beats ad-hoc `if`s:

| State | Enter when | Does | Leaves when |
|---|---|---|---|
| Patrol | spawn / returned home | walks tagged patrol points | target seen within AggroRange with line of sight |
| Chase | target acquired | direct `MoveTo` when close + visible, else path; repath on timer/blocked/target moved | target dead/left/out of LoseRange |
| Attack | in AttackRange | server-side cooldown + damage | out of range |
| Return | target lost | path home | home reached |

- Line of sight: `workspace:Raycast` from NPC to target with an Exclude filter for both characters.
- Damage, cooldowns and ranges are server-side constants/attributes — never from clients.
- Horror monsters: telegraph (sound/light) before attacks; leave escape routes; tune speed slightly under the player's sprint.

## 5. Streaming and ownership

- Server-simulated NPCs: `root:SetNetworkOwner(nil)` (unanchored parts) so clients can't fling or freeze them (outside Server Authority).
- With StreamingEnabled, clients may not have the NPC model; never put NPC logic in LocalScripts. For important NPCs (quest givers), use `ModelStreamingMode = Persistent` sparingly or Atomic.
- Clients only render effects (footsteps, VFX, health bars) from replicated state/attributes.

## 6. Scaling

- One loop for all NPCs (`for npc in npcs`) at 5 Hz decisions; physics/animation still run every frame.
- Stagger path computations across ticks; cap concurrent `ComputeAsync` calls.
- Disable unused Humanoid states (`SetStateEnabled`) for simple mobs; simplified rigs; `CanTouch/CanQuery` off on cosmetic parts.
- Spatial index (grid) for target search when there are many players/NPCs.
- Above ~30 moving Humanoids, switch to the client-rendered pattern.

## 7. Checklist

- [ ] `pcall` around `ComputeAsync`; `Status` checked; `Blocked` handled and disconnected on replace.
- [ ] One update loop, throttled; no per-NPC scripts.
- [ ] Server-owned physics; server-side damage/cooldowns.
- [ ] Repath conditions bounded (timer, blocked, goal moved).
- [ ] NPCs removed from the registry when destroyed (CollectionService InstanceRemoved).
