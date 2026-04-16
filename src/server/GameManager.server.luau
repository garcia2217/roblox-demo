local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local playerDB = DataStoreService:GetDataStore("PlayerData_v1")

local Config = require(ReplicatedStorage.Shared.Config)
local OreTypes = require(ReplicatedStorage.Shared.OreTypes)

-- RemoteEvent setup
local Events = ReplicatedStorage:WaitForChild("Events")

local MineEvent = Instance.new("RemoteEvent")
MineEvent.Name = "MineEvent"
MineEvent.Parent = Events

-- DataStore helpers
local function saveData(player)
	local coins = player.leaderstats and player.leaderstats:FindFirstChild("Coins")
	if not coins then return end

	local success, err = pcall(function()
		playerDB:SetAsync("player_" .. player.UserId, coins.Value)
	end)

	if not success then
		warn("Failed to save data for", player.Name, ":", err)
	end
end

local function loadData(player)
	local success, result = pcall(function()
		return playerDB:GetAsync("player_" .. player.UserId)
	end)

	if success then
		return result or 0
	else
		warn("Failed to load data for", player.Name, ":", result)
		return 0
	end
end

-- Leaderstats + data load
local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = loadData(player)
	coins.Parent = leaderstats
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(saveData)

-- Auto-save loop
task.spawn(function()
	while true do
		task.wait(Config.AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end
end)

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

-- Particle hit effect
local function emitHitParticles(orePart, oreType)
	local data = OreTypes[oreType]

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(data.color.Color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Speed = NumberRange.new(5, 15)
	emitter.SpreadAngle = Vector2.new(60, 60)
	emitter.Lifetime = NumberRange.new(0.3, 0.7)
	emitter.LightEmission = 0.3
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Rate = 0
	emitter.Parent = orePart

	emitter:Emit(10)

	task.delay(1, function()
		if emitter and emitter.Parent then
			emitter:Destroy()
		end
	end)
end

-- MineEvent handler
local lastMineTimes = {} -- [player.UserId] = os.clock() of last successful mine

MineEvent.OnServerEvent:Connect(function(player, orePart)
	-- Guard: part must still exist and be mineable
	if not orePart or not orePart.Parent then return end
	if not orePart:GetAttribute("IsMineable") then return end

	-- Guard: player must have a character in the world
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Validate distance
	local distance = (rootPart.Position - orePart.Position).Magnitude
	if distance > Config.MINE_REACH then return end

	-- Validate cooldown
	local now = os.clock()
	local lastMine = lastMineTimes[player.UserId] or 0
	if (now - lastMine) < Config.MINE_COOLDOWN then return end
	lastMineTimes[player.UserId] = now

	-- Apply damage
	local oreType = orePart:GetAttribute("OreType")
	local hp = orePart:GetAttribute("HP") - 1

	-- Hit effects
	emitHitParticles(orePart, oreType)
	local originalColor = orePart.BrickColor
	orePart.BrickColor = BrickColor.new("White")
	task.delay(0.1, function()
		if orePart and orePart.Parent then
			orePart.BrickColor = originalColor
		end
	end)

	if hp > 0 then
		orePart:SetAttribute("HP", hp)
		-- HP transparency: gets more transparent as ore weakens
		orePart.Transparency = (1 - hp / OreTypes[oreType].hp) * 0.5
		return
	end

	-- HP reached 0 — break the ore
	local position = orePart.Position

	orePart:Destroy()

	-- Award coins
	local coins = player.leaderstats.Coins
	coins.Value = coins.Value + OreTypes[oreType].coins

	-- Schedule respawn
	task.delay(Config.RESPAWN_DELAY, spawnOre, position, oreType)
end)
