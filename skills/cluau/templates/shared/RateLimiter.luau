--!strict
--[[
	RateLimiter — token bucket per key (usually per Player).
	Location: ReplicatedStorage/Shared/RateLimiter (ModuleScript) — used by server code.

	local buyLimiter = RateLimiter.new(3, 1) -- burst 3, refill 1 token/second
	if not buyLimiter:check(player) then return end

	Buckets keyed by Player are removed automatically on PlayerRemoving.
]]

local Players = game:GetService("Players")

type Bucket = {
	tokens: number,
	updatedAt: number,
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiter = typeof(setmetatable({} :: {
	_capacity: number,
	_refillPerSecond: number,
	_buckets: { [any]: Bucket },
}, RateLimiter))

local allLimiters: { RateLimiter } = {}

function RateLimiter.new(capacity: number, refillPerSecond: number): RateLimiter
	assert(capacity >= 1, "capacity must be >= 1")
	assert(refillPerSecond > 0, "refillPerSecond must be > 0")
	local self = setmetatable({
		_capacity = capacity,
		_refillPerSecond = refillPerSecond,
		_buckets = {},
	}, RateLimiter)
	table.insert(allLimiters, self)
	return self
end

--- Consumes `cost` tokens (default 1). Returns true if allowed.
function RateLimiter.check(self: RateLimiter, key: any, cost: number?): boolean
	local amount = cost or 1
	local now = os.clock()
	local bucket = self._buckets[key]
	if bucket == nil then
		bucket = { tokens = self._capacity, updatedAt = now }
		self._buckets[key] = bucket
	else
		local elapsed = now - bucket.updatedAt
		bucket.tokens = math.min(self._capacity, bucket.tokens + elapsed * self._refillPerSecond)
		bucket.updatedAt = now
	end
	if bucket.tokens < amount then
		return false
	end
	bucket.tokens -= amount
	return true
end

function RateLimiter.reset(self: RateLimiter, key: any)
	self._buckets[key] = nil
end

Players.PlayerRemoving:Connect(function(player: Player)
	for _, limiter in allLimiters do
		limiter._buckets[player] = nil
	end
end)

return RateLimiter
