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

-- Ore spawning
local function spawnOre(position, oreType)
	local data = OreTypes[oreType]

	local part = Instance.new("Part")
	part.Name = "OreNode"
	part.Size = Vector3.new(2, 2, 2)
	part.Anchored = true
	part.BrickColor = data.color
	part.Material = Enum.Material.SmoothPlastic

	part:SetAttribute("IsMineable", true)
	part:SetAttribute("OreType", oreType)
	part:SetAttribute("HP", data.hp)

	part.Position = position
	part.Parent = workspace
end

for _, entry in ipairs(Config.ORE_SPAWN_POSITIONS) do
	spawnOre(entry.position, entry.oreType)
end
