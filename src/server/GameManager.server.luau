local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local OreTypes = require(ReplicatedStorage.Shared.OreTypes)

-- RemoteEvent setup
local Events = ReplicatedStorage:WaitForChild("Events")

local MineEvent = Instance.new("RemoteEvent")
MineEvent.Name = "MineEvent"
MineEvent.Parent = Events

-- Leaderstats
local function setupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats
end

Players.PlayerAdded:Connect(setupLeaderstats)
