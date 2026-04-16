local Players = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WelcomeScreen"
screenGui.ResetOnSpawn = false  -- only show once per session, not on every respawn
screenGui.Parent = playerGui

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.45
overlay.BorderSizePixel = 0
overlay.Parent = screenGui

-- Center panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 420, 0, 340)
panel.Position = UDim2.new(0.5, -210, 0.5, -170)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 60)
title.Position = UDim2.new(0, 0, 0, 16)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 200, 0)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "Mining Frenzy"
title.Parent = panel

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.8, 0, 0, 2)
divider.Position = UDim2.new(0.1, 0, 0, 74)
divider.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
divider.BackgroundTransparency = 0.6
divider.BorderSizePixel = 0
divider.Parent = panel

-- Instructions list
local instructions = {
	"Walk up to a glowing ore node",
	"Click to strike it — mine it down to 0 HP",
	"Rarer ores give more coins",
	"Earn the most coins before time runs out",
	"Most coins at the end of the round wins!",
}

for i, line in ipairs(instructions) do
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, -40, 0, 30)
	row.Position = UDim2.new(0, 20, 0, 74 + i * 34)
	row.BackgroundTransparency = 1
	row.TextColor3 = Color3.fromRGB(220, 220, 220)
	row.TextScaled = true
	row.Font = Enum.Font.Gotham
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Text = "•  " .. line
	row.Parent = panel
end

-- "Got it!" button
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 160, 0, 44)
button.Position = UDim2.new(0.5, -80, 1, -60)
button.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
button.BorderSizePixel = 0
button.TextColor3 = Color3.fromRGB(20, 20, 20)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Text = "Got it!"
button.Parent = panel
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

button.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)
