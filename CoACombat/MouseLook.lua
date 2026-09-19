-- MouseLook.lua
-- Persistent mouselook engine. Keeps the cursor centred (hidden) whenever
-- the world has focus and no blocker frame is up. Frees the cursor the
-- instant anything menu-y appears (bags, chat edit, quest log, static popup,
-- dead player, cinematic, ground-target spell arming).
--
-- MouselookStart/Stop are non-secure. That's why
-- we can drive them from OnUpdate without combat-lockdown hassles.

local A = CoACombat
local L = CoACombatLocale

A._paused = false                -- one-shot pause (until next press)
A._enabled = false               -- module-level enable

-- Build the release-frame set once, allowing user extensions.
local function buildBlockerList()
	local seen, list = {}, {}
	for _, name in ipairs(A.releaseFrames) do
		if not seen[name] then seen[name] = true; list[#list+1] = name end
	end
	if CoACombatDB and CoACombatDB.extraReleaseFrames then
		for _, name in ipairs(CoACombatDB.extraReleaseFrames) do
			if not seen[name] then seen[name] = true; list[#list+1] = name end
		end
	end
	return list
end

local blockerList

-- ------------------------------------------------------------------
-- Blocker detection
-- ------------------------------------------------------------------
local function isChatOpen()
	if GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() then return true end
	local edit = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow() or nil
	if edit and edit:IsShown() then return true end
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		edit = _G["ChatFrame" .. i .. "EditBox"]
		if edit and edit:HasFocus() then return true end
	end
	return false
end

local function isPopupOpen()
	do
		for i = 1, (STATICPOPUP_NUMDIALOGS or 4) do
			local dlg = _G["StaticPopup"..i]
			if dlg and dlg:IsShown() then return true end
		end
	end
	return false
end

local function isCinematic()
	local cf = _G["CinematicFrame"]
	local mf = _G["MovieFrame"]
	return (cf and cf:IsShown()) or (mf and mf:IsShown()) or false
end

local function isBlockerShown()
	blockerList = blockerList or buildBlockerList()
	for i = 1, #blockerList do
		local f = _G[blockerList[i]]
		if f and f.IsVisible and f:IsVisible() then return true, blockerList[i] end
	end
	return false
end

function A:ShouldReleaseMouselook()
	if A._paused then return true end
	if UnitIsDeadOrGhost("player") then return true end
	if isChatOpen() then return true end
	if isPopupOpen() then return true end
	if isCinematic() then return true end
	if SpellIsTargeting and SpellIsTargeting() then return true end
	if CursorHasItem and CursorHasItem() then return true end
	if CursorHasSpell and CursorHasSpell() then return true end
	local blocked = isBlockerShown()
	if blocked then return true end
	return false
end

-- ------------------------------------------------------------------
-- Engine
-- ------------------------------------------------------------------
local function tick()
	if not A._enabled then return end
	local shouldRelease = A:ShouldReleaseMouselook()
	local looking = IsMouselooking()
	if shouldRelease and looking then
		MouselookStop()
		if A.Reticle_SetShown then A:Reticle_SetShown(false) end
	elseif not shouldRelease and not looking then
		-- Only reclaim mouselook when the pointer is over the world frame
		-- (or nothing) so we don't fight action-bar clicks.
		local focus = GetMouseFocus and GetMouseFocus() or nil
		if focus == nil or focus == WorldFrame or focus == UIParent then
			-- Ascension's native API takes normalized client coordinates, not
			-- pixels. Centre once before capture; never warp on every update.
			if SetCursorPosition then SetCursorPosition(0.5, 0.5) end
			MouselookStart()
			if A.Reticle_SetShown and CoACombatDB.reticleShown then
				A:Reticle_SetShown(true)
			end
		end
	end
	if A.Reticle_SetShown then
		A:Reticle_SetShown(not shouldRelease and IsMouselooking())
	end
end

-- ------------------------------------------------------------------
-- Chat edit hooks - reclaim mouselook the moment chat closes.
-- ------------------------------------------------------------------
local function hookChat()
	if A._chatHooked then return end
	if ChatEdit_ActivateChat then
		hooksecurefunc("ChatEdit_ActivateChat", function()
			if IsMouselooking() then MouselookStop() end
			if A.Reticle_SetShown then A:Reticle_SetShown(false) end
		end)
	end
	A._chatHooked = true
end

-- ------------------------------------------------------------------
-- Public API (called by Core)
-- ------------------------------------------------------------------
function A:MouseLook_Init()
	blockerList = buildBlockerList()
	hookChat()
end

function A:MouseLook_Enable()
	A._paused = false
	A:UnregisterUpdate("mouselook_pause_watch")
	A._enabled = true
	A:RegisterUpdate("mouselook", tick)
	tick()
end

function A:MouseLook_Disable()
	A._enabled = false
	A._paused = false
	A:UnregisterUpdate("mouselook_pause_watch")
	A:UnregisterUpdate("mouselook")
	if IsMouselooking() then MouselookStop() end
end

-- One-shot release: leaves mouselook off until the player clicks or
-- otherwise interacts. Handy for using ground-target AoE at the crosshair.
function A:MouseLook_PauseOnce()
	if not A._enabled then return end
	A._paused = true
	if IsMouselooking() then MouselookStop() end
	if A.Reticle_SetShown then A:Reticle_SetShown(false) end
	-- Require a new world press and its release, so pause cannot consume
	-- the mouse press which invoked it or reclaim during a UI drag.
	local wasDown = IsMouseButtonDown(1) or IsMouseButtonDown(2)
	local clicked = false
	local pauseId = "mouselook_pause_watch"
	A:RegisterUpdate(pauseId, function(dt)
		local down = IsMouseButtonDown(1) or IsMouseButtonDown(2)
		local focus = GetMouseFocus and GetMouseFocus()
		if down and not wasDown and focus == WorldFrame then clicked = true end
		wasDown = down
		if not A._paused or (clicked and not down) then
			A._paused = false
			A:UnregisterUpdate(pauseId)
		end
	end)
end

-- Let other modules ask whether we're actively driving mouselook. Reticle
-- uses this to know when to show/hide.
function A:MouseLook_IsActive()
	return A._enabled and not A:ShouldReleaseMouselook() and IsMouselooking() and true or false
end
