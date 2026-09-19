local A = CoACombat
local L = CoACombatLocale

function A:Presets_Load(name, silent)
	local preset = CoACombatDBPC.presets[name]
	if not preset then self:Print(L.PRESET_MISSING); return false end
	CoACombatDB.bindings = A.CopyTable(preset.bindings)
	CoACombatDB.interactKey = preset.interactKey
	CoACombatDBPC.activePreset = name
	self:Bindings_ApplyAll()
	if not silent then self:Print(string.format(L.PRESET_LOADED, name)) end
	return true
end

function A:Presets_ApplySpec(force)
	if not CoACombatDBPC or not GetActiveTalentGroup then return end
	local group = GetActiveTalentGroup()
	if not force and group == self._presetTalentGroup then return end
	self._presetTalentGroup = group
	local name = CoACombatDBPC.specPresets[group]
	if name then self:Presets_Load(name, true) end
end

function A:Presets_Command(args)
	local command, name = string.lower(args[2] or ""), args[3]
	if name and string.find(name, "%s") then self:Print(L.PRESET_HELP); return end
	local presets = CoACombatDBPC.presets
	if command == "list" then
		local names = {}
		for n in pairs(presets) do names[#names + 1] = n end
		table.sort(names)
		self:Print(#names > 0 and table.concat(names, ", ") or L.PRESET_EMPTY)
	elseif command == "save" and name then
		presets[name] = { bindings = A.CopyTable(CoACombatDB.bindings), interactKey = CoACombatDB.interactKey }
		CoACombatDBPC.activePreset = name
		self:Print(string.format(L.PRESET_SAVED, name))
	elseif command == "load" and name then
		self:Presets_Load(name)
	elseif command == "delete" and name then
		presets[name] = nil
		if CoACombatDBPC.activePreset == name then CoACombatDBPC.activePreset = nil end
		for group, mapped in pairs(CoACombatDBPC.specPresets) do
			if mapped == name then CoACombatDBPC.specPresets[group] = nil end
		end
	elseif command == "spec" then
		local group, mapped = tonumber(name), args[4]
		if (group ~= 1 and group ~= 2) or not mapped then self:Print(L.PRESET_HELP); return end
		if mapped == "off" then CoACombatDBPC.specPresets[group] = nil
		elseif presets[mapped] then CoACombatDBPC.specPresets[group] = mapped
		else self:Print(L.PRESET_MISSING); return end
		if GetActiveTalentGroup and group == GetActiveTalentGroup() then self:Presets_ApplySpec(true) end
	else self:Print(L.PRESET_HELP) end
end
