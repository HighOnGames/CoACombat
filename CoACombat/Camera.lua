-- Original Ascension camera controller. Uses the CVars registered by this
-- client's Extensions.dll, not retail's test_camera* CVars.
local A = CoACombat
local L = CoACombatLocale
local names = {
	"ActionCam", "cameraActionAngle", "cameraActionDist", "cameraActionZ",
	"cameraActionHeadBobs", "cameraTargetFocusEnemyEnable",
	"cameraTargetFocusInteractEnable", "cameraTargetFocusTurnSpeed",
}
local supported = {}
local transition, state, zoomCaptured, zoomStable = nil, nil, nil, 0
local travelForms = { [3] = true, [4] = true, [27] = true, [29] = true }

local function read(name)
	if not GetCVar then return end
	local ok, value = pcall(GetCVar, name)
	if ok and value ~= nil and value ~= "" then return tostring(value) end
end

local function same(a, b)
	if a == nil or b == nil then return false end
	local na, nb = tonumber(a), tonumber(b)
	if na and nb then return math.abs(na - nb) < 0.0001 end
	return tostring(a) == tostring(b)
end

local function write(name, value)
	if not supported[name] or not SetCVar then return end
	local current = read(name)
	if same(current, value) then return end
	CoACombatDB.cameraOriginal = CoACombatDB.cameraOriginal or {}
	CoACombatDB.cameraApplied = CoACombatDB.cameraApplied or {}
	if CoACombatDB.cameraOriginal[name] == nil then CoACombatDB.cameraOriginal[name] = current end
	local ok, result = pcall(SetCVar, name, value)
	if ok and result ~= false then CoACombatDB.cameraApplied[name] = read(name) or tostring(value) end
end

function A:Camera_Restore()
	transition, state, zoomCaptured, zoomStable = nil, nil, nil, 0
	if not CoACombatDB then return end
	local original, applied = CoACombatDB.cameraOriginal or {}, CoACombatDB.cameraApplied or {}
	for name, value in pairs(original) do
		-- Respect another addon/user changing a value since our last write.
		if same(read(name), applied[name]) and SetCVar then
			local ok, result = pcall(SetCVar, name, value)
			if ok and result ~= false then original[name], applied[name] = nil, nil end
		else original[name], applied[name] = nil, nil end
	end
	if not next(original) then CoACombatDB.cameraOriginal, CoACombatDB.cameraApplied = nil, nil end
	self._cameraZoomCapture = nil
end

function A:Camera_State()
	if IsMounted and IsMounted() then return "mounted" end
	if CoACombatDB.camera.travelForms and GetShapeshiftFormID and travelForms[GetShapeshiftFormID()] then return "mounted" end
	if UnitAffectingCombat and UnitAffectingCombat("player") or self:InCombat() then return "combat" end
	return "foot"
end

local function cameraZoom()
	if not GetCameraZoom then return end
	local ok, value = pcall(GetCameraZoom)
	if ok then return tonumber(value) end
end

local function setZoom(profile)
	local current = cameraZoom()
	if not profile.recall or not current or not CameraZoomIn or not CameraZoomOut then return end
	local delta = profile.zoom - current
	A._cameraZoomWriting = true
	if delta > 0.05 then pcall(CameraZoomOut, delta)
	elseif delta < -0.05 then pcall(CameraZoomIn, -delta) end
	A._cameraZoomWriting = nil
end

function A:Camera_Update(dt)
	if not CoACombatDB or self._cameraShuttingDown then return end
	if not CoACombatDB.enabled or not CoACombatDB.camera.enabled then
		if state or CoACombatDB.cameraOriginal then self:Camera_Restore() end
		return
	end
	if not self._cameraSupported then return end
	local nextState = self:Camera_State()
	local profile = CoACombatDB.camera.profiles[nextState]
	if nextState ~= state then
		state = nextState
		self._cameraZoomCapture = nil
		zoomCaptured, zoomStable = nil, 0
		transition = {
			time = 0, duration = CoACombatDB.camera.transition,
			from = { tonumber(read("cameraActionAngle")) or profile.angle,
				tonumber(read("cameraActionDist")) or profile.distance,
				tonumber(read("cameraActionZ")) or profile.height },
			to = { profile.angle, profile.distance, profile.height },
		}
		setZoom(profile)
	end
	write("ActionCam", 1)
	if transition then
		transition.time = math.min(transition.duration, transition.time + (dt or 0))
		local t = transition.duration <= 0 and 1 or transition.time / transition.duration
		t = t * t * (3 - 2 * t)
		for i, name in ipairs({"cameraActionAngle", "cameraActionDist", "cameraActionZ"}) do
			write(name, transition.from[i] + (transition.to[i] - transition.from[i]) * t)
		end
		if transition.time >= transition.duration then transition = nil end
	end
	-- Keep framing while browsing UI, but suspend automatic focus so it
	-- cannot move the camera while a targeting circle or menu is in use.
	local aiming = self:MouseLook_IsActive()
	write("cameraTargetFocusEnemyEnable", aiming and profile.enemy and 1 or 0)
	write("cameraTargetFocusInteractEnable", aiming and profile.interact and 1 or 0)
	write("cameraActionHeadBobs", profile.headbob and 1 or 0)
	if self._cameraZoomCapture and profile.recall then
		local zoom = cameraZoom()
		if zoom then
			if zoomCaptured and math.abs(zoom - zoomCaptured) < 0.01 then zoomStable = zoomStable + (dt or 0)
			else zoomCaptured, zoomStable = zoom, 0 end
			if zoomStable >= 0.25 then
				profile.zoom = math.max(0, math.min(50, zoom))
				self._cameraZoomCapture = nil
			end
		end
	end
end

function A:Camera_Init()
	if self._cameraInitialized then return end
	self._cameraInitialized = true
	for _, name in ipairs(names) do supported[name] = read(name) ~= nil end
	self._cameraSupported = supported.ActionCam and supported.cameraActionAngle and supported.cameraActionDist and supported.cameraActionZ
	self._cameraZoomSupported = cameraZoom() ~= nil and CameraZoomIn ~= nil and CameraZoomOut ~= nil
	-- Recover persisted originals after an interrupted logout or /reload.
	self:Camera_Restore()
	self:RegisterUpdate("camera", function(dt) A:Camera_Update(dt) end)
	if self._cameraZoomSupported and hooksecurefunc then
		for _, fn in ipairs({"CameraZoomIn", "CameraZoomOut"}) do
			hooksecurefunc(fn, function()
				if not A._cameraZoomWriting and state then
					A._cameraZoomCapture = true
					zoomCaptured, zoomStable = nil, 0
				end
			end)
		end
	end
end

function A:Camera_Shutdown()
	self._cameraShuttingDown = true
	self:Camera_Restore()
end

function A:Camera_Refresh()
	state = nil
	self:Camera_Update(0)
end

local ranges = { angle = {0, 6}, distance = {0.25, 2}, height = {-1.25, 0.75}, zoom = {0, 50} }
function A:Camera_SetProfileValue(name, key, value)
	local profile = CoACombatDB.camera.profiles[name]
	if not profile then return false end
	if ranges[key] then
		value = tonumber(value)
		if not value or value < ranges[key][1] or value > ranges[key][2] then return false end
	elseif key == "enemy" or key == "interact" or key == "headbob" or key == "recall" then
		if value ~= "on" and value ~= "off" and type(value) ~= "boolean" then return false end
		if key == "recall" and not self._cameraZoomSupported and (value == true or value == "on") then return false end
		value = value == true or value == "on"
	else return false end
	profile[key] = value
	self:Camera_Refresh()
	return true
end

function A:Camera_Command(args)
	local command = string.lower(args[2] or "")
	if command == "on" or command == "off" then
		CoACombatDB.camera.enabled = command == "on"
		if command == "on" and not self._cameraSupported then self:Print(L.CAMERA_UNSUPPORTED) end
		self:Camera_Refresh()
	elseif command == "options" then self:Camera_OpenOptions()
	elseif command == "rpg" then
		CoACombatDB.camera = A.CopyTable(A.defaults.camera)
		CoACombatDB.reticleStyle = "triangle"
		self:Reticle_Resize(CoACombatDB.reticleSize)
		self:Camera_Refresh()
		self:Print(L.CAMERA_RPG_READY)
	elseif command == "speed" then
		local value = tonumber(args[3])
		if not value or value < 0 or value > 3 then self:Print(L.CAMERA_HELP); return end
		CoACombatDB.camera.transition = value
		self:Camera_Refresh()
	elseif command == "profile" then
		if not self:Camera_SetProfileValue(args[3], args[4], args[5]) then self:Print(L.CAMERA_HELP) end
	elseif command == "" then
		self:Print(self._cameraSupported and string.format(L.CAMERA_STATUS, self:Camera_State()) or L.CAMERA_UNSUPPORTED)
	else self:Print(L.CAMERA_HELP) end
end
