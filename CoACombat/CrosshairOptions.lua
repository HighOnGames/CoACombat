local A = CoACombat
local L = CoACombatLocale
local panel, styleText, colorText, sizeSlider, opacitySlider
local preview, previewArt, previewArms

local function label(parent, text, x, y, template)
	local font = parent:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
	font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); font:SetText(text); return font
end

local function button(parent, text, x, y, w, fn)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); b:SetSize(w, 24); b:SetText(text); b:SetScript("OnClick", fn); return b
end

local function findIndex(list, value)
	for index, item in ipairs(list) do if item == value then return index end end
	return 1
end

local function previewColor()
	local r, g, b, alpha = A:Reticle_GetColor("friendly")
	for _, tex in ipairs(previewArms) do tex:SetVertexColor(r, g, b, alpha) end
	previewArt:SetVertexColor(r, g, b, alpha)
end

local function updatePreview()
	if not panel then return end
	local style = A.reticleStyles[CoACombatDB.reticleStyle] or A.reticleStyles.triangle
	styleText:SetText(style.label)
	colorText:SetText(A.reticleColorLabels[CoACombatDB.reticleColorMode] or A.reticleColorLabels.normal)
	local px = CoACombatDB.reticleSize
	previewArt:SetSize(px, px); previewArt:ClearAllPoints(); previewArt:SetPoint("CENTER", preview, "CENTER", 0, 0)
	local textured = style.texture ~= nil
	if textured then previewArt:SetTexture("Interface\\AddOns\\CoACombat\\Textures\\" .. style.texture); previewArt:Show() else previewArt:Hide() end
	local len, thick, offset = px / 4, math.max(1, px / 12), px * 3 / 8
	local dimensions = {{thick,len,0,offset},{thick,len,0,-offset},{len,thick,-offset,0},{len,thick,offset,0},{thick,thick,0,0}}
	for index, tex in ipairs(previewArms) do
		local d = dimensions[index]; tex:SetSize(d[1],d[2]); tex:ClearAllPoints(); tex:SetPoint("CENTER",preview,"CENTER",d[3],d[4])
		if textured or (style.dotOnly and index < 5) then tex:Hide() else tex:Show() end
	end
	previewColor()
end

local function cycleStyle(delta)
	local list = A.reticleStyleOrder
	local index = ((findIndex(list, CoACombatDB.reticleStyle) - 1 + delta) % #list) + 1
	A:Reticle_SetStyle(list[index]); updatePreview()
end

local function cycleColor(delta)
	local list = A.reticleColorOrder
	local index = ((findIndex(list, CoACombatDB.reticleColorMode) - 1 + delta) % #list) + 1
	A:Reticle_SetColorMode(list[index]); updatePreview()
end

function A:CrosshairOptions_Init()
	if panel or not InterfaceOptions_AddCategory then return end
	panel = CreateFrame("Frame", "CoACombatCrosshairOptions", UIParent)
	panel.name = L.CROSSHAIR_SETTINGS; panel.parent = L.ADDON_NAME; panel:Hide()
	label(panel, L.CROSSHAIR_SETTINGS, 16, -16, "GameFontNormalLarge")
	local hint = label(panel, L.CROSSHAIR_HINT, 20, -48, "GameFontHighlightSmall"); hint:SetWidth(390); hint:SetJustifyH("LEFT")

	label(panel, "Style", 20, -98)
	button(panel, "<", 20, -123, 36, function() cycleStyle(-1) end)
	styleText = label(panel, "", 76, -129, "GameFontHighlight")
	button(panel, ">", 250, -123, 36, function() cycleStyle(1) end)

	preview = CreateFrame("Frame", nil, panel); preview:SetPoint("TOPLEFT", panel, "TOPLEFT", 410, -70); preview:SetSize(128,128)
	previewArt = preview:CreateTexture(nil,"OVERLAY")
	previewArms = {}
	for index=1,5 do local tex=preview:CreateTexture(nil,"OVERLAY"); tex:SetTexture(1,1,1); previewArms[index]=tex end

	sizeSlider = CreateFrame("Slider", "CoACombatCrosshairScaleSlider", panel, "OptionsSliderTemplate")
	sizeSlider:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -188); sizeSlider:SetWidth(260)
	sizeSlider:SetMinMaxValues(4,128); sizeSlider:SetValueStep(1)
	_G.CoACombatCrosshairScaleSliderLow:SetText("4"); _G.CoACombatCrosshairScaleSliderHigh:SetText("128")
	sizeSlider:SetScript("OnValueChanged", function(self,value)
		value=math.floor(value+0.5); _G.CoACombatCrosshairScaleSliderText:SetText(L.OPT_SIZE .. ": " .. value)
		A:Reticle_Resize(value); updatePreview()
	end)

	opacitySlider = CreateFrame("Slider", "CoACombatCrosshairOpacitySlider", panel, "OptionsSliderTemplate")
	opacitySlider:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -252); opacitySlider:SetWidth(260)
	opacitySlider:SetMinMaxValues(10,100); opacitySlider:SetValueStep(5)
	_G.CoACombatCrosshairOpacitySliderLow:SetText("10%"); _G.CoACombatCrosshairOpacitySliderHigh:SetText("100%")
	opacitySlider:SetScript("OnValueChanged", function(self,value)
		value=math.floor(value/5+0.5)*5; CoACombatDB.reticleOpacity=value/100
		_G.CoACombatCrosshairOpacitySliderText:SetText(L.OPT_OPACITY .. ": " .. value .. "%")
		A:Reticle_ApplyStyle(); updatePreview()
	end)

	label(panel, L.OPT_COLOR_MODE, 20, -317)
	button(panel, "<", 20, -342, 36, function() cycleColor(-1) end)
	colorText = label(panel, "", 76, -348, "GameFontHighlight")
	button(panel, ">", 250, -342, 36, function() cycleColor(1) end)
	button(panel, "Reset appearance", 20, -402, 150, function()
		CoACombatDB.reticleStyle="triangle"; CoACombatDB.reticleSize=24
		CoACombatDB.reticleOpacity=1; CoACombatDB.reticleColorMode="normal"
		A:Reticle_Resize(24); sizeSlider:SetValue(24); opacitySlider:SetValue(100); updatePreview()
	end)
	panel:SetScript("OnShow", function()
		sizeSlider:SetValue(CoACombatDB.reticleSize); opacitySlider:SetValue((CoACombatDB.reticleOpacity or 1)*100); updatePreview()
	end)
	InterfaceOptions_AddCategory(panel)
end

function A:CrosshairOptions_Open()
	self:CrosshairOptions_Init()
	if panel and InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(panel); InterfaceOptionsFrame_OpenToCategory(panel)
	else self:Print(L.OPT_UNAVAILABLE) end
end
