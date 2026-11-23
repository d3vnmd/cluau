-- 2018-style script
local Players = game:GetService("Players")
local part = workspace.Part
task.wait(1)
task.spawn(function() print("hi") end)
task.delay(2, function() end)
part.Touched:Connect(function(hit) end)
local kids = part:GetChildren()
local c = part:FindFirstChild("Child")
if c and c:IsA("BasePart") then c:Destroy() end
local copy = part:Clone()
workspace.Model:PivotTo(CFrame.new())
local pivot = workspace.Model:GetPivot()
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local player = Players.LocalPlayer
player:LoadCharacterAsync()
local isFriend = player:IsFriendsWithAsync(1)
local n = #kids
local body = Instance.new("BodyVelocity")
print("wait(1) in a string stays") -- and wait(2) in a comment stays
