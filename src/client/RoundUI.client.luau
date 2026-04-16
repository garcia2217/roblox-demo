local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundStateEvent   = ReplicatedStorage.Events:WaitForChild("RoundStateEvent")
local RoundResultsEvent = ReplicatedStorage.Events:WaitForChild("RoundResultsEvent")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoundUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Top status bar — shared by Lobby label and timer
local topBar = Instance.new("Frame")
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Size = UDim2.new(0.75, 0, 0, 44)
topBar.Position = UDim2.new(0.5, 0, 0, 18)
topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
topBar.BackgroundTransparency = 0.45
topBar.BorderSizePixel = 0
topBar.Visible = false
topBar.Parent = screenGui
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)
local topBarConstraint = Instance.new("UISizeConstraint")
topBarConstraint.MaxSize = Vector2.new(340, 44)
topBarConstraint.Parent = topBar

local topLabel = Instance.new("TextLabel")
topLabel.Size = UDim2.new(1, -16, 1, 0)
topLabel.Position = UDim2.new(0, 8, 0, 0)
topLabel.BackgroundTransparency = 1
topLabel.TextColor3 = Color3.new(1, 1, 1)
topLabel.TextScaled = true
topLabel.Font = Enum.Font.GothamBold
topLabel.Parent = topBar

-- Scoreboard overlay — visible only during Scoreboard phase
local scoreboard = Instance.new("Frame")
scoreboard.AnchorPoint = Vector2.new(0.5, 0.5)
scoreboard.Size = UDim2.new(0.85, 0, 0, 260)
scoreboard.Position = UDim2.new(0.5, 0, 0.5, 0)
scoreboard.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
scoreboard.BackgroundTransparency = 0.2
scoreboard.BorderSizePixel = 0
scoreboard.Visible = false
scoreboard.Parent = screenGui
Instance.new("UICorner", scoreboard).CornerRadius = UDim.new(0, 12)
local scoreConstraint = Instance.new("UISizeConstraint")
scoreConstraint.MaxSize = Vector2.new(420, 260)
scoreConstraint.Parent = scoreboard

local scoreTitle = Instance.new("TextLabel")
scoreTitle.Size = UDim2.new(1, -50, 0, 46)
scoreTitle.BackgroundTransparency = 1
scoreTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
scoreTitle.TextScaled = true
scoreTitle.Font = Enum.Font.GothamBold
scoreTitle.Text = "Round Over!"
scoreTitle.Parent = scoreboard

-- Close button (top-right corner of scoreboard)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.Position = UDim2.new(1, -44, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
closeButton.BackgroundTransparency = 0.3
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.Parent = scoreboard
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

closeButton.MouseButton1Click:Connect(function()
	scoreboard.Visible = false
end)

-- Scrollable list for ranked rows
local scoreList = Instance.new("Frame")
scoreList.Size = UDim2.new(1, -40, 1, -58)
scoreList.Position = UDim2.new(0, 20, 0, 52)
scoreList.BackgroundTransparency = 1
scoreList.Parent = scoreboard

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scoreList

-- Helper: format seconds as M:SS
local function formatTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%d:%02d", m, s)
end

-- Timer system — incrementing timerKey cancels the previous countdown loop
local timerKey = 0

local function startCountdown(seconds, labelFn)
	timerKey = timerKey + 1
	local myKey = timerKey
	local remaining = seconds
	task.spawn(function()
		while remaining >= 0 and timerKey == myKey do
			topLabel.Text = labelFn(remaining)
			task.wait(1)
			remaining = remaining - 1
		end
	end)
end

-- Helper: clear and rebuild scoreboard rows from ranked results table
local function populateScoreboard(results)
	-- Remove old rows
	for _, child in ipairs(scoreList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local medals = { "1st", "2nd", "3rd" }

	for i, entry in ipairs(results) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		row.BackgroundTransparency = i == 1 and 0.7 or 0.88
		row.BorderSizePixel = 0
		row.LayoutOrder = i
		row.Parent = scoreList
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

		local rank = Instance.new("TextLabel")
		rank.Size = UDim2.new(0, 40, 1, 0)
		rank.BackgroundTransparency = 1
		rank.TextColor3 = i == 1 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(180, 180, 180)
		rank.TextScaled = true
		rank.Font = Enum.Font.GothamBold
		rank.Text = medals[i] or tostring(i)
		rank.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -90, 1, 0)
		nameLabel.Position = UDim2.new(0, 44, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = entry.name
		nameLabel.Parent = row

		local coinsLabel = Instance.new("TextLabel")
		coinsLabel.Size = UDim2.new(0, 80, 1, 0)
		coinsLabel.Position = UDim2.new(1, -84, 0, 0)
		coinsLabel.BackgroundTransparency = 1
		coinsLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
		coinsLabel.TextScaled = true
		coinsLabel.Font = Enum.Font.GothamBold
		coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
		coinsLabel.Text = entry.coins .. " coins"
		coinsLabel.Parent = row
	end
end

-- State handler
RoundStateEvent.OnClientEvent:Connect(function(state, seconds)
	-- Reset visibility
	topBar.Visible = false
	scoreboard.Visible = false
	timerKey = timerKey + 1 -- cancel any running countdown

	if state == "Lobby" then
		topBar.Visible = true
		topLabel.Text = "Waiting for round..."
		topLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

	elseif state == "Countdown" then
		topBar.Visible = true
		topLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
		startCountdown(seconds, function(t)
			return "Round starts in " .. t .. "..."
		end)

	elseif state == "Playing" then
		topBar.Visible = true
		topLabel.TextColor3 = Color3.new(1, 1, 1)
		startCountdown(seconds, function(t)
			return "Time  " .. formatTime(t)
		end)

	elseif state == "Scoreboard" then
		scoreboard.Visible = true
	end
end)

-- Populate scoreboard when results arrive (fires just before Scoreboard state)
RoundResultsEvent.OnClientEvent:Connect(function(results)
	populateScoreboard(results)
end)
