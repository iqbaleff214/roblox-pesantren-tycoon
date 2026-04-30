--!strict

-- T30: Main HUD ScreenGui.
-- Top-left: currency bars (Rupiah, Barakah, Ilmu, Sanad) via UIListLayout.
-- Top-right: Reputation bar + tier label.
-- Top-center: notification area (NotifController renders toasts into its own ScreenGui above).
-- Bottom-left: Sedekah Jariyah rate + Waqf pool progress bar.
-- Bottom-center: action buttons (Bangun, Santri, Ustadz, Event, Social).
-- Listens to SyncPlayerData and SyncWaqfPool for live updates.

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Net.Events)
local Constants = require(ReplicatedStorage.Shared.Modules.Constants)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

-- Lazy-require panels so they init after HUD's ScreenGui exists
local function getBuildMenu()
	return require(script.Parent.BuildMenu)
end
local function getSantriPanel()
	return require(script.Parent.SantriPanel)
end
local function getInputController()
	return require(script.Parent.Parent.Controllers.InputController)
end

type PlayerData = Types.PlayerData

local LocalPlayer = Players.LocalPlayer

local HUD = {}

-- Mutable UI refs updated by SyncPlayerData
local currencyLabels: { [string]: TextLabel } = {}
local repFill: Frame
local tierLabel: TextLabel
local sedekahLabel: TextLabel
local waqfFill: Frame

-- ── Internal helpers ───────────────────────────────────────────────────────────

local function makeCurrencyRow(parent: Frame, currencyKey: string): TextLabel
	local row = Instance.new("Frame")
	row.Size = UDim2.fromScale(1, 0.22)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromScale(0.18, 1)
	icon.BackgroundTransparency = 1
	local asp = Instance.new("UIAspectRatioConstraint")
	asp.AspectRatio = 1
	asp.Parent = icon
	icon.Parent = row

	local amount = Instance.new("TextLabel")
	amount.Size = UDim2.fromScale(0.8, 1)
	amount.Position = UDim2.fromScale(0.2, 0)
	amount.TextScaled = true
	amount.BackgroundTransparency = 1
	amount.TextColor3 = Color3.fromRGB(240, 240, 240)
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.Text = currencyKey .. ": 0"
	amount.Parent = row

	return amount
end

local function tierName(rep: number): string
	if rep >= Constants.REP_TIER_PRESTIGE_UNLOCK then
		return "Prestige"
	elseif rep >= Constants.REP_TIER_UNGGULAN then
		return "Unggulan"
	elseif rep >= Constants.REP_TIER_BERKEMBANG then
		return "Berkembang"
	else
		return "Biasa"
	end
end

-- ── Public init ────────────────────────────────────────────────────────────────

function HUD.init(): ()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PesantrenHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 1
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	-- Safe-area bottom offset (home indicator on mobile, task bar on console)
	local _, bottomRight = (GuiService :: any):GetGuiInset()
	local safeBottom = math.max((bottomRight :: Vector2).Y, 0)

	-- ── Currency frame (top-left) ──────────────────────────────────────────────
	local currFrame = Instance.new("Frame")
	currFrame.AnchorPoint = Vector2.new(0, 0)
	currFrame.Position = UDim2.fromScale(0, 0)
	currFrame.Size = UDim2.fromScale(0.28, 0.22)
	currFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	currFrame.BackgroundTransparency = 0.45
	currFrame.Parent = screenGui

	local currCorner = Instance.new("UICorner")
	currCorner.CornerRadius = UDim.new(0.04, 0)
	currCorner.Parent = currFrame

	local currPad = Instance.new("UIPadding")
	currPad.PaddingLeft = UDim.new(0.04, 0)
	currPad.PaddingRight = UDim.new(0.04, 0)
	currPad.PaddingTop = UDim.new(0.04, 0)
	currPad.PaddingBottom = UDim.new(0.04, 0)
	currPad.Parent = currFrame

	local currList = Instance.new("UIListLayout")
	currList.FillDirection = Enum.FillDirection.Vertical
	currList.SortOrder = Enum.SortOrder.LayoutOrder
	currList.Padding = UDim.new(0.02, 0)
	currList.Parent = currFrame

	currencyLabels["Rupiah"] = makeCurrencyRow(currFrame, "Rp")
	currencyLabels["Barakah"] = makeCurrencyRow(currFrame, "Bk")
	currencyLabels["Ilmu"] = makeCurrencyRow(currFrame, "Il")
	currencyLabels["Sanad"] = makeCurrencyRow(currFrame, "Sn")

	-- ── Reputation frame (top-right) ───────────────────────────────────────────
	local repFrame = Instance.new("Frame")
	repFrame.AnchorPoint = Vector2.new(1, 0)
	repFrame.Position = UDim2.fromScale(1, 0)
	repFrame.Size = UDim2.fromScale(0.22, 0.1)
	repFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	repFrame.BackgroundTransparency = 0.45
	repFrame.Parent = screenGui

	local repCorner = Instance.new("UICorner")
	repCorner.CornerRadius = UDim.new(0.08, 0)
	repCorner.Parent = repFrame

	tierLabel = Instance.new("TextLabel")
	tierLabel.Size = UDim2.fromScale(1, 0.48)
	tierLabel.TextScaled = true
	tierLabel.BackgroundTransparency = 1
	tierLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	tierLabel.Text = "Biasa"
	tierLabel.Parent = repFrame

	local repBarBg = Instance.new("Frame")
	repBarBg.AnchorPoint = Vector2.new(0.5, 1)
	repBarBg.Position = UDim2.fromScale(0.5, 0.98)
	repBarBg.Size = UDim2.fromScale(0.88, 0.35)
	repBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	repBarBg.Parent = repFrame

	local repBarCorner = Instance.new("UICorner")
	repBarCorner.CornerRadius = UDim.new(0.5, 0)
	repBarCorner.Parent = repBarBg

	repFill = Instance.new("Frame")
	repFill.Size = UDim2.fromScale(0, 1)
	repFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	repFill.Parent = repBarBg

	local repFillCorner = Instance.new("UICorner")
	repFillCorner.CornerRadius = UDim.new(0.5, 0)
	repFillCorner.Parent = repFill

	-- ── Sedekah + Waqf bar (bottom-left) ──────────────────────────────────────
	local btnH = 0.09 -- button frame height scale

	sedekahLabel = Instance.new("TextLabel")
	sedekahLabel.Name = "SedekahLabel"
	sedekahLabel.AnchorPoint = Vector2.new(0, 1)
	sedekahLabel.Position = UDim2.new(0.01, 0, 1, -safeBottom - math.round(btnH * 667) - 4)
	sedekahLabel.Size = UDim2.fromScale(0.35, 0.05)
	sedekahLabel.TextScaled = true
	sedekahLabel.BackgroundTransparency = 1
	sedekahLabel.TextColor3 = Color3.fromRGB(160, 255, 160)
	sedekahLabel.TextXAlignment = Enum.TextXAlignment.Left
	sedekahLabel.Text = "+Rp 0/min passive"
	sedekahLabel.Parent = screenGui

	local waqfBarBg = Instance.new("Frame")
	waqfBarBg.Name = "WaqfBarBg"
	waqfBarBg.AnchorPoint = Vector2.new(0, 1)
	waqfBarBg.Position = UDim2.new(0.01, 0, 1, -safeBottom - math.round(btnH * 667) - 8)
	waqfBarBg.Size = UDim2.fromScale(0.18, 0.008)
	waqfBarBg.BackgroundColor3 = Color3.fromRGB(60, 40, 10)
	waqfBarBg.Parent = screenGui

	waqfFill = Instance.new("Frame")
	waqfFill.Size = UDim2.fromScale(0, 1)
	waqfFill.BackgroundColor3 = Color3.fromRGB(210, 160, 50)
	waqfFill.Parent = waqfBarBg

	local waqfTip = Instance.new("TextLabel")
	waqfTip.AnchorPoint = Vector2.new(0, 1)
	waqfTip.Position = UDim2.fromScale(0, -0.1)
	waqfTip.Size = UDim2.fromScale(1.5, 0.6)
	waqfTip.TextScaled = true
	waqfTip.BackgroundTransparency = 1
	waqfTip.TextColor3 = Color3.fromRGB(180, 140, 60)
	waqfTip.TextXAlignment = Enum.TextXAlignment.Left
	waqfTip.Text = "Waqf"
	waqfTip.Parent = waqfBarBg

	-- ── Bottom action buttons ──────────────────────────────────────────────────
	local btnFrame = Instance.new("Frame")
	btnFrame.Name = "ButtonsFrame"
	btnFrame.AnchorPoint = Vector2.new(0.5, 1)
	btnFrame.Position = UDim2.new(0.5, 0, 1, -safeBottom)
	btnFrame.Size = UDim2.fromScale(0.75, btnH)
	btnFrame.BackgroundTransparency = 1
	btnFrame.Parent = screenGui

	local btnList = Instance.new("UIListLayout")
	btnList.FillDirection = Enum.FillDirection.Horizontal
	btnList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnList.VerticalAlignment = Enum.VerticalAlignment.Center
	btnList.SortOrder = Enum.SortOrder.LayoutOrder
	btnList.Padding = UDim.new(0.01, 0)
	btnList.Parent = btnFrame

	local BUTTONS: { { label: string, action: string } } = {
		{ label = "Bangun", action = "OpenBuildMenu"   },
		{ label = "Santri", action = "OpenSantriPanel" },
		{ label = "Ustadz", action = ""                },
		{ label = "Event",  action = ""                },
		{ label = "Social", action = "OpenSocialMenu"  },
	}

	local InputController = getInputController()

	for i, btnDef in BUTTONS do
		local btn = Instance.new("TextButton")
		btn.LayoutOrder = i
		btn.Size = UDim2.fromScale(0.18, 1) -- 5 buttons × 0.18 + 4 gaps × 0.01 ≈ 0.94 of frame
		btn.BackgroundColor3 = Color3.fromRGB(35, 75, 35)
		btn.TextScaled = true
		btn.Text = btnDef.label
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Parent = btnFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0.15, 0)
		btnCorner.Parent = btn

		if btnDef.action ~= "" then
			local actionName = btnDef.action
			btn.Activated:Connect(function()
				InputController.fireAction(actionName)
			end)
		end
	end

	-- ── Wire InputController actions to panels ─────────────────────────────────
	-- BuildMenu and SantriPanel are initialised separately in init.client.luau;
	-- connect here so HUD owns the wiring.
	InputController.onAction("OpenBuildMenu"):Connect(function()
		getBuildMenu().toggle()
	end)
	InputController.onAction("OpenSantriPanel"):Connect(function()
		getSantriPanel().toggle()
	end)
	InputController.onAction("CloseMenu"):Connect(function()
		getBuildMenu().close()
		getSantriPanel().close()
	end)

	-- ── SyncPlayerData ─────────────────────────────────────────────────────────
	Events.SyncPlayerData.OnClientEvent:Connect(function(rawData: any)
		local data = rawData :: PlayerData
		currencyLabels["Rupiah"].Text = "Rp " .. tostring(math.floor(data.rupiah))
		currencyLabels["Barakah"].Text = "Bk " .. tostring(math.floor(data.barakah))
		currencyLabels["Ilmu"].Text = "Il " .. tostring(math.floor(data.ilmu))
		currencyLabels["Sanad"].Text = "Sn " .. tostring(math.floor(data.sanad))
		repFill.Size = UDim2.fromScale(math.clamp(data.reputation / 100, 0, 1), 1)
		tierLabel.Text = tierName(data.reputation)
		sedekahLabel.Text = "+Rp " .. tostring(data.sedekahJariyahPerMin) .. "/min passive"
	end)

	-- ── SyncWaqfPool ───────────────────────────────────────────────────────────
	Events.SyncWaqfPool.OnClientEvent:Connect(function(rawAmount: any)
		local pool = (rawAmount :: any) :: number
		waqfFill.Size = UDim2.fromScale(math.clamp(pool / Constants.WAQF_UPGRADE_THRESHOLD, 0, 1), 1)
	end)
end

return HUD
