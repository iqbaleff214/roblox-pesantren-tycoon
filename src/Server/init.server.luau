--!strict

-- Bootstrap: require all services and managers, wire player lifecycle.
-- Order matters: DataService must be loaded before Replication or Economy.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── Force RemoteEvents/Functions to exist in ReplicatedStorage ────────────────
-- Events.luau and Functions.luau use getOrCreate — requiring them here ensures
-- all remotes are created before any client script can run.
require(ReplicatedStorage.Shared.Net.Events)
local Functions = require(ReplicatedStorage.Shared.Net.Functions)

-- ── Services ──────────────────────────────────────────────────────────────────
local DataService = require(script.Services.DataService)
local ReplicationService = require(script.Services.ReplicationService)
require(script.Services.EconomyService)
local EventService = require(script.Services.EventService)

-- ── Managers (stubs — side-effect require ensures module loads for later phases)
require(script.Managers.SantriManager)
require(script.Managers.BuildingManager)
require(script.Managers.UstadzManager)
require(script.Managers.ReputationManager)

-- ── RemoteFunction handlers ────────────────────────────────────────────────────

Functions.GetPlayerData.OnServerInvoke = function(player: Player): any
	if not DataService.isLoaded(player) then
		return nil
	end
	return DataService.getPlayerData(player)
end

Functions.GetLeaderboard.OnServerInvoke = function(): any
	-- Implemented in T29 (Phase 7 — Leaderboards)
	return {}
end

Functions.CheckGamePass.OnServerInvoke = function(): any
	-- Implemented in T41 (Phase 10 — Monetisation)
	return false
end

-- ── Player lifecycle ──────────────────────────────────────────────────────────

local function onPlayerAdded(player: Player): ()
	-- 1. Load data (may yield up to 3s on retry)
	DataService.loadPlayer(player)

	-- 2. Auto-save loop — runs until the player leaves
	task.spawn(function()
		while player.Parent ~= nil do
			task.wait(300) -- 5 minutes
			if player.Parent ~= nil then
				DataService.savePlayer(player)
			end
		end
	end)

	-- 3. Push initial state to client
	ReplicationService.syncAll(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player: Player)
	DataService.unloadPlayer(player)
end)

-- Handle players already in-game (Studio Play Solo spawns player before scripts run)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- ── Start event scheduler ─────────────────────────────────────────────────────
-- EventService.start() is a no-op until Phase 6 (T22).
EventService.start()

