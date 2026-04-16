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

return Config
