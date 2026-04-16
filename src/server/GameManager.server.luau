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

local CoinSoundEvent = Instance.new("RemoteEvent")
CoinSoundEvent.Name = "CoinSoundEvent"
CoinSoundEvent.Parent = Events

local FloatingCoinsEvent = Instance.new("RemoteEvent")
FloatingCoinsEvent.Name = "FloatingCoinsEvent"
FloatingCoinsEvent.Parent = Events

-- DataStore helpers
local function saveData(player)
	local coins = player.leaderstats and player.leaderstats:FindFirstChild("Coins")
	if not coins then return end

	local key = "player_" .. player.UserId
	local saved = false
	for attempt = 1, 3 do
		local success, err = pcall(function()
			playerDB:SetAsync(key, coins.Value)
		end)
		if success then
			saved = true
			break
		end
		if attempt < 3 then
			task.wait(2)
		else
			warn("Failed to save data for", player.Name, "after 3 attempts:", err)
		end
	end
	return saved
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

-- Plays a sound at a position in the world, heard by all nearby players.
-- Uses Debris to auto-clean up the Sound instance after it finishes.
local Debris = game:GetService("Debris")
local function playWorldSound(soundId, parent, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.RollOffMaxDistance = 60
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 5)
end

-- Ore folder keeps Workspace Explorer tidy
local oreFolder = Instance.new("Folder")
oreFolder.Name = "Ores"
oreFolder.Parent = workspace

-- Server-authoritative HP store — keyed by ore part to avoid race conditions
-- when two players hit the same ore in the same frame
local oreHP = {}

-- Ore spawning
local function spawnOre(position, oreType)
	local data = OreTypes[oreType]

	local part = Instance.new("Part")
	part.Name = "OreNode"
	part.Size = Vector3.new(2, 2, 2)
	part.Anchored = true
	part.BrickColor = data.color
	part.Material = data.material

	part:SetAttribute("IsMineable", true)
	part:SetAttribute("OreType", oreType)
	part:SetAttribute("HP", data.hp)

	oreHP[part] = data.hp

	part.Position = position
	part.Parent = oreFolder
end

-- Build a weighted pool from OreTypes.weight at startup
local ORE_TYPE_POOL = {}
for oreType, data in pairs(OreTypes) do
	for _ = 1, data.weight do
		table.insert(ORE_TYPE_POOL, oreType)
	end
end

local function pickOreType()
	return ORE_TYPE_POOL[math.random(1, #ORE_TYPE_POOL)]
end

-- Scans the workspace for valid ore spawn positions by:
--   1. Using the SpawnLocation Y as the floor reference height
--   2. Collecting XZ grid points from flat floor-level parts
--   3. Raycasting downward at each point to get the TRUE surface Y (not estimated from Size)
--   4. Casting 6 studs upward from the hit surface to reject low-headroom spots
local function findOreSpawnCandidates()
	local PLAYER_HEIGHT = 6   -- studs of clear space needed above the surface
	local MIN_FLOOR_AREA = 50 -- minimum X*Z area (studs²) to consider as floor
	local GRID_STEP = 10      -- studs between sample points
	local EDGE_INSET = 2      -- studs inset from part edges to avoid rim spawns
	local HEIGHT_TOLERANCE = 15 -- studs above/below SpawnLocation Y to accept

	local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local spawnY = spawnLocation and spawnLocation.Position.Y or 0

	-- Step 1: collect unique XZ grid points from all floor-level parts
	local gridPoints = {} -- keyed to deduplicate overlapping parts
	for _, part in ipairs(workspace:GetDescendants()) do
		if not part:IsA("BasePart") then continue end
		if part:IsA("Terrain") then continue end
		if part:IsA("SpawnLocation") then continue end
		if not part.CanCollide then continue end

		local sX, sY, sZ = part.Size.X, part.Size.Y, part.Size.Z
		if sY >= sX / 2 or sY >= sZ / 2 then continue end
		if (sX * sZ) < MIN_FLOOR_AREA then continue end

		local topY = part.Position.Y + sY / 2
		if math.abs(topY - spawnY) > HEIGHT_TOLERANCE then continue end

		local halfX = sX / 2 - EDGE_INSET
		local halfZ = sZ / 2 - EDGE_INSET
		if halfX <= 0 or halfZ <= 0 then continue end

		for dx = -halfX, halfX, GRID_STEP do
			for dz = -halfZ, halfZ, GRID_STEP do
				local x = math.floor(part.Position.X + dx)
				local z = math.floor(part.Position.Z + dz)
				gridPoints[x .. "_" .. z] = Vector2.new(x, z)
			end
		end
	end

	-- Step 2: raycast each XZ point from above to find the real surface Y
	local candidates = {}
	for _, pt in pairs(gridPoints) do
		local x, z = pt.X, pt.Y
		-- Cast from just above the expected floor zone downward
		local hit = workspace:Raycast(
			Vector3.new(x, spawnY + 50, z),
			Vector3.new(0, -(HEIGHT_TOLERANCE + 55), 0)
		)
		if not hit then continue end

		local surfaceY = hit.Position.Y
		if math.abs(surfaceY - spawnY) > HEIGHT_TOLERANCE then continue end

		-- Check headroom: nothing solid within PLAYER_HEIGHT studs above the surface
		local headHit = workspace:Raycast(
			Vector3.new(x, surfaceY + 0.5, z),
			Vector3.new(0, PLAYER_HEIGHT, 0)
		)
		if not headHit then
			table.insert(candidates, Vector3.new(x, surfaceY + 1, z))
		end
	end

	return candidates
end

-- Cached at startup so respawns can also pick from the same pool
local oreCandidates = findOreSpawnCandidates()

if #oreCandidates == 0 then
	warn("GameManager: findOreSpawnCandidates found no valid positions — no ores will spawn")
end

local function pickRandomPosition()
	return oreCandidates[math.random(1, #oreCandidates)]
end

local function pickRandomOreSpawns()
	if #oreCandidates == 0 then return {} end

	-- Fisher-Yates shuffle on a copy, then take the first ORE_SPAWN_COUNT
	local shuffled = { table.unpack(oreCandidates) }
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	local picks = {}
	for i = 1, #shuffled do
		if #picks >= Config.ORE_SPAWN_COUNT then break end

		local candidate = shuffled[i]
		local tooClose = false
		for _, pick in ipairs(picks) do
			if (candidate - pick.position).Magnitude < Config.ORE_MIN_SPACING then
				tooClose = true
				break
			end
		end

		if not tooClose then
			table.insert(picks, { position = candidate, oreType = pickOreType() })
		end
	end
	return picks
end

for _, entry in ipairs(pickRandomOreSpawns()) do
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

	-- Apply damage (read from server table, not the replicated attribute)
	local oreType = orePart:GetAttribute("OreType")
	local hp = oreHP[orePart]
	if not hp then return end -- already broken by another player this frame
	hp = hp - 1
	oreHP[orePart] = hp

	-- Keep attribute in sync so clients can read it (tooltip HP display)
	orePart:SetAttribute("HP", hp)

	-- Hit effects
	emitHitParticles(orePart, oreType)
	playWorldSound(Config.SOUNDS.OreHit, orePart)
	local originalColor = orePart.BrickColor
	orePart.BrickColor = BrickColor.new("White")
	task.delay(0.1, function()
		if orePart and orePart.Parent then
			orePart.BrickColor = originalColor
		end
	end)

	if hp > 0 then
		-- HP transparency: gets more transparent as ore weakens
		orePart.Transparency = (1 - hp / OreTypes[oreType].hp) * 0.5
		return
	end

	-- HP reached 0 — break the ore
	oreHP[orePart] = nil
	local position = orePart.Position

	-- Play break sound at the ore's position before destroying it
	local breakSound = Instance.new("Sound")
	breakSound.SoundId = Config.SOUNDS.OreBreak
	breakSound.Volume = 1
	breakSound.Parent = workspace
	breakSound.RollOffMaxDistance = 60
	breakSound:Play()
	Debris:AddItem(breakSound, 5)

	orePart:Destroy()

	-- Award coins
	local coinAmount = OreTypes[oreType].coins
	local coins = player.leaderstats.Coins
	coins.Value = coins.Value + coinAmount

	-- Notify clients: coin sound (mining player only) + floating text (everyone)
	CoinSoundEvent:FireClient(player)
	FloatingCoinsEvent:FireAllClients(position, coinAmount, oreType)

	-- Schedule respawn with a freshly rolled ore type so all types
	-- remain in circulation regardless of the initial spawn draw
	task.delay(Config.RESPAWN_DELAY, function()
		spawnOre(pickRandomPosition(), pickOreType())
	end)
end)
