--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.Parent.Services.DataService)
local ReplicationService = require(script.Parent.Parent.Services.ReplicationService)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type PlayerData = Types.PlayerData

local ReputationManager = {}

-- Adds `amount` reputation, capping at 100. Schedules a full state push.
function ReputationManager.addReputation(player: Player, amount: number): ()
	local data = DataService.getPlayerData(player)
	local newRep = math.min(100, data.reputation + amount)
	DataService.updatePlayerData(player, { reputation = newRep })
	ReplicationService.syncAll(player)
end

return ReputationManager
