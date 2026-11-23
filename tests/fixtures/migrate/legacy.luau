-- 2018-style script
local Players = game.Players
local part = workspace.Part
wait(1)
spawn(function() print("hi") end)
delay(2, function() end)
part.Touched:connect(function(hit) end)
local kids = part:children()
local c = part:findFirstChild("Child")
if c and c:isA("BasePart") then c:Remove() end
local copy = part:clone()
workspace.Model:SetPrimaryPartCFrame(CFrame.new())
local pivot = workspace.Model:GetPrimaryPartCFrame()
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Blacklist
local player = Players.localPlayer
player:LoadCharacter()
local isFriend = player:IsFriendsWith(1)
local n = table.getn(kids)
local body = Instance.new("BodyVelocity")
print("wait(1) in a string stays") -- and wait(2) in a comment stays
