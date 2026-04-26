--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type SantriProgram = Types.SantriProgram
type SantriDefinition = Types.SantriDefinition

-- All santri program definitions keyed by SantriProgram.
-- `generates`          = currencies produced per in-game minute with an active ustadz.
-- `alumniSedekahBonus` = Rupiah/min added to sedekahJariyahPerMin on graduation (forever).
-- `ujianPassBonus`     = added to UJIAN_PASS_CHANCE_BASE (e.g. 0.05 = +5% pass chance).
-- `requiredBuilding`   = the BuildingType that must be placed before enrolling this program.

local SantriData: { [SantriProgram]: SantriDefinition } = {

	-- High Barakah generator. Graduates become Hafidz — best alumni passive income.
	Tahfidz = {
		displayName = "Tahfidz Al-Qur'an",
		generates = {
			{ currency = "Barakah", baseRate = 2 },
			{ currency = "Rupiah",  baseRate = 3 },
		},
		alumniSedekahBonus = 10,
		ujianPassBonus = 0.05,
		requiredBuilding = "Musholla",
	},

	-- Balanced Ilmu + Rupiah generator. Boosts research speed via Library synergy.
	KitabKuning = {
		displayName = "Kitab Kuning",
		generates = {
			{ currency = "Ilmu",   baseRate = 3 },
			{ currency = "Rupiah", baseRate = 5 },
		},
		alumniSedekahBonus = 5,
		ujianPassBonus = 0.10,
		requiredBuilding = "Education",
	},

	-- Reputation-focused. Attracts foreign (higher-value) santri when rep rises.
	Bahasa = {
		displayName = "Bahasa Arab/Inggris",
		generates = {
			{ currency = "Rupiah", baseRate = 4 },
			{ currency = "Ilmu",   baseRate = 1 },
		},
		alumniSedekahBonus = 3,
		ujianPassBonus = 0.08,
		requiredBuilding = "Education",
	},

	-- Highest Rupiah generator. Required for Economy buildings in later zones.
	Wirausaha = {
		displayName = "Wirausaha Santri",
		generates = {
			{ currency = "Rupiah", baseRate = 15 },
		},
		alumniSedekahBonus = 8,
		ujianPassBonus = 0.0,
		requiredBuilding = "Economy",
	},

	-- Rupiah + Ilmu. Required for and only available after LabKomputer is placed.
	Teknologi = {
		displayName = "Teknologi & Informatika",
		generates = {
			{ currency = "Rupiah", baseRate = 10 },
			{ currency = "Ilmu",   baseRate = 2 },
		},
		alumniSedekahBonus = 6,
		ujianPassBonus = 0.05,
		requiredBuilding = "LabKomputer",
	},
}

return SantriData
