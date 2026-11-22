--!strict
--[[
	Trove — minimal lifetime/cleanup helper.
	Location: ReplicatedStorage/Shared/Trove (ModuleScript)

	Usage:
		local trove = Trove.new()
		trove:Connect(part.Touched, onTouched)
		trove:Add(someInstance)              -- Destroy() on clean
		trove:Add(function() print("bye") end)
		trove:Add(tween)                      -- Cancel() on clean
		trove:AttachToInstance(character)     -- auto-clean when character is destroyed
		trove:Clean()
]]

type Cleanable = Instance | RBXScriptConnection | thread | Tween | () -> () | { Destroy: (any) -> () }

local Trove = {}
Trove.__index = Trove

export type Trove = typeof(setmetatable({} :: {
	_items: { Cleanable },
	_cleaning: boolean,
}, Trove))

function Trove.new(): Trove
	return setmetatable({
		_items = {},
		_cleaning = false,
	}, Trove)
end

local function cleanItem(item: Cleanable)
	local kind = typeof(item)
	if kind == "RBXScriptConnection" then
		(item :: RBXScriptConnection):Disconnect()
	elseif kind == "function" then
		(item :: () -> ())()
	elseif kind == "thread" then
		local thread = item :: thread
		if coroutine.status(thread) ~= "dead" then
			pcall(task.cancel, thread)
		end
	elseif kind == "Instance" then
		local inst = item :: Instance
		if inst:IsA("Tween") then
			(inst :: Tween):Cancel()
		end
		inst:Destroy()
	elseif kind == "table" then
		local obj = item :: { Destroy: (any) -> () }
		if type(obj.Destroy) == "function" then
			obj:Destroy()
		end
	end
end

--- Adds an item to be cleaned later. Returns the item for chaining.
function Trove.Add<T>(self: Trove, item: T): T
	if self._cleaning then
		error("Trove:Add called while cleaning", 2)
	end
	table.insert(self._items, item :: any)
	return item
end

--- Connects to a signal and tracks the connection.
function Trove.Connect(self: Trove, signal: RBXScriptSignal, fn: (...any) -> ()): RBXScriptConnection
	local connection = signal:Connect(fn)
	self:Add(connection)
	return connection
end

--- Creates a child Trove that is cleaned with this one.
function Trove.Extend(self: Trove): Trove
	local child = Trove.new()
	self:Add(function()
		child:Clean()
	end)
	return child
end

--- Cleans this trove automatically when `instance` is destroyed.
function Trove.AttachToInstance(self: Trove, instance: Instance)
	self:Connect(instance.Destroying, function()
		self:Clean()
	end)
end

--- Cleans every tracked item in reverse order of addition.
function Trove.Clean(self: Trove)
	if self._cleaning then
		return
	end
	self._cleaning = true
	local items = self._items
	for index = #items, 1, -1 do
		local ok, err = pcall(cleanItem, items[index])
		if not ok then
			warn(`[Trove] cleanup error: {err}`)
		end
		items[index] = nil
	end
	self._cleaning = false
end

Trove.Destroy = Trove.Clean

return Trove
