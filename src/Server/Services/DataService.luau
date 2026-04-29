--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Modules.Types)

type PlayerData = Types.PlayerData

local DataService = {}

local store = DataStoreService:GetDataStore("PlayerData_v1")
local publicStore = DataStoreService:GetDataStore("PublicPesantren")
local doaCooldownStore = DataStoreService:GetDataStore("DoaCooldowns")
local leaderboardRepStore = DataStoreService:GetOrderedDataStore("Leaderboard_Reputation")
local leaderboardSanadStore = DataStoreService:GetOrderedDataStore("Leaderboard_Sanad")
local leaderboardAlumniStore = DataStoreService:GetOrderedDataStore("Leaderboard_Alumni")

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

	-- Side-effects: non-blocking, failures tolerated
	task.spawn(function()
		DataService.writePublicSnapshot(player)
	end)
	task.spawn(function()
		DataService.updateLeaderboards(player)
	end)
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

-- ─── T27: Public snapshot ──────────────────────────────────────────────────────

-- Writes a public-facing snapshot for this player. Called from savePlayer.
-- Failures are silently swallowed — public data is best-effort.
function DataService.writePublicSnapshot(player: Player): ()
	local data = cache[player.UserId]
	if data == nil then
		return
	end
	local snapshot = {
		reputation = data.reputation,
		alumniCount = data.alumniCount,
		buildingList = data.buildingList,
		lastSeen = os.time(),
		lastServerId = game.JobId,
	}
	pcall(function()
		publicStore:SetAsync("public_" .. player.UserId, snapshot)
	end)
end

-- Returns the public snapshot for any userId, or nil on failure/not found.
function DataService.readPublicSnapshot(userId: number): { [string]: any }?
	local ok, result = pcall(function(): any
		return publicStore:GetAsync("public_" .. userId)
	end)
	if not ok then
		return nil
	end
	return (result :: any) :: { [string]: any }?
end

-- ─── T27: Doa cooldown ─────────────────────────────────────────────────────────

-- Returns true and records the cooldown if the visitor-host pair is not on cooldown.
-- Returns false if still within DOA_COOLDOWN_SEC, or on DataStore error.
function DataService.checkDoaCooldown(visitorId: number, hostId: number): boolean
	local key = "doa_" .. visitorId .. "_" .. hostId
	local ok, result = pcall(function(): any
		return doaCooldownStore:GetAsync(key)
	end)
	if not ok then
		return false
	end
	local lastDoa = (result :: any) :: number?
	local Constants = require(game:GetService("ReplicatedStorage").Shared.Modules.Constants)
	if lastDoa ~= nil and os.time() < lastDoa + (Constants :: any).DOA_COOLDOWN_SEC then
		return false
	end
	local setOk = pcall(function()
		doaCooldownStore:SetAsync(key, os.time())
	end)
	return setOk
end

-- ─── T29: Leaderboards ─────────────────────────────────────────────────────────

-- Updates all three ordered leaderboard stores for this player.
-- Runs in task.spawn from savePlayer — failures are silent.
function DataService.updateLeaderboards(player: Player): ()
	local data = cache[player.UserId]
	if data == nil then
		return
	end
	local key = tostring(player.UserId)
	pcall(function()
		leaderboardRepStore:SetAsync(key, math.max(0, math.floor(data.reputation)))
	end)
	pcall(function()
		leaderboardSanadStore:SetAsync(key, math.max(0, math.floor(data.sanad)))
	end)
	pcall(function()
		leaderboardAlumniStore:SetAsync(key, math.max(0, math.floor(data.alumniCount)))
	end)
end

-- Returns top-10 entries for the given leaderboard, sorted descending.
-- Each entry: { player = userId string, value = score }.
function DataService.getLeaderboard(board: string): { { player: string, value: number } }
	local ds = if board == "Reputation" then leaderboardRepStore
		elseif board == "Sanad" then leaderboardSanadStore
		else leaderboardAlumniStore
	local ok, pages = pcall(function(): any
		return ds:GetSortedAsync(false, 10)
	end)
	if not ok then
		return {}
	end
	local results: { { player: string, value: number } } = {}
	for _, entry in (pages :: any):GetCurrentPage() do
		local e = entry :: any
		table.insert(results, { player = tostring(e.key), value = e.value })
	end
	return results
end

return DataService
