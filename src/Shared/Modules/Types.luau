--!strict

-- Primitive union types (defined first — referenced by composite types below)

export type Currency = "Rupiah" | "Barakah" | "Ilmu" | "Sanad"

export type SantriProgram = "Tahfidz" | "KitabKuning" | "Bahasa" | "Wirausaha" | "Teknologi"

export type BuildingType =
	"Musholla"
	| "Dormitory"
	| "Education"
	| "Food"
	| "Economy"
	| "Library"
	| "Studio"
	| "LabKomputer"
	| "Klinik"
	| "Aula"

export type UstadzRarity = "Biasa" | "Terkenal" | "KyaiBesar" | "KyaiInternasional"

export type MasalahType = "SantriSakit" | "UstadzAbsen" | "BanjirAsrama"

export type SeasonalEvent =
	"Ramadan"
	| "IdulFitri"
	| "IdulAdha"
	| "MaulidNabi"
	| "TahunBaru"
	| "IsraMiraj"

-- Composite types

export type SantriData = {
	id: string,
	program: SantriProgram,
	needMakan: number, -- 0–100
	needIlmu: number, -- 0–100
	needIbadah: number, -- 0–100
	needIstirahat: number, -- 0–100
	studyProgress: number, -- 0–100, toward ujian
	enrollTime: number, -- os.time() at enrollment
}

export type BuildingData = {
	id: string,
	buildingType: BuildingType,
	level: number, -- 1–5
	zone: number, -- 1–5
	placedAt: number, -- os.time() when placed
}

export type UstadzData = {
	id: string,
	program: SantriProgram,
	skill: number, -- 1–5
	kharisma: number, -- 1–5
	fatigue: number, -- 0–100 (100 = fully rested)
	rarity: UstadzRarity,
	liburUntil: number?, -- os.time() expiry for libur; nil = not on libur
}

export type MasalahEvent = {
	id: string,
	eventType: MasalahType,
	severity: number, -- 1–3
	triggeredAt: number, -- os.time()
	resolved: boolean,
}

-- Root player save data.
-- Fields prefixed with _ are runtime-only flags (not persisted to DataStore).
export type PlayerData = {
	-- Currencies
	rupiah: number,
	barakah: number,
	ilmu: number,
	sanad: number,
	-- Progression
	reputation: number, -- 0–100, resets on prestige
	prestigeCount: number,
	prestigeMultiplier: number, -- 1 + (prestigeCount * 0.15), applied to Rupiah income
	tutorialStep: number, -- 0 = not started, 6 = complete
	-- Collections
	santriList: { [string]: SantriData },
	buildingList: { [string]: BuildingData },
	ustadzList: { [string]: UstadzData },
	-- Alumni & passive income
	alumniCount: number,
	sedekahJariyahPerMin: number,
	-- Tier unlock flags (each fires once)
	tierBerkembangFired: boolean,
	tierUnggulanFired: boolean,
	tierPrestgeFired: boolean,
	-- Daily prayer tracking
	dailyPrayerCount: number, -- reset at day rollover
	waktuSholatActive: boolean,
	waktuSholatExpiry: number, -- os.time() expiry
	-- Monetisation
	starterPackExpiry: number, -- os.time() expiry; 0 = not active
	-- Metadata
	lastSaved: number, -- os.time()
	-- Runtime-only flags (not written to DataStore)
	_loadFailed: boolean?,
}

-- Leaderboard entry returned by GetLeaderboard remote function
export type LeaderboardEntry = {
	player: string,
	value: number,
}
