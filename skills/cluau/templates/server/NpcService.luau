--!strict
--[[
	NpcService — patrol / chase / return AI for every NPC in ONE throttled loop (not a script per NPC).
	Location: ServerScriptService/Services/NpcService (ModuleScript)

	Setup per NPC (a Model with Humanoid + HumanoidRootPart):
	  • Tag it "Npc" (CollectionService). Optional attributes: AggroRange (default 40), LoseRange (60),
	    Damage (10), AttackCooldown (1.2), AttackRange (5).
	  • Optional child Folder "Patrol" containing BaseParts as waypoints (visited in name order).

	Studio-grade choices:
	  • Decisions at 5 Hz, not per frame; path computations run on their own threads with a per-NPC busy flag.
	  • Path recomputed when blocked (Path.Blocked), when the target moved far, or every REPATH_SECONDS.
	  • Direct MoveTo when the target is close and visible (cheaper and smoother than a path).
	  • Server owns NPC physics (SetNetworkOwner(nil)) so exploiters can't fling or freeze them.
	  • Damage, range and cooldown are decided here on the server.
	  • Over ~30 moving Humanoid NPCs, switch to the client-rendered pattern (genre-playbooks.md, TD section).
]]

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local TAG = "Npc"
local TICK_SECONDS = 0.2
local REPATH_SECONDS = 1.5
local REPATH_TARGET_MOVED = 8
local DIRECT_CHASE_DISTANCE = 14
local WAYPOINT_REACHED = 3

type Mode = "Patrol" | "Chase" | "Return"

type Npc = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	home: Vector3,
	mode: Mode,
	target: Player?,
	waypoints: { PathWaypoint },
	waypointIndex: number,
	computing: boolean,
	requestId: number, -- bumped whenever plans change; late path results with an old id are dropped
	lastPathAt: number,
	lastGoal: Vector3?,
	patrolIndex: number,
	lastAttackAt: number,
	blockedConnection: RBXScriptConnection?,
}

local NpcService = {}

local npcs: { [Model]: Npc } = {}
local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude

local function attribute(model: Model, name: string, default: number): number
	local value = model:GetAttribute(name)
	return if typeof(value) == "number" and value == value then value else default
end

local function patrolPoints(model: Model): { BasePart }
	local folder = model:FindFirstChild("Patrol")
	local points = {}
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(points, child)
			end
		end
		table.sort(points, function(a, b)
			return a.Name < b.Name
		end)
	end
	return points
end

local function hasLineOfSight(npc: Npc, targetRoot: BasePart): boolean
	losParams.FilterDescendantsInstances = { npc.model, targetRoot.Parent :: Instance }
	local direction = targetRoot.Position - npc.root.Position
	return workspace:Raycast(npc.root.Position, direction, losParams) == nil
end

local function aliveRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function findTarget(npc: Npc): Player?
	local aggro = attribute(npc.model, "AggroRange", 40)
	local best, bestDistance = nil, aggro
	for _, player in Players:GetPlayers() do
		local root = aliveRoot(player)
		if root then
			local distance = (root.Position - npc.root.Position).Magnitude
			if distance < bestDistance and hasLineOfSight(npc, root) then
				best, bestDistance = player, distance
			end
		end
	end
	return best
end

-- Invalidate any in-flight path and clear the current one (call on every mode/goal change).
local function resetPlan(npc: Npc)
	npc.requestId += 1
	npc.waypoints = {}
end

local function requestPath(npc: Npc, goal: Vector3)
	if npc.computing then
		return
	end
	npc.computing = true
	local myRequest = npc.requestId
	npc.lastPathAt = os.clock()
	npc.lastGoal = goal
	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			WaypointSpacing = 4,
			Costs = { Water = 20 },
		})
		local ok = pcall(path.ComputeAsync, path, npc.root.Position, goal)
		npc.computing = false
		if npcs[npc.model] ~= npc or npc.requestId ~= myRequest then
			return -- NPC removed, or its mode/goal changed while computing: this path is stale
		end
		if npc.blockedConnection then
			npc.blockedConnection:Disconnect()
			npc.blockedConnection = nil
		end
		if not ok or path.Status ~= Enum.PathStatus.Success then
			npc.waypoints = {}
			return
		end
		npc.waypoints = path:GetWaypoints()
		npc.waypointIndex = 2 -- index 1 is the start position
		npc.blockedConnection = path.Blocked:Connect(function(blockedIndex: number)
			if blockedIndex >= npc.waypointIndex then
				npc.lastPathAt = 0 -- force a repath next tick
			end
		end)
	end)
end

local function followPath(npc: Npc)
	local waypoint = npc.waypoints[npc.waypointIndex]
	if waypoint == nil then
		return
	end
	if (waypoint.Position - npc.root.Position).Magnitude < WAYPOINT_REACHED then
		npc.waypointIndex += 1
		waypoint = npc.waypoints[npc.waypointIndex]
		if waypoint == nil then
			return
		end
	end
	if waypoint.Action == Enum.PathWaypointAction.Jump then
		npc.humanoid.Jump = true
	end
	npc.humanoid:MoveTo(waypoint.Position)
end

local function tryAttack(npc: Npc, targetRoot: BasePart)
	local now = os.clock()
	local range = attribute(npc.model, "AttackRange", 5)
	if now - npc.lastAttackAt < attribute(npc.model, "AttackCooldown", 1.2) then
		return
	end
	if (targetRoot.Position - npc.root.Position).Magnitude > range then
		return
	end
	local humanoid = (targetRoot.Parent :: Instance):FindFirstChildOfClass("Humanoid")
	if humanoid then
		npc.lastAttackAt = now
		humanoid:TakeDamage(attribute(npc.model, "Damage", 10))
	end
end

local function step(npc: Npc)
	if npc.humanoid.Health <= 0 then
		return
	end
	local now = os.clock()

	-- Target acquisition / loss.
	local targetRoot = if npc.target then aliveRoot(npc.target) else nil
	if npc.target and (targetRoot == nil or npc.target.Parent ~= Players
		or (targetRoot.Position - npc.root.Position).Magnitude > attribute(npc.model, "LoseRange", 60)) then
		npc.target = nil
		npc.mode = "Return"
		resetPlan(npc)
	end
	if npc.target == nil then
		local found = findTarget(npc)
		if found then
			npc.target = found
			npc.mode = "Chase"
			resetPlan(npc)
			targetRoot = aliveRoot(found)
		end
	end

	if npc.mode == "Chase" and targetRoot then
		local distance = (targetRoot.Position - npc.root.Position).Magnitude
		if distance < DIRECT_CHASE_DISTANCE and hasLineOfSight(npc, targetRoot) then
			resetPlan(npc)
			npc.humanoid:MoveTo(targetRoot.Position)
		else
			local moved = npc.lastGoal == nil or (targetRoot.Position - (npc.lastGoal :: Vector3)).Magnitude > REPATH_TARGET_MOVED
			if #npc.waypoints == 0 or now - npc.lastPathAt > REPATH_SECONDS or moved then
				requestPath(npc, targetRoot.Position)
			end
			followPath(npc)
		end
		tryAttack(npc, targetRoot)
		return
	end

	if npc.mode == "Return" then
		if (npc.home - npc.root.Position).Magnitude < WAYPOINT_REACHED * 2 then
			npc.mode = "Patrol"
			resetPlan(npc)
		elseif #npc.waypoints == 0 or now - npc.lastPathAt > REPATH_SECONDS * 2 then
			requestPath(npc, npc.home)
		end
		followPath(npc)
		return
	end

	-- Patrol
	local points = patrolPoints(npc.model)
	if #points == 0 then
		return
	end
	local point = points[(npc.patrolIndex - 1) % #points + 1]
	if (point.Position - npc.root.Position).Magnitude < WAYPOINT_REACHED * 2 then
		npc.patrolIndex += 1
		resetPlan(npc)
		return
	end
	if #npc.waypoints == 0 or now - npc.lastPathAt > REPATH_SECONDS * 3 then
		requestPath(npc, point.Position)
	end
	followPath(npc)
end

local pendingAncestry: { [Instance]: RBXScriptConnection } = {}

local function register(instance: Instance)
	if not instance:IsA("Model") or npcs[instance] then
		return
	end
	-- Tagged templates often live in ServerStorage: only simulate NPCs that are in the world,
	-- and register them later if they get moved into workspace.
	if not instance:IsDescendantOf(workspace) then
		if pendingAncestry[instance] == nil then
			pendingAncestry[instance] = instance.AncestryChanged:Connect(function()
				if instance:IsDescendantOf(workspace) then
					pendingAncestry[instance]:Disconnect()
					pendingAncestry[instance] = nil
					register(instance)
				elseif instance.Parent == nil then
					pendingAncestry[instance]:Disconnect()
					pendingAncestry[instance] = nil
				end
			end)
		end
		return
	end
	local humanoid = instance:FindFirstChildOfClass("Humanoid")
	local root = instance:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or root == nil or not root:IsA("BasePart") then
		warn(`[NpcService] {instance:GetFullName()} needs a Humanoid and a HumanoidRootPart`)
		return
	end
	local canSetOwner = root:CanSetNetworkOwnership() -- false for anchored/welded-to-anchored parts
	if canSetOwner then
		root:SetNetworkOwner(nil)
	end
	npcs[instance] = {
		model = instance,
		humanoid = humanoid,
		root = root,
		home = root.Position,
		mode = "Patrol",
		target = nil,
		waypoints = {},
		waypointIndex = 1,
		computing = false,
		requestId = 0,
		lastPathAt = 0,
		lastGoal = nil,
		patrolIndex = 1,
		lastAttackAt = 0,
		blockedConnection = nil,
	}
end

local function unregister(instance: Instance)
	local npc = npcs[instance :: Model]
	if npc then
		if npc.blockedConnection then
			npc.blockedConnection:Disconnect()
		end
		npcs[instance :: Model] = nil
	end
end

function NpcService.Init() end

function NpcService.Start()
	local function safeRegister(instance: Instance)
		local ok, err = pcall(register, instance)
		if not ok then
			warn(`[NpcService] failed to register {instance:GetFullName()}: {err}`)
		end
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(safeRegister)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(unregister)
	for _, instance in CollectionService:GetTagged(TAG) do
		safeRegister(instance)
	end
	task.spawn(function()
		while true do
			for model, npc in npcs do
				if not model:IsDescendantOf(workspace) then
					unregister(model)
					if model.Parent ~= nil and model:HasTag(TAG) then
						safeRegister(model) -- moved out of the world: wait for it to come back
					end
				else
					local ok, err = pcall(step, npc)
					if not ok then
						warn(`[NpcService] {model.Name}: {err}`)
					end
				end
			end
			task.wait(TICK_SECONDS)
		end
	end)
end

return NpcService
