-- Native mouselook overrides are inactive while the cursor is released.
-- No owner frame/getter exists: avoid other mouselook addons on the same keys.
local A = CoACombat
local L = CoACombatLocale
local installed = {}
local attacks = {}
-- Only interaction also applies outside mouselook. Use an owned temporary
-- override so releasing the cursor can still interact with a selected NPC.
local interactOwner = CreateFrame("Frame", "CoACombatInteractionBindings", UIParent)
local cursorBindings = {}

-- The macro executes through a hardware-clicked secure button, including in
-- combat. A live old target must not prevent selecting the new aimed enemy.
local function attackCommand(command)
	local slot = tonumber(string.match(command, "^ACTIONBUTTON(%d+)$"))
	if not slot or slot < 1 or slot > 12 or not CoACombatDB.aimTargetEnabled then return command end
	if not attacks[slot] then
		local button = CreateFrame("Button", "CoACombatAttack" .. slot, UIParent, "SecureActionButtonTemplate")
		button:RegisterForClicks("AnyUp")
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", "/target [@mouseover,harm,nodead]\n/targetenemy [noexists][dead]\n/click ActionButton" .. slot)
		attacks[slot] = button
	end
	return "CLICK CoACombatAttack" .. slot .. ":LeftButton"
end

function A:Bindings_ClearAll()
	if self:InCombat() then self._deferredApply = true; return end
	if SetMouselookOverrideBinding then
		for key in pairs(installed) do SetMouselookOverrideBinding(key, nil) end
	end
	if ClearOverrideBindings then ClearOverrideBindings(interactOwner) end
	installed = {}
	cursorBindings = {}
end

function A:Bindings_ApplyAll()
	if not CoACombatDB then return end
	if self:InCombat() then
		if not self._deferredApply then self:Print(L.ERR_COMBAT .. " (bindings deferred)") end
		self._deferredApply = true
		return
	end
	self._deferredApply = nil
	self:Bindings_ClearAll()
	if not CoACombatDB.enabled then return end
	if not SetMouselookOverrideBinding then
		self:Print(L.ERR_MOUSELOOK_API)
		self:Disable(true)
		return
	end
	for key, command in pairs(CoACombatDB.bindings) do
		if type(command) == "string" and command ~= "" then
			command = attackCommand(command)
			local button, mouse = string.match(command, "^CLICK%s+(%S+)%s+(%S+)$")
			if button then command = "CLICK " .. button .. ":" .. mouse end
			local ok, result = pcall(SetMouselookOverrideBinding, key, command)
			if ok and result ~= false then installed[key] = command
			else self:Print(string.format(L.BINDING_FAILED, key)) end
			if command == "INTERACTMOUSEOVER" or command == "INTERACTTARGET" then
				-- Dispatch the existing native hardware binding, whose secure
				-- handler invokes InteractUnit. /run InteractNearest() does not
				-- honor a selected quest giver and is unnecessary here.
				if SetOverrideBinding and ClearOverrideBindings then
					local bound, applied = pcall(SetOverrideBinding, interactOwner, true, key, command)
					if bound and applied ~= false then cursorBindings[key] = command
					else self:Print(string.format(L.BINDING_FAILED, key)) end
				end
			end
		end
	end
end

function A:Bindings_DebugKey(key)
	self:Print(("key %s -> %s (mouselook: %s)"):format(tostring(key),
		tostring(GetBindingAction(key, true) or "-"),
		tostring(installed[key] or "-")))
	self:Print("Cursor-released interaction: " .. tostring(cursorBindings[key] or "not installed"))
end
