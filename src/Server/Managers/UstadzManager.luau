--!strict

-- T18: hireUstadz (rarity roll, cost, one-per-program), getUstadzForProgram, getUstadzCount
-- T19: 60-min fatigue decay tick, UstadzTired notification, restoreUstadz, sendLibur

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.Parent.Services.DataService)
local EconomyService = require(script.Parent.Parent.Services.EconomyService)
local ReplicationService = require(script.Parent.Parent.Services.ReplicationService)

-- Lazy: EventService → UstadzManager would be circular at load time
local function getEventSvc()
	return require(script.Parent.Parent.Services.EventService)
end
local Events = require(ReplicatedStorage.Shared.Net.Events)
local UstadzDefs = require(ReplicatedStorage.Shared.Data.UstadzData)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type UstadzRecord = Types.UstadzData
type UstadzHireCost = Types.UstadzHireCost
type PlayerData = Types.PlayerData
type SantriProgram = Types.SantriProgram
type UstadzRarity = Types.UstadzRarity

local UstadzManager = {}

local idCounter = 0

-- ─── Internal helpers ─────────────────────────────────────────────────────────

local function generateId(): string
	idCounter += 1
	return "ustadz_" .. tostring(math.floor(tick() * 1000)) .. "_" .. tostring(idCounter)
end

-- Rolls rarity using UstadzData.rarityWeights (must sum to 100).
local function rollRarity(): UstadzRarity
	local r = math.random(1, 100)
	local cumulative = 0
	local ORDER: { UstadzRarity } = { "Biasa", "Terkenal", "KyaiBesar", "KyaiInternasional" }
	for _, rarity in ORDER do
		cumulative += (UstadzDefs.rarityWeights :: { [string]: number })[rarity :: string] or 0
		if r <= cumulative then
			return rarity
		end
	end
	return "Biasa"
end

-- ─── Public API ────────────────────────────────────────────────────────────────

function UstadzManager.getUstadzCount(player: Player): number
	local n = 0
	for _ in DataService.getPlayerData(player).ustadzList do
		n += 1
	end
	return n
end

-- Returns the ustadz for the given program, or nil if none hired or currently on libur.
function UstadzManager.getUstadzForProgram(player: Player, program: SantriProgram): UstadzRecord?
	for _, u in DataService.getPlayerData(player).ustadzList do
		if u.program == program then
			if u.liburUntil ~= nil and os.time() < u.liburUntil then
				return nil -- on libur; not available
			end
			return u
		end
	end
	return nil
end

-- Hires a new ustadz for `program`.
-- `targetRarity` nil = roll rarity from weight table.
-- Returns false if: slot already filled, KyaiInternasional requested (no direct hire),
-- insufficient funds, or invalid rarity.
function UstadzManager.hireUstadz(
	player: Player,
	program: SantriProgram,
	targetRarity: UstadzRarity?
): boolean
	local data = DataService.getPlayerData(player)

	-- One ustadz per program in v1
	for _, u in data.ustadzList do
		if u.program == program then
			return false
		end
	end

	local rarity: UstadzRarity = if targetRarity ~= nil then targetRarity else rollRarity()

	-- KyaiInternasional has no direct hire path (Maulid Nabi event / Sanad unlock only)
	if rarity == "KyaiInternasional" then
		return false
	end

	local costEntry: UstadzHireCost? = (UstadzDefs.hireCost :: { [string]: UstadzHireCost })[rarity :: string]
	if costEntry == nil then
		return false
	end
	if not EconomyService.spendCurrency(player, costEntry.currency, costEntry.amount) then
		return false
	end

	local id = generateId()
	data.ustadzList[id] = {
		id = id,
		program = program,
		skill = math.random(1, 5),
		kharisma = math.random(1, 5),
		fatigue = 100,
		rarity = rarity,
		liburUntil = nil,
	}

	-- Broadcast notable hires to all players
	if rarity == "KyaiBesar" then
		ReplicationService.broadcastToServer("NotifyKyaiBesar", {
			ustadzRarity = rarity :: string,
			pesantrenOwner = player.Name,
		})
	end

	ReplicationService.syncAll(player)
	-- T42: tutorial step 5 — first ustadz hired
	getEventSvc().advanceTutorialStep(player, "HireUstadz")
	return true
end

-- Spends USTADZ_RESTORE_COST_RUPIAH to top up the ustadz's fatigue by USTADZ_RESTORE_AMOUNT.
-- Returns false on insufficient funds or invalid ustadzId; refunds on late id-miss.
function UstadzManager.restoreUstadz(player: Player, ustadzId: string): boolean
	if not EconomyService.spendCurrency(player, "Rupiah", Constants.USTADZ_RESTORE_COST_RUPIAH) then
		return false
	end
	local ustadz = DataService.getPlayerData(player).ustadzList[ustadzId]
	if ustadz == nil then
		EconomyService.addCurrency(player, "Rupiah", Constants.USTADZ_RESTORE_COST_RUPIAH)
		return false
	end
	ustadz.fatigue = math.min(100, ustadz.fatigue + Constants.USTADZ_RESTORE_AMOUNT)
	ReplicationService.syncAll(player)
	return true
end

-- Sends the ustadz on a 2-hour libur (full fatigue recovery on return).
-- Ustadz cannot teach while liburUntil has not expired.
function UstadzManager.sendLibur(player: Player, ustadzId: string): ()
	local ustadz = DataService.getPlayerData(player).ustadzList[ustadzId]
	if ustadz == nil then
		return
	end
	ustadz.liburUntil = os.time() + Constants.USTADZ_LIBUR_DURATION_SEC
	ReplicationService.syncAll(player)
end

-- ─── T19: 60-minute fatigue decay tick ────────────────────────────────────────

task.spawn(function()
	while true do
		task.wait(3600) -- 60 real minutes

		for _, player in Players:GetPlayers() do
			if not DataService.isLoaded(player) then
				continue
			end
			local data = DataService.getPlayerData(player)
			local changed = false

			for ustadzId, ustadz in data.ustadzList do
				if ustadz.liburUntil ~= nil then
					-- Libur in progress or just ended
					if os.time() >= ustadz.liburUntil then
						ustadz.fatigue = 100
						ustadz.liburUntil = nil
						changed = true
					end
					-- No decay while on libur
				else
					local prev = ustadz.fatigue
					ustadz.fatigue = math.max(0, prev - Constants.USTADZ_FATIGUE_DECAY_PER_HOUR)
					changed = true

					if ustadz.fatigue < Constants.USTADZ_CANT_TEACH_THRESHOLD
						and prev >= Constants.USTADZ_CANT_TEACH_THRESHOLD
					then
						-- Threshold just crossed — notify once
						Events.NotifyEvent:FireClient(player, {
							eventType = "UstadzTired",
							ustadzId = ustadzId,
						})
					end
				end
			end

			if changed then
				ReplicationService.syncAll(player)
			end
		end
	end
end)

-- ─── RemoteEvent: HireUstadz ──────────────────────────────────────────────────

Events.HireUstadz.OnServerEvent:Connect(function(player: Player, rawProgram: any, rawRarity: any)
	if type(rawProgram) ~= "string" then
		return
	end
	if not DataService.isLoaded(player) then
		return
	end
	local targetRarity: UstadzRarity? = nil
	if type(rawRarity) == "string" then
		targetRarity = rawRarity :: UstadzRarity
	end
	UstadzManager.hireUstadz(player, rawProgram :: SantriProgram, targetRarity)
end)

return UstadzManager
