--!strict
--[[
	Guard — validation helpers for untrusted (client-sent) values.
	Location: ReplicatedStorage/Shared/Guard (ModuleScript)

	All functions accept `unknown` and return booleans so handlers read top-to-bottom:

		if not Guard.string(itemId, 32) then return end
		if not Guard.integer(amount, 1, 99) then return end
]]

local Guard = {}

function Guard.finite(value: unknown): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Guard.number(value: unknown, min: number, max: number): boolean
	if not Guard.finite(value) then
		return false
	end
	local n = value :: number
	return n >= min and n <= max
end

function Guard.integer(value: unknown, min: number, max: number): boolean
	return Guard.number(value, min, max) and (value :: number) % 1 == 0
end

function Guard.boolean(value: unknown): boolean
	return typeof(value) == "boolean"
end

--- String with 1..maxLength UTF-8 characters (invalid UTF-8 rejected).
function Guard.string(value: unknown, maxLength: number): boolean
	if typeof(value) ~= "string" then
		return false
	end
	local length = utf8.len(value :: string)
	return length ~= nil and length >= 1 and length <= maxLength
end

--- Value must be a key of `allowed` (e.g. a frozen config table of item ids).
function Guard.oneOf(value: unknown, allowed: { [string]: any }): boolean
	return typeof(value) == "string" and allowed[value :: string] ~= nil
end

function Guard.vector3(value: unknown, maxMagnitude: number): boolean
	if typeof(value) ~= "Vector3" then
		return false
	end
	local v = value :: Vector3
	return Guard.finite(v.X) and Guard.finite(v.Y) and Guard.finite(v.Z) and v.Magnitude <= maxMagnitude
end

--- Instance of `className` that is a descendant of `ancestor`.
function Guard.instanceIn(value: unknown, className: string, ancestor: Instance): boolean
	return typeof(value) == "Instance"
		and (value :: Instance):IsA(className)
		and (value :: Instance):IsDescendantOf(ancestor)
end

--- Returns the player's living HumanoidRootPart, or nil.
function Guard.aliveRoot(player: Player): BasePart?
	local character = player.Character
	if character == nil then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

--- True if the player's character is within `maxDistance` studs of `position`.
function Guard.near(player: Player, position: Vector3, maxDistance: number): boolean
	local root = Guard.aliveRoot(player)
	return root ~= nil and (root.Position - position).Magnitude <= maxDistance
end

return table.freeze(Guard)
