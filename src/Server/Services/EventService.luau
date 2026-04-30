--!strict

-- T22: In-game clock (1 real second = 1 in-game minute), seasonal flags, getActiveMultiplier
-- T23: Waktu Sholat — 5 prayer windows/day, acknowledge → 3× Rupiah 60s, Sholat Sempurna chest
-- T24: Jum'at Berkah — in-game day 5 at minute 576, 2× Rupiah for JUMAT_BERKAH_DURATION_MIN real min
-- T25: Seasonal framework — Tarawih, AutoGraduate, Qurban, FreeKyai special mechanics
-- T26: Tabligh Akbar — majority vote (10+ players), 5× income for TABLIGH_AKBAR_DURATION_MIN real min

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local ReplicationService = require(script.Parent.ReplicationService)
local Events = require(ReplicatedStorage.Shared.Net.Events)
local EventData = require(ReplicatedStorage.Shared.Data.EventData)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type SeasonalEvent = Types.SeasonalEvent
type SantriProgram = Types.SantriProgram
type UstadzRecord = Types.UstadzData

-- Lazy: Managers are required after Services in init.server.luau.
-- At runtime all modules are fully loaded before any of these are called.
local function santriMgr()
	return require(script.Parent.Parent.Managers.SantriManager)
end
local function repMgr()
	return require(script.Parent.Parent.Managers.ReputationManager)
end

local EventService = {}

-- ── In-game clock ──────────────────────────────────────────────────────────────
-- 1 real second = 1 in-game minute. One in-game day = 1440 real seconds = 24 real minutes.
local currentDayMinutes: number = 0 -- 0–1439
local currentDayOfWeek: number = 1 -- 1=Mon … 5=Fri … 7=Sun

-- ── Seasonal events ────────────────────────────────────────────────────────────
local activeSeasonals: { [string]: boolean } = {}

-- ── Jum'at Berkah ─────────────────────────────────────────────────────────────
-- Expiry in os.time(); 0 = inactive.
local jumatBerkahExpiry: number = 0

-- ── Tabligh Akbar ─────────────────────────────────────────────────────────────
local tabligExpiry: number = 0
local tabligVoteOpen: boolean = false
local tabligVoters: { [number]: boolean } = {}
local tabligEligibleCount: number = 0
local tabligLastEndTime: number = 0 -- throttle: min 5 min between votes

-- ── Prayer window ─────────────────────────────────────────────────────────────
-- Fire at in-game minutes: 288, 576, 864, 1152, 1440 (= day end).
local PRAYER_MINUTES: { number } = {
	Constants.WAKTU_SHOLAT_INTERVAL_MIN * 1,
	Constants.WAKTU_SHOLAT_INTERVAL_MIN * 2,
	Constants.WAKTU_SHOLAT_INTERVAL_MIN * 3,
	Constants.WAKTU_SHOLAT_INTERVAL_MIN * 4,
	Constants.WAKTU_SHOLAT_INTERVAL_MIN * 5,
}
local prayerFiredThisDay: { [number]: boolean } = {}
local prayerWindowOpenTime: number = 0 -- os.time() when last prayer opened; 0 = none

-- ── Ramadan Tarawih ────────────────────────────────────────────────────────────
local TARAWIH_MINUTE: number = 1200 -- "8 PM" in 1440-minute day
local tarawihFiredToday: boolean = false

-- ── Free-ustadz counter ────────────────────────────────────────────────────────
local freeIdCounter = 0
local function newFreeId(): string
	freeIdCounter += 1
	return "free_" .. tostring(math.floor(tick() * 1000)) .. "_" .. tostring(freeIdCounter)
end

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function spawnFreeKyaiForAll(): ()
	local ALL: { SantriProgram } = { "Tahfidz", "KitabKuning", "Bahasa", "Wirausaha", "Teknologi" }
	for _, player in Players:GetPlayers() do
		if not DataService.isLoaded(player) then
			continue
		end
		local data = DataService.getPlayerData(player)

		local usedPrograms: { [string]: boolean } = {}
		for _, u in data.ustadzList do
			usedPrograms[u.program :: string] = true
		end

		local chosen: SantriProgram? = nil
		for _, prog in ALL do
			if not usedPrograms[prog :: string] then
				chosen = prog
				break
			end
		end
		if chosen == nil then
			continue -- all slots filled for this player
		end

		local id = newFreeId()
		data.ustadzList[id] = {
			id = id,
			program = chosen,
			skill = 5,
			kharisma = 5,
			fatigue = 100,
			rarity = "KyaiBesar",
			liburUntil = nil,
		}
		ReplicationService.syncAll(player)

		-- Remove after 24 in-game hours (1440 real seconds at 1:1 clock ratio)
		local playerId = player.UserId
		local ustadzId = id
		task.delay(1440, function()
			local p = Players:GetPlayerByUserId(playerId)
			if p == nil or not DataService.isLoaded(p) then
				return
			end
			local d = DataService.getPlayerData(p)
			;(d.ustadzList :: { [string]: UstadzRecord? })[ustadzId] = nil
			ReplicationService.syncAll(p)
		end)
	end
end

local function onSeasonalStart(event: SeasonalEvent): ()
	local def = (EventData :: any)[event :: string]
	if def == nil then
		return
	end

	-- Flat reputation bonus to all online players
	local repBonus = (def.reputationBonus :: any) :: number
	if repBonus > 0 then
		for _, player in Players:GetPlayers() do
			if DataService.isLoaded(player) then
				repMgr().addReputation(player, repBonus)
			end
		end
	end

	-- Special mechanics
	local mechanic = (def.specialMechanic :: any) :: string?
	if mechanic == "AutoGraduate" then
		-- Idul Fitri: graduate every santri at studyProgress >= 80
		for _, player in Players:GetPlayers() do
			if DataService.isLoaded(player) then
				santriMgr().graduateAllEligible(player, 80)
			end
		end
	elseif mechanic == "FreeKyai" then
		-- Maulid Nabi: one free KyaiBesar ustadz per player for 24 in-game hours
		spawnFreeKyaiForAll()
	end
	-- "Tarawih"        → handled in the clock loop at TARAWIH_MINUTE
	-- "NightTheme"     → client-side skybox; triggered by SeasonalTheme notify
	-- "LeaderboardReset" → T29
	-- "Qurban"         → TriggerQurban RemoteEvent handler (below)
end

-- ── Tabligh Akbar helpers (closeTabligVote first — referenced by checkTabligTrigger) ──

local function closeTabligVote(): ()
	if not tabligVoteOpen then
		return
	end
	tabligVoteOpen = false
	tabligLastEndTime = os.time()

	local yesCount = 0
	for _ in tabligVoters do
		yesCount += 1
	end

	if tabligEligibleCount > 0 and yesCount > tabligEligibleCount / 2 then
		tabligExpiry = os.time() + Constants.TABLIGH_AKBAR_DURATION_MIN * 60

		for _, player in Players:GetPlayers() do
			Events.NotifyEvent:FireClient(player, { eventType = "TabligStart" })
			-- Deduct Barakah from voters; skip silently if insufficient
			if DataService.isLoaded(player) and tabligVoters[player.UserId] then
				EconomyService.spendCurrency(
					player, "Barakah", Constants.TABLIGH_AKBAR_BARAKAH_COST
				)
			end
		end
	end
end

local function checkTabligTrigger(): ()
	if tabligVoteOpen then
		return
	end
	if os.time() < tabligExpiry then
		return -- already active
	end
	if os.time() < tabligLastEndTime + 300 then
		return -- 5-minute cooldown between votes
	end

	local playerList = Players:GetPlayers()
	if #playerList < Constants.TABLIGH_AKBAR_MIN_PLAYERS then
		return
	end

	tabligVoteOpen = true
	tabligVoters = {}
	tabligEligibleCount = #playerList

	for _, player in playerList do
		Events.NotifyEvent:FireClient(player, { eventType = "TabligVoteOpen" })
	end

	task.delay(60, closeTabligVote)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function EventService.isSeasonalActive(event: SeasonalEvent): boolean
	return activeSeasonals[event :: string] == true
end

-- Activates or deactivates a seasonal event server-wide.
-- Fires on-start effects (rep bonus, special mechanic) when going active.
-- Notifies all clients with SeasonalTheme so they can update visuals/audio.
function EventService.setSeasonalEvent(event: SeasonalEvent, active: boolean): ()
	local wasActive = activeSeasonals[event :: string] == true
	activeSeasonals[event :: string] = active

	if active and not wasActive then
		onSeasonalStart(event)
	end

	ReplicationService.broadcastToServer("NotifyEvent", {
		eventType = "SeasonalTheme",
		theme = event :: string,
		active = active,
	})
end

-- Returns the combined Rupiah income multiplier from all active server-wide events.
-- Called by EconomyService.addCurrency for every Rupiah transaction.
function EventService.getActiveMultiplier(_player: Player): number
	local m = 1

	for eventName, isActive in activeSeasonals do
		if isActive then
			local def = (EventData :: any)[eventName]
			if def ~= nil then
				m *= (def.incomeMultiplier :: any) :: number
			end
		end
	end

	if os.time() < jumatBerkahExpiry then
		m *= Constants.JUMAT_BERKAH_MULTIPLIER
	end

	if os.time() < tabligExpiry then
		m *= Constants.TABLIGH_AKBAR_MULTIPLIER
	end

	return m
end

-- Returns the combined Barakah multiplier from active seasonal events.
-- Called by EconomyService.addCurrency for every Barakah transaction.
function EventService.getActiveBarakahMultiplier(): number
	local m = 1
	for eventName, isActive in activeSeasonals do
		if isActive then
			local def = (EventData :: any)[eventName]
			if def ~= nil then
				m *= (def.barakahMultiplier :: any) :: number
			end
		end
	end
	return m
end

-- ── Main clock loop ────────────────────────────────────────────────────────────

-- Starts the in-game clock and all event loops.
-- Called once from init.server.luau after all modules are loaded.
function EventService.start(): ()
	task.spawn(function()
		while true do
			task.wait(1) -- 1 real second = 1 in-game minute

			currentDayMinutes += 1

			-- ── Waktu Sholat prayer windows (T23) ─────────────────────────
			for i, minute in PRAYER_MINUTES do
				if currentDayMinutes == minute and not prayerFiredThisDay[i] then
					prayerFiredThisDay[i] = true
					prayerWindowOpenTime = os.time()
					for _, player in Players:GetPlayers() do
						Events.NotifyEvent:FireClient(player, { eventType = "WaktuSholat" })
					end
				end
			end

			-- ── Ramadan Tarawih (T25) — nightly at 8 PM ───────────────────
			if activeSeasonals["Ramadan"] == true
				and currentDayMinutes == TARAWIH_MINUTE
				and not tarawihFiredToday
			then
				tarawihFiredToday = true
				for _, player in Players:GetPlayers() do
					if DataService.isLoaded(player) then
						EconomyService.addCurrency(player, "Barakah", Constants.TARAWIH_BARAKAH_REWARD)
					end
				end
				ReplicationService.broadcastToServer("NotifyEvent", { eventType = "Tarawih" })
			end

			-- ── Jum'at Berkah (T24) — day 5, Dhuhr window (minute 576) ───
			if currentDayOfWeek == 5
				and currentDayMinutes == PRAYER_MINUTES[2]
				and os.time() > jumatBerkahExpiry -- not already active
			then
				jumatBerkahExpiry = os.time() + Constants.JUMAT_BERKAH_DURATION_MIN * 60
				ReplicationService.broadcastToServer("NotifyEvent", { eventType = "JumatBerkah" })
			end

			-- ── Tabligh Akbar vote check (T26) — every 5 in-game minutes ──
			if currentDayMinutes % 5 == 0 then
				checkTabligTrigger()
			end

			-- ── Day rollover at minute 1440 ────────────────────────────────
			if currentDayMinutes >= 1440 then
				-- Sholat Sempurna chest — must check before dailyPrayerCount resets
				for _, player in Players:GetPlayers() do
					if DataService.isLoaded(player) then
						local data = DataService.getPlayerData(player)
						if data.dailyPrayerCount >= 5 then
							EconomyService.addCurrency(
								player, "Rupiah", Constants.SHOLAT_SEMPURNA_RUPIAH
							)
							EconomyService.addCurrency(
								player, "Barakah", Constants.SHOLAT_SEMPURNA_BARAKAH
							)
							Events.NotifyEvent:FireClient(player, { eventType = "SholatSempurna" })
						end
						DataService.updatePlayerData(player, { dailyPrayerCount = 0 })
					end
				end

				currentDayMinutes = 0
				currentDayOfWeek = (currentDayOfWeek % 7) + 1
				prayerFiredThisDay = {}
				tarawihFiredToday = false
			end
		end
	end)
end

-- ── RemoteEvent handlers ──────────────────────────────────────────────────────

-- T23: Player acknowledges Waktu Sholat within the 60-second window.
Events.AcknowledgeWaktuSholat.OnServerEvent:Connect(function(player: Player)
	if prayerWindowOpenTime == 0 then
		return -- no prayer window has ever opened
	end
	local windowExpiry = prayerWindowOpenTime + Constants.WAKTU_SHOLAT_DURATION_SEC
	if os.time() > windowExpiry then
		return -- window has closed
	end
	if not DataService.isLoaded(player) then
		return
	end
	local data = DataService.getPlayerData(player)
	-- Guard: don't let the player acknowledge the same prayer window twice.
	-- If their waktuSholatExpiry is still within this window, they already acknowledged.
	if data.waktuSholatExpiry > prayerWindowOpenTime then
		return
	end
	DataService.updatePlayerData(player, {
		waktuSholatActive = true,
		waktuSholatExpiry = os.time() + Constants.WAKTU_SHOLAT_DURATION_SEC,
		dailyPrayerCount = data.dailyPrayerCount + 1,
	})
	ReplicationService.syncAll(player)
end)

-- T26: Player casts a vote for Tabligh Akbar.
Events.VoteTabligAkbar.OnServerEvent:Connect(function(player: Player)
	if tabligVoteOpen then
		tabligVoters[player.UserId] = true
	end
end)

-- T25: Player performs Qurban sacrifice (only during Idul Adha).
Events.TriggerQurban.OnServerEvent:Connect(function(player: Player)
	if not activeSeasonals["IdulAdha"] then
		return
	end
	if not DataService.isLoaded(player) then
		return
	end
	if not EconomyService.spendCurrency(player, "Rupiah", 1000) then
		return
	end
	repMgr().addReputation(player, 10)
	ReplicationService.broadcastToServer("NotifyEvent", {
		eventType = "QurbanEvent",
		player = player.Name,
	})
end)

-- ─── T42: Tutorial step advancement ──────────────────────────────────────────
-- trigger strings map to the step they complete:
--   "Musholla" → step 1, "Dormitory" → step 2, "EnrollSantri" → step 3,
--   "Education" → step 4, "HireUstadz" → step 5, "Graduation" → step 6
local TUTORIAL_TRIGGERS: { [string]: number } = {
	Musholla     = 1,
	Dormitory    = 2,
	EnrollSantri = 3,
	Education    = 4,
	HireUstadz   = 5,
	Graduation   = 6,
}

function EventService.advanceTutorialStep(player: Player, trigger: string): ()
	if not DataService.isLoaded(player) then
		return
	end
	local data = DataService.getPlayerData(player)
	if data.tutorialStep >= 6 then
		return
	end
	local nextStep = TUTORIAL_TRIGGERS[trigger]
	if nextStep == nil then
		return
	end
	-- Enforce sequential order — only advance if this trigger is the next expected step
	if data.tutorialStep ~= nextStep - 1 then
		return
	end
	DataService.updatePlayerData(player, { tutorialStep = nextStep })
	if nextStep == 6 then
		Events.NotifyEvent:FireClient(player, { eventType = "TutorialComplete" })
	else
		Events.NotifyEvent:FireClient(player, { eventType = "TutorialStep", step = nextStep })
	end
	ReplicationService.syncAll(player)
end

-- SkipTutorial: allowed from step 3 onward
Events.SkipTutorial.OnServerEvent:Connect(function(player: Player)
	if not DataService.isLoaded(player) then
		return
	end
	local data = DataService.getPlayerData(player)
	if data.tutorialStep < 3 or data.tutorialStep >= 6 then
		return
	end
	DataService.updatePlayerData(player, { tutorialStep = 6 })
	Events.NotifyEvent:FireClient(player, { eventType = "TutorialComplete" })
	ReplicationService.syncAll(player)
end)

return EventService
