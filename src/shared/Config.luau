local Config = {}

-- Mining
Config.MINE_REACH = 10        -- max studs from ore to allow mining
Config.MINE_COOLDOWN = 0.8    -- seconds between mining actions per player

-- Ore lifecycle
Config.RESPAWN_DELAY = 5      -- seconds before a mined ore respawns

-- DataStore
Config.AUTOSAVE_INTERVAL = 60 -- seconds between periodic saves

-- Ore spawn positions (Vector3)
-- Spread these around your baseplate as needed
Config.ORE_SPAWN_POSITIONS = {
	{ position = Vector3.new(10, 1, 10),   oreType = "Stone" },
	{ position = Vector3.new(-10, 1, 10),  oreType = "Iron"  },
	{ position = Vector3.new(10, 1, -10),  oreType = "Stone" },
	{ position = Vector3.new(-10, 1, -10), oreType = "Gold"  },
	{ position = Vector3.new(25, 1, 0),    oreType = "Iron"  },
	{ position = Vector3.new(-25, 1, 0),   oreType = "Stone" },
	{ position = Vector3.new(0, 1, 25),    oreType = "Gold"  },
	{ position = Vector3.new(0, 1, -25),   oreType = "Iron"  },
}

return Config
