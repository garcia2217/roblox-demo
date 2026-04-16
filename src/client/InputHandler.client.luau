local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local OreTypes = require(ReplicatedStorage.Shared.OreTypes)

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

local MineEvent = ReplicatedStorage.Events:WaitForChild("MineEvent")

-- Hover highlight
local selectionBox = Instance.new("SelectionBox")
selectionBox.Color3 = Color3.fromRGB(255, 200, 0)
selectionBox.LineThickness = 0.05
selectionBox.SurfaceTransparency = 0.8
selectionBox.SurfaceColor3 = Color3.fromRGB(255, 200, 0)
selectionBox.Parent = workspace

-- Ore tooltip
local tooltip = Instance.new("BillboardGui")
tooltip.Size = UDim2.new(0, 140, 0, 60)
tooltip.StudsOffset = Vector3.new(0, 4, 0)
tooltip.AlwaysOnTop = true
tooltip.Enabled = false
tooltip.Parent = workspace

local tooltipFrame = Instance.new("Frame")
tooltipFrame.Size = UDim2.new(1, 0, 1, 0)
tooltipFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
tooltipFrame.BackgroundTransparency = 0.3
tooltipFrame.BorderSizePixel = 0
tooltipFrame.Parent = tooltip

Instance.new("UICorner", tooltipFrame).CornerRadius = UDim.new(0, 6)

local tooltipName = Instance.new("TextLabel")
tooltipName.Size = UDim2.new(1, -8, 0.5, 0)
tooltipName.Position = UDim2.new(0, 4, 0, 2)
tooltipName.BackgroundTransparency = 1
tooltipName.TextColor3 = Color3.new(1, 1, 1)
tooltipName.TextScaled = true
tooltipName.Font = Enum.Font.GothamBold
tooltipName.TextXAlignment = Enum.TextXAlignment.Left
tooltipName.Parent = tooltipFrame

local tooltipStats = Instance.new("TextLabel")
tooltipStats.Size = UDim2.new(1, -8, 0.5, -4)
tooltipStats.Position = UDim2.new(0, 4, 0.5, 2)
tooltipStats.BackgroundTransparency = 1
tooltipStats.TextColor3 = Color3.fromRGB(200, 200, 200)
tooltipStats.TextScaled = true
tooltipStats.Font = Enum.Font.Gotham
tooltipStats.TextXAlignment = Enum.TextXAlignment.Left
tooltipStats.Parent = tooltipFrame

local function getRaycastParams()
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { player.Character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	return params
end

RunService.RenderStepped:Connect(function()
	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local result = workspace:Raycast(ray.Origin, ray.Direction * 50, getRaycastParams())

	if result and result.Instance:GetAttribute("IsMineable") then
		local ore = result.Instance
		selectionBox.Adornee = ore
		tooltip.Adornee = ore
		tooltip.Enabled = true

		local oreType = ore:GetAttribute("OreType")
		local hp = ore:GetAttribute("HP")
		local data = OreTypes[oreType]
		if data then
			tooltipName.Text = data.name
			tooltipName.TextColor3 = data.color.Color
			tooltipStats.Text = "HP " .. hp .. "/" .. data.hp .. "  ·  +" .. data.coins .. " coins"
		end
	else
		selectionBox.Adornee = nil
		tooltip.Adornee = nil
		tooltip.Enabled = false
	end
end)

local function tryMineAtScreenPos(screenPos)
	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
	local result = workspace:Raycast(ray.Origin, ray.Direction * 50, getRaycastParams())
	if not result then return end
	local hitPart = result.Instance
	if not hitPart:GetAttribute("IsMineable") then return end
	MineEvent:FireServer(hitPart)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryMineAtScreenPos(UserInputService:GetMouseLocation())
	elseif input.UserInputType == Enum.UserInputType.Touch then
		-- input.Position is a Vector3 where X, Y are screen coordinates
		tryMineAtScreenPos(Vector2.new(input.Position.X, input.Position.Y))
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
		-- R2 (trigger) or A button — aim at screen center
		if input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.ButtonA then
			local viewport = camera.ViewportSize
			tryMineAtScreenPos(Vector2.new(viewport.X / 2, viewport.Y / 2))
		end
	end
end)