--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Events = require(ReplicatedStorage.Shared.Net.Events)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type PlayerData = Types.PlayerData

local ReplicationService = {}

-- "all"       → send full PlayerData on next Heartbeat
-- "currencies"→ send currency subset only (lightweight)
type DirtyMode = "all" | "currencies"
local dirtyFlags: { [number]: DirtyMode } = {} -- keyed by UserId

-- ─── Dirty-flag helpers ────────────────────────────────────────────────────────

local function markDirty(player: Player, mode: DirtyMode): ()
	local userId = player.UserId
	-- Never downgrade from "all" to "currencies" within the same frame
	if mode == "all" or dirtyFlags[userId] == nil then
		dirtyFlags[userId] = mode
	end
end

-- ─── Public API ────────────────────────────────────────────────────────────────

-- Schedules a full PlayerData push to the client on the next Heartbeat.
function ReplicationService.syncAll(player: Player): ()
	markDirty(player, "all")
end

-- Schedules a lightweight currency-only push to the client on the next Heartbeat.
-- If a full sync is already pending, this is a no-op (full wins).
function ReplicationService.syncCurrencies(player: Player): ()
	markDirty(player, "currencies")
end

-- Fires a named RemoteEvent to every player currently in the server.
function ReplicationService.broadcastToServer(eventName: string, payload: any): ()
	local event = (Events :: { [string]: any })[eventName] :: RemoteEvent?
	if event == nil then
		warn("[ReplicationService] broadcastToServer: no RemoteEvent named '" .. eventName .. "'")
		return
	end
	for _, player in Players:GetPlayers() do
		event:FireClient(player, payload)
	end
end

-- ─── Heartbeat flush ──────────────────────────────────────────────────────────
-- Flushes all dirty players once per frame.
-- Collecting keys first avoids modifying dirtyFlags while iterating it.

RunService.Heartbeat:Connect(function()
	-- Collect all dirty userIds
	local pending: { number } = {}
	for userId in dirtyFlags do
		table.insert(pending, userId)
	end
	if #pending == 0 then
		return
	end

	for _, userId in pending do
		local mode = dirtyFlags[userId]
		dirtyFlags[userId] = nil -- clear before firing; re-marked if mutation occurs during send

		local player = Players:GetPlayerByUserId(userId)
		if player == nil then
			continue
		end
		if not DataService.isLoaded(player) then
			continue
		end

		local ok, err = pcall(function()
			local data = DataService.getPlayerData(player)
			if mode == "all" then
				Events.SyncPlayerData:FireClient(player, data)
			else
				-- Lightweight: only send the four currency fields
				Events.SyncPlayerData:FireClient(player, {
					rupiah = data.rupiah,
					barakah = data.barakah,
					ilmu = data.ilmu,
					sanad = data.sanad,
				})
			end
		end)
		if not ok then
			warn(string.format("[ReplicationService] Heartbeat flush failed for userId %d: %s", userId, tostring(err)))
		end
	end
end)

return ReplicationService
