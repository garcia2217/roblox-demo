local Config = {}

-- Mining
Config.MINE_REACH = 10        -- max studs from ore to allow mining
Config.MINE_COOLDOWN = 0.8    -- seconds between mining actions per player

-- Ore lifecycle
Config.RESPAWN_DELAY = 5      -- seconds before a mined ore respawns

-- DataStore
Config.AUTOSAVE_INTERVAL = 60 -- seconds between periodic saves

-- How many ores to place at game start (server picks this many at random each run)
Config.ORE_SPAWN_COUNT = 10

-- Round session timing (seconds)
Config.LOBBY_DURATION      = 10
Config.COUNTDOWN_DURATION  = 5
Config.ROUND_DURATION      = 180
Config.SCOREBOARD_DURATION = 10

-- Minimum studs between any two ore spawn positions
Config.ORE_MIN_SPACING = 15

-- Sound asset IDs (replace with your own from the Creator Marketplace if desired)
Config.SOUNDS = {
	OreHit   = "rbxassetid://9119713951", -- rock impact
	OreBreak = "rbxassetid://104934835352245", -- rock crumble/break
	CoinPickup = "rbxassetid://4590662766", -- coin chime
	BackgroundMusic = "rbxassetid://85016458703950", -- dungeon/cave ambient loop
}

Config.BGM_VOLUME = 0.35

return Config
