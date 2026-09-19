-- Core.lua
-- Addon entrypoint. Sets up the global table, saved variables, the shared
-- event/OnUpdate frame, and the /coacombat slash command. Every module hangs
-- off the CoACombat table (methods like :Enable, :ApplyBindings, :UpdateReticle).

local ADDON_NAME = ...
local L = CoACombatLocale

CoACombat = CoACombat or {}
local A = CoACombat

-- ------------------------------------------------------------------
-- Defaults. Anything the user hasn't set falls back to this.
-- ------------------------------------------------------------------
A.defaults = {
	enabled          = false,     -- action mode on/off
	reticleShown     = true,
	reticleSize      = 24,
	reticleStyle     = "triangle",
	reticleOpacity   = 1,
	reticleColorMode = "normal",
	reticleColorNone     = {1.00, 1.00, 1.00, 0.35},
	reticleColorHostile  = {1.00, 0.55, 0.15, 0.90},
	reticleColorFriendly = {0.35, 0.60, 1.00, 0.85},
	reticleColorInteract = {0.35, 1.00, 0.40, 0.90},
	reticleColorDead     = {0.55, 0.55, 0.55, 0.75},

	-- Mouselook override bindings. Keys are input names, values are the
	-- action strings accepted by SetMouselookOverrideBinding.
	bindings = {
		BUTTON1 = "ACTIONBUTTON1",
		BUTTON2 = "ACTIONBUTTON2",
		E       = "INTERACTMOUSEOVER",
	},

	-- Interact key (kept separately so the user can rebind it via the
	-- friendly `interact` slash without touching `bindings`).
	interactKey = "E",

	-- Frames whose presence forces mouselook to release. Extend if a UI
	-- addon (Bagnon replacement, etc.) uses a non-default frame name.
	extraReleaseFrames = {},
	softTargetEnabled = false,
	aimTargetEnabled = true,
	softTargetRadius = 90,
	camera = {
		enabled = true,
		transition = 0.7,
		travelForms = true,
		profiles = {
			foot = { angle = 4, distance = 1.25, height = 0.05, enemy = false, interact = false, headbob = false, recall = false, zoom = 6 },
			mounted = { angle = 4, distance = 1.75, height = 0.2, enemy = false, interact = false, headbob = false, recall = false, zoom = 10 },
			combat = { angle = 4, distance = 1.4, height = 0.05, enemy = false, interact = false, headbob = false, recall = false, zoom = 8 },
		},
	},
}

A.releaseFrames = {
	"GameMenuFrame", "CharacterFrame", "SpellBookFrame", "TalentFrame", "QuestLogFrame",
	"PVPFrame", "AchievementFrame", "QuestFrame", "GossipFrame",
	"MerchantFrame", "TrainerFrame", "MailFrame", "OpenMailFrame",
	"BankFrame", "AuctionFrame", "TradeFrame", "TaxiFrame",
	"MacroFrame", "CraftFrame", "TradeSkillFrame",
	"OptionsFrame", "InterfaceOptionsFrame", "VideoOptionsFrame",
	"KeyBindingFrame", "LootFrame", "PetitionFrame",
	"GuildRegistrarFrame", "ItemTextFrame", "ReadyCheckFrame",
	"WorldMapFrame", "HelpFrame", "RaidBrowserFrame",
	"LFDParentFrame", "PVEFrame", "DressUpFrame", "TutorialFrame",
	"ContainerFrame1", "ContainerFrame2", "ContainerFrame3",
	"ContainerFrame4", "ContainerFrame5", "BagFrame",
	"GuildBankFrame", "StackSplitFrame", "ItemRefTooltip",
	"AscensionCharacterFrame", "AscensionSpellbookFrame",
}

-- ------------------------------------------------------------------
-- Utility: chat print + combat gate
-- ------------------------------------------------------------------
function A:Print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(L["PREFIX"] .. (msg or ""))
	end
end

function A:InCombat()
	return InCombatLockdown and InCombatLockdown() or false
end

-- Deep-copy defaults so we never mutate the table in code.
local function deepcopy(t)
	if type(t) ~= "table" then return t end
	local out = {}
	for k, v in pairs(t) do out[k] = deepcopy(v) end
	return out
end
A.CopyTable = deepcopy

-- Merge missing keys from defaults into db (non-destructive, one level for
-- scalars, recursive for sub-tables).
local function merge(db, defs)
	for k, v in pairs(defs) do
		-- Binding maps are complete sets; do not resurrect removed keys.
		if k == "bindings" then
			if type(db[k]) ~= "table" then db[k] = deepcopy(v) end
		elseif type(v) == "table" then
			if type(db[k]) ~= "table" then db[k] = {} end
			merge(db[k], v)
		elseif db[k] == nil then
			db[k] = v
		end
	end
end

-- ------------------------------------------------------------------
-- Shared frame: single OnEvent + throttled OnUpdate for the whole addon.
-- Modules register hooks via A:RegisterUpdate(id, fn) instead of making
-- their own frames.
-- ------------------------------------------------------------------
local root = CreateFrame("Frame", "CoACombatRootFrame", UIParent)
A.root = root
A._updates = {}
A._updateInterval = 0.05
A._updateAccum = 0

function A:RegisterUpdate(id, fn)
	self._updates[id] = fn
end

function A:UnregisterUpdate(id)
	self._updates[id] = nil
end

root:SetScript("OnUpdate", function(self, elapsed)
	A._updateAccum = A._updateAccum + elapsed
	if A._updateAccum < A._updateInterval then return end
	local dt = A._updateAccum
	A._updateAccum = 0
	for _, fn in pairs(A._updates) do
		fn(dt)
	end
end)

-- ------------------------------------------------------------------
-- Event handler
-- ------------------------------------------------------------------
root:RegisterEvent("ADDON_LOADED")
root:RegisterEvent("PLAYER_LOGIN")
root:RegisterEvent("PLAYER_ENTERING_WORLD")
root:RegisterEvent("PLAYER_REGEN_DISABLED")
root:RegisterEvent("PLAYER_REGEN_ENABLED")
root:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
root:RegisterEvent("PLAYER_LOGOUT")

root:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		CoACombatDB   = CoACombatDB   or {}
		CoACombatDBPC = CoACombatDBPC or {}
		-- Account settings and character-local preset storage.
		A.db = setmetatable(CoACombatDBPC, { __index = CoACombatDB })
		merge(CoACombatDB, A.defaults)
		CoACombatDBPC.presets = CoACombatDBPC.presets or {}
		CoACombatDBPC.specPresets = CoACombatDBPC.specPresets or {}
		self:UnregisterEvent("ADDON_LOADED")
		return
	end

	if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		if not CoACombatDB then return end
		if A.MouseLook_Init      then A:MouseLook_Init()      end
		if A.Reticle_Init        then A:Reticle_Init()        end
		if A.Targeting_Init then A:Targeting_Init() end
		if A.Camera_Init then A:Camera_Init() end
		if A.Options_Init then A:Options_Init() end
		if A.CrosshairOptions_Init then A:CrosshairOptions_Init() end
		if A.CameraOptions_Init then A:CameraOptions_Init() end
		if (not A.Camera_Init or not A.CameraOptions_Init or not A.CrosshairOptions_Init) and not A._missingModulesWarned then
			A._missingModulesWarned = true
			A:Print(L.RESTART_REQUIRED)
		end
		if A.Presets_ApplySpec then A:Presets_ApplySpec() end
		-- Auto-enable if the user had it on last time.
		if CoACombatDB.enabled then A:Enable(true) else A:Disable(true) end
		if not A._loginAnnounced then
			A:Print(CoACombatDB.enabled and L["STATE_ON"] or L["STATE_OFF"])
			A._loginAnnounced = true
		end
		return
	end
	if event == "ACTIVE_TALENT_GROUP_CHANGED" then
		if A.Presets_ApplySpec then A:Presets_ApplySpec() end
		return
	end
	if event == "PLAYER_LOGOUT" then
		if A.Camera_Shutdown then A:Camera_Shutdown() end
		return
	end

	if event == "PLAYER_REGEN_DISABLED" then
		-- Entering combat: freeze binding changes.
		A._combatLocked = true
		return
	end

	if event == "PLAYER_REGEN_ENABLED" then
		A._combatLocked = false
		-- Re-apply any deferred bindings.
		if A._deferredApply then
			A._deferredApply = nil
			if A.Bindings_ApplyAll then A:Bindings_ApplyAll() end
		end
		if A._deferredEnable then
			A._deferredEnable = nil
			if CoACombatDB.enabled then A:MouseLook_Enable() end
		end
		return
	end
end)

-- ------------------------------------------------------------------
-- Public API used by the slash commands and by other modules
-- ------------------------------------------------------------------
function A:Enable(silent)
	CoACombatDB.enabled = true
	if self.Bindings_ApplyAll then self:Bindings_ApplyAll() end
	if not CoACombatDB.enabled then return end
	-- Do not capture the cursor before the first combat bindings can install.
	if self:InCombat() and not self._enabled then
		self._deferredEnable = true
		if not silent then self:Print(L.ENABLE_DEFERRED) end
		return
	end
	if self.MouseLook_Enable then self:MouseLook_Enable() end
	if self.Reticle_SetShown then self:Reticle_SetShown(CoACombatDB.reticleShown) end
	if self.Camera_Update then self:Camera_Update(0) end
	if not silent then self:Print(L["STATE_ON"]) end
end

function A:Disable(silent)
	CoACombatDB.enabled = false
	self._deferredEnable = nil
	if self.MouseLook_Disable then self:MouseLook_Disable() end
	if self.Reticle_SetShown  then self:Reticle_SetShown(false) end
	if self.Bindings_ClearAll then self:Bindings_ClearAll() end
	if self.Camera_Restore then self:Camera_Restore() end
	if not silent then self:Print(L["STATE_OFF"]) end
end

function A:Toggle()
	if CoACombatDB.enabled then self:Disable() else self:Enable() end
end

function A:Camera_OpenOptions()
	if self.CameraOptions_Open and self.Camera_Init then self:CameraOptions_Open()
	else self:Print(L.RESTART_REQUIRED) end
end

function A:Crosshair_OpenOptions()
	if self.CrosshairOptions_Open then self:CrosshairOptions_Open()
	else self:Print(L.RESTART_REQUIRED) end
end

function A:PauseOnce()
	if self.MouseLook_PauseOnce then self:MouseLook_PauseOnce() end
end

function A:ToggleReticle()
	CoACombatDB.reticleShown = not CoACombatDB.reticleShown
	if self.Reticle_SetShown then
		self:Reticle_SetShown(CoACombatDB.reticleShown and CoACombatDB.enabled)
	end
end

function A:ResetDefaults()
	if self:InCombat() then self:Print(L["ERR_COMBAT"]); return end
	self:Disable(true)
	CoACombatDB = deepcopy(self.defaults)
	CoACombatDBPC = {}
	self.db = setmetatable(CoACombatDBPC, { __index = CoACombatDB })
	CoACombatDBPC.presets = {}
	CoACombatDBPC.specPresets = {}
	self._presetTalentGroup = nil
	if self.MouseLook_Init then self:MouseLook_Init() end
	if self.Reticle_Resize then self:Reticle_Resize(CoACombatDB.reticleSize) end
	if self.Bindings_ApplyAll then self:Bindings_ApplyAll() end
	self:Print(L["DEFAULTS_RESTORED"])
end

-- ------------------------------------------------------------------
-- Slash command
-- ------------------------------------------------------------------
SLASH_COACOMBAT1 = "/coacombat"
SLASH_COACOMBAT2 = "/cac"

local function status()
	local db = CoACombatDB
	A:Print(db.enabled and L["STATE_ON"] or L["STATE_OFF"])
	A:Print(string.format(L["STATUS_LMB"], tostring(db.bindings.BUTTON1 or "-")))
	A:Print(string.format(L["STATUS_RMB"], tostring(db.bindings.BUTTON2 or "-")))
	A:Print(string.format(L["STATUS_MMB"], tostring(db.bindings.BUTTON3 or "-")))
	A:Print(string.format(L["STATUS_INTERACT"], tostring(db.interactKey or "-")))
	for k, v in pairs(db.bindings) do
		if k ~= "BUTTON1" and k ~= "BUTTON2" and k ~= "BUTTON3" and k ~= db.interactKey then
			A:Print(string.format(L["STATUS_EXTRA"], k, tostring(v)))
		end
	end
	if db.reticleShown then
		A:Print(string.format(L["STATUS_RETICLE_ON"], db.reticleSize))
	else
		A:Print(L["STATUS_RETICLE_OFF"])
	end
end

local function help()
	A:Print(L["HELP_HEADER"])
	for _, line in ipairs(L["HELP_LINES"]) do A:Print(line) end
end

local function words(s)
	local t = {}
	for w in string.gmatch(s or "", "%S+") do t[#t+1] = w end
	return t
end

SlashCmdList.COACOMBAT = function(msg)
	local args = words(msg)
	local cmd  = string.lower(args[1] or "")
	if cmd == "" then return status() end
	if cmd == "help" or cmd == "?" then return help() end
	if cmd == "on"     then return A:Enable() end
	if cmd == "off"    then return A:Disable() end
	if cmd == "toggle" then return A:Toggle() end
	if cmd == "pause"  then return A:PauseOnce() end
	if cmd == "reset"  then return A:ResetDefaults() end
	if cmd == "options" then return A:Options_Open() end
	if cmd == "preset" then return A:Presets_Command(args) end
	if cmd == "camera" then
		if A.Camera_Command then return A:Camera_Command(args) end
		return A:Print(L.RESTART_REQUIRED)
	end
	if cmd == "assist" then
		local sub = string.lower(args[2] or "")
		if sub == "on" or sub == "off" then
			CoACombatDB.softTargetEnabled = sub == "on"
		elseif sub == "radius" then
			local n = tonumber(args[3])
			if not n or n < 20 or n > 300 then A:Print(L.ERR_NO_ARG); return end
			CoACombatDB.softTargetRadius = n
		else A:Print(L.ASSIST_HELP); return end
		return
	end
	if cmd == "macros" then
		if A.Macros_Print then A:Macros_Print() end
		return
	end
	if cmd == "targeting" then
		local sub = string.lower(args[2] or "")
		if sub == "on" or sub == "off" then
			CoACombatDB.aimTargetEnabled = sub == "on"
			A:Bindings_ApplyAll()
		elseif sub == "debug" then
			A:Print("Last camera-lock aim: " .. tostring(A._aimName or "none") .. "; target: " .. tostring(A._aimTargetName or "none"))
			A:Print("Attack switching: " .. tostring(CoACombatDB.aimTargetEnabled) .. "; native cursor: " .. tostring(SetCursorPosition ~= nil) .. "; nearest interact: " .. tostring(InteractNearest ~= nil))
			A:Bindings_DebugKey(CoACombatDB.interactKey)
		else A:Print("/cac targeting on|off|debug") end
		return
	end
	if cmd == "reticle" then
		local sub = string.lower(args[2] or "")
		if sub == "show" then
			CoACombatDB.reticleShown = true
			if A.Reticle_SetShown then A:Reticle_SetShown(CoACombatDB.enabled) end
		elseif sub == "hide" then
			CoACombatDB.reticleShown = false
			if A.Reticle_SetShown then A:Reticle_SetShown(false) end
		elseif sub == "size" then
			local n = tonumber(args[3] or "")
			if n and n >= 4 and n <= 128 then
				CoACombatDB.reticleSize = n
				if A.Reticle_Resize then A:Reticle_Resize(n) end
			else
				A:Print(L["ERR_NO_ARG"])
			end
		elseif sub == "style" and A.reticleStyles[args[3] or ""] then
			A:Reticle_SetStyle(args[3])
		elseif sub == "opacity" then
			local n = tonumber(args[3] or "")
			if not n or n < 10 or n > 100 then A:Print(L["ERR_NO_ARG"]); return end
			CoACombatDB.reticleOpacity = n / 100
			A:Reticle_ApplyStyle()
		elseif sub == "color" and A.reticleColorLabels[args[3] or ""] then
			A:Reticle_SetColorMode(args[3])
		elseif sub == "options" then
			A:Crosshair_OpenOptions()
		else
			A:Print(L["ERR_NO_ARG"])
		end
		return
	end
	if cmd == "lmb" or cmd == "rmb" or cmd == "mmb" then
		local target = ({ lmb = "BUTTON1", rmb = "BUTTON2", mmb = "BUTTON3" })[cmd]
		local rest = table.concat(args, " ", 2)
		if rest == "" then
			CoACombatDB.bindings[target] = ""
		else
			CoACombatDB.bindings[target] = rest
		end
		A:Print(string.format(L["BOUND"], target, rest ~= "" and rest or "(cleared)"))
		if A.Bindings_ApplyAll then A:Bindings_ApplyAll() end
		return
	end
	if cmd == "interact" then
		local key = string.upper(args[2] or "")
		if key == "" then A:Print(L["ERR_NO_ARG"]); return end
		-- Remove old interact key from bindings, add the new one.
		if CoACombatDB.interactKey and CoACombatDB.bindings[CoACombatDB.interactKey] == "INTERACTMOUSEOVER" then
			CoACombatDB.bindings[CoACombatDB.interactKey] = ""
		end
		CoACombatDB.interactKey = key
		CoACombatDB.bindings[key] = "INTERACTMOUSEOVER"
		A:Print(string.format(L["BOUND"], key, "INTERACTMOUSEOVER"))
		if A.Bindings_ApplyAll then A:Bindings_ApplyAll() end
		return
	end
	if cmd == "bind" then
		local key = string.upper(args[2] or "")
		local rest = table.concat(args, " ", 3)
		if key == "" or rest == "" then A:Print(L["ERR_NO_ARG"]); return end
		CoACombatDB.bindings[key] = rest
		A:Print(string.format(L["BOUND"], key, rest))
		if A.Bindings_ApplyAll then A:Bindings_ApplyAll() end
		return
	end
	if cmd == "unbind" then
		local key = string.upper(args[2] or "")
		if key == "" then A:Print(L["ERR_NO_ARG"]); return end
		CoACombatDB.bindings[key] = ""
		A:Print(string.format(L["UNBOUND"], key))
		if A.Bindings_ApplyAll then A:Bindings_ApplyAll() end
		return
	end
	A:Print(L["ERR_UNKNOWN_CMD"])
end
