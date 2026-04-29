--!strict

-- T20: addReputation, getReputation, checkTierUnlocks (tier events + Kunjungan Menteri)
-- T21: bukaCabang prestige reset (Sanad reward, data wipe, multiplier update)

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.Parent.Services.DataService)
local EconomyService = require(script.Parent.Parent.Services.EconomyService)
local ReplicationService = require(script.Parent.Parent.Services.ReplicationService)
local Events = require(ReplicatedStorage.Shared.Net.Events)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type PlayerData = Types.PlayerData

-- Lazy require to break circular dep: BuildingManager → ReputationManager → BuildingManager.
-- All modules are fully initialised before any function body runs at runtime.
local function buildingMgr()
	return require(script.Parent.BuildingManager)
end

local ReputationManager = {}

-- ─── Public API ────────────────────────────────────────────────────────────────

function ReputationManager.getReputation(player: Player): number
	return DataService.getPlayerData(player).reputation
end

-- Adds `amount` reputation (clamped to [0, 100]), then checks tier unlocks.
function ReputationManager.addReputation(player: Player, amount: number): ()
	local data = DataService.getPlayerData(player)
	local newRep = math.clamp(data.reputation + amount, 0, 100)
	DataService.updatePlayerData(player, { reputation = newRep })
	ReputationManager.checkTierUnlocks(player)
	ReplicationService.syncAll(player)
end

-- Fires tier-unlock notifications once per tier (tracked via PlayerData flags).
-- Tier 50  → TierBerkembang  (enables auto-enroll in SantriManager)
-- Tier 75  → TierUnggulan    (rechecks zone unlock)
-- Tier 100 → KunjunganMenteri (5× Rupiah for 3 minutes; enables Buka Cabang)
function ReputationManager.checkTierUnlocks(player: Player): ()
	local data = DataService.getPlayerData(player)

	if data.reputation >= Constants.REP_TIER_BERKEMBANG and not data.tierBerkembangFired then
		DataService.updatePlayerData(player, { tierBerkembangFired = true })
		Events.NotifyEvent:FireClient(player, { eventType = "TierBerkembang" })
	end

	if data.reputation >= Constants.REP_TIER_UNGGULAN and not data.tierUnggulanFired then
		DataService.updatePlayerData(player, { tierUnggulanFired = true })
		Events.NotifyEvent:FireClient(player, { eventType = "TierUnggulan" })
		buildingMgr().checkZoneUnlock(player)
	end

	if data.reputation >= Constants.REP_TIER_PRESTIGE_UNLOCK and not data.tierPrestigeFired then
		DataService.updatePlayerData(player, { tierPrestigeFired = true })
		Events.NotifyEvent:FireClient(player, { eventType = "KunjunganMenteri" })
		EconomyService.setKunjunganActive(player, Constants.KUNJUNGAN_MENTERI_DURATION_SEC)
	end
end

-- ─── T21: Buka Cabang (prestige reset) ────────────────────────────────────────

-- Resets the player's pesantren for a new prestige run.
-- Preserves: sanad (+reward), prestigeCount+1, alumniCount, sedekahJariyahPerMin.
-- Resets: rupiah, barakah, ilmu, reputation, all lists, zone, tier flags.
-- Returns false if reputation < 100 (server-side guard — never trust client).
function ReputationManager.bukaCabang(player: Player): boolean
	local data = DataService.getPlayerData(player)

	if data.reputation < Constants.REP_TIER_PRESTIGE_UNLOCK then
		return false
	end

	local sanadReward = 1 + math.floor(data.prestigeCount * 0.5)
	local newPrestigeCount = data.prestigeCount + 1
	local newMultiplier = 1 + (newPrestigeCount * Constants.PRESTIGE_RUPIAH_MULTIPLIER_PER_COUNT)

	-- Destroy this player's workspace building parts before wiping buildingList
	for _, inst in CollectionService:GetTagged("Building") do
		if inst:IsA("BasePart") and inst:GetAttribute("ownerId") == player.UserId then
			inst:Destroy()
		end
	end

	DataService.updatePlayerData(player, {
		-- Currencies reset
		rupiah = Constants.PRESTIGE_STARTING_RUPIAH,
		barakah = 0,
		ilmu = 0,
		-- Reputation & prestige progression
		reputation = 0,
		prestigeCount = newPrestigeCount,
		prestigeMultiplier = newMultiplier,
		-- Sanad preserved + reward
		sanad = data.sanad + sanadReward,
		-- Lists wiped
		santriList = {},
		buildingList = {},
		ustadzList = {},
		-- Zone reset
		zoneUnlocked = 1,
		-- Tier flags reset so the new run re-fires them
		tierBerkembangFired = false,
		tierUnggulanFired = false,
		tierPrestigeFired = false,
		-- alumniCount and sedekahJariyahPerMin intentionally NOT reset (passive income preserved)
	})

	DataService.savePlayer(player)
	ReplicationService.syncAll(player)
	Events.NotifyEvent:FireClient(player, { eventType = "BukaCabang", sanadReward = sanadReward })
	return true
end

-- ─── RemoteEvent: BukaCabang ──────────────────────────────────────────────────

Events.BukaCabang.OnServerEvent:Connect(function(player: Player)
	if not DataService.isLoaded(player) then
		return
	end
	ReputationManager.bukaCabang(player)
end)

return ReputationManager
