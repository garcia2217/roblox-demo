local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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
		selectionBox.Adornee = result.Instance
	else
		selectionBox.Adornee = nil
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local result = workspace:Raycast(ray.Origin, ray.Direction * 50, getRaycastParams())
	if not result then return end

	local hitPart = result.Instance
	if not hitPart:GetAttribute("IsMineable") then return end

	MineEvent:FireServer(hitPart)
end)