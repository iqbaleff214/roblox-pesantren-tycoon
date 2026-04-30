--!strict

-- T34: Toast alert system.
-- NotifyMasalah → red toast, tap → ResolveMasalah confirm.
-- NotifyGraduation → green toast.
-- Max 3 visible, 8-second auto-dismiss, slide-in from top, queue overflow.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Net.Events)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type MasalahEvent = Types.MasalahEvent

local LocalPlayer = Players.LocalPlayer

local TOAST_H = 0.06
local TOAST_GAP = 0.006
local TOAST_W = 0.42
local TOAST_X = 0.5
local DISMISS_SEC = 8
local SLIDE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local NotifController = {}

local toastGui: ScreenGui
local visibleToasts: { Frame } = {}
local pendingQueue: { { color: Color3, message: string, onTap: ((() -> ())?) } } = {}

local function repositionToasts(): ()
	for i, toast in visibleToasts do
		local targetY = 0.01 + (i - 1) * (TOAST_H + TOAST_GAP)
		TweenService:Create(toast, SLIDE, {
			Position = UDim2.fromScale(TOAST_X, targetY),
		}):Play()
	end
end

local function drainQueue(): ()
	if #pendingQueue > 0 and #visibleToasts < 3 then
		local entry = table.remove(pendingQueue, 1)
		;(NotifController :: any).showToast(entry.color, entry.message, entry.onTap)
	end
end

local function dismissToast(toast: Frame): ()
	for i, t in visibleToasts do
		if t == toast then
			table.remove(visibleToasts, i)
			break
		end
	end
	local slideOut = TweenService:Create(toast, SLIDE, {
		Position = UDim2.fromScale(TOAST_X, -TOAST_H - 0.02),
	})
	slideOut.Completed:Connect(function()
		toast:Destroy()
		repositionToasts()
		drainQueue()
	end)
	slideOut:Play()
end

-- Creates and shows one toast. If 3 already visible, queues it.
function NotifController.showToast(color: Color3, message: string, onTap: ((() -> ()))?): ()
	if #visibleToasts >= 3 then
		table.insert(pendingQueue, { color = color, message = message, onTap = onTap })
		return
	end

	local slotIndex = #visibleToasts + 1
	local targetY = 0.01 + (slotIndex - 1) * (TOAST_H + TOAST_GAP)

	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.fromScale(TOAST_X, -TOAST_H - 0.02) -- start above screen
	toast.Size = UDim2.fromScale(TOAST_W, TOAST_H)
	toast.BackgroundColor3 = color
	toast.ZIndex = 10
	toast.Parent = toastGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.85, 1)
	label.Position = UDim2.fromScale(0.075, 0)
	label.TextScaled = true
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = message
	label.ZIndex = 11
	label.Parent = toast

	table.insert(visibleToasts, toast)

	TweenService:Create(toast, SLIDE, {
		Position = UDim2.fromScale(TOAST_X, targetY),
	}):Play()

	task.delay(DISMISS_SEC, function()
		if toast.Parent ~= nil then
			dismissToast(toast)
		end
	end)

	if onTap ~= nil then
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromScale(1, 1)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 12
		btn.Parent = toast
		local tapCb = onTap
		btn.Activated:Connect(function()
			dismissToast(toast)
			tapCb()
		end)
	end
end

-- ── Masalah confirm dialog ─────────────────────────────────────────────────────

local function showMasalahConfirm(masalahId: string, masalahType: string): ()
	local dialog = Instance.new("Frame")
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.Position = UDim2.fromScale(0.5, 0.5)
	dialog.Size = UDim2.fromScale(0.5, 0.25)
	dialog.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	dialog.ZIndex = 15
	dialog.Parent = toastGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.08, 0)
	corner.Parent = dialog

	local prompt = Instance.new("TextLabel")
	prompt.Size = UDim2.fromScale(1, 0.5)
	prompt.TextScaled = true
	prompt.BackgroundTransparency = 1
	prompt.TextColor3 = Color3.fromRGB(255, 255, 255)
	prompt.Text = "Selesaikan " .. masalahType .. "?"
	prompt.ZIndex = 16
	prompt.Parent = dialog

	local yesBtn = Instance.new("TextButton")
	yesBtn.AnchorPoint = Vector2.new(0, 1)
	yesBtn.Position = UDim2.fromScale(0.1, 1)
	yesBtn.Size = UDim2.fromScale(0.35, 0.4)
	yesBtn.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
	yesBtn.TextScaled = true
	yesBtn.Text = "Ya"
	yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	yesBtn.ZIndex = 16
	yesBtn.Parent = dialog

	local noBtn = Instance.new("TextButton")
	noBtn.AnchorPoint = Vector2.new(1, 1)
	noBtn.Position = UDim2.fromScale(0.9, 1)
	noBtn.Size = UDim2.fromScale(0.35, 0.4)
	noBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	noBtn.TextScaled = true
	noBtn.Text = "Tidak"
	noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	noBtn.ZIndex = 16
	noBtn.Parent = dialog

	yesBtn.Activated:Connect(function()
		Events.ResolveMasalah:FireServer(masalahId)
		dialog:Destroy()
	end)
	noBtn.Activated:Connect(function()
		dialog:Destroy()
	end)
end

-- ── Initialization ─────────────────────────────────────────────────────────────

function NotifController.init(): ()
	toastGui = Instance.new("ScreenGui")
	toastGui.Name = "NotifGui"
	toastGui.ResetOnSpawn = false
	toastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	toastGui.DisplayOrder = 10
	toastGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	Events.NotifyMasalah.OnClientEvent:Connect(function(rawEvent: any)
		local event = rawEvent :: MasalahEvent
		local masalahType = tostring(event.eventType)
		NotifController.showToast(
			Color3.fromRGB(180, 50, 50),
			"⚠ " .. masalahType .. "! Ketuk untuk selesaikan",
			function()
				showMasalahConfirm(event.id, masalahType)
			end
		)
	end)

	Events.NotifyGraduation.OnClientEvent:Connect(function(_rawSantriId: any, rawProgram: any)
		NotifController.showToast(
			Color3.fromRGB(50, 160, 80),
			"Santri " .. tostring(rawProgram) .. " lulus!",
			nil
		)
	end)
end

return NotifController
