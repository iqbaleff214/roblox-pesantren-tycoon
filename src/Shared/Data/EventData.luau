--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type SeasonalEvent = Types.SeasonalEvent
type EventDefinition = Types.EventDefinition

-- Seasonal event definitions keyed by SeasonalEvent.
-- `durationDays`       = in-game days the event is active.
-- `barakahMultiplier`  = multiplied on top of base (1.0 = no change; 2.0 = double Barakah).
-- `incomeMultiplier`   = multiplied on top of base for Rupiah income.
-- `reputationBonus`    = flat rep added to all online players when the event starts.
-- `specialMechanic`    = string key used by EventService to trigger unique behaviour:
--                        "Tarawih"       → nightly Tarawih bonus window (+10 Barakah)
--                        "AutoGraduate"  → auto-graduate all santri at studyProgress ≥ 80
--                        "Qurban"        → enables TriggerQurban RemoteEvent
--                        "FreeKyai"      → all players get a free KyaiBesar ustadz for 24h
--                        "NightTheme"    → nighttime skybox override on client
--                        "LeaderboardReset" → yearly leaderboard wipe

local EventData: { [SeasonalEvent]: EventDefinition } = {

	Ramadan = {
		displayName = "Ramadan Mubarak",
		durationDays = 30,
		barakahMultiplier = 2.0, -- double Barakah for the full month
		incomeMultiplier = 1.0,  -- income unchanged (fasting theme)
		reputationBonus = 5,
		specialMechanic = "Tarawih",
	},

	IdulFitri = {
		displayName = "Idul Fitri",
		durationDays = 3,
		barakahMultiplier = 1.5,
		incomeMultiplier = 1.5,
		reputationBonus = 10,
		specialMechanic = "AutoGraduate",
	},

	IdulAdha = {
		displayName = "Idul Adha",
		durationDays = 3,
		barakahMultiplier = 1.5,
		incomeMultiplier = 1.0,
		reputationBonus = 0, -- rep comes from the Qurban mechanic itself
		specialMechanic = "Qurban",
	},

	MaulidNabi = {
		displayName = "Maulid Nabi Muhammad SAW",
		durationDays = 3,
		barakahMultiplier = 1.5,
		incomeMultiplier = 1.0,
		reputationBonus = 5,
		specialMechanic = "FreeKyai",
	},

	IsraMiraj = {
		displayName = "Isra Mi'raj",
		durationDays = 1,
		barakahMultiplier = 2.0, -- double Barakah for this one night
		incomeMultiplier = 1.0,
		reputationBonus = 3,
		specialMechanic = "NightTheme",
	},

	TahunBaru = {
		displayName = "Tahun Baru Hijriyah",
		durationDays = 1,
		barakahMultiplier = 1.2,
		incomeMultiplier = 1.2,
		reputationBonus = 0,
		specialMechanic = "LeaderboardReset",
	},
}

return EventData
