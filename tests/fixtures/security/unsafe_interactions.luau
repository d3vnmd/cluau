--!strict
-- Server script: prompt, click and touch handlers without distance checks.
local prompt = workspace.Shop.ProximityPrompt
prompt.Triggered:Connect(function(player) end) -- expect CL113
workspace.Button.ClickDetector.MouseClick:Connect(function(player) end) -- expect CL113
workspace.Coin.Touched:Connect(function(hit) end) -- expect CL113
