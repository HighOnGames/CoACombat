local A = CoACombat
local L = CoACombatLocale
local panel, checks, inputs, size

function A:Options_Init()
	if panel or not InterfaceOptions_AddCategory then return end
	panel = CreateFrame("Frame", "CoACombatOptions", UIParent)
	panel.name = L.ADDON_NAME
	panel:Hide()
	checks, inputs = {}, {}
	local function label(text, x, y, template)
		local font = panel:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
		font:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
		font:SetText(text)
		return font
	end
	label(L.ADDON_NAME, 16, -16, "GameFontNormalLarge")
	local function check(key, text, y, change)
		local button = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
		button:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
		label(text, 50, y - 8)
		button:SetScript("OnClick", function(self) change(self:GetChecked() and true or false) end)
		checks[key] = button
	end
	check("enabled", L.OPT_ENABLED, -46, function(on) if on then A:Enable() else A:Disable() end end)
	check("reticleShown", L.OPT_RETICLE, -78, function(on)
		CoACombatDB.reticleShown = on
		A:Reticle_SetShown(CoACombatDB.enabled)
	end)
	check("softTargetEnabled", L.OPT_ASSIST, -110, function(on) CoACombatDB.softTargetEnabled = on end)
	local function input(key, text, y)
		label(text, 20, y - 5)
		local edit = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
		edit:SetPoint("TOPLEFT", panel, "TOPLEFT", 165, y)
		edit:SetSize(240, 24)
		-- Ascension skins Common-Input-Border with oversized grey end caps.
		-- Hide only the inherited border textures and draw a stable flat field;
		-- the EditBox font string and text cursor remain untouched.
		for _, region in ipairs({edit:GetRegions()}) do
			if region:GetObjectType() == "Texture" then region:Hide() end
		end
		local background = edit:CreateTexture(nil, "BACKGROUND")
		background:SetTexture(0.025, 0.025, 0.025, 0.92)
		background:SetAllPoints(edit)
		local borders = {}
		local function edge(width, height, point)
			local texture = edit:CreateTexture(nil, "ARTWORK")
			texture:SetTexture(0.28, 0.28, 0.28, 1)
			texture:SetSize(width, height)
			texture:SetPoint(point, edit, point, 0, 0)
			borders[#borders + 1] = texture
		end
		edge(240, 1, "TOP"); edge(240, 1, "BOTTOM")
		edge(1, 24, "LEFT"); edge(1, 24, "RIGHT")
		edit.coaBackground, edit.coaBorders = background, borders
		edit:SetAutoFocus(false)
		edit:SetMaxLetters(255)
		edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		inputs[key] = edit
		return edit
	end
	input("BUTTON1", L.OPT_LMB, -158)
	input("BUTTON2", L.OPT_RMB, -190)
	input("BUTTON3", L.OPT_MMB, -222)
	input("interactKey", L.OPT_INTERACT, -254)
	local function button(text, x, y, fn)
		local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		b:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
		b:SetSize(110, 24)
		b:SetText(text)
		b:SetScript("OnClick", fn)
	end
	button(L.CAMERA_SETTINGS, 295, -16, function() A:Camera_OpenOptions() end)
	button(L.CROSSHAIR_SETTINGS, 165, -16, function() A:Crosshair_OpenOptions() end)
	button(L.OPT_APPLY, 295, -286, function()
		for _, key in ipairs({"BUTTON1", "BUTTON2", "BUTTON3"}) do
			CoACombatDB.bindings[key] = string.match(inputs[key]:GetText(), "^%s*(.-)%s*$")
			inputs[key]:ClearFocus()
		end
		local key = string.upper(string.match(inputs.interactKey:GetText(), "^%s*(.-)%s*$"))
		if key ~= "" then SlashCmdList.COACOMBAT("interact " .. key) else A:Bindings_ApplyAll() end
		inputs.interactKey:ClearFocus()
	end)
	size = CreateFrame("Slider", "CoACombatSizeSlider", panel, "OptionsSliderTemplate")
	size:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -294)
	size:SetWidth(230)
	size:SetMinMaxValues(4, 128)
	size:SetValueStep(1)
	_G.CoACombatSizeSliderLow:SetText("4")
	_G.CoACombatSizeSliderHigh:SetText("128")
	size:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value + 0.5)
		CoACombatDB.reticleSize = value
		_G.CoACombatSizeSliderText:SetText(L.OPT_SIZE .. ": " .. value)
		A:Reticle_Resize(value)
	end)
	local preset = input("preset", L.OPT_PRESET, -350)
	button(L.OPT_SAVE, 165, -382, function() A:Presets_Command({"preset", "save", preset:GetText() ~= "" and preset:GetText() or nil}) end)
	button(L.OPT_LOAD, 295, -382, function() A:Presets_Command({"preset", "load", preset:GetText() ~= "" and preset:GetText() or nil}) end)
	local hint = label(L.OPT_HINT, 20, -423, "GameFontHighlightSmall")
	hint:SetWidth(400)
	hint:SetJustifyH("LEFT")
	panel:SetScript("OnShow", function()
		for key, box in pairs(checks) do box:SetChecked(CoACombatDB[key]) end
		for _, key in ipairs({"BUTTON1", "BUTTON2", "BUTTON3"}) do inputs[key]:SetText(CoACombatDB.bindings[key] or "") end
		inputs.interactKey:SetText(CoACombatDB.interactKey or "")
		preset:SetText(CoACombatDBPC.activePreset or "")
		size:SetValue(CoACombatDB.reticleSize)
	end)
	InterfaceOptions_AddCategory(panel)
end

function A:Options_Open()
	self:Options_Init()
	if panel and InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(panel)
		InterfaceOptionsFrame_OpenToCategory(panel)
	else self:Print(L.OPT_UNAVAILABLE) end
end
