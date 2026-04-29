--!strict

-- T27: Visit Mode — friend list, live visit teleport, offline snapshot display.
-- T29: Leaderboard data retrieval for the social panel.
-- Rendering is handled by HUD.luau (T30); this module is pure logic.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Net.Events)
local Functions = require(ReplicatedStorage.Shared.Net.Functions)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type LeaderboardEntry = Types.LeaderboardEntry

local LocalPlayer = Players.LocalPlayer

-- ── Public types ───────────────────────────────────────────────────────────────

export type FriendCard = {
	userId: number,
	username: string,
	isOnline: boolean,
	snapshot: { [string]: any }?,
}

local UIController = {}

-- ── T27: Visit arrival detection ──────────────────────────────────────────────

-- Call once from init.client.luau on game start.
-- If this session was entered via a RequestVisit teleport, announces arrival to server.
function UIController.init(): ()
	local ok, data = pcall(function(): any
		return TeleportService:GetLocalPlayerTeleportData()
	end)
	if ok and type(data) == "table" and type((data :: any).hostUserId) == "number" then
		Events.NotifyVisitArrival:FireServer((data :: any).hostUserId)
	end
end

-- ── T27: Friend list ──────────────────────────────────────────────────────────

-- Fetches the local player's friend list and each friend's public snapshot.
-- Yields — call inside task.spawn from the UI layer.
function UIController.getFriendCards(): { FriendCard }
	local results: { FriendCard } = {}

	local pagesOk, pages = pcall(function(): any
		return Players:GetFriendsAsync(LocalPlayer.UserId)
	end)
	if not pagesOk then
		return results
	end

	local pagesObj = pages :: any
	while true do
		for _, entry in pagesObj:GetCurrentPage() do
			local e = entry :: any
			local snapOk, snapshot = pcall(function(): any
				return Functions.GetPublicSnapshot:InvokeServer(e.Id)
			end)
			table.insert(results, {
				userId = e.Id,
				username = e.Username,
				isOnline = e.IsOnline == true,
				snapshot = if snapOk and snapshot ~= nil then snapshot :: { [string]: any } else nil,
			})
		end
		if pagesObj.IsFinished then
			break
		end
		local advOk = pcall(function()
			pagesObj:AdvanceToNextPageAsync()
		end)
		if not advOk then
			break
		end
	end

	return results
end

-- ── T27: Visit a friend ───────────────────────────────────────────────────────

-- Requests the server to teleport this player to a friend's live server.
-- If the friend is offline the server fires NotifyEvent { OfflineSnapshot } back.
function UIController.visitFriend(friendUserId: number): ()
	Events.RequestVisit:FireServer(friendUserId)
end

-- ── T29: Leaderboard ──────────────────────────────────────────────────────────

-- Returns top-10 leaderboard entries for "Reputation", "Sanad", or "Alumni".
-- Each entry: { player = userId string, value = score }.
-- Yields — call inside task.spawn from the UI layer.
function UIController.getLeaderboard(board: string): { LeaderboardEntry }
	local ok, result = pcall(function(): any
		return Functions.GetLeaderboard:InvokeServer(board)
	end)
	if not ok or result == nil then
		return {}
	end
	return (result :: any) :: { LeaderboardEntry }
end

return UIController
