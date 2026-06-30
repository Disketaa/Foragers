---@class Controllable
---@field parent Sprite|nil Parent sprite reference
---@field keys { up: string, down: string, left: string, right: string }
---@field speed number Base movement speed in pixels per second
---@field mouseX number|nil Mouse X in world coordinates
---@field mouseY number|nil Mouse Y in world coordinates
---@field type "Controllable"
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
	return setmetatable({
		keys = data.keys or { up = "w", down = "s", left = "a", right = "d" },
		speed = data.movementSpeed or 64,
		mouseControl = data.mouseControl,
		type = "Controllable",
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

	local mouseActive = self.mouseControl and self.mouseX and self.mouseY and not keyboardActive
	local inputX, inputY = keyboardInputX, keyboardInputY

	if mouseActive then
		local dx = self.mouseX - self.parent.x
		local dy = self.mouseY - self.parent.y
		local distance = math.sqrt(dx * dx + dy * dy)
		if distance > 1 then
			local moveAngle = math.atan2(dy, dx)
			inputX, inputY = math.cos(moveAngle), math.sin(moveAngle)
		end
	end

	local effectiveSpeed = self.speed
	if mouseActive then
		local dx = self.mouseX - self.parent.x
		local dy = self.mouseY - self.parent.y
		local distance = math.sqrt(dx * dx + dy * dy)
		effectiveSpeed = self.speed * calculateSpeedMultiplier(distance, self.mouseControl.slowdownRadius)
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

	for _, comp in ipairs(self.parent.components) do
		if comp.type == "Animatable" then
			if len > 0 then
				local shouldFlip = mouseActive and (self.mouseX < self.parent.x) or (not mouseActive and inputX < 0)
				if comp.flipX ~= shouldFlip then
					comp.flipX = shouldFlip
					if comp.OnFlip then
						comp:OnFlip()
					end
				end
				comp:setAnimation("run")
			else
				comp:setAnimation("idle")
			end
			break
		end
	end
end

return Controllable
