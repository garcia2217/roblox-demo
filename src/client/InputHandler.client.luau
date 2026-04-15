local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

local MineEvent = ReplicatedStorage.Events:WaitForChild("MineEvent")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { player.Character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(ray.Origin, ray.Direction * 50, raycastParams)
	if not result then return end

	local hitPart = result.Instance
	if not hitPart:GetAttribute("IsMineable") then return end

	MineEvent:FireServer(hitPart)
end)