--!strict

-- Single source for all RemoteFunctions.
-- Server creates them on first require; client finds existing instances.
-- No other script should call Instance.new("RemoteFunction").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreate(name: string): RemoteFunction
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		assert(existing:IsA("RemoteFunction"), name .. " already exists but is not a RemoteFunction")
		return existing :: RemoteFunction
	end
	local fn = Instance.new("RemoteFunction")
	fn.Name = name
	fn.Parent = ReplicatedStorage
	return fn
end

-- ─── Server-implemented remote functions ──────────────────────────────────────
-- GetPlayerData  : () → PlayerData
-- GetLeaderboard : (board: "Reputation" | "Sanad" | "Alumni") → LeaderboardEntry[]
-- CheckGamePass  : (gamePassId: number) → boolean

local Functions = {
	GetPlayerData = getOrCreate("GetPlayerData"),
	GetLeaderboard = getOrCreate("GetLeaderboard"),
	CheckGamePass = getOrCreate("CheckGamePass"),
}

return Functions
