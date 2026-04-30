--!strict

-- T31: Slide-up building purchase/upgrade panel.
-- UIGridLayout of cards: icon, name, cost, level indicator, Beli/Upgrade button.
-- Locked zone buildings: greyed-out with unlock requirement text.
-- Gamepad: GuiService.SelectedObject set to first card on open.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Net.Events)
local BuildingData = require(ReplicatedStorage.Shared.Data.BuildingData)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type PlayerData = Types.PlayerData
type BuildingDefinition = Types.BuildingDefinition

local LocalPlayer = Players.LocalPlayer
local SLIDE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Ordered list so the grid renders consistently
local BUILDING_ORDER: { string } = {
	"Musholla", "Dormitory", "Education", "Food",
	"Economy", "Library", "Studio", "LabKomputer", "Klinik", "Aula",
}

local BuildMenu = {}

local menuGui: ScreenGui
local panel: Frame
local gridFrame: Frame
local isOpen = false
local latestData: PlayerData? = nil

local function getOwnedBuilding(data: PlayerData, buildingType: string): Types.BuildingData?
	for _, b in data.buildingList do
		if tostring(b.buildingType) == buildingType then
			return b
		end
	end
	return nil
end

local function zoneLabel(zone: number): string
	if zone == 2 then
		return "Komplek (20 santri)"
	elseif zone == 3 then
		return "Alam (100 santri)"
	elseif zone == 4 then
		return "Bukit (250 santri)"
	elseif zone == 5 then
		return "Puncak (600 santri)"
	end
	return "Zona " .. zone
end

local function rebuildGrid(): ()
	for _, child in gridFrame:GetChildren() do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	local data = latestData
	if data == nil then
		return
	end

	local firstCard: TextButton? = nil

	for _, typeName in BUILDING_ORDER do
		local def: BuildingDefinition? = (BuildingData :: any)[typeName]
		if def == nil then
			continue
		end

		local owned = getOwnedBuilding(data, typeName)
		local locked = data.zoneUnlocked < def.zone
		local maxed = owned ~= nil and owned.level >= 5

		local card = Instance.new("Frame")
		card.BackgroundColor3 = if locked
			then Color3.fromRGB(50, 50, 50)
			else Color3.fromRGB(45, 60, 45)
		card.Parent = gridFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0.06, 0)
		cardCorner.Parent = card

		local cardLayout = Instance.new("UIListLayout")
		cardLayout.FillDirection = Enum.FillDirection.Vertical
		cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
		cardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		cardLayout.Padding = UDim.new(0.02, 0)
		cardLayout.Parent = card

		local cardPad = Instance.new("UIPadding")
		cardPad.PaddingLeft = UDim.new(0.05, 0)
		cardPad.PaddingRight = UDim.new(0.05, 0)
		cardPad.PaddingTop = UDim.new(0.04, 0)
		cardPad.PaddingBottom = UDim.new(0.04, 0)
		cardPad.Parent = card

		-- Icon placeholder (ImageLabel with aspect ratio constraint)
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.fromScale(0.5, 0)
		icon.AutomaticSize = Enum.AutomaticSize.Y
		icon.BackgroundTransparency = 1
		icon.LayoutOrder = 0
		local asp = Instance.new("UIAspectRatioConstraint")
		asp.AspectRatio = 1
		asp.Parent = icon
		icon.Parent = card

		-- Building name
		local tier1 = def.tiers[1]
		local currentLevel = if owned ~= nil then owned.level else 0
		local currentTierName = if owned ~= nil
			then (def.tiers[currentLevel] :: any).tierName
			else tier1.tierName

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.fromScale(1, 0.18)
		nameLabel.TextScaled = true
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = if locked
			then Color3.fromRGB(120, 120, 120)
			else Color3.fromRGB(255, 255, 255)
		nameLabel.Text = currentTierName
		nameLabel.LayoutOrder = 1
		nameLabel.Parent = card

		-- Level indicator
		local levelLabel = Instance.new("TextLabel")
		levelLabel.Size = UDim2.fromScale(1, 0.13)
		levelLabel.TextScaled = true
		levelLabel.BackgroundTransparency = 1
		levelLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		levelLabel.Text = if owned ~= nil then "Lv " .. currentLevel .. "/5" else "Belum dimiliki"
		levelLabel.LayoutOrder = 2
		levelLabel.Parent = card

		-- Cost / requirement label
		local costLabel = Instance.new("TextLabel")
		costLabel.Size = UDim2.fromScale(1, 0.13)
		costLabel.TextScaled = true
		costLabel.BackgroundTransparency = 1
		costLabel.LayoutOrder = 3

		if locked then
			costLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			costLabel.Text = "Butuh: " .. zoneLabel(def.zone)
		elseif maxed then
			costLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
			costLabel.Text = "Sudah maksimal"
		elseif owned ~= nil then
			local nextTier = def.tiers[currentLevel + 1]
			costLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
			costLabel.Text = "Upgrade: " .. nextTier.cost.amount .. " " .. tostring(nextTier.cost.currency)
		else
			costLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
			costLabel.Text = "Beli: " .. tier1.cost.amount .. " " .. tostring(tier1.cost.currency)
		end
		costLabel.Parent = card

		-- Action button
		if not locked and not maxed then
			local actionBtn = Instance.new("TextButton")
			actionBtn.Size = UDim2.fromScale(0.85, 0.2)
			actionBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 50)
			actionBtn.TextScaled = true
			actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			actionBtn.LayoutOrder = 4

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0.2, 0)
			btnCorner.Parent = actionBtn

			local capturedType = typeName
			local capturedOwned = owned

			if capturedOwned == nil then
				actionBtn.Text = "Beli"
				actionBtn.Activated:Connect(function()
					Events.PurchaseBuilding:FireServer(capturedType, data.zoneUnlocked)
				end)
			else
				actionBtn.Text = "Upgrade"
				local capturedId = capturedOwned.id
				actionBtn.Activated:Connect(function()
					Events.UpgradeBuilding:FireServer(capturedId)
				end)
			end

			actionBtn.Parent = card

			if firstCard == nil then
				firstCard = actionBtn
			end
		end
	end

	-- Set gamepad focus to first actionable card
	if firstCard ~= nil then
		GuiService.SelectedObject = firstCard
	end
end

function BuildMenu.open(): ()
	isOpen = true
	TweenService:Create(panel, SLIDE, {
		Position = UDim2.fromScale(0.05, 0.15),
	}):Play()
	rebuildGrid()
end

function BuildMenu.close(): ()
	isOpen = false
	TweenService:Create(panel, SLIDE, {
		Position = UDim2.fromScale(0.05, 1.1),
	}):Play()
end

function BuildMenu.toggle(): ()
	if isOpen then
		BuildMenu.close()
	else
		BuildMenu.open()
	end
end

function BuildMenu.init(): ()
	menuGui = Instance.new("ScreenGui")
	menuGui.Name = "BuildMenuGui"
	menuGui.ResetOnSpawn = false
	menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	menuGui.DisplayOrder = 5
	menuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	panel = Instance.new("Frame")
	panel.Name = "BuildMenuPanel"
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.Position = UDim2.fromScale(0.05, 1.1) -- off-screen below
	panel.Size = UDim2.fromScale(0.9, 0.78)
	panel.BackgroundColor3 = Color3.fromRGB(20, 25, 20)
	panel.Parent = menuGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.03, 0)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.07)
	title.TextScaled = true
	title.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = "Bangun"
	title.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.fromScale(1, 0)
	closeBtn.Size = UDim2.fromScale(0.1, 0.07)
	closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
	closeBtn.TextScaled = true
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Parent = panel
	closeBtn.Activated:Connect(function()
		BuildMenu.close()
	end)

	-- Scrollable grid container
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Position = UDim2.fromScale(0, 0.08)
	scrollFrame.Size = UDim2.fromScale(1, 0.92)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.XY
	scrollFrame.CanvasSize = UDim2.fromScale(0, 0)
	scrollFrame.Parent = panel

	gridFrame = Instance.new("Frame")
	gridFrame.Size = UDim2.fromScale(1, 1)
	gridFrame.AutomaticSize = Enum.AutomaticSize.Y
	gridFrame.BackgroundTransparency = 1
	gridFrame.Parent = scrollFrame

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromScale(0.3, 0)
	grid.CellPadding = UDim2.fromScale(0.02, 0.01)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = gridFrame

	-- Also constrain cell height via UIAspectRatioConstraint on the grid
	local gridAsp = Instance.new("UIAspectRatioConstraint")
	gridAsp.AspectRatio = 0.8
	gridAsp.Parent = grid

	Events.SyncPlayerData.OnClientEvent:Connect(function(rawData: any)
		latestData = rawData :: PlayerData
		if isOpen then
			rebuildGrid()
		end
	end)
end

return BuildMenu
