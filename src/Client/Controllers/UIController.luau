--!strict

-- T27: Visit Mode — friend list, live visit teleport, offline snapshot display.
-- T29: Leaderboard data retrieval for the social panel.
-- T38: Gamepad navigation — AutoSelectGuiEnabled, thumbstick scroll registration.
-- T42: Tutorial UI — step arrow, instruction text, skip button, step-6 camera zoom.
-- Rendering is handled by HUD.luau (T30); this module is pure logic except for T42 GUI.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = require(ReplicatedStorage.Shared.Net.Events)
local Functions = require(ReplicatedStorage.Shared.Net.Functions)
local Types = require(ReplicatedStorage.Shared.Modules.Types)

type LeaderboardEntry = Types.LeaderboardEntry

local LocalPlayer = Players.LocalPlayer

-- ── Public types ───────────────────────────────────────────────────────────────

export type FriendCard = {
	userId: number,
	username: string,
	isOnline: boolean,
	snapshot: { [string]: any }?,
}

local UIController = {}

-- ── T42: Tutorial state ───────────────────────────────────────────────────────

-- Arrow X positions (screen fraction) matching HUD button centers.
-- HUD: btnFrame width=0.75, 5 buttons×0.18 + 4 gaps×0.01 centered → first btn center≈0.215
local STEP_INFO: { [number]: { arrowX: number, text: string } } = {
	[1] = { arrowX = 0.215, text = "Tap 'Bangun' dan beli Musholla" },
	[2] = { arrowX = 0.215, text = "Sekarang beli Gubuk untuk santri tinggal" },
	[3] = { arrowX = 0.358, text = "Tap 'Santri' lalu daftarkan santri pertamamu" },
	[4] = { arrowX = 0.215, text = "Bangun Ruang Kelas agar santri bisa belajar" },
	[5] = { arrowX = 0.500, text = "Hire ustadz di menu Ustadz" },
	[6] = { arrowX = 0.500, text = "Tunggu santri belajar dan lulus ujian!" },
}

local tutorialGui: ScreenGui? = nil
local tutorialArrow: TextLabel? = nil
local tutorialInstr: TextLabel? = nil
local tutorialSkip: TextButton? = nil
local tutorialTween: Tween? = nil
local tutorialInitialized = false -- only apply initial state from first SyncPlayerData
local tutorialSkipped = false -- suppress celebration when player explicitly skips

local function hideTutorial(): ()
	if tutorialTween ~= nil then
		(tutorialTween :: Tween):Cancel()
		tutorialTween = nil
	end
	if tutorialGui ~= nil then
		(tutorialGui :: ScreenGui).Enabled = false
	end
end

local function showTutorialStep(displayStep: number): ()
	local info = STEP_INFO[displayStep]
	if info == nil or tutorialGui == nil then
		return
	end
	local gui = tutorialGui :: ScreenGui
	local arrow = tutorialArrow :: TextLabel
	local instr = tutorialInstr :: TextLabel
	local skip = tutorialSkip :: TextButton

	gui.Enabled = true
	instr.Text = info.text
	skip.Visible = displayStep >= 3

	-- Cancel existing bounce and reposition arrow
	if tutorialTween ~= nil then
		(tutorialTween :: Tween):Cancel()
		tutorialTween = nil
	end
	arrow.Visible = displayStep < 6  -- step 6 has no specific button target
	if arrow.Visible then
		arrow.Position = UDim2.fromScale(info.arrowX, 0.80)
		-- Bounce arrow toward the button (downward)
		local bounce = TweenService:Create(
			arrow,
			TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = UDim2.fromScale(info.arrowX, 0.83) }
		)
		tutorialTween = bounce
		bounce:Play()
	end
end

local function playCompletionEffect(): ()
	-- 2-second camera FOV zoom (in then out)
	local camera = workspace.CurrentCamera
	if camera ~= nil then
		local defaultFov = camera.FieldOfView
		local zoomIn = TweenService:Create(
			camera,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ FieldOfView = 40 }
		)
		local zoomOut = TweenService:Create(
			camera,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ FieldOfView = defaultFov }
		)
		zoomIn:Play()
		zoomIn.Completed:Connect(function()
			task.wait(0.5)
			zoomOut:Play()
		end)
	end

	-- Full-screen "Selamat!" overlay — auto-destroys after 3 seconds
	local celebGui = Instance.new("ScreenGui")
	celebGui.Name = "TutorialCelebGui"
	celebGui.DisplayOrder = 15
	celebGui.ResetOnSpawn = false
	celebGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
	overlay.BackgroundTransparency = 0.3
	overlay.Parent = celebGui

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.fromScale(0.8, 0.25)
	msg.AnchorPoint = Vector2.new(0.5, 0.5)
	msg.Position = UDim2.fromScale(0.5, 0.5)
	msg.TextScaled = true
	msg.BackgroundTransparency = 1
	msg.TextColor3 = Color3.fromRGB(255, 220, 80)
	msg.Text = "Selamat! Santrimu lulus!"
	msg.Parent = overlay

	task.delay(3, function()
		celebGui:Destroy()
	end)
end

-- ── T38: Gamepad thumbstick scroll ────────────────────────────────────────────

local activeScroll: ScrollingFrame? = nil
local SCROLL_SPEED = 8

-- Panels call this on open/close to register which ScrollingFrame thumbstick scrolls.
function UIController.setActiveScroll(frame: ScrollingFrame?): ()
	activeScroll = frame
end

local function onThumbstickScroll(
	_actionName: string,
	inputState: Enum.UserInputState,
	inputObject: InputObject
): Enum.ContextActionResult
	if inputState ~= Enum.UserInputState.Change then
		return Enum.ContextActionResult.Pass
	end
	local frame = activeScroll
	if frame == nil then
		return Enum.ContextActionResult.Pass
	end
	local newY = frame.CanvasPosition.Y - inputObject.Position.Y * SCROLL_SPEED
	local maxY = math.max(0, frame.AbsoluteCanvasSize.Y - frame.AbsoluteSize.Y)
	frame.CanvasPosition = Vector2.new(frame.CanvasPosition.X, math.clamp(newY, 0, maxY))
	return Enum.ContextActionResult.Sink
end

-- ── T27: Visit arrival detection ──────────────────────────────────────────────

-- Call once from init.client.luau on game start.
-- If this session was entered via a RequestVisit teleport, announces arrival to server.
function UIController.init(): ()
	-- T38: disable Roblox auto-select when a gamepad is present
	local function disableAutoSelect(): ()
		GuiService.AutoSelectGuiEnabled = false
	end
	UserInputService.GamepadConnected:Connect(disableAutoSelect)
	if #UserInputService:GetConnectedGamepads() > 0 then
		disableAutoSelect()
	end

	-- T38: bind left thumbstick to scroll the active panel ScrollingFrame
	ContextActionService:BindAction(
		"PesantrenGamepadScroll",
		onThumbstickScroll,
		false,
		Enum.KeyCode.Thumbstick1
	)

	-- T27: teleport arrival — announce to host server
	local ok, data = pcall(function(): any
		return TeleportService:GetLocalPlayerTeleportData()
	end)
	if ok and type(data) == "table" and type((data :: any).hostUserId) == "number" then
		Events.NotifyVisitArrival:FireServer((data :: any).hostUserId)
	end

	-- T42: Tutorial GUI creation
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")

	local tGui = Instance.new("ScreenGui")
	tGui.Name = "TutorialGui"
	tGui.DisplayOrder = 9
	tGui.ResetOnSpawn = false
	tGui.Enabled = false
	tGui.Parent = playerGui
	tutorialGui = tGui

	local arrow = Instance.new("TextLabel")
	arrow.Name = "TutorialArrow"
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.fromScale(0.06, 0.06)
	arrow.Position = UDim2.fromScale(0.5, 0.80)
	arrow.TextScaled = true
	arrow.BackgroundTransparency = 1
	arrow.TextColor3 = Color3.fromRGB(255, 220, 80)
	arrow.Text = "▼"
	arrow.Parent = tGui
	tutorialArrow = arrow

	local instrFrame = Instance.new("Frame")
	instrFrame.AnchorPoint = Vector2.new(0.5, 1)
	instrFrame.Position = UDim2.fromScale(0.5, 0.76)
	instrFrame.Size = UDim2.fromScale(0.62, 0.07)
	instrFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	instrFrame.BackgroundTransparency = 0.25
	instrFrame.Parent = tGui

	local instrCorner = Instance.new("UICorner")
	instrCorner.CornerRadius = UDim.new(0.12, 0)
	instrCorner.Parent = instrFrame

	local instrPad = Instance.new("UIPadding")
	instrPad.PaddingLeft = UDim.new(0.03, 0)
	instrPad.PaddingRight = UDim.new(0.03, 0)
	instrPad.Parent = instrFrame

	local instr = Instance.new("TextLabel")
	instr.Size = UDim2.fromScale(1, 1)
	instr.TextScaled = true
	instr.BackgroundTransparency = 1
	instr.TextColor3 = Color3.fromRGB(255, 255, 255)
	instr.Text = ""
	instr.Parent = instrFrame
	tutorialInstr = instr

	local skip = Instance.new("TextButton")
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Position = UDim2.fromScale(0.98, 0.02)
	skip.Size = UDim2.new(0.14, 0, 0, 44)
	skip.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	skip.TextScaled = true
	skip.Text = "Lewati"
	skip.TextColor3 = Color3.fromRGB(200, 200, 200)
	skip.Visible = false
	skip.Parent = tGui
	tutorialSkip = skip

	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0.2, 0)
	skipCorner.Parent = skip

	skip.Activated:Connect(function()
		tutorialSkipped = true
		Events.SkipTutorial:FireServer()
		hideTutorial()
	end)

	-- T42: Show initial step from first SyncPlayerData (returning players may already be past step 6)
	Events.SyncPlayerData.OnClientEvent:Connect(function(rawData: any)
		if tutorialInitialized then
			return
		end
		tutorialInitialized = true
		local step = (rawData :: { tutorialStep: number }).tutorialStep
		if type(step) == "number" and step < 6 then
			showTutorialStep(step + 1)
		end
	end)

	-- T42: React to server-pushed step advances and completion
	Events.NotifyEvent.OnClientEvent:Connect(function(rawPayload: any)
		local payload = rawPayload :: { [string]: any }
		local eventType = tostring((payload :: any).eventType)
		if eventType == "TutorialStep" then
			local step = (payload :: any).step
			if type(step) == "number" and step < 6 then
				showTutorialStep(step + 1)
			end
		elseif eventType == "TutorialComplete" then
			hideTutorial()
			if not tutorialSkipped then
				playCompletionEffect()
			end
		end
	end)
end

-- ── T27: Friend list ──────────────────────────────────────────────────────────

-- Fetches the local player's friend list and each friend's public snapshot.
-- Yields — call inside task.spawn from the UI layer.
function UIController.getFriendCards(): { FriendCard }
	local results: { FriendCard } = {}

	local pagesOk, pages = pcall(function(): any
		return Players:GetFriendsAsync(LocalPlayer.UserId)
	end)
	if not pagesOk then
		return results
	end

	local pagesObj = pages :: any
	while true do
		for _, entry in pagesObj:GetCurrentPage() do
			local e = entry :: any
			local snapOk, snapshot = pcall(function(): any
				return Functions.GetPublicSnapshot:InvokeServer(e.Id)
			end)
			table.insert(results, {
				userId = e.Id,
				username = e.Username,
				isOnline = e.IsOnline == true,
				snapshot = if snapOk and snapshot ~= nil then snapshot :: { [string]: any } else nil,
			})
		end
		if pagesObj.IsFinished then
			break
		end
		local advOk = pcall(function()
			pagesObj:AdvanceToNextPageAsync()
		end)
		if not advOk then
			break
		end
	end

	return results
end

-- ── T27: Visit a friend ───────────────────────────────────────────────────────

-- Requests the server to teleport this player to a friend's live server.
-- If the friend is offline the server fires NotifyEvent { OfflineSnapshot } back.
function UIController.visitFriend(friendUserId: number): ()
	Events.RequestVisit:FireServer(friendUserId)
end

-- ── T29: Leaderboard ──────────────────────────────────────────────────────────

-- Returns top-10 leaderboard entries for "Reputation", "Sanad", or "Alumni".
-- Each entry: { player = userId string, value = score }.
-- Yields — call inside task.spawn from the UI layer.
function UIController.getLeaderboard(board: string): { LeaderboardEntry }
	local ok, result = pcall(function(): any
		return Functions.GetLeaderboard:InvokeServer(board)
	end)
	if not ok or result == nil then
		return {}
	end
	return (result :: any) :: { LeaderboardEntry }
end

return UIController
