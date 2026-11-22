--!strict
--[[
	ModerationService — evidence log, strikes, delayed ban waves via Players:BanAsync.
	Location: ServerScriptService/Services/ModerationService (ModuleScript)

	Philosophy (big-studio practice):
	  • Validators reject bad input silently; they call ModerationService.Flag() with evidence.
	  • Low-confidence signals only accumulate strikes. High-confidence ones queue a ban.
	  • Bans are applied in delayed waves so cheaters can't tell which check caught them.
	  • Honeypot remotes only Flag(); they never respond.

	Usage from any validator:
		ModerationService.Flag(player, "SpeedHack", 3, `moved {dist} studs in {dt}s`)
		ModerationService.Flag(player, "HoneypotRemote", 10, "fired AdminGiveCoins")
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local STRIKE_THRESHOLD = 10 -- total weight that queues a ban
local WAVE_DELAY_SECONDS = 15 * 60 -- delay between detection and enforcement
local BAN_DURATION_SECONDS = 7 * 24 * 60 * 60 -- -1 for permanent
local MAX_EVIDENCE = 20
local DISPLAY_REASON = "Exploiting was detected on your account in this experience."

type Evidence = { reason: string, weight: number, detail: string, at: number }

local strikes: { [number]: { total: number, evidence: { Evidence } } } = {}
local banQueue: { [number]: number } = {} -- userId -> enforce at (os.time)

local ModerationService = {}

local function evidenceSummary(userId: number): string
	local entry = strikes[userId]
	if entry == nil then
		return ""
	end
	local parts = {}
	for _, item in entry.evidence do
		table.insert(parts, `{item.reason}({item.weight}): {item.detail}`)
	end
	-- PrivateReason is visible only to you in moderation tools; keep it short.
	return string.sub(table.concat(parts, " | "), 1, 900)
end

--- Records evidence. `weight` 1–3 = suspicious, 5 = strong, 10 = certain (e.g. honeypot).
function ModerationService.Flag(player: Player, reason: string, weight: number, detail: string)
	local userId = player.UserId
	local entry = strikes[userId]
	if entry == nil then
		entry = { total = 0, evidence = {} }
		strikes[userId] = entry
	end
	entry.total += math.clamp(weight, 0, 10)
	if #entry.evidence < MAX_EVIDENCE then
		table.insert(entry.evidence, { reason = reason, weight = weight, detail = string.sub(detail, 1, 120), at = os.time() })
	end
	warn(`[Moderation] {player.Name} ({userId}) {reason} +{weight} → {entry.total}: {detail}`)

	if entry.total >= STRIKE_THRESHOLD and banQueue[userId] == nil then
		banQueue[userId] = os.time() + WAVE_DELAY_SECONDS
	end
end

local function enforce(userId: number)
	if RunService:IsStudio() then
		warn(`[Moderation] (Studio) would ban {userId}: {evidenceSummary(userId)}`)
		return
	end
	local ok, err = pcall(function()
		Players:BanAsync({
			UserIds = { userId },
			ApplyToUniverse = true,
			Duration = BAN_DURATION_SECONDS,
			DisplayReason = DISPLAY_REASON,
			PrivateReason = evidenceSummary(userId),
			ExcludeAltAccounts = false,
		})
	end)
	if not ok then
		warn(`[Moderation] BanAsync failed for {userId}: {err}`)
		banQueue[userId] = os.time() + 60 -- retry later
		return
	end
	banQueue[userId] = nil
	strikes[userId] = nil
end

local function waveLoop()
	while true do
		task.wait(30)
		local now = os.time()
		-- Snapshot first: enforce() yields (BanAsync) and Flag() may add entries meanwhile.
		local due = {}
		for userId, enforceAt in banQueue do
			if now >= enforceAt then
				table.insert(due, userId)
			end
		end
		for _, userId in due do
			if banQueue[userId] then
				enforce(userId)
			end
		end
	end
end

function ModerationService.Init() end

function ModerationService.Start()
	task.spawn(waveLoop)
	-- Bans queued for players who already left are still enforced (BanAsync works by UserId).
	-- Keep strikes for the server's lifetime so rejoining doesn't reset evidence.
	game:BindToClose(function()
		local due = {}
		for userId in banQueue do
			table.insert(due, userId)
		end
		for _, userId in due do
			enforce(userId) -- enforce early rather than lose the evidence on shutdown
		end
	end)
end

return ModerationService
