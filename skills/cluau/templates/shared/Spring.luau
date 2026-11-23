--!strict
--[[
	Spring — damped harmonic motion for UI (pure; unit-tested with Lune).
	Location: ReplicatedStorage/Shared/Spring (ModuleScript)

	Why designers prefer springs over fixed tweens: motion keeps its velocity when the target changes mid-way
	(hover → press → release feels continuous), and one "personality" (frequency + damping) gives a whole UI a
	consistent feel. Theme presets define it (bouncy: damping ≈ 0.55, precise/instant: 1.0 = no overshoot).

	local s = Spring.new(1, 5, 0.6)   -- start value, frequency (Hz), damping ratio
	s:setTarget(0.96)
	-- every frame: local value = s:step(dt)
]]

local Spring = {}
Spring.__index = Spring

export type Spring = typeof(setmetatable({} :: {
	position: number,
	velocity: number,
	target: number,
	frequency: number,
	damping: number,
}, Spring))

function Spring.new(initial: number, frequency: number, damping: number): Spring
	assert(frequency > 0, "frequency must be > 0")
	assert(damping >= 0, "damping must be >= 0")
	return setmetatable({
		position = initial,
		velocity = 0,
		target = initial,
		frequency = frequency,
		damping = damping,
	}, Spring)
end

function Spring.setTarget(self: Spring, target: number)
	self.target = target
end

--- Jumps to `value` with no motion (use for Reduced Motion or initial layout).
function Spring.snap(self: Spring, value: number)
	self.position = value
	self.target = value
	self.velocity = 0
end

--- True when close enough to the target to stop updating.
function Spring.isSettled(self: Spring, epsilon: number?): boolean
	local e = epsilon or 1e-3
	return math.abs(self.position - self.target) < e and math.abs(self.velocity) < e
end

--- Advances the simulation. Sub-steps keep it stable for long frames (e.g. a hitch of 0.2 s).
function Spring.step(self: Spring, dt: number): number
	local omega = 2 * math.pi * self.frequency
	local remaining = math.clamp(dt, 0, 0.5)
	while remaining > 0 do
		local h = math.min(remaining, 1 / 240)
		-- semi-implicit Euler on x'' = -ω²(x - target) - 2ζω x'
		local acceleration = -omega * omega * (self.position - self.target) - 2 * self.damping * omega * self.velocity
		self.velocity += acceleration * h
		self.position += self.velocity * h
		remaining -= h
	end
	return self.position
end

return Spring
