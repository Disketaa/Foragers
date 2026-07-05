---@class Control
---@field parent Sprite|nil Parent sprite reference
---@field keys { up: string, down: string, left: string, right: string }|nil
---@field speed number Base movement speed in pixels per second
---@field swimmingSpeed number|nil Movement speed in water
---@field mouseX number|nil Mouse X in world coordinates
---@field mouseY number|nil Mouse Y in world coordinates
---@field tags table<string, string>|nil Mapping of states to animation names
---@field _grounded boolean|nil Grounded state cached from grounded_changed event
---@field type "control"
local Control = {}
Control.__index = Control

local function calculateSpeedMultiplier(distance, slowdownRadius)
	if not slowdownRadius or slowdownRadius <= 0 then
		return 1.0
	end
	return math.max(0, math.min(1, distance / slowdownRadius))
end

function Control.new(data)
	data = data or {}
	local kc = data.keyboardControl
	local self = setmetatable({
		keys = kc and kc.keys,
		speed = data.movementSpeed or 50,
		swimmingSpeed = data.swimmingSpeed or 30,
		mouseControl = data.mouseControl,
		tags = data.tags,
		_grounded = nil,
		type = "control",
	}, Control)
	return self
end

function Control:attach()
	self.parent:on("grounded_changed", function(isGrounded)
		self._grounded = isGrounded
	end, 10)
end

function Control:setMousePosition(worldX, worldY)
	self.mouseX, self.mouseY = worldX, worldY
end

function Control:update(dt)
	if not self.parent or not self.parent.components then
		return
	end

	local keyboardInputX, keyboardInputY = 0, 0
	local keyboardActive = false
	if self.keys then
		if love.keyboard.isDown(self.keys.up) then
			keyboardInputY, keyboardActive = keyboardInputY - 1, true
		end
		if love.keyboard.isDown(self.keys.down) then
			keyboardInputY, keyboardActive = keyboardInputY + 1, true
		end
		if love.keyboard.isDown(self.keys.left) then
			keyboardInputX, keyboardActive = keyboardInputX - 1, true
		end
		if love.keyboard.isDown(self.keys.right) then
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
	if self._grounded == false then
		newState = "swimming"
	else
		newState = len > 0 and "moving" or "idle"
	end
	self.parent._state = newState
	if newState ~= oldState then
		self.parent:emit("state_changed", newState, oldState)
	end

	local oldFlip = self.parent.flipX
	---@type boolean|nil
	local newFlip
	if mouseActive then
		newFlip = self.mouseX < self.parent.x
	elseif inputX ~= 0 then
		newFlip = inputX < 0
	end
	if newFlip ~= nil and newFlip ~= oldFlip then
		self.parent.flipX = newFlip
		self.parent:emit("flipped", newFlip)
	end

	self.parent.animSpeedFactor = speedFactor
end

return Control
