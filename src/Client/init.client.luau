--!strict

-- Bootstrap: require and initialise all controllers and components.
-- Order matters: InputController must be init'd before HUD (which wires action callbacks).

local InputController = require(script.Controllers.InputController)
local UIController = require(script.Controllers.UIController)
local NotifController = require(script.Controllers.NotifController)
local BuildController = require(script.Controllers.BuildController)

local HUD = require(script.Components.HUD)
local BuildMenu = require(script.Components.BuildMenu)
local SantriPanel = require(script.Components.SantriPanel)
local EventBanner = require(script.Components.EventBanner)

-- 1. Input bindings first — everything else connects to these actions
InputController.init()

-- 2. Root HUD (creates ScreenGui, wires action → panel toggle)
HUD.init()

-- 3. Panels (each creates its own ScreenGui; HUD's OpenBuildMenu/OpenSantriPanel already wired)
BuildMenu.init()
SantriPanel.init()
EventBanner.init()

-- 4. Controller side-effects
NotifController.init()
UIController.init() -- visit arrival detection

-- Suppress unused-require lint: BuildController is a side-effect module
local _ = BuildController
