--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type Currency = Types.Currency
type BuildingType = Types.BuildingType
type BuildingDefinition = Types.BuildingDefinition

-- All building definitions keyed by BuildingType.
-- `zone`   = minimum player zone required to purchase.
-- `tiers`  = indexed 1–5 (or 1 for single-tier Special buildings).
--            `capacity` = dormitory slots OR education program slots; 0 if not applicable.
--            `incomeBonus`  = flat Rupiah/min added while the building is present.
--            `barakahBonus` = flat Barakah/min added while the building is present.
--            `ilmuBonus`    = flat Ilmu/min added while the building is present.

local BuildingData: { [BuildingType]: BuildingDefinition } = {

	-- ── Ibadah (Prayer) ─────────────────────────────────────────────────────────
	-- Progression: Musholla → Masjid → Masjid Jami → Masjid Agung → Masjid Internasional
	Musholla = {
		displayName = "Bangunan Ibadah",
		category = "Ibadah",
		zone = 1,
		tiers = {
			[1] = { tierName = "Musholla",           cost = { currency = "Rupiah", amount = 250 },    capacity = 0, incomeBonus = 0,  barakahBonus = 1,  ilmuBonus = 0 },
			[2] = { tierName = "Masjid",             cost = { currency = "Rupiah", amount = 2000 },   capacity = 0, incomeBonus = 0,  barakahBonus = 3,  ilmuBonus = 0 },
			[3] = { tierName = "Masjid Jami",        cost = { currency = "Rupiah", amount = 10000 },  capacity = 0, incomeBonus = 0,  barakahBonus = 7,  ilmuBonus = 0 },
			[4] = { tierName = "Masjid Agung",       cost = { currency = "Rupiah", amount = 50000 },  capacity = 0, incomeBonus = 0,  barakahBonus = 15, ilmuBonus = 0 },
			[5] = { tierName = "Masjid Internasional", cost = { currency = "Rupiah", amount = 250000 }, capacity = 0, incomeBonus = 0, barakahBonus = 30, ilmuBonus = 0 },
		},
		unlockCondition = nil,
	},

	-- ── Dormitory ────────────────────────────────────────────────────────────────
	-- Progression: Gubuk → Pondok Kayu → Asrama → Gedung Asrama → Menara Santri
	Dormitory = {
		displayName = "Tempat Tinggal",
		category = "Dormitory",
		zone = 1,
		tiers = {
			[1] = { tierName = "Gubuk",          cost = { currency = "Rupiah", amount = 100 },    capacity = 5,   incomeBonus = 0, barakahBonus = 0, ilmuBonus = 0 },
			[2] = { tierName = "Pondok Kayu",    cost = { currency = "Rupiah", amount = 500 },    capacity = 15,  incomeBonus = 0, barakahBonus = 0, ilmuBonus = 0 },
			[3] = { tierName = "Asrama",         cost = { currency = "Rupiah", amount = 2500 },   capacity = 30,  incomeBonus = 0, barakahBonus = 0, ilmuBonus = 0 },
			[4] = { tierName = "Gedung Asrama",  cost = { currency = "Rupiah", amount = 12500 },  capacity = 60,  incomeBonus = 0, barakahBonus = 0, ilmuBonus = 0 },
			[5] = { tierName = "Menara Santri",  cost = { currency = "Rupiah", amount = 75000 },  capacity = 100, incomeBonus = 0, barakahBonus = 0, ilmuBonus = 0 },
		},
		unlockCondition = nil,
	},

	-- ── Education ────────────────────────────────────────────────────────────────
	-- Progression: Tanah Lapang → Kelas Darurat → Ruang Kelas → Gedung Madrasah → Kampus Terpadu
	-- `capacity` here = program slots (how many different programs can run simultaneously)
	Education = {
		displayName = "Pendidikan",
		category = "Education",
		zone = 1,
		tiers = {
			[1] = { tierName = "Tanah Lapang",     cost = { currency = "Rupiah", amount = 200 },    capacity = 1, incomeBonus = 0, barakahBonus = 0, ilmuBonus = 1  },
			[2] = { tierName = "Kelas Darurat",    cost = { currency = "Rupiah", amount = 1000 },   capacity = 2, incomeBonus = 0, barakahBonus = 0, ilmuBonus = 2  },
			[3] = { tierName = "Ruang Kelas",      cost = { currency = "Rupiah", amount = 5000 },   capacity = 3, incomeBonus = 0, barakahBonus = 0, ilmuBonus = 5  },
			[4] = { tierName = "Gedung Madrasah",  cost = { currency = "Rupiah", amount = 25000 },  capacity = 4, incomeBonus = 0, barakahBonus = 0, ilmuBonus = 12 },
			[5] = { tierName = "Kampus Terpadu",   cost = { currency = "Rupiah", amount = 150000 }, capacity = 5, incomeBonus = 0, barakahBonus = 0, ilmuBonus = 25 },
		},
		unlockCondition = nil,
	},

	-- ── Food ─────────────────────────────────────────────────────────────────────
	-- Progression: Warung Kecil → Kantin → Dapur Bersama → Food Court Halal → Restoran Halal
	Food = {
		displayName = "Konsumsi",
		category = "Food",
		zone = 1,
		tiers = {
			[1] = { tierName = "Warung Kecil",       cost = { currency = "Rupiah", amount = 150 },    capacity = 0, incomeBonus = 5,   barakahBonus = 0, ilmuBonus = 0 },
			[2] = { tierName = "Kantin",             cost = { currency = "Rupiah", amount = 800 },    capacity = 0, incomeBonus = 15,  barakahBonus = 0, ilmuBonus = 0 },
			[3] = { tierName = "Dapur Bersama",      cost = { currency = "Rupiah", amount = 4000 },   capacity = 0, incomeBonus = 35,  barakahBonus = 0, ilmuBonus = 0 },
			[4] = { tierName = "Food Court Halal",   cost = { currency = "Rupiah", amount = 20000 },  capacity = 0, incomeBonus = 80,  barakahBonus = 0, ilmuBonus = 0 },
			[5] = { tierName = "Restoran Halal",     cost = { currency = "Rupiah", amount = 100000 }, capacity = 0, incomeBonus = 180, barakahBonus = 0, ilmuBonus = 0 },
		},
		unlockCondition = nil,
	},

	-- ── Economy ──────────────────────────────────────────────────────────────────
	-- Progression: Kebun Sayur → Ladang → Koperasi Santri → Pusat Bisnis → Konglomerat Santri
	Economy = {
		displayName = "Ekonomi",
		category = "Economy",
		zone = 3, -- unlocked at Komplek Alam (100 santri)
		tiers = {
			[1] = { tierName = "Kebun Sayur",           cost = { currency = "Rupiah", amount = 200 },    capacity = 0, incomeBonus = 8,   barakahBonus = 0, ilmuBonus = 0 },
			[2] = { tierName = "Ladang",                cost = { currency = "Rupiah", amount = 1000 },   capacity = 0, incomeBonus = 25,  barakahBonus = 0, ilmuBonus = 0 },
			[3] = { tierName = "Koperasi Santri",       cost = { currency = "Rupiah", amount = 5000 },   capacity = 0, incomeBonus = 60,  barakahBonus = 0, ilmuBonus = 0 },
			[4] = { tierName = "Pusat Bisnis",          cost = { currency = "Rupiah", amount = 30000 },  capacity = 0, incomeBonus = 150, barakahBonus = 0, ilmuBonus = 0 },
			[5] = { tierName = "Konglomerat Santri",    cost = { currency = "Rupiah", amount = 150000 }, capacity = 0, incomeBonus = 350, barakahBonus = 0, ilmuBonus = 0 },
		},
		unlockCondition = nil,
	},

	-- ── Special buildings (single-tier, unlocked via Ilmu) ─────────────────────

	Library = {
		displayName = "Perpustakaan Kitab Kuning",
		category = "Special",
		zone = 2,
		tiers = {
			[1] = { tierName = "Perpustakaan Kitab Kuning", cost = { currency = "Ilmu", amount = 500 }, capacity = 0, incomeBonus = 0, barakahBonus = 0, ilmuBonus = 10 },
		},
		unlockCondition = "Ilmu:500",
	},

	Studio = {
		displayName = "Studio Podcast/Dakwah",
		category = "Special",
		zone = 4,
		tiers = {
			[1] = { tierName = "Studio Podcast/Dakwah", cost = { currency = "Ilmu", amount = 3000 }, capacity = 0, incomeBonus = 0, barakahBonus = 5, ilmuBonus = 0 },
		},
		unlockCondition = "Ilmu:3000",
	},

	LabKomputer = {
		displayName = "Lab Komputer",
		category = "Special",
		zone = 4,
		tiers = {
			[1] = { tierName = "Lab Komputer", cost = { currency = "Ilmu", amount = 8000 }, capacity = 0, incomeBonus = 50, barakahBonus = 0, ilmuBonus = 0 },
		},
		unlockCondition = "Ilmu:8000",
	},

	Klinik = {
		displayName = "Klinik Sehat",
		category = "Special",
		zone = 2,
		tiers = {
			[1] = { tierName = "Klinik Sehat", cost = { currency = "Ilmu", amount = 2000 }, capacity = 0, incomeBonus = 0, barakahBonus = 0, ilmuBonus = 0 },
		},
		unlockCondition = "Ilmu:2000",
	},

	Aula = {
		displayName = "Aula Serbaguna",
		category = "Special",
		zone = 5,
		tiers = {
			[1] = { tierName = "Aula Serbaguna", cost = { currency = "Ilmu", amount = 4000 }, capacity = 0, incomeBonus = 0, barakahBonus = 0, ilmuBonus = 0 },
		},
		unlockCondition = "Ilmu:4000",
	},
}

return BuildingData
