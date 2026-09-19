-- Macros.lua
-- Prints reticle-cast macro templates. This is the "just tell me how to
-- wire my spells to the reticle" convenience. On 3.3.5a there is no
-- reliable way to inject a spell's own targeting logic - the user has
-- to author a macro. We give them the canonical shapes.

local A = CoACombat
local L = CoACombatLocale

local function print(msg) A:Print(msg) end

function A:Macros_Print()
	print(L["MACRO_HEADER"])
	print(L["MACRO_DAMAGE"])
	print(L["MACRO_HEAL"])
	print(L["MACRO_AOE"])
	print(L["MACRO_INTERACT"])
	print("Drop the macro onto the action bar slot you bound as LMB/RMB.")
	print("Replace |cff88ccffSpellName|r with the spell name shown in your spellbook.")
end
