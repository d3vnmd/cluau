--!strict
--[[
	AudioController — the 2024+ Audio API as a mixer: Music and SFX buses → compressor → your speakers,
	plus pooled 2D UI sounds and 3D world sounds. Volumes follow the player's saved settings.
	Location: StarterPlayer/StarterPlayerScripts/Controllers/AudioController (ModuleScript)

	Graph (built once on the client):
		music AudioPlayer ─Wire─▶ MusicBus (AudioFader) ─┐
		UI sfx AudioPlayers ─Wire─▶ SfxBus (AudioFader) ──┼─▶ Master (AudioCompressor) ─Wire─▶ AudioDeviceOutput
		3D: AudioPlayer ─Wire─▶ AudioEmitter (in a part) ··air··▶ AudioListener (camera) ─Wire─▶ SfxBus
	Studio setting: SoundService.DefaultListenerLocation = None (this module creates the listener; otherwise
	the engine adds its own and 3D sounds play twice).

	Usage:
		AudioController.PlayMusic("rbxassetid://123")
		AudioController.PlayUi("rbxassetid://456")                -- clicks, purchase success
		AudioController.PlayAt("rbxassetid://789", somePart)       -- positional (client-side cosmetic)
		AudioController.SetVolume("Music", 0.4)                    -- 0..1, e.g. from the Settings screen
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

export type Bus = "Music" | "Sfx"

local UI_POOL_SIZE = 8
local MUSIC_FADE_SECONDS = 1.5

local AudioController = {}

local root: Folder
local buses: { [Bus]: AudioFader } = {}
local musicPlayer: AudioPlayer
local musicFade: thread? = nil -- the running crossfade, cancelled when a new track starts
local uiPool: { AudioPlayer } = {}
local uiNext = 1

local function wire(source: Instance, target: Instance, parent: Instance)
	local w = Instance.new("Wire")
	w.SourceInstance = source
	w.TargetInstance = target
	w.Parent = parent
end

local function newPlayer(name: string, target: Instance): AudioPlayer
	local player = Instance.new("AudioPlayer")
	player.Name = name
	player.Parent = root
	wire(player, target, player)
	return player
end

local function build()
	if SoundService.DefaultListenerLocation ~= Enum.ListenerLocation.None then
		warn("[AudioController] Set SoundService.DefaultListenerLocation = None; an engine-created listener (Camera/Character, or Default with voice chat) makes 3D audio play twice.")
	end
	root = Instance.new("Folder")
	root.Name = "AudioGraph"
	root.Parent = SoundService

	local output = Instance.new("AudioDeviceOutput")
	output.Parent = root

	-- Gentle master compressor: keeps loud moments from clipping and evens out asset loudness.
	local master = Instance.new("AudioCompressor")
	master.Name = "Master"
	master.Threshold = -12
	master.Ratio = 3
	master.Attack = 0.01
	master.Release = 0.2
	master.Parent = root
	wire(master, output, master)

	for _, name in { "Music", "Sfx" } :: { Bus } do
		local fader = Instance.new("AudioFader")
		fader.Name = `{name}Bus`
		fader.Parent = root
		wire(fader, master, fader)
		buses[name] = fader
	end

	musicPlayer = newPlayer("Music", buses.Music)
	musicPlayer.Looping = true

	for index = 1, UI_POOL_SIZE do
		table.insert(uiPool, newPlayer(`Ui{index}`, buses.Sfx))
	end

	local listener = Instance.new("AudioListener")
	listener.Parent = workspace.CurrentCamera
	wire(listener, buses.Sfx, listener)
end

--- Sets a bus volume (0..1). Persist the value with your settings data.
function AudioController.SetVolume(bus: Bus, volume: number)
	if volume ~= volume then
		return
	end
	buses[bus].Volume = math.clamp(volume, 0, 1)
end

--- Crossfades to a new looping track ("" or nil stops music).
--- Fades the track's own AudioPlayer.Volume, never the bus: the bus holds the player's saved setting, so
--- SetVolume during a fade and rapid track changes can't corrupt it.
function AudioController.PlayMusic(asset: string?)
	if musicFade then
		task.cancel(musicFade)
	end
	musicFade = task.spawn(function()
		local steps = 15
		local from = musicPlayer.Volume
		for i = steps, 0, -1 do
			musicPlayer.Volume = from * (i / steps)
			task.wait(MUSIC_FADE_SECONDS / 2 / steps)
		end
		musicPlayer:Stop()
		if asset and asset ~= "" then
			musicPlayer.Asset = asset
			musicPlayer.TimePosition = 0
			musicPlayer:Play()
			for i = 0, steps do
				musicPlayer.Volume = i / steps
				task.wait(MUSIC_FADE_SECONDS / 2 / steps)
			end
		end
		musicFade = nil
	end)
end

--- Fire-and-forget 2D sound through the SFX bus (round-robin pool; no instance churn).
function AudioController.PlayUi(asset: string, playbackSpeed: number?)
	local player = uiPool[uiNext]
	uiNext = uiNext % #uiPool + 1
	player:Stop()
	player.Asset = asset
	-- Slight pitch variation keeps repeated clicks/pickups from sounding robotic.
	player.PlaybackSpeed = playbackSpeed or (0.96 + math.random() * 0.08)
	player.TimePosition = 0
	player:Play()
end

--- Positional one-shot at a part (client-side cosmetic). Cleans itself up when finished.
function AudioController.PlayAt(asset: string, part: BasePart)
	local emitter = Instance.new("AudioEmitter")
	emitter.Parent = part
	local player = Instance.new("AudioPlayer")
	player.Asset = asset
	player.Parent = emitter
	wire(player, emitter, player)
	player.Ended:Once(function()
		emitter:Destroy()
	end)
	task.delay(30, function() -- safety net if Ended never fires (asset failed to load)
		if emitter.Parent then
			emitter:Destroy()
		end
	end)
	player:Play()
end

function AudioController.Init()
	build()
end

function AudioController.Start()
	-- Follow the player's saved volume settings from the DataService snapshot.
	Net.event("DataSnapshot").OnClientEvent:Connect(function(snapshot: any)
		local settings = if typeof(snapshot) == "table" then snapshot.Settings else nil
		if typeof(settings) == "table" then
			if typeof(settings.Music) == "number" then
				AudioController.SetVolume("Music", settings.Music)
			end
			if typeof(settings.Sfx) == "number" then
				AudioController.SetVolume("Sfx", settings.Sfx)
			end
		end
	end)
end

return AudioController
