--!strict

-- T35: Cross-platform action bindings via ContextActionService.
-- Consumers connect via InputController.onAction(name).
-- HUD touch buttons call InputController.fireAction(name) so all inputs share one path.

local ContextActionService = game:GetService("ContextActionService")

local InputController = {}

local actionEvents: { [string]: BindableEvent } = {}

local ACTIONS: { { name: string, key: Enum.KeyCode, pad: Enum.KeyCode } } = {
	{ name = "OpenBuildMenu",   key = Enum.KeyCode.B,      pad = Enum.KeyCode.DPadDown     },
	{ name = "OpenSantriPanel", key = Enum.KeyCode.S,      pad = Enum.KeyCode.DPadUp       },
	{ name = "OpenSocialMenu",  key = Enum.KeyCode.F,      pad = Enum.KeyCode.ButtonSelect },
	{ name = "ConfirmDialog",   key = Enum.KeyCode.Return, pad = Enum.KeyCode.ButtonA      },
	{ name = "CloseMenu",       key = Enum.KeyCode.Escape, pad = Enum.KeyCode.ButtonB      },
	{ name = "CameraZoomIn",    key = Enum.KeyCode.E,      pad = Enum.KeyCode.ButtonR2     },
	{ name = "CameraZoomOut",   key = Enum.KeyCode.Q,      pad = Enum.KeyCode.ButtonL2     },
}

local function ensureEvent(name: string): BindableEvent
	if actionEvents[name] == nil then
		actionEvents[name] = Instance.new("BindableEvent")
	end
	return actionEvents[name]
end

-- Returns the RBXScriptSignal to connect callbacks to the named action.
function InputController.onAction(name: string): RBXScriptSignal
	return ensureEvent(name).Event
end

-- Fires the named action programmatically (used by HUD touch buttons).
function InputController.fireAction(name: string): ()
	local be = actionEvents[name]
	if be ~= nil then
		be:Fire()
	end
end

-- Binds all keyboard/gamepad actions. Call once from init.client.luau.
function InputController.init(): ()
	for _, action in ACTIONS do
		local be = ensureEvent(action.name)
		ContextActionService:BindAction(
			action.name,
			function(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
				if state == Enum.UserInputState.Begin then
					be:Fire()
				end
				return Enum.ContextActionResult.Pass
			end,
			false, -- createTouchButton = false; HUD handles touch
			action.key,
			action.pad
		)
	end
end

return InputController
