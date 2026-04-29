--!strict

-- Bootstrap: require all services and managers, wire player lifecycle.
-- Order matters: DataService must be loaded before Replication or Economy.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

-- ── Force RemoteEvents/Functions to exist in ReplicatedStorage ────────────────
-- Events.luau and Functions.luau use getOrCreate — requiring them here ensures
-- all remotes are created before any client script can run.
local Events = require(ReplicatedStorage.Shared.Net.Events)
local Functions = require(ReplicatedStorage.Shared.Net.Functions)

-- ── Services ──────────────────────────────────────────────────────────────────
local DataService = require(script.Services.DataService)
local ReplicationService = require(script.Services.ReplicationService)
require(script.Services.EconomyService)
local EventService = require(script.Services.EventService)

-- ── Managers ──────────────────────────────────────────────────────────────────
require(script.Managers.SantriManager)
require(script.Managers.BuildingManager)
require(script.Managers.UstadzManager)
local ReputationManager = require(script.Managers.ReputationManager)

local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

-- ── RemoteFunction handlers ────────────────────────────────────────────────────

Functions.GetPlayerData.OnServerInvoke = function(player: Player): any
	if not DataService.isLoaded(player) then
		return nil
	end
	return DataService.getPlayerData(player)
end

-- T29: Return top-10 leaderboard entries for the requested board.
Functions.GetLeaderboard.OnServerInvoke = function(_player: Player, rawBoard: any): any
	if type(rawBoard) ~= "string" then
		return {}
	end
	local board = rawBoard :: string
	if board ~= "Reputation" and board ~= "Sanad" and board ~= "Alumni" then
		return {}
	end
	return DataService.getLeaderboard(board)
end

-- T27: Return the public snapshot for a given userId.
Functions.GetPublicSnapshot.OnServerInvoke = function(_player: Player, rawUserId: any): any
	if type(rawUserId) ~= "number" then
		return nil
	end
	return DataService.readPublicSnapshot(math.floor(rawUserId))
end

Functions.CheckGamePass.OnServerInvoke = function(): any
	-- Implemented in T41 (Phase 10 — Monetisation)
	return false
end

-- ── T27: Visit Mode RemoteEvent handlers ─────────────────────────────────────

-- Visitor announces their arrival; notify the host and award reputation.
Events.NotifyVisitArrival.OnServerEvent:Connect(function(visitor: Player, rawHostId: any)
	if type(rawHostId) ~= "number" then
		return
	end
	if not DataService.isLoaded(visitor) then
		return
	end
	local hostId = math.floor(rawHostId)
	local host = Players:GetPlayerByUserId(hostId)
	if host == nil or not DataService.isLoaded(host) then
		return
	end
	Events.NotifyEvent:FireClient(host, { eventType = "VisitorArrived", visitorName = visitor.Name })
	ReputationManager.addReputation(host, Constants.REP_PER_VISITOR)
end)

-- Server-side teleport to friend's live server, or fall back to offline snapshot.
Events.RequestVisit.OnServerEvent:Connect(function(player: Player, rawFriendId: any)
	if type(rawFriendId) ~= "number" then
		return
	end
	if not DataService.isLoaded(player) then
		return
	end
	local friendId = math.floor(rawFriendId)
	local snapshot = DataService.readPublicSnapshot(friendId)
	if snapshot == nil then
		Events.NotifyEvent:FireClient(player, { eventType = "OfflineSnapshot", snapshot = nil })
		return
	end
	local lastServerId = (snapshot :: any).lastServerId :: string?
	if lastServerId == nil or lastServerId == "" or lastServerId == game.JobId then
		-- Friend offline or in same server — show snapshot
		Events.NotifyEvent:FireClient(player, { eventType = "OfflineSnapshot", snapshot = snapshot })
		return
	end
	-- Teleport player to the friend's live server
	local options: any = Instance.new("TeleportOptions")
	options.ServerInstanceId = lastServerId
	options:SetTeleportData({ hostUserId = friendId })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	if not ok then
		warn("[Visit] TeleportAsync failed:", tostring(err))
		Events.NotifyEvent:FireClient(player, { eventType = "OfflineSnapshot", snapshot = snapshot })
	end
end)

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
EventService.start()
