--!strict

-- T13: enrollSantri, getSantriCount, getMaxCapacity, dropoutSantri + auto-enroll
-- T14: 60-second needs decay loop with building-based modifiers
-- T15: study progress + ujian graduation on the same 60-second tick
-- T16: 10-minute masalah (random crisis) loop with cascade and fast-resolve bonus

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.Parent.Services.DataService)
local EconomyService = require(script.Parent.Parent.Services.EconomyService)
local ReplicationService = require(script.Parent.Parent.Services.ReplicationService)
local ReputationManager = require(script.Parent.ReputationManager)
local BuildingManager = require(script.Parent.BuildingManager)
local Events = require(ReplicatedStorage.Shared.Net.Events)
local SantriDefs = require(ReplicatedStorage.Shared.Data.SantriData)
local BuildingDefs = require(ReplicatedStorage.Shared.Data.BuildingData)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

-- Type aliases to avoid name collision with the static-data modules
type SantriRecord = Types.SantriData
type UstadzRecord = Types.UstadzData
type PlayerData = Types.PlayerData
type SantriProgram = Types.SantriProgram
type BuildingType = Types.BuildingType
type MasalahType = Types.MasalahType
type MasalahEvent = Types.MasalahEvent

local SantriManager = {}

-- ─── Module-level state ────────────────────────────────────────────────────────

local idCounter = 0

type ActiveMasalahEntry = {
	masalah: MasalahEvent,
	playerId: number,
	affectedIds: { string }, -- santriIds (SantriSakit/BanjirAsrama) or ustadzId (UstadzAbsen)
}

local activeMasalah: { [string]: ActiveMasalahEntry } = {}

-- Players whose unresolved masalah cascaded; dropout chance doubles until cleared
local cascadedPlayers: { [number]: boolean } = {}

-- ─── Internal helpers ─────────────────────────────────────────────────────────

local function generateId(prefix: string): string
	idCounter += 1
	return prefix .. "_" .. tostring(math.floor(tick() * 1000)) .. "_" .. tostring(idCounter)
end

local function hasBuilding(data: PlayerData, buildingType: BuildingType): boolean
	for _, b in data.buildingList do
		if b.buildingType == buildingType then
			return true
		end
	end
	return false
end

local function maxBuildingLevel(data: PlayerData, buildingType: BuildingType): number
	local maxLvl = 0
	for _, b in data.buildingList do
		if b.buildingType == buildingType and b.level > maxLvl then
			maxLvl = b.level
		end
	end
	return maxLvl
end

-- Returns first active ustadz assigned to the given program, or nil.
local function getUstadzForProgram(data: PlayerData, program: SantriProgram): UstadzRecord?
	for _, u in data.ustadzList do
		if u.program == program then
			return u
		end
	end
	return nil
end

-- Selects a program for auto-enroll: prefers programs that have an active ustadz,
-- falls back to any program whose required building is present.
local function selectAutoEnrollProgram(data: PlayerData): SantriProgram?
	local withUstadz: { SantriProgram } = {}
	for _, u in data.ustadzList do
		table.insert(withUstadz, u.program)
	end
	if #withUstadz > 0 then
		return withUstadz[math.random(1, #withUstadz)]
	end

	local ALL: { SantriProgram } = { "Tahfidz", "KitabKuning", "Bahasa", "Wirausaha", "Teknologi" }
	local available: { SantriProgram } = {}
	for _, prog in ALL do
		local def = SantriDefs[prog]
		local req = def.requiredBuilding
		if req == nil or hasBuilding(data, req) then
			table.insert(available, prog)
		end
	end
	if #available == 0 then
		return nil
	end
	return available[math.random(1, #available)]
end

local function rollMasalahType(): MasalahType
	local r = math.random(1, 100)
	if r <= 40 then
		return "SantriSakit"
	elseif r <= 75 then
		return "UstadzAbsen"
	else
		return "BanjirAsrama"
	end
end

-- ─── Public API ────────────────────────────────────────────────────────────────

function SantriManager.getSantriCount(player: Player): number
	local n = 0
	for _ in DataService.getPlayerData(player).santriList do
		n += 1
	end
	return n
end

-- Total dormitory capacity across all Dormitory buildings the player owns.
function SantriManager.getMaxCapacity(player: Player): number
	local data = DataService.getPlayerData(player)
	local total = 0
	for _, b in data.buildingList do
		if b.buildingType == "Dormitory" then
			local tier = BuildingDefs.Dormitory.tiers[b.level]
			if tier ~= nil then
				total += tier.capacity
			end
		end
	end
	return total
end

-- Enrolls a new santri for the given program.
-- Validates: capacity, required building present. Returns false on any failure.
function SantriManager.enrollSantri(player: Player, program: SantriProgram): boolean
	local data = DataService.getPlayerData(player)

	if SantriManager.getSantriCount(player) >= SantriManager.getMaxCapacity(player) then
		return false
	end

	local progDef = SantriDefs[program]
	local reqBuilding = progDef.requiredBuilding
	if reqBuilding ~= nil and not hasBuilding(data, reqBuilding) then
		return false
	end

	local id = generateId("santri")
	data.santriList[id] = {
		id = id,
		program = program,
		needMakan = 100,
		needIlmu = 100,
		needIbadah = 100,
		needIstirahat = 100,
		studyProgress = 0,
		enrollTime = os.time(),
	}

	ReplicationService.syncAll(player)
	BuildingManager.checkZoneUnlock(player)
	return true
end

-- Removes a santri and notifies the client.
function SantriManager.dropoutSantri(player: Player, santriId: string): ()
	local data = DataService.getPlayerData(player);
	(data.santriList :: { [string]: SantriRecord? })[santriId] = nil
	Events.NotifyEvent:FireClient(player, { eventType = "SantriDropout", santriId = santriId })
	ReplicationService.syncAll(player)
end

-- ─── Graduation handler ────────────────────────────────────────────────────────

local function graduateSantri(player: Player, santriId: string, santri: SantriRecord): ()
	local data = DataService.getPlayerData(player);
	(data.santriList :: { [string]: SantriRecord? })[santriId] = nil

	local sedekahBonus = SantriDefs[santri.program].alumniSedekahBonus
	DataService.updatePlayerData(player, {
		alumniCount = data.alumniCount + 1,
		sedekahJariyahPerMin = data.sedekahJariyahPerMin + sedekahBonus,
	})

	ReputationManager.addReputation(player, Constants.REP_PER_GRADUATION)
	Events.NotifyGraduation:FireClient(player, santriId, santri.program)
end

-- ─── Masalah resolve / tutoring handlers ──────────────────────────────────────

local function handleTutoring(player: Player, santriId: string): ()
	if not EconomyService.spendCurrency(player, "Rupiah", Constants.TUTORING_COST_RUPIAH) then
		return
	end
	local santri = DataService.getPlayerData(player).santriList[santriId]
	if santri == nil then
		return
	end
	santri.studyProgress = Constants.TUTORING_PROGRESS_RESET
	ReplicationService.syncAll(player)
end

local function handleMasalahResolve(player: Player, masalahId: string): ()
	local entry = activeMasalah[masalahId]
	if entry == nil or entry.playerId ~= player.UserId or entry.masalah.resolved then
		return
	end

	local eventType = entry.masalah.eventType
	local data = DataService.getPlayerData(player)

	if eventType == "SantriSakit" then
		if not hasBuilding(data, "Klinik") then
			if not EconomyService.spendCurrency(player, "Rupiah", Constants.MASALAH_SANTRISAKIT_COST) then
				return
			end
		end
	elseif eventType == "UstadzAbsen" then
		-- Prefer Rupiah (substitute); fall back to Barakah (instant recovery)
		local spentRupiah = EconomyService.spendCurrency(
			player, "Rupiah", Constants.MASALAH_USTADZABSEN_COST_RUPIAH
		)
		if not spentRupiah then
			if not EconomyService.spendCurrency(
				player, "Barakah", Constants.MASALAH_USTADZABSEN_COST_BARAKAH
			) then
				return
			end
			-- Barakah = instant recovery: restore affected ustadz fatigue
			if #entry.affectedIds > 0 then
				local ustadz = data.ustadzList[entry.affectedIds[1]]
				if ustadz ~= nil then
					ustadz.fatigue = 100
				end
			end
		end
	elseif eventType == "BanjirAsrama" then
		if not EconomyService.spendCurrency(player, "Rupiah", Constants.MASALAH_BANJIR_COST) then
			return
		end
	end

	entry.masalah.resolved = true
	activeMasalah[masalahId] = nil
	cascadedPlayers[player.UserId] = nil

	local elapsed = os.time() - entry.masalah.triggeredAt
	if elapsed < Constants.MASALAH_FAST_RESOLVE_MIN * 60 then
		ReputationManager.addReputation(player, Constants.REP_PER_MASALAH_FAST_RESOLVE)
	end

	ReplicationService.syncAll(player)
end

-- ─── 60-second tick: needs decay (T14) + study/graduation (T15) ───────────────

task.spawn(function()
	while true do
		task.wait(60)

		for _, player in Players:GetPlayers() do
			if not DataService.isLoaded(player) then
				continue
			end
			local data = DataService.getPlayerData(player)

			local hasFood = hasBuilding(data, "Food")
			local hasIbadah = hasBuilding(data, "Musholla")
			local dormLvl = maxBuildingLevel(data, "Dormitory")
			local hasEducation = hasBuilding(data, "Education")

			local toDropout: { string } = {}
			local toGraduate: { string } = {}
			local barakahGain = 0

			for santriId, santri in data.santriList do
				-- ── Needs decay ────────────────────────────────────────────────
				local makanDecay = Constants.NEED_MAKAN_DECAY
				if hasFood then
					makanDecay *= 0.5
				end

				local ilmuDecay = Constants.NEED_ILMU_DECAY
				local ustadz = getUstadzForProgram(data, santri.program)
				if hasEducation and ustadz ~= nil then
					ilmuDecay *= 0.30 -- 70% reduction
				end

				local ibadahDecay = Constants.NEED_IBADAH_DECAY
				if hasIbadah then
					ibadahDecay *= 0.40 -- 60% reduction
				end

				local istirahatDecay = Constants.NEED_ISTIRAHAT_DECAY
				if dormLvl >= 2 then
					istirahatDecay *= 0.60 -- 40% reduction
				end

				santri.needMakan = math.clamp(santri.needMakan - makanDecay, 0, 100)
				santri.needIlmu = math.clamp(santri.needIlmu - ilmuDecay, 0, 100)
				santri.needIbadah = math.clamp(santri.needIbadah - ibadahDecay, 0, 100)
				santri.needIstirahat = math.clamp(santri.needIstirahat - istirahatDecay, 0, 100)

				-- ── Happiness effects ─────────────────────────────────────────
				local happiness = (santri.needMakan + santri.needIlmu + santri.needIbadah + santri.needIstirahat) / 4

				if happiness > Constants.HAPPINESS_BONUS_THRESHOLD then
					barakahGain += 0.1
				end

				if happiness < Constants.HAPPINESS_DROPOUT_THRESHOLD then
					local dropChance = cascadedPlayers[player.UserId] and 0.20 or 0.10
					if math.random() < dropChance then
						table.insert(toDropout, santriId)
						continue -- skip study progress for this santri
					end
				end

				-- ── Study progress (T15) ──────────────────────────────────────
				if ustadz ~= nil and ustadz.fatigue > Constants.USTADZ_CANT_TEACH_THRESHOLD then
					santri.studyProgress = math.min(100, santri.studyProgress + Constants.STUDY_PROGRESS_PER_MIN)
				end

				if santri.studyProgress >= 100 and ustadz ~= nil then
					local passChance = Constants.UJIAN_PASS_CHANCE_BASE + ustadz.skill * 0.04
					if math.random() <= passChance then
						table.insert(toGraduate, santriId)
					else
						santri.studyProgress = 0
						Events.NotifyEvent:FireClient(player, { eventType = "UjianFail", santriId = santriId })
					end
					-- studyProgress stays at 100 while no ustadz is assigned; ujian held on reunion
				end
			end

			-- Apply dropout and graduation after iteration (safe table mutation)
			for _, id in toDropout do
				SantriManager.dropoutSantri(player, id)
			end
			for _, id in toGraduate do
				local santri = data.santriList[id]
				if santri ~= nil then
					graduateSantri(player, id, santri)
				end
			end

			if barakahGain > 0 then
				EconomyService.addCurrency(player, "Barakah", barakahGain)
			end

			ReplicationService.syncAll(player)
		end
	end
end)

-- ─── Auto-enroll loop (T13) — one free santri every 5 min when rep ≥ 50 ──────

task.spawn(function()
	while true do
		task.wait(Constants.AUTO_ENROLL_INTERVAL_MIN * 60)

		for _, player in Players:GetPlayers() do
			if not DataService.isLoaded(player) then
				continue
			end
			local data = DataService.getPlayerData(player)
			if data.reputation < Constants.REP_TIER_BERKEMBANG then
				continue
			end
			local program = selectAutoEnrollProgram(data)
			if program == nil then
				continue
			end
			SantriManager.enrollSantri(player, program)
		end
	end
end)

-- ─── Masalah loop (T16) — 30% chance per player every 10 minutes ─────────────

task.spawn(function()
	while true do
		task.wait(Constants.MASALAH_ROLL_INTERVAL_MIN * 60)

		for _, player in Players:GetPlayers() do
			if not DataService.isLoaded(player) then
				continue
			end
			if math.random() > Constants.MASALAH_TRIGGER_CHANCE then
				continue
			end

			local data = DataService.getPlayerData(player)
			local eventType = rollMasalahType()
			local affected: { string } = {}

			if eventType == "SantriSakit" then
				-- Force 3 random santri needs to 10
				local pool: { string } = {}
				for id in data.santriList do
					table.insert(pool, id)
				end
				for _ = 1, math.min(3, #pool) do
					local idx = math.random(1, #pool)
					local id = table.remove(pool, idx)
					local santri = data.santriList[id]
					if santri ~= nil then
						santri.needMakan = 10
						santri.needIlmu = 10
						table.insert(affected, id)
					end
				end

				-- Klinik present → free auto-resolve, skip client notify
				if hasBuilding(data, "Klinik") then
					ReplicationService.syncAll(player)
					continue
				end

			elseif eventType == "UstadzAbsen" then
				local pool: { string } = {}
				for id in data.ustadzList do
					table.insert(pool, id)
				end
				if #pool == 0 then
					continue -- no ustadz, skip event
				end
				local id = pool[math.random(1, #pool)]
				local ustadz = data.ustadzList[id]
				if ustadz ~= nil then
					ustadz.fatigue = 0
					table.insert(affected, id)
				end

			elseif eventType == "BanjirAsrama" then
				-- All santri needIstirahat → 20
				for id, santri in data.santriList do
					santri.needIstirahat = 20
					table.insert(affected, id)
				end
			end

			local masalahId = generateId(eventType)
			local masalah: MasalahEvent = {
				id = masalahId,
				eventType = eventType,
				severity = math.random(1, 3),
				triggeredAt = os.time(),
				resolved = false,
			}

			activeMasalah[masalahId] = {
				masalah = masalah,
				playerId = player.UserId,
				affectedIds = affected,
			}

			Events.NotifyMasalah:FireClient(player, masalah)

			-- Cascade after MASALAH_EXPIRE_MIN if unresolved
			task.delay(Constants.MASALAH_EXPIRE_MIN * 60, function()
				local entry = activeMasalah[masalahId]
				if entry == nil or entry.masalah.resolved then
					return
				end
				cascadedPlayers[player.UserId] = true

				local cascadePlayer = Players:GetPlayerByUserId(entry.playerId)
				if cascadePlayer == nil or not DataService.isLoaded(cascadePlayer) then
					activeMasalah[masalahId] = nil
					return
				end
				local cd = DataService.getPlayerData(cascadePlayer)
				-- Additional 20-point need penalty to affected entities
				if eventType == "SantriSakit" or eventType == "BanjirAsrama" then
					for _, id in entry.affectedIds do
						local s = cd.santriList[id]
						if s ~= nil then
							s.needMakan = math.max(0, s.needMakan - 20)
							s.needIstirahat = math.max(0, s.needIstirahat - 20)
						end
					end
				elseif eventType == "UstadzAbsen" then
					-- All santri of the absent ustadz's program lose Ilmu needs
					if #entry.affectedIds > 0 then
						local u = cd.ustadzList[entry.affectedIds[1]]
						if u ~= nil then
							for _, s in cd.santriList do
								if s.program == u.program then
									s.needIlmu = math.max(0, s.needIlmu - 20)
								end
							end
						end
					end
				end

				ReplicationService.syncAll(cascadePlayer)
			end)
		end
	end
end)

-- ─── RemoteEvent: ResolveMasalah ──────────────────────────────────────────────

local UJIAN_PREFIX = "UjianFail_"

Events.ResolveMasalah.OnServerEvent:Connect(function(player: Player, rawId: any)
	if type(rawId) ~= "string" then
		return
	end
	if not DataService.isLoaded(player) then
		return
	end

	if string.sub(rawId, 1, #UJIAN_PREFIX) == UJIAN_PREFIX then
		handleTutoring(player, string.sub(rawId, #UJIAN_PREFIX + 1))
	else
		handleMasalahResolve(player, rawId)
	end
end)

return SantriManager
