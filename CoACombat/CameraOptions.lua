local A = CoACombat
local L = CoACombatLocale
local panel, selected = nil, "foot"

function A:CameraOptions_Init()
	if panel or not InterfaceOptions_AddCategory then return end
	panel = CreateFrame("Frame", "CoACombatCameraOptions", UIParent)
	panel.name, panel.parent = L.CAMERA_SETTINGS, L.ADDON_NAME
	panel:Hide()
	local checks, sliders = {}, {}
	local refreshing = false
	local function label(text, x, y, template)
		local f = panel:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
		f:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
		f:SetText(text)
		return f
	end
	label(L.CAMERA_SETTINGS, 16, -16, "GameFontNormalLarge")
	local function check(key, text, y, change)
		local b = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
		b:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
		label(text, 50, y - 8)
		b:SetScript("OnClick", function(self) change(self:GetChecked() and true or false) end)
		checks[key] = b
		return b
	end
	check("enabled", L.CAMERA_ENABLED, -46, function(on)
		CoACombatDB.camera.enabled = on; A:Camera_Refresh()
	end)
	local function slider(key, text, x, y, low, high, step, change)
		local name = "CoACombatCameraSlider" .. key
		local s = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
		s:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
		s:SetWidth(175)
		s:SetMinMaxValues(low, high)
		s:SetValueStep(step)
		_G[name .. "Low"]:SetText(tostring(low)); _G[name .. "High"]:SetText(tostring(high))
		s:SetScript("OnValueChanged", function(self, value)
			_G[name .. "Text"]:SetText(text .. ": " .. string.format("%.2f", value))
			if not refreshing then change(value) end
		end)
		sliders[key] = s
	end
	local function profileSlider(key, text, x, y, low, high)
		slider(key, text, x, y, low, high, 0.01, function(v) A:Camera_SetProfileValue(selected, key, v) end)
	end
	profileSlider("angle", L.CAMERA_ANGLE, 24, -143, 0, 6)
	profileSlider("distance", L.CAMERA_DISTANCE, 230, -143, 0.25, 2)
	profileSlider("height", L.CAMERA_HEIGHT, 24, -208, -1.25, 0.75)
	slider("transition", L.CAMERA_TRANSITION, 230, -208, 0, 3, 0.05, function(v)
		CoACombatDB.camera.transition = v; A:Camera_Refresh()
	end)
	for i, key in ipairs({"headbob", "enemy", "interact"}) do
		check(key, L["CAMERA_" .. string.upper(key)], -239 - (i - 1) * 30, function(on)
			A:Camera_SetProfileValue(selected, key, on)
		end)
	end
	check("travelForms", L.CAMERA_TRAVEL_FORMS, -329, function(on)
		CoACombatDB.camera.travelForms = on; A:Camera_Refresh()
	end)
	local recall = check("recall", L.CAMERA_RECALL, -359, function(on)
		if not A:Camera_SetProfileValue(selected, "recall", on) then checks.recall:SetChecked(false) end
	end)
	profileSlider("zoom", L.CAMERA_ZOOM, 230, -375, 0, 50)
	local hint = label("", 20, -421, "GameFontHighlightSmall")
	hint:SetWidth(390); hint:SetJustifyH("LEFT")
	local tabs = {}
	local function refresh()
		refreshing = true
		local settings = CoACombatDB.camera
		local profile = settings.profiles[selected]
		for key, s in pairs(sliders) do s:SetValue(key == "transition" and settings.transition or profile[key]) end
		for key, b in pairs(checks) do
			if key == "enabled" or key == "travelForms" then b:SetChecked(settings[key]) else b:SetChecked(profile[key]) end
		end
		for key, b in pairs(tabs) do b:SetText((key == selected and "|cff33ccff" or "|cffffffff") .. L["CAMERA_STATE_" .. string.upper(key)] .. "|r") end
		if A._cameraZoomSupported then recall:Enable(); sliders.zoom:Enable()
		else recall:Disable(); sliders.zoom:Disable() end
		hint:SetText(A._cameraSupported and L.CAMERA_HINT or L.CAMERA_UNSUPPORTED)
		refreshing = false
	end
	for i, key in ipairs({"foot", "mounted", "combat"}) do
		local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		b:SetPoint("TOPLEFT", panel, "TOPLEFT", 20 + (i - 1) * 135, -92)
		b:SetSize(120, 24)
		b:SetScript("OnClick", function() selected = key; refresh() end)
		tabs[key] = b
	end
	panel:SetScript("OnShow", refresh)
	InterfaceOptions_AddCategory(panel)
end

function A:CameraOptions_Open()
	self:CameraOptions_Init()
	if panel and InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(panel)
		InterfaceOptionsFrame_OpenToCategory(panel)
	else self:Print(L.OPT_UNAVAILABLE) end
end
