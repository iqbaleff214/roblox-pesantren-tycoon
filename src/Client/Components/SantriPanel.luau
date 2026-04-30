--!strict

-- T32: Santri list panel.
-- Cards show program, four color-coded need bars, study progress.
-- studyProgress >= 100: tapping card shows tutoring confirm (ResolveMasalah "UjianFail_{id}").
-- UjianFail NotifyEvent: immediately show tutoring confirm for that santri.
-- Sort: any need < 30 → LayoutOrder 0 (floated top), else 1.
-- Refresh on every SyncPlayerData.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getUIController()
	return require(script.Parent.Parent.Controllers.UIController)
end

local Events = require(ReplicatedStorage.Shared.Net.Events)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type PlayerData = Types.PlayerData
type SantriData = Types.SantriData

local LocalPlayer = Players.LocalPlayer
local SLIDE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SantriPanel = {}

local panelGui: ScreenGui
local panel: Frame
local scrollFrame: ScrollingFrame
local isOpen = false
local latestData: PlayerData? = nil

local function needColor(value: number): Color3
	if value > 60 then
		return Color3.fromRGB(60, 180, 60)
	elseif value >= 30 then
		return Color3.fromRGB(200, 180, 40)
	else
		return Color3.fromRGB(200, 60, 60)
	end
end

local function makeNeedBar(parent: Frame, label: string, value: number, layoutOrder: number): ()
	local row = Instance.new("Frame")
	row.Size = UDim2.fromScale(1, 0.18)
	row.BackgroundTransparency = 1
	row.LayoutOrder = layoutOrder
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(0.25, 1)
	lbl.TextScaled = true
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	lbl.Text = label
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.fromScale(0.73, 0.5)
	barBg.Position = UDim2.fromScale(0.26, 0.25)
	barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	barBg.Parent = row

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1)
	fill.BackgroundColor3 = needColor(value)
	fill.Parent = barBg
end

local function showTutoringConfirm(santriId: string, program: string): ()
	local dialog = Instance.new("Frame")
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.Position = UDim2.fromScale(0.5, 0.5)
	dialog.Size = UDim2.fromScale(0.55, 0.28)
	dialog.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	dialog.ZIndex = 20
	dialog.Parent = panelGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.06, 0)
	corner.Parent = dialog

	local prompt = Instance.new("TextLabel")
	prompt.Size = UDim2.fromScale(1, 0.5)
	prompt.TextScaled = true
	prompt.BackgroundTransparency = 1
	prompt.TextColor3 = Color3.fromRGB(255, 255, 255)
	prompt.Text = "Bayar " .. Constants.TUTORING_COST_RUPIAH .. " Rp untuk tutoring " .. program .. "?"
	prompt.ZIndex = 21
	prompt.Parent = dialog

	local yesBtn = Instance.new("TextButton")
	yesBtn.AnchorPoint = Vector2.new(0, 1)
	yesBtn.Position = UDim2.fromScale(0.1, 1)
	yesBtn.Size = UDim2.fromScale(0.35, 0.38)
	yesBtn.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
	yesBtn.TextScaled = true
	yesBtn.Text = "Ya"
	yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	yesBtn.ZIndex = 21
	yesBtn.Parent = dialog

	local noBtn = Instance.new("TextButton")
	noBtn.AnchorPoint = Vector2.new(1, 1)
	noBtn.Position = UDim2.fromScale(0.9, 1)
	noBtn.Size = UDim2.fromScale(0.35, 0.38)
	noBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	noBtn.TextScaled = true
	noBtn.Text = "Tidak"
	noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	noBtn.ZIndex = 21
	noBtn.Parent = dialog

	yesBtn.Activated:Connect(function()
		Events.ResolveMasalah:FireServer("UjianFail_" .. santriId)
		dialog:Destroy()
	end)
	noBtn.Activated:Connect(function()
		dialog:Destroy()
	end)
end

local function rebuildCards(): ()
	for _, child in scrollFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local data = latestData
	if data == nil then
		return
	end

	for santriId, santri in data.santriList do
		local isUrgent = santri.needMakan < 30
			or santri.needIlmu < 30
			or santri.needIbadah < 30
			or santri.needIstirahat < 30

		local card = Instance.new("Frame")
		card.Size = UDim2.fromScale(1, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		card.LayoutOrder = if isUrgent then 0 else 1
		card.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0.04, 0)
		cardCorner.Parent = card

		local cardPad = Instance.new("UIPadding")
		cardPad.PaddingLeft = UDim.new(0.03, 0)
		cardPad.PaddingRight = UDim.new(0.03, 0)
		cardPad.PaddingTop = UDim.new(0.02, 0)
		cardPad.PaddingBottom = UDim.new(0.02, 0)
		cardPad.Parent = card

		local cardLayout = Instance.new("UIListLayout")
		cardLayout.FillDirection = Enum.FillDirection.Vertical
		cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
		cardLayout.Padding = UDim.new(0.01, 0)
		cardLayout.Parent = card

		-- Program label row
		local programRow = Instance.new("Frame")
		programRow.Size = UDim2.fromScale(1, 0.14)
		programRow.BackgroundTransparency = 1
		programRow.LayoutOrder = 0
		programRow.Parent = card

		local programLabel = Instance.new("TextLabel")
		programLabel.Size = UDim2.fromScale(0.7, 1)
		programLabel.TextScaled = true
		programLabel.BackgroundTransparency = 1
		programLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
		programLabel.Text = tostring(santri.program)
		programLabel.TextXAlignment = Enum.TextXAlignment.Left
		programLabel.Parent = programRow

		local progressLabel = Instance.new("TextLabel")
		progressLabel.Size = UDim2.fromScale(0.28, 1)
		progressLabel.Position = UDim2.fromScale(0.72, 0)
		progressLabel.TextScaled = true
		progressLabel.BackgroundTransparency = 1
		progressLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		progressLabel.Text = "Progress: " .. math.floor(santri.studyProgress) .. "%"
		progressLabel.TextXAlignment = Enum.TextXAlignment.Right
		progressLabel.Parent = programRow

		-- Need bars
		local needsFrame = Instance.new("Frame")
		needsFrame.Size = UDim2.fromScale(1, 0)
		needsFrame.AutomaticSize = Enum.AutomaticSize.Y
		needsFrame.BackgroundTransparency = 1
		needsFrame.LayoutOrder = 1
		needsFrame.Parent = card

		local needLayout = Instance.new("UIListLayout")
		needLayout.FillDirection = Enum.FillDirection.Vertical
		needLayout.SortOrder = Enum.SortOrder.LayoutOrder
		needLayout.Padding = UDim.new(0.005, 0)
		needLayout.Parent = needsFrame

		makeNeedBar(needsFrame, "Makan", santri.needMakan, 0)
		makeNeedBar(needsFrame, "Ilmu", santri.needIlmu, 1)
		makeNeedBar(needsFrame, "Ibadah", santri.needIbadah, 2)
		makeNeedBar(needsFrame, "Istirahat", santri.needIstirahat, 3)

		-- Tap: show tutoring confirm if studyProgress >= 100
		if santri.studyProgress >= 100 then
			local tutoringBtn = Instance.new("TextButton")
			tutoringBtn.Size = UDim2.new(1, 0, 0, 44)
			tutoringBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 20)
			tutoringBtn.TextScaled = true
			tutoringBtn.Text = "Tutoring? (" .. Constants.TUTORING_COST_RUPIAH .. " Rp)"
			tutoringBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			tutoringBtn.LayoutOrder = 2
			tutoringBtn.Parent = card

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0.2, 0)
			btnCorner.Parent = tutoringBtn

			local capturedId = santriId
			local capturedProgram = tostring(santri.program)
			tutoringBtn.Activated:Connect(function()
				showTutoringConfirm(capturedId, capturedProgram)
			end)
		end
	end
end

function SantriPanel.open(): ()
	isOpen = true
	TweenService:Create(panel, SLIDE, {
		Position = UDim2.fromScale(0.1, 0.1),
	}):Play()
	rebuildCards()
	-- T38: register scroll frame for gamepad thumbstick; focus first tutoring button if any
	getUIController().setActiveScroll(scrollFrame)
	local firstBtn: GuiObject? = nil
	for _, child in scrollFrame:GetChildren() do
		if child:IsA("Frame") then
			local btn = child:FindFirstChildWhichIsA("TextButton")
			if btn ~= nil then
				firstBtn = btn :: GuiObject
				break
			end
		end
	end
	if firstBtn ~= nil then
		GuiService.SelectedObject = firstBtn
	end
end

function SantriPanel.close(): ()
	isOpen = false
	TweenService:Create(panel, SLIDE, {
		Position = UDim2.fromScale(0.1, 1.1),
	}):Play()
	getUIController().setActiveScroll(nil)
end

function SantriPanel.toggle(): ()
	if isOpen then
		SantriPanel.close()
	else
		SantriPanel.open()
	end
end

function SantriPanel.init(): ()
	panelGui = Instance.new("ScreenGui")
	panelGui.Name = "SantriPanelGui"
	panelGui.ResetOnSpawn = false
	panelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	panelGui.DisplayOrder = 5
	panelGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	panel = Instance.new("Frame")
	panel.Name = "SantriPanel"
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.Position = UDim2.fromScale(0.1, 1.1) -- off-screen
	panel.Size = UDim2.fromScale(0.8, 0.75)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	panel.Parent = panelGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.03, 0)
	corner.Parent = panel

	-- T37: 44 px touch target for title bar and close button
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 44)
	title.TextScaled = true
	title.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = "Daftar Santri"
	title.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.fromScale(1, 0)
	closeBtn.Size = UDim2.new(0.15, 0, 0, 44)
	closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
	closeBtn.TextScaled = true
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Parent = panel
	closeBtn.Activated:Connect(function()
		SantriPanel.close()
	end)

	scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Position = UDim2.fromOffset(0, 46)
	scrollFrame.Size = UDim2.new(1, 0, 1, -46)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.CanvasSize = UDim2.fromScale(1, 0)
	scrollFrame.Parent = panel

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0.01, 0)
	listLayout.Parent = scrollFrame

	-- SyncPlayerData: update cards if open
	Events.SyncPlayerData.OnClientEvent:Connect(function(rawData: any)
		latestData = rawData :: PlayerData
		if isOpen then
			rebuildCards()
		end
	end)

	-- Immediate tutoring prompt on ujian fail
	Events.NotifyEvent.OnClientEvent:Connect(function(rawPayload: any)
		local payload = rawPayload :: { [string]: any }
		if tostring((payload :: any).eventType) == "UjianFail" then
			local santriId = tostring((payload :: any).santriId or "")
			local program = ""
			if latestData ~= nil and santriId ~= "" then
				local s = latestData.santriList[santriId]
				if s ~= nil then
					program = tostring(s.program)
				end
			end
			showTutoringConfirm(santriId, program)
		end
	end)
end

return SantriPanel
