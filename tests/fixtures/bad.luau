-- Intentionally bad legacy code. Every marked line must be flagged by cluau-lint.
local Players = game.Players -- expect CL014
local part = Instance.new("Part", workspace) -- expect CL010
local bv = Instance.new("BodyVelocity") -- expect CL020
local hint = Instance.new("Hint") -- expect CL017

wait(1) -- expect CL001
spawn(function() end) -- expect CL002
delay(2, function() end) -- expect CL003
local t0 = tick() -- expect CL004

part.Touched:connect(function() end) -- expect CL011
part:Remove() -- expect CL012
local kids = part:children() -- expect CL013

local model = workspace.Model
model:SetPrimaryPartCFrame(CFrame.new()) -- expect CL015
model:MakeJoints() -- expect CL016

local hit = workspace:FindPartOnRay(Ray.new(Vector3.zero, Vector3.yAxis)) -- expect CL021
local parts = workspace:FindPartsInRegion3(Region3.new(Vector3.zero, Vector3.one)) -- expect CL022
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Blacklist -- expect CL023

local humanoid = Players.LocalPlayer.Character.Humanoid
local track = humanoid:LoadAnimation(script.Animation) -- expect CL030

local mouse = Players.LocalPlayer:GetMouse() -- expect CL040
game:GetService("PhysicsService"):CreateCollisionGroup("Enemies") -- expect CL050
game:GetService("TeleportService"):Teleport(123, Players.LocalPlayer) -- expect CL051

local store = game:GetService("DataStoreService"):GetDataStore("x")
store:SetAsync("key", 1) -- expect CL060

loadstring("print(1)")() -- expect CL070
local env = getfenv() -- expect CL071
local backdoor = require(4567890) -- expect CL072
game.ReplicatedStorage.Remote:InvokeClient(Players.LocalPlayer) -- expect CL073 (and CL014)
_G.Coins = 5 -- expect CL075
local n = table.getn({}) -- expect CL080

local label = Instance.new("TextLabel")
label.TextScaled = true -- expect CL090
label.Font = Enum.Font.SourceSans -- expect CL091
label.BorderSizePixel = 1 -- expect CL092
label.Text = "💰 Welcome to the Game!" -- expect CL094 and CL095

local chat = game:GetService("Chat") -- expect CL053
Players.LocalPlayer.Chatted:Connect(function() end) -- expect CL064
local physics = game:GetService("PhysicsService") -- expect CL059
local rank = Players.LocalPlayer:GetRankInGroup(1) -- expect CL200
Players.LocalPlayer:LoadCharacter() -- expect CL200
local tool = Instance.new("HopperBin") -- expect CL203
label.TextWrap = true -- expect CL201
local options = Instance.new("TeleportOptions")
options.ShouldReserveServer = true -- expect CL201
if local x = 1 then end -- expect CL077
game:GetService("MarketplaceService").PromptProductPurchaseFinished:Connect(print) -- expect CL078

-- These must NOT be flagged (strings/comments): "wait(1)", 'spawn()', [[ tick() ]]
local ok = "task.wait() is fine"
task.wait(1)
task.spawn(function() end)
local fine = workspace:Raycast(Vector3.zero, Vector3.yAxis * 10)
local ignored = tick() -- cluau-ignore CL004
