--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local ReplicationService = require(script.Parent.ReplicationService)
local Types = require(ReplicatedStorage.Shared.Modules.Types)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)

-- Lazy: EventService requires EconomyService; break cycle by requiring at call time.
local function eventSvc()
	return require(script.Parent.EventService)
end

type Currency = Types.Currency
type PlayerData = Types.PlayerData

local EconomyService = {}

-- Server-side game pass ownership cache.
-- Populated by MarketplaceService check in init.server.luau (T41).
-- Defaults to false (non-premium) until explicitly set.
local premiumPassOwners: { [number]: boolean } = {}

-- Kunjungan Menteri temporary 5× multiplier: userId → expiry os.time().
-- Set via EconomyService.setKunjunganActive; checked in rupiahMultiplier.
local kunjunganExpiry: { [number]: number } = {}

-- ─── Internal helpers ──────────────────────────────────────────────────────────

-- Reads the raw balance for a given currency from player data.
local function getBalance(data: PlayerData, currency: Currency): number
	if currency == "Rupiah" then
		return data.rupiah
	elseif currency == "Barakah" then
		return data.barakah
	elseif currency == "Ilmu" then
		return data.ilmu
	else -- "Sanad"
		return data.sanad
	end
end

-- Builds the updatePlayerData patch for setting one currency field.
local function makePatch(currency: Currency, value: number): { [string]: any }
	if currency == "Rupiah" then
		return { rupiah = value }
	elseif currency == "Barakah" then
		return { barakah = value }
	elseif currency == "Ilmu" then
		return { ilmu = value }
	else -- "Sanad"
		return { sanad = value }
	end
end

-- Returns the combined multiplier applied to Rupiah income for this player.
-- Accounts for prestige, starter pack, premium game pass, and Kunjungan Menteri.
local function rupiahMultiplier(player: Player, data: PlayerData): number
	local m = data.prestigeMultiplier

	if data.starterPackExpiry > 0 and os.time() < data.starterPackExpiry then
		m *= Constants.STARTER_PACK_MULTIPLIER
	end

	if premiumPassOwners[player.UserId] == true then
		m *= Constants.GAMEPASS_PREMIUM_MULTIPLIER
	end

	local expiry = kunjunganExpiry[player.UserId]
	if expiry ~= nil and os.time() < expiry then
		m *= Constants.KUNJUNGAN_MENTERI_MULTIPLIER
	end

	if data.waktuSholatActive and os.time() < data.waktuSholatExpiry then
		m *= Constants.WAKTU_SHOLAT_MULTIPLIER
	end

	return m
end

-- ─── Public API ────────────────────────────────────────────────────────────────

-- Activates the Kunjungan Menteri 5× Rupiah multiplier for `durationSec` seconds.
-- Called by ReputationManager when tier-100 is reached (T20).
function EconomyService.setKunjunganActive(player: Player, durationSec: number): ()
	kunjunganExpiry[player.UserId] = os.time() + durationSec
end

-- Marks a player as owning the premium game pass.
-- Called from init.server.luau during T41 MarketplaceService setup.
function EconomyService.setPremiumPass(userId: number, owned: boolean): ()
	premiumPassOwners[userId] = owned
end

-- Adds `amount` of `currency` to the player's balance.
-- For Rupiah, the amount is scaled by the active income multipliers.
-- Amount must be >= 0.
function EconomyService.addCurrency(player: Player, currency: Currency, amount: number): ()
	assert(amount >= 0, "[EconomyService] addCurrency: amount must be non-negative, got " .. amount)

	local data = DataService.getPlayerData(player)
	local effective = amount

	if currency == "Rupiah" then
		effective = math.floor(amount * rupiahMultiplier(player, data) * eventSvc().getActiveMultiplier(player))
	elseif currency == "Barakah" then
		effective = math.floor(amount * eventSvc().getActiveBarakahMultiplier())
	end

	local current = getBalance(data, currency)
	DataService.updatePlayerData(player, makePatch(currency, current + effective))

	print(string.format("[Economy] +%d %s → %s (effective, requested %d)", effective, currency, player.Name, amount))
	ReplicationService.syncCurrencies(player)
end

-- Deducts `amount` of `currency` from the player's balance.
-- Returns true on success, false (no side effects) if insufficient funds.
-- Amount must be >= 0.
function EconomyService.spendCurrency(player: Player, currency: Currency, amount: number): boolean
	assert(amount >= 0, "[EconomyService] spendCurrency: amount must be non-negative, got " .. amount)

	local data = DataService.getPlayerData(player)
	local current = getBalance(data, currency)

	if current < amount then
		return false
	end

	DataService.updatePlayerData(player, makePatch(currency, current - amount))

	print(string.format("[Economy] -%d %s ← %s", amount, currency, player.Name))
	ReplicationService.syncCurrencies(player)
	return true
end

-- Returns the player's current balance for the given currency.
function EconomyService.getCurrency(player: Player, currency: Currency): number
	local data = DataService.getPlayerData(player)
	return getBalance(data, currency)
end

-- Returns true if the player can afford the given amount of currency.
function EconomyService.canAfford(player: Player, currency: Currency, amount: number): boolean
	return EconomyService.getCurrency(player, currency) >= amount
end

-- ─── Sedekah Jariyah passive income tick (T17) ────────────────────────────────
-- Credits each connected player's accumulated alumni Rupiah every 60 seconds.
-- sedekahJariyahPerMin grows permanently on every santri graduation (T15).
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in Players:GetPlayers() do
			if DataService.isLoaded(player) then
				local data = DataService.getPlayerData(player)
				if data.sedekahJariyahPerMin > 0 then
					EconomyService.addCurrency(player, "Rupiah", data.sedekahJariyahPerMin)
				end
			end
		end
	end
end)

return EconomyService
