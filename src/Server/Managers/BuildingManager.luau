--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.Parent.Services.DataService)
local EconomyService = require(script.Parent.Parent.Services.EconomyService)
local ReplicationService = require(script.Parent.Parent.Services.ReplicationService)
local ReputationManager = require(script.Parent.ReputationManager)
local Events = require(ReplicatedStorage.Shared.Net.Events)
local BuildingData = require(ReplicatedStorage.Shared.Data.BuildingData)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type PlayerData = Types.PlayerData
type BuildingType = Types.BuildingType
type BuildingDefinition = Types.BuildingDefinition

local BuildingManager = {}

-- Server-session part references; populated by placeBuilding, lazily populated by findPart.
local partById: { [string]: BasePart } = {}
local idCounter = 0

-- ─── Internal helpers ──────────────────────────────────────────────────────────

local function generateId(prefix: string): string
	idCounter += 1
	return prefix .. "_" .. tostring(math.floor(tick() * 1000)) .. "_" .. tostring(idCounter)
end

local function santriCount(data: PlayerData): number
	local n = 0
	for _ in data.santriList do
		n += 1
	end
	return n
end

local function computeZone(count: number): number
	if count >= Constants.ZONE_5_UNLOCK then
		return 5
	elseif count >= Constants.ZONE_4_UNLOCK then
		return 4
	elseif count >= Constants.ZONE_3_UNLOCK then
		return 3
	elseif count >= Constants.ZONE_2_UNLOCK then
		return 2
	else
		return 1
	end
end

-- Searches partById cache first, then falls back to a CollectionService scan.
local function findPart(buildingId: string): BasePart?
	if partById[buildingId] ~= nil then
		return partById[buildingId]
	end
	for _, inst in CollectionService:GetTagged("Building") do
		if inst:IsA("BasePart") and inst:GetAttribute("buildingId") == buildingId then
			local part = inst :: BasePart
			partById[buildingId] = part
			return part
		end
	end
	return nil
end

-- ─── Public API ────────────────────────────────────────────────────────────────

-- Returns the highest zone the player has unlocked (1–5), stored in PlayerData.
function BuildingManager.getZoneUnlocked(player: Player): number
	return DataService.getPlayerData(player).zoneUnlocked
end

-- Recomputes the unlocked zone from santri count.
-- If a new zone was reached, persists it and notifies the client.
-- Call this whenever santri count changes (T13+) and after placeBuilding.
function BuildingManager.checkZoneUnlock(player: Player): ()
	local data = DataService.getPlayerData(player)
	local newZone = computeZone(santriCount(data))
	if newZone > data.zoneUnlocked then
		DataService.updatePlayerData(player, { zoneUnlocked = newZone })
		Events.NotifyEvent:FireClient(player, { eventType = "ZoneUnlocked", zone = newZone })
	end
end

-- Places a new tier-1 building for the player.
-- Validates type, zone access, and funds server-side before mutating any state.
-- Returns true on success, false if any validation fails (no side effects on false).
function BuildingManager.placeBuilding(player: Player, buildingType: BuildingType, zone: number): boolean
	if zone < 1 or zone > 5 then
		return false
	end

	-- Validate building type via runtime lookup (client input is untrusted)
	local def: BuildingDefinition? = (BuildingData :: any)[buildingType :: string]
	if def == nil then
		return false
	end

	local data = DataService.getPlayerData(player)

	-- Building requires a minimum zone the player must have reached
	if data.zoneUnlocked < def.zone then
		return false
	end

	-- Placement zone must also be within the player's reach
	if data.zoneUnlocked < zone then
		return false
	end

	-- Attempt to deduct tier-1 cost (returns false + no side effects if insufficient)
	local tierCost = def.tiers[1].cost
	if not EconomyService.spendCurrency(player, tierCost.currency, tierCost.amount) then
		return false
	end

	-- Count existing buildings BEFORE inserting to compute a non-overlapping position
	local existingCount = 0
	for _ in data.buildingList do
		existingCount += 1
	end
	local col = existingCount % 10
	local row = math.floor(existingCount / 10)
	local position = Vector3.new(col * 12, 2, row * 12)

	local id = generateId(buildingType :: string)

	-- Persist into player data
	data.buildingList[id] = {
		id = id,
		buildingType = buildingType,
		level = 1,
		zone = zone,
		placedAt = os.time(),
	}

	-- Spawn placeholder Part; replicated to all clients automatically
	local part = Instance.new("Part")
	part.Name = (buildingType :: string) .. "_Building"
	part.Size = Vector3.new(8, 4, 8)
	part.Anchored = true
	part.Position = position
	part.Parent = workspace

	-- Generic "Building" tag drives the BillboardGui (T11); type tag for specific queries
	CollectionService:AddTag(part, "Building")
	CollectionService:AddTag(part, buildingType :: string)
	-- Category-specific tags drive SurfaceGui income display (T12)
	if buildingType == "Food" then
		CollectionService:AddTag(part, "FoodBuilding")
	elseif buildingType == "Economy" then
		CollectionService:AddTag(part, "EconomyBuilding")
	end

	part:SetAttribute("buildingId", id)
	part:SetAttribute("buildingLevel", 1)
	part:SetAttribute("buildingType", buildingType :: string)
	part:SetAttribute("ownerId", player.UserId)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Lihat Info"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = 10
	prompt.Parent = part

	-- T27: Doa mechanic — only on Ibadah buildings (Musholla and upgrades)
	if def.category == "Ibadah" then
		local doaPrompt = Instance.new("ProximityPrompt")
		doaPrompt.ActionText = "Doakan"
		doaPrompt.KeyboardKeyCode = Enum.KeyCode.F
		doaPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
		doaPrompt.MaxActivationDistance = 10
		doaPrompt.Parent = part

		local capturedPart = part
		doaPrompt.Triggered:Connect(function(visitor: Player)
			local hostId = (capturedPart:GetAttribute("ownerId") :: any) :: number?
			if hostId == nil then
				return
			end
			if visitor.UserId == hostId then
				return -- can't doa your own building
			end
			if not DataService.isLoaded(visitor) then
				return
			end
			if not DataService.checkDoaCooldown(visitor.UserId, hostId) then
				return
			end
			EconomyService.addCurrency(visitor, "Barakah", Constants.DOA_BARAKAH_GIFT)
			local host = Players:GetPlayerByUserId(hostId)
			if host ~= nil and DataService.isLoaded(host) then
				EconomyService.addCurrency(host, "Barakah", Constants.DOA_BARAKAH_GIFT)
				Events.NotifyEvent:FireClient(host, { eventType = "DoaReceived", visitorName = visitor.Name })
			end
			Events.NotifyEvent:FireClient(visitor, {
				eventType = "DoaSent",
				hostName = if host ~= nil then host.Name else "unknown",
			})
		end)
	end

	partById[id] = part

	ReplicationService.syncAll(player)
	BuildingManager.checkZoneUnlock(player)
	return true
end

-- Upgrades a placed building to the next tier.
-- Returns true on success, false if not found, already max level, or insufficient funds.
function BuildingManager.upgradeBuilding(player: Player, buildingId: string): boolean
	local data = DataService.getPlayerData(player)
	local building = data.buildingList[buildingId]
	if building == nil then
		return false
	end
	if building.level >= 5 then
		return false
	end

	local def: BuildingDefinition? = (BuildingData :: any)[building.buildingType :: string]
	if def == nil then
		return false
	end

	local nextLevel = building.level + 1
	local tierCost = def.tiers[nextLevel].cost
	if not EconomyService.spendCurrency(player, tierCost.currency, tierCost.amount) then
		return false
	end

	-- Mutate nested BuildingData directly (cache holds a reference, not a copy)
	building.level = nextLevel

	-- Update the workspace Part attribute so clients see the change immediately
	local part = findPart(buildingId)
	if part ~= nil then
		part:SetAttribute("buildingLevel", nextLevel)
	end

	ReputationManager.addReputation(player, Constants.REP_PER_BUILDING_UPGRADE)
	ReplicationService.syncAll(player)
	return true
end

-- ─── RemoteEvent handlers ─────────────────────────────────────────────────────
-- Wired here so the manager owns its event surface; fires on module require.

Events.PurchaseBuilding.OnServerEvent:Connect(function(player: Player, rawType: any, rawZone: any)
	if type(rawType) ~= "string" then
		return
	end
	if type(rawZone) ~= "number" then
		return
	end
	if not DataService.isLoaded(player) then
		return
	end
	BuildingManager.placeBuilding(player, rawType :: BuildingType, math.floor(rawZone))
end)

Events.UpgradeBuilding.OnServerEvent:Connect(function(player: Player, rawId: any)
	if type(rawId) ~= "string" then
		return
	end
	if not DataService.isLoaded(player) then
		return
	end
	BuildingManager.upgradeBuilding(player, rawId)
end)

return BuildingManager
