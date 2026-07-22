local Events = require("Source.Helpers.Events")
local Options = require("Content.Data.Options")

---@class Control
---@field parent Sprite|nil Parent sprite reference
---@field keys table<string, { keyboard: string[]?, gamepad: { buttons: string[]?, axes: table[]? }? }>|nil
---@field speed number Base movement speed in pixels per second
---@field swimmingSpeed number|nil Movement speed in water
---@field mouseX number|nil Mouse X in world coordinates
---@field mouseY number|nil Mouse Y in world coordinates
---@field tags table<string, string>|nil Mapping of states to animation names
---@field _grounded boolean|nil Grounded state cached from grounded_changed event
---@field _slowdown number Speed multiplier from collision zones (1 = normal)
---@field type "control"
local Control = {}
Control.__index = Control

local function calculateSpeedMultiplier(distance, slowdownRadius)
	if not slowdownRadius or slowdownRadius <= 0 then
		return 1
	end
	return math.max(0, math.min(1, distance / slowdownRadius))
end

--- Normalize legacy string-format keys to the multi-input table format.
--- Old: { up = "w" } → New: { up = { keyboard = { "w" } } }
---@param keys table<string, string|table>|nil
---@return table<string, table>|nil
local function normalizeKeys(keys)
	if not keys then
		return nil
	end
	local normalized = {}
	for direction, value in pairs(keys) do
		if type(value) == "string" then
			normalized[direction] = { keyboard = { value } }
		else
			normalized[direction] = value
		end
	end
	return normalized
end

--- Check if any keyboard key in the array is held down.
---@param kbKeys string[]
---@return boolean
local function isKeyboardDown(kbKeys)
	return #kbKeys > 0 and love.keyboard.isDown(unpack(kbKeys))
end

--- Check if any gamepad button in the array is held down on the joystick.
---@param joystick love.Joystick
---@param btnKeys string[]
---@return boolean
local function isGamepadButtonDown(joystick, btnKeys)
	return #btnKeys > 0 and joystick:isGamepadDown(unpack(btnKeys))
end

--- Check if any gamepad axis in the array exceeds the deadzone in the given direction.
---@param joystick love.Joystick
---@param axes { [1]: string, [2]: number }[]
---@return boolean
local function isGamepadAxisActive(joystick, axes)
	for _, entry in ipairs(axes) do
		local axis, sign = entry[1], entry[2]
		if sign > 0 then
			if joystick:getGamepadAxis(axis) > Options.gamepadDeadzone then
				return true
			end
		else
			if joystick:getGamepadAxis(axis) < -Options.gamepadDeadzone then
				return true
			end
		end
	end
	return false
end

function Control.new(data)
	data = data or {}
	local kc = data.keyboardControl
	local rawKeys = (kc and kc.keys) or Options.keybinds
	local self = setmetatable({
		keys = normalizeKeys(rawKeys),
		speed = data.movementSpeed or 50,
		swimmingSpeed = data.swimmingSpeed or 30,
		mouseControl = data.mouseControl or { slowdownRadius = Options.mouseSlowdownRadius },
		tags = data.tags,
		_grounded = nil,
		_groundedInitialized = false,
		_slowdown = 1,
		type = "control",
	}, Control)
	return self
end

function Control:attach()
	self.parent:on(Events.GROUNDED_CHANGED, function(isGrounded)
		self._grounded = isGrounded
		self._groundedInitialized = true
	end, 10)
	self.parent:on(Events.SLOWDOWN_CHANGED, function(multiplier)
		self._slowdown = multiplier
	end, 10)
end

function Control:setMousePosition(worldX, worldY)
	self.mouseX, self.mouseY = worldX, worldY
end

--- Check if a direction is active via keyboard or gamepad.
---@param binding table { keyboard, gamepad }
---@return boolean
function Control:isDirectionActive(binding)
	if binding.keyboard and isKeyboardDown(binding.keyboard) then
		return true
	end
	local gp = binding.gamepad
	if gp then
		local joysticks = love.joystick.getJoysticks()
		for _, joystick in ipairs(joysticks) do
			if joystick:isGamepad() then
				if gp.buttons and isGamepadButtonDown(joystick, gp.buttons) then
					return true
				end
				if gp.axes and isGamepadAxisActive(joystick, gp.axes) then
					return true
				end
			end
		end
	end
	return false
end

function Control:update(dt)
	if not self.parent or not self.parent.components then
		return
	end

	local keyboardInputX, keyboardInputY = 0, 0
	local keyboardActive = false
	if self.keys then
		if self:isDirectionActive(self.keys.up) then
			keyboardInputY, keyboardActive = keyboardInputY - 1, true
		end
		if self:isDirectionActive(self.keys.down) then
			keyboardInputY, keyboardActive = keyboardInputY + 1, true
		end
		if self:isDirectionActive(self.keys.left) then
			keyboardInputX, keyboardActive = keyboardInputX - 1, true
		end
		if self:isDirectionActive(self.keys.right) then
			keyboardInputX, keyboardActive = keyboardInputX + 1, true
		end
	end

	local mouseActive = self.mouseControl and self.mouseX and self.mouseY and not keyboardActive
	local inputX, inputY = keyboardInputX, keyboardInputY

	local dx, dy, distance
	if mouseActive then
		dx = self.mouseX - self.parent.x
		dy = self.mouseY - self.parent.y
		distance = math.sqrt(dx * dx + dy * dy)
		if distance > 1 then
			local moveAngle = math.atan2(dy, dx)
			inputX, inputY = math.cos(moveAngle), math.sin(moveAngle)
		end
	end

	local effectiveSpeed = self.speed
	if self._grounded ~= nil and self._grounded == false and self.swimmingSpeed then
		effectiveSpeed = self.swimmingSpeed
	end
	effectiveSpeed = effectiveSpeed * self._slowdown
	local speedFactor = 1
	if mouseActive and self.mouseControl then
		speedFactor = calculateSpeedMultiplier(distance, self.mouseControl.slowdownRadius)
		effectiveSpeed = effectiveSpeed * speedFactor
	end

	local len = math.sqrt(inputX * inputX + inputY * inputY)
	local moveX, moveY = 0, 0
	if len > 0 then
		moveX, moveY = inputX / len, inputY / len
	end

	if len > 0 then
		self.parent.y = self.parent.y + moveY * effectiveSpeed * dt
		self.parent.x = self.parent.x + moveX * effectiveSpeed * dt
	end

	local oldState = self.parent._state
	local newState
	if self._groundedInitialized and self._grounded == false then
		newState = len > 0 and "swim" or "float"
	else
		newState = len > 0 and "run" or "idle"
	end
	self.parent._state = newState
	if newState ~= oldState then
		self.parent:emit(Events.STATE_CHANGED, newState, oldState)
	end

	local newFlip ---@type boolean|nil
	if mouseActive then
		newFlip = self.mouseX < self.parent.x
	elseif inputX ~= 0 then
		newFlip = inputX < 0
	end
	if newFlip ~= nil and newFlip ~= self.parent.flipX then
		self.parent.flipX = newFlip
		self.parent:emit(Events.FLIPPED, newFlip)
	end

	self.parent.animSpeedFactor = speedFactor * self._slowdown
end

return Control