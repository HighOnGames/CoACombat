-- Centre-screen reticle rendering, shape selection and accessible palettes.
-- Texture assets retain a fixed centre pivot; asymmetric art is never cropped
-- or re-centred around its visible pixels.

local A = CoACombat
local L = CoACombatLocale
local ARM_LEN, ARM_THICK, DOT_SIZE = 6, 2, 2
local reticle

A.reticleStyleOrder = {"triangle", "cross", "dot", "plus", "stacked", "diagonal", "curved", "tbar"}
A.reticleStyles = {
	triangle = { label = "Three bars", texture = "Triad.tga" },
	cross = { label = "Classic cross" }, dot = { label = "Small dot", dotOnly = true },
	plus = { label = "Plus", texture = "Plus.tga" },
	stacked = { label = "Stacked", texture = "Stacked.tga" },
	diagonal = { label = "Diagonal", texture = "Diagonal.tga" },
	curved = { label = "Curved", texture = "Curved.tga" },
	tbar = { label = "T-bar", texture = "TBar.tga" },
}
A.reticleColorOrder = {"normal", "redgreen", "blueyellow", "contrast", "mono"}
A.reticleColorLabels = {
	normal = "Default", redgreen = "Red-green safe", blueyellow = "Blue-yellow safe",
	contrast = "High contrast", mono = "Monochrome",
}

-- Okabe-Ito-derived alternatives plus two visibility-oriented choices.
local palettes = {
	redgreen = {
		none={1,0.78,0.10}, hostile={0.90,0.62,0}, friendly={0,0.45,0.70},
		interact={0,0.62,0.45}, dead={0.55,0.55,0.55},
	},
	blueyellow = {
		none={0.95,0.35,0.75}, hostile={0.84,0.37,0}, friendly={0.80,0.47,0.65},
		interact={0,0.62,0.45}, dead={0.55,0.55,0.55},
	},
	contrast = {
		none={0,1,1}, hostile={1,0.82,0}, friendly={0,0.85,1},
		interact={1,0.25,0.85}, dead={0.45,0.45,0.45},
	},
	mono = {
		none={0.72,0.72,0.72}, hostile={1,1,1}, friendly={0.72,0.72,0.72},
		interact={0.9,0.9,0.9}, dead={0.4,0.4,0.4},
	},
}
local normalKeys = {
	none="reticleColorNone", hostile="reticleColorHostile", friendly="reticleColorFriendly",
	interact="reticleColorInteract", dead="reticleColorDead",
}

local function texturePath(filename)
	return "Interface\\AddOns\\CoACombat\\Textures\\" .. filename
end

function A:Reticle_GetColor(state)
	state = state or "none"
	local normal = CoACombatDB[normalKeys[state]] or CoACombatDB.reticleColorNone
	local selected = palettes[CoACombatDB.reticleColorMode or "normal"]
	local rgb = selected and selected[state] or normal
	local alpha = (normal[4] or 1) * (CoACombatDB.reticleOpacity or 1)
	return rgb[1], rgb[2], rgb[3], alpha
end

local function ensureReticle()
	if reticle then return reticle end
	local r = CreateFrame("Frame", "CoACombatReticle", UIParent)
	r:SetFrameStrata("HIGH"); r:SetFrameLevel(20)
	r:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	r:SetSize(CoACombatDB.reticleSize or 24, CoACombatDB.reticleSize or 24)
	r:EnableMouse(false)
	r.art = r:CreateTexture(nil, "OVERLAY"); r.art:SetAllPoints(r)
	r.triad = r.art -- compatibility alias
	local function arm(w, h, ox, oy)
		local tex = r:CreateTexture(nil, "OVERLAY")
		tex:SetTexture(1, 1, 1); tex:SetSize(w, h); tex:SetPoint("CENTER", r, "CENTER", ox, oy)
		return tex
	end
	r.armT = arm(ARM_THICK, ARM_LEN, 0, ARM_LEN)
	r.armB = arm(ARM_THICK, ARM_LEN, 0, -ARM_LEN)
	r.armL = arm(ARM_LEN, ARM_THICK, -ARM_LEN, 0)
	r.armR = arm(ARM_LEN, ARM_THICK, ARM_LEN, 0)
	r.dot = arm(DOT_SIZE, DOT_SIZE, 0, 0)
	r:Hide(); reticle = r
	return r
end

local function stateAtMouseover()
	if not UnitExists("mouseover") then return "none" end
	if UnitIsDeadOrGhost("mouseover") then return "dead" end
	if UnitCanAttack("player", "mouseover") then return "hostile" end
	if not UnitIsPlayer("mouseover") and UnitReaction("player", "mouseover") and UnitReaction("player", "mouseover") >= 5 then return "interact" end
	return "friendly"
end

local function paint(state)
	if not reticle then return end
	local r, g, b, alpha = A:Reticle_GetColor(state)
	for _, tex in ipairs({reticle.armT, reticle.armB, reticle.armL, reticle.armR, reticle.dot, reticle.art}) do tex:SetVertexColor(r, g, b, alpha) end
end

local function tick()
	if not reticle then return end
	A:Reticle_SetShown(CoACombatDB.enabled)
	if reticle:IsShown() then paint(stateAtMouseover()) end
end

function A:Reticle_ApplyStyle()
	ensureReticle()
	local style = A.reticleStyles[CoACombatDB.reticleStyle] and CoACombatDB.reticleStyle or "triangle"
	CoACombatDB.reticleStyle = style
	local definition = A.reticleStyles[style]
	local textured, loaded = definition.texture ~= nil, false
	if textured then
		local result = reticle.art:SetTexture(texturePath(definition.texture))
		loaded = result ~= false and reticle.art:GetTexture() ~= nil
	end
	if textured and not loaded and not A._textureWarned then A._textureWarned = true; A:Print(L.RETICLE_RESTART) end
	if textured and loaded then reticle.art:Show() else reticle.art:Hide() end
	for _, tex in ipairs({reticle.armT, reticle.armB, reticle.armL, reticle.armR}) do
		if (textured and loaded) or definition.dotOnly then tex:Hide() else tex:Show() end
	end
	if textured and loaded then reticle.dot:Hide() else reticle.dot:Show() end
	paint(stateAtMouseover())
end

function A:Reticle_Init()
	ensureReticle(); self:Reticle_Resize(CoACombatDB.reticleSize); A:RegisterUpdate("reticle", tick)
end

function A:Reticle_SetShown(show)
	ensureReticle()
	if show and CoACombatDB.reticleShown and A:MouseLook_IsActive() then reticle:Show() else reticle:Hide() end
end

function A:Reticle_Resize(px)
	ensureReticle()
	px = math.max(4, math.min(128, tonumber(px) or 24)); CoACombatDB.reticleSize = px
	reticle:SetSize(px, px)
	local len, thick, offset = px / 4, math.max(1, px / 12), px * 3 / 8
	local function resize(tex, w, h, x, y)
		tex:SetSize(w, h); tex:ClearAllPoints(); tex:SetPoint("CENTER", reticle, "CENTER", x, y)
	end
	resize(reticle.armT, thick, len, 0, offset); resize(reticle.armB, thick, len, 0, -offset)
	resize(reticle.armL, len, thick, -offset, 0); resize(reticle.armR, len, thick, offset, 0)
	resize(reticle.dot, thick, thick, 0, 0); self:Reticle_ApplyStyle()
end

function A:Reticle_SetStyle(style)
	if not self.reticleStyles[style] then return false end
	CoACombatDB.reticleStyle = style; self:Reticle_ApplyStyle(); return true
end

function A:Reticle_SetColorMode(mode)
	if not self.reticleColorLabels[mode] then return false end
	CoACombatDB.reticleColorMode = mode; paint(stateAtMouseover()); return true
end
