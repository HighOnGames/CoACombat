-- Bindings.lua installs the existing native INTERACTMOUSEOVER handler both
-- while mouselooking and with a free cursor: mouseover, then selected target.
-- No interaction is ever invoked by an update or slash-command callback.
local A = CoACombat

function A:Interact_Init()
	-- No runtime initialization is needed for the native binding.
end

function A:Interact()
	self:Print(string.format(CoACombatLocale.INTERACT_HINT, CoACombatDB.interactKey))
end
