---@class Controllable
---@field parent Sprite|nil Parent sprite reference
---@field keys { up: string, down: string, left: string, right: string }|nil
---@field speed number Base movement speed in pixels per second
---@field mouseX number|nil Mouse X in world coordinates
---@field mouseY number|nil Mouse Y in world coordinates
---@field tags table<string, string>|nil Mapping of states to animation names
---@field type "controllable"
local Controllable = {}
Controllable.__index = Controllable

local function calculateSpeedMultiplier(distance, slowdownRadius)
	if not slowdownRadius or slowdownRadius <= 0 then
		return 1.0
	end
	return math.max(0, math.min(1, distance / slowdownRadius))
end

function Controllable.new(data)
	data = data or {}
	local kc = data.keyboardControl
	return setmetatable({
		keys = kc and kc.keys,
		speed = data.movementSpeed or 64,
		mouseControl = data.mouseControl,
		tags = data.tags,
		type = "controllable",
	}, Controllable)
end

function Controllable:setMousePosition(worldX, worldY)
	self.mouseX, self.mouseY = worldX, worldY
end

function Controllable:update(dt)
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
	local speedFactor = 1
	if mouseActive and self.mouseControl then
		speedFactor = calculateSpeedMultiplier(distance, self.mouseControl.slowdownRadius)
		effectiveSpeed = self.speed * speedFactor
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

	self.parent._state = len > 0 and "moving" or "idle"
	if mouseActive then
		self.parent.flipX = self.mouseX < self.parent.x
	elseif len > 0 then
		self.parent.flipX = inputX < 0
	end
	self.parent.animSpeedFactor = speedFactor
	if len > 0 and self.parent._debugState ~= "moving" then
		print("Moving state set")
		self.parent._debugState = "moving"
	elseif len == 0 and self.parent._debugState ~= "idle" then
		print("Idle state set")
		self.parent._debugState = "idle"
	end
end
return Controllable
