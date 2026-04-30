--!strict

-- T33: Event banners per eventType, queued, animated in/out via TweenService.
-- WaktuSholat: 60-second countdown via RunService.Heartbeat, tap → AcknowledgeWaktuSholat.
-- Haptic fires on WaktuSholat (gamepad/mobile).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HapticService = game:GetService("HapticService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Net.Events)

local LocalPlayer = Players.LocalPlayer

local SLIDE_IN = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLIDE_OUT = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local EventBanner = {}

local bannerGui: ScreenGui
local bannerQueue: { { eventType: string, payload: { [string]: any } } } = {}
local bannerActive = false

local function tryHaptic(): ()
	pcall(function()
		if HapticService:IsVibrationSupported() then
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.5)
			task.delay(0.3, function()
				pcall(function()
					HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
				end)
			end)
		end
	end)
end

local function makeBaseBanner(bgColor: Color3, text: string): Frame
	local frame = Instance.new("Frame")
	frame.Name = "EventBanner"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.fromScale(0.5, -0.2) -- off-screen top
	frame.Size = UDim2.fromScale(0.6, 0.12)
	frame.BackgroundColor3 = bgColor
	frame.ZIndex = 8
	frame.Parent = bannerGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = text
	label.ZIndex = 9
	label.Parent = frame

	return frame
end

local showBanner -- forward declared

local function slideIn(frame: Frame): ()
	TweenService:Create(frame, SLIDE_IN, {
		Position = UDim2.fromScale(0.5, 0.04),
	}):Play()
end

local function slideOutAndNext(frame: Frame): ()
	local tween = TweenService:Create(frame, SLIDE_OUT, {
		Position = UDim2.fromScale(0.5, -0.2),
	})
	tween.Completed:Connect(function()
		frame:Destroy()
		bannerActive = false
		if #bannerQueue > 0 then
			local next = table.remove(bannerQueue, 1)
			showBanner(next.eventType, next.payload)
		end
	end)
	tween:Play()
end

local function autoDismiss(frame: Frame, delaySec: number): ()
	task.delay(delaySec, function()
		if frame.Parent ~= nil then
			slideOutAndNext(frame)
		end
	end)
end

-- showBanner: renders the correct banner for eventType.
showBanner = function(eventType: string, payload: { [string]: any }): ()
	bannerActive = true

	if eventType == "WaktuSholat" then
		tryHaptic()
		local frame = makeBaseBanner(Color3.fromRGB(30, 100, 180), "Waktu Sholat! Tap untuk bonus!")
		slideIn(frame)

		-- Countdown label
		local label = frame:FindFirstChildWhichIsA("TextLabel")
		local remaining = 60
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function(dt: number)
			remaining -= dt
			if remaining <= 0 then
				conn:Disconnect()
				if frame.Parent ~= nil then
					slideOutAndNext(frame)
				end
			elseif label ~= nil then
				label.Text = string.format("Waktu Sholat! Tap untuk bonus! (%ds)", math.ceil(remaining))
			end
		end)

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromScale(1, 1)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 10
		btn.Parent = frame
		btn.Activated:Connect(function()
			if frame.Parent ~= nil then
				conn:Disconnect()
				Events.AcknowledgeWaktuSholat:FireServer()
				slideOutAndNext(frame)
			end
		end)

	elseif eventType == "JumatBerkah" then
		local frame = makeBaseBanner(Color3.fromRGB(180, 140, 20), "Jum'at Berkah! Pendapatan 2× selama 30 menit!")
		slideIn(frame)
		autoDismiss(frame, 3)

	elseif eventType == "SeasonalTheme" then
		local theme = tostring((payload :: any).theme or "")
		local active = (payload :: any).active
		local text = if active then "Musim " .. theme .. " dimulai!" else "Musim " .. theme .. " berakhir."
		local frame = makeBaseBanner(Color3.fromRGB(100, 50, 150), text)
		slideIn(frame)
		autoDismiss(frame, 5)

	elseif eventType == "ZoneUnlocked" then
		local zone = tostring((payload :: any).zone or "")
		local frame = makeBaseBanner(Color3.fromRGB(20, 140, 60), "Zona " .. zone .. " baru terbuka!")
		slideIn(frame)
		local label = frame:FindFirstChildWhichIsA("TextLabel")
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromScale(1, 1)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.ZIndex = 10
		btn.Parent = frame
		btn.Activated:Connect(function()
			if frame.Parent ~= nil then
				slideOutAndNext(frame)
			end
		end)
		-- also show zone label
		if label ~= nil then
			label.Text = "Zona " .. zone .. " baru terbuka! (Tap tutup)"
		end

	elseif eventType == "KunjunganMenteri" then
		local frame = makeBaseBanner(Color3.fromRGB(200, 50, 50), "Kunjungan Menteri! 5× income selama 3 menit!")
		slideIn(frame)
		autoDismiss(frame, 4)

	elseif eventType == "BukaCabang" then
		local sanad = tostring((payload :: any).sanadReward or 1)
		local frame = makeBaseBanner(Color3.fromRGB(60, 60, 180), "Prestige! +" .. sanad .. " Sanad. Pesantren baru dimulai!")
		slideIn(frame)
		autoDismiss(frame, 5)

	elseif eventType == "TabligStart" then
		local frame = makeBaseBanner(Color3.fromRGB(120, 60, 20), "Tabligh Akbar! 5× income selama 5 menit!")
		slideIn(frame)
		autoDismiss(frame, 4)

	elseif eventType == "SholatSempurna" then
		local frame = makeBaseBanner(Color3.fromRGB(20, 120, 140), "Sholat Sempurna! Bonus harian diterima!")
		slideIn(frame)
		autoDismiss(frame, 4)

	else
		-- Generic fallback for unknown event types
		bannerActive = false
		if #bannerQueue > 0 then
			local next = table.remove(bannerQueue, 1)
			showBanner(next.eventType, next.payload)
		end
	end
end

function EventBanner.init(): ()
	bannerGui = Instance.new("ScreenGui")
	bannerGui.Name = "EventBannerGui"
	bannerGui.ResetOnSpawn = false
	bannerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	bannerGui.DisplayOrder = 8
	bannerGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	Events.NotifyEvent.OnClientEvent:Connect(function(rawPayload: any)
		local payload = (rawPayload :: any) :: { [string]: any }
		local eventType = tostring(payload.eventType or "")
		if eventType == "" then
			return
		end
		if bannerActive then
			table.insert(bannerQueue, { eventType = eventType, payload = payload })
		else
			showBanner(eventType, payload)
		end
	end)

	-- Haptic on graduation too
	Events.NotifyGraduation.OnClientEvent:Connect(function()
		tryHaptic()
	end)
end

return EventBanner
