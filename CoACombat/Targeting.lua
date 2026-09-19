-- Advisory only: nameplates do not expose a reliable unit token on 3.3.5.
-- TargetUnit(name) is protected and names cannot distinguish duplicate mobs.
local A = CoACombat
local L = CoACombatLocale
local previous, cue

local function nameplateName(plate)
	local border, name, hostile = false, nil, false
	for _, region in ipairs({plate:GetRegions()}) do
		local kind = region:GetObjectType()
		if kind == "Texture" then
			local path = region:GetTexture()
			if type(path) == "string" and string.find(string.lower(path), "nameplate%-border") then border = true end
		elseif kind == "FontString" then
			local text = region:GetText()
			if text and text ~= "" and not tonumber(text) and not name then name = text end
		end
	end
	if not border or not name then return end
	for _, child in ipairs({plate:GetChildren()}) do
		if child:GetObjectType() == "StatusBar" then
			local r, g, b = child:GetStatusBarColor()
			local value = child:GetValue()
			if value and value > 0 and r > 0.7 and g < 0.8 and b < 0.3 then hostile = true end
		end
	end
	if hostile then return name end
end

function A:Targeting_SoftTarget()
	if not CoACombatDB.softTargetEnabled or not self:MouseLook_IsActive() or UnitExists("mouseover") then
		previous = nil
		return
	end
	local cx, cy = UIParent:GetCenter()
	if not cx or not cy then previous = nil; return end
	local scale = UIParent:GetEffectiveScale()
	cx, cy = cx * scale, cy * scale
	local radius = CoACombatDB.softTargetRadius * scale
	local best, bestDistance, bestName
	for _, plate in ipairs({WorldFrame:GetChildren()}) do
		if plate:IsVisible() then
			local name = nameplateName(plate)
			if name then
				local x, y = plate:GetCenter()
				if x and y then
					local ps = plate:GetEffectiveScale()
					local d = (x * ps - cx)^2 + (y * ps - cy)^2
					-- Modest hysteresis without retaining a hidden/off-cone plate.
					local score = plate == previous and d * 0.8 or d
					if d <= radius^2 and (not bestDistance or score < bestDistance) then
						best, bestDistance, bestName = plate, score, name
					end
				end
			end
		end
	end
	previous = best
	return bestName
end

function A:Targeting_Init()
	if not cue then
		local frame = CreateFrame("Frame", "CoACombatAimCue", UIParent)
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, -32)
		frame:SetSize(300, 20)
		frame:EnableMouse(false)
		cue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		cue:SetAllPoints(frame)
	end
	self:RegisterUpdate("targeting", function()
		-- Keep the last camera-lock sample: typing a diagnostic command
		-- releases the cursor and can replace the current mouseover unit.
		if A:MouseLook_IsActive() then
			A._aimName = UnitName("mouseover")
			A._aimTargetName = UnitName("target")
		end
		local name = A:Targeting_SoftTarget()
		cue:SetText(name and string.format(L.AIM_CUE, name) or "")
	end)
end
