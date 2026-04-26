--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Modules.Types)

type PlayerData = Types.PlayerData

local DataService = {}

local store = DataStoreService:GetDataStore("PlayerData_v1")

-- In-memory cache keyed by UserId. Populated on loadPlayer, cleared on unloadPlayer.
local cache: { [number]: PlayerData } = {}

-- ─── Default data ──────────────────────────────────────────────────────────────

local function defaultData(): PlayerData
	return {
		rupiah = 500,
		barakah = 0,
		ilmu = 0,
		sanad = 0,
		reputation = 0,
		prestigeCount = 0,
		prestigeMultiplier = 1,
		tutorialStep = 0,
		santriList = {},
		buildingList = {},
		ustadzList = {},
		alumniCount = 0,
		sedekahJariyahPerMin = 0,
		tierBerkembangFired = false,
		tierUnggulanFired = false,
		tierPrestigeFired = false,
		zoneUnlocked = 1,
		dailyPrayerCount = 0,
		waktuSholatActive = false,
		waktuSholatExpiry = 0,
		starterPackExpiry = 0,
		lastSaved = 0,
	}
end

-- Merge loaded data with defaults so new fields added in future versions
-- don't remain nil when old save data is loaded.
local function mergeWithDefaults(loaded: { [string]: any }): PlayerData
	local defaults = defaultData() :: { [string]: any }
	for key, value in defaults do
		if loaded[key] == nil then
			loaded[key] = value
		end
	end
	return loaded :: any
end

-- Strip runtime-only fields before writing to DataStore.
local function toSavable(data: PlayerData): { [string]: any }
	local copy: { [string]: any } = {}
	for k, v in data :: { [string]: any } do
		if string.sub(tostring(k), 1, 1) ~= "_" then
			copy[k] = v
		end
	end
	return copy
end

-- ─── Public API ────────────────────────────────────────────────────────────────

-- Loads data from DataStore into cache. Retries up to 3 times on failure.
-- Always returns a valid PlayerData (defaults on all-retry failure).
function DataService.loadPlayer(player: Player): PlayerData
	local userId = player.UserId
	local key = "player_" .. userId
	local loadedRaw: { [string]: any }? = nil
	local allFailed = false

	for attempt = 1, 3 do
		local ok, result = pcall(function(): any
			return store:GetAsync(key)
		end)
		if ok then
			-- result is nil for new players (never saved) — that's fine
			loadedRaw = (result :: any) :: { [string]: any }?
			allFailed = false
			break
		end
		warn(string.format("[DataService] GetAsync attempt %d failed for %s: %s", attempt, player.Name, tostring(result)))
		allFailed = true
		if attempt < 3 then
			task.wait(1)
		end
	end

	local playerData: PlayerData
	if loadedRaw ~= nil then
		playerData = mergeWithDefaults(loadedRaw)
	else
		playerData = defaultData()
		if allFailed then
			playerData._loadFailed = true
			warn("[DataService] All retries failed for " .. player.Name .. " — using defaults (data NOT saved until next successful load)")
		end
	end

	cache[userId] = playerData
	return playerData
end

-- Writes the cached data for a player to DataStore via UpdateAsync.
-- Safe to call multiple times; no-op if player is not in cache.
function DataService.savePlayer(player: Player): ()
	local userId = player.UserId
	local data = cache[userId]
	if data == nil then
		return
	end

	local key = "player_" .. userId
	local savable = toSavable(data)
	savable.lastSaved = os.time()

	local ok, err = pcall(function()
		store:UpdateAsync(key, function(_: any): { [string]: any }
			return savable
		end)
	end)
	if not ok then
		warn(string.format("[DataService] SavePlayer failed for %s: %s", player.Name, tostring(err)))
	end
end

-- Saves and removes the player from the in-memory cache. Call on PlayerRemoving.
function DataService.unloadPlayer(player: Player): ()
	DataService.savePlayer(player)
	cache[player.UserId] = nil
end

-- Returns the cached PlayerData. Errors if loadPlayer was not called first.
function DataService.getPlayerData(player: Player): PlayerData
	local data = cache[player.UserId]
	if data == nil then
		error(string.format("[DataService] getPlayerData called before loadPlayer for %s", player.Name))
	end
	return data
end

-- Shallow-patches the cached PlayerData with the provided key-value pairs.
-- All mutations to player state must go through this function or EconomyService.
function DataService.updatePlayerData(player: Player, patch: { [string]: any }): ()
	local data = cache[player.UserId]
	if data == nil then
		error(string.format("[DataService] updatePlayerData called before loadPlayer for %s", player.Name))
	end
	for key, value in patch do
		(data :: { [string]: any })[key] = value
	end
end

-- Returns true if the player's data is loaded and in cache.
function DataService.isLoaded(player: Player): boolean
	return cache[player.UserId] ~= nil
end

return DataService
