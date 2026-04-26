--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type UstadzDefinition = Types.UstadzDefinition

-- Rarity roll table for hiring ustadz.
-- `rarityWeights`     = probability weights (must sum to 100).
-- `rarityMultipliers` = income/Ilmu multiplier applied to the ustadz's program.
-- `hireCost`          = cost per rarity tier; KyaiInternasional has no direct hire cost
--                       (late-game unlock only — awarded via Maulid Nabi event or Sanad spend).

local UstadzData: UstadzDefinition = {
	rarityWeights = {
		Biasa             = 70,
		Terkenal          = 22,
		KyaiBesar         = 7,
		KyaiInternasional = 1,
	},

	rarityMultipliers = {
		Biasa             = 1,
		Terkenal          = 2,
		KyaiBesar         = 5,
		KyaiInternasional = 10,
	},

	-- KyaiInternasional intentionally omitted: no direct hire path.
	-- Awarded as a free temporary ustadz during Maulid Nabi event (T25),
	-- or purchasable for Sanad after late-game unlock (future task).
	hireCost = {
		Biasa    = { currency = "Rupiah",  amount = 500 },
		Terkenal = { currency = "Barakah", amount = 20  },
		KyaiBesar = { currency = "Sanad",  amount = 1   },
	},
}

return UstadzData
