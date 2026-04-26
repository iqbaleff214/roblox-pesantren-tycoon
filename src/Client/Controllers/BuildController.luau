--!strict

-- T11: Attaches a BillboardGui to every "Building"-tagged Part that appears in
--      workspace. Label updates when the buildingLevel attribute changes.
-- T12: Attaches a SurfaceGui (front face) to "FoodBuilding" / "EconomyBuilding"
--      Parts showing "+Rp <rate>/min". Value updates on attribute change and on
--      every SyncPlayerData event (in case prestige multipliers change in future).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Net.Events)
local BuildingData = require(ReplicatedStorage.Shared.Data.BuildingData)

local BuildController = {}

-- ─── Helpers ──────────────────────────────────────────────────────────────────

-- Returns the base incomeBonus for a part at its current buildingLevel.
local function incomeRate(part: BasePart): number
	local btStr = part:GetAttribute("buildingType") :: string?
	local level = part:GetAttribute("buildingLevel") :: number?
	if btStr == nil or level == nil then
		return 0
	end
	local def = (BuildingData :: any)[btStr]
	if def == nil then
		return 0
	end
	local tier = def.tiers[math.floor(level)]
	if tier == nil then
		return 0
	end
	return (tier.incomeBonus :: any) :: number
end

-- ─── T11: BillboardGui ────────────────────────────────────────────────────────

local function attachBillboard(part: BasePart): ()
	-- Guard: skip if already attached (e.g. initial scan races with signal)
	if part:FindFirstChild("BuildingBillboard") ~= nil then
		return
	end

	local btStr = (part:GetAttribute("buildingType") :: string?) or "?"
	local level = (part:GetAttribute("buildingLevel") :: number?) or 1

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BuildingBillboard"
	billboard.Size = UDim2.fromOffset(120, 40)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "InfoLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Text = btStr .. " Lv." .. tostring(math.floor(level))
	label.Parent = billboard

	part:GetAttributeChangedSignal("buildingLevel"):Connect(function()
		local newLevel = (part:GetAttribute("buildingLevel") :: number?) or 1
		label.Text = btStr .. " Lv." .. tostring(math.floor(newLevel))
	end)
end

-- ─── T12: SurfaceGui income display ──────────────────────────────────────────

local function attachIncomeGui(part: BasePart): ()
	if part:FindFirstChild("IncomeDisplay") ~= nil then
		return
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "IncomeDisplay"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "IncomeLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Text = "+Rp " .. tostring(incomeRate(part)) .. "/min"
	label.Parent = surfaceGui

	part:GetAttributeChangedSignal("buildingLevel"):Connect(function()
		label.Text = "+Rp " .. tostring(incomeRate(part)) .. "/min"
	end)
end

-- ─── CollectionService wiring ─────────────────────────────────────────────────

-- Handle parts already in workspace when this controller loads
for _, inst in CollectionService:GetTagged("Building") do
	if inst:IsA("BasePart") then
		task.spawn(attachBillboard, inst :: BasePart)
	end
end
CollectionService:GetInstanceAddedSignal("Building"):Connect(function(inst: Instance)
	if inst:IsA("BasePart") then
		attachBillboard(inst :: BasePart)
	end
end)

for _, inst in CollectionService:GetTagged("FoodBuilding") do
	if inst:IsA("BasePart") then
		task.spawn(attachIncomeGui, inst :: BasePart)
	end
end
CollectionService:GetInstanceAddedSignal("FoodBuilding"):Connect(function(inst: Instance)
	if inst:IsA("BasePart") then
		attachIncomeGui(inst :: BasePart)
	end
end)

for _, inst in CollectionService:GetTagged("EconomyBuilding") do
	if inst:IsA("BasePart") then
		task.spawn(attachIncomeGui, inst :: BasePart)
	end
end
CollectionService:GetInstanceAddedSignal("EconomyBuilding"):Connect(function(inst: Instance)
	if inst:IsA("BasePart") then
		attachIncomeGui(inst :: BasePart)
	end
end)

-- ─── SyncPlayerData → refresh all income labels ──────────────────────────────
-- One central connection avoids per-building connection accumulation.

local function refreshAllIncomeLabels(): ()
	for _, tag in { "FoodBuilding", "EconomyBuilding" } do
		for _, inst in CollectionService:GetTagged(tag) do
			if inst:IsA("BasePart") then
				local part = inst :: BasePart
				local gui = part:FindFirstChild("IncomeDisplay")
				if gui ~= nil then
					local lbl = gui:FindFirstChild("IncomeLabel") :: TextLabel?
					if lbl ~= nil then
						lbl.Text = "+Rp " .. tostring(incomeRate(part)) .. "/min"
					end
				end
			end
		end
	end
end

Events.SyncPlayerData.OnClientEvent:Connect(function()
	refreshAllIncomeLabels()
end)

return BuildController
