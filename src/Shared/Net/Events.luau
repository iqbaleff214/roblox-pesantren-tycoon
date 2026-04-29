--!strict

-- Single source for all RemoteEvents.
-- Server creates them on first require; client finds existing instances.
-- No other script should call Instance.new("RemoteEvent").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreate(name: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		assert(existing:IsA("RemoteEvent"), name .. " already exists but is not a RemoteEvent")
		return existing :: RemoteEvent
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = ReplicatedStorage
	return event
end

-- ─── Client → Server ──────────────────────────────────────────────────────────
-- PurchaseBuilding     : (buildingType: string, zone: number)
-- UpgradeBuilding      : (buildingId: string)
-- HireUstadz           : (program: string, targetRarity: string?)
-- ResolveMasalah       : (masalahId: string)
-- BukaCabang           : ()
-- TriggerWaqf          : (amount: number)
-- VoteTabligAkbar      : ()
-- AcknowledgeWaktuSholat : ()
-- TriggerQurban        : ()
-- RequestVisit         : (friendUserId: number)       T27 — teleport to friend's server
-- NotifyVisitArrival   : (hostUserId: number)         T27 — visitor announces arrival

-- ─── Server → Client ──────────────────────────────────────────────────────────
-- SyncPlayerData    : (data: PlayerData)
-- NotifyMasalah     : (event: MasalahEvent)
-- NotifyEvent       : (eventType: string, payload: any?)
-- NotifyGraduation  : (santriId: string, program: string)
-- NotifyKyaiBesar   : (ustadzName: string, pesantrenName: string)  [broadcast]
-- SyncWaqfPool      : (poolAmount: number)            T28 — live waqf progress bar

local Events = {
	-- Client → Server
	PurchaseBuilding = getOrCreate("PurchaseBuilding"),
	UpgradeBuilding = getOrCreate("UpgradeBuilding"),
	HireUstadz = getOrCreate("HireUstadz"),
	ResolveMasalah = getOrCreate("ResolveMasalah"),
	BukaCabang = getOrCreate("BukaCabang"),
	TriggerWaqf = getOrCreate("TriggerWaqf"),
	VoteTabligAkbar = getOrCreate("VoteTabligAkbar"),
	AcknowledgeWaktuSholat = getOrCreate("AcknowledgeWaktuSholat"),
	TriggerQurban = getOrCreate("TriggerQurban"),
	RequestVisit = getOrCreate("RequestVisit"),
	NotifyVisitArrival = getOrCreate("NotifyVisitArrival"),
	-- Server → Client (and broadcast)
	SyncPlayerData = getOrCreate("SyncPlayerData"),
	NotifyMasalah = getOrCreate("NotifyMasalah"),
	NotifyEvent = getOrCreate("NotifyEvent"),
	NotifyGraduation = getOrCreate("NotifyGraduation"),
	NotifyKyaiBesar = getOrCreate("NotifyKyaiBesar"),
	SyncWaqfPool = getOrCreate("SyncWaqfPool"),
}

return Events
