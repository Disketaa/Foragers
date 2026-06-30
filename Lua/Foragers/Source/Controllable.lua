---@class Controllable
---@field parent Object|nil Reference to owning object, set by Object:addComponent
---@field keys { up: string, down: string, left: string, right: string }
---@field speed number Base movement speed in pixels per second
---@field mouseControl table|nil Mouse control config: { slowdownRadius: number }
local Controllable = {}
Controllable.__index = Controllable

-- Creates input control component.
-- @param data|nil - { keys: {up,down,left,right}, movementSpeed: number, mouseControl: {slowdownRadius} }
-- @return Controllable instance with configurable key bindings and optional mouse control
function Controllable.new(data)
	data = data or {}
	local instance = setmetatable({
		keys = data.keys or { up = "w", down = "s", left = "a", right = "d" },
		speed = data.movementSpeed or 64,
		mouseControl = data.mouseControl, -- { slowdownRadius: distance where character begins slowing down to cursor }
		type = "Controllable", -- Used by Main.lua to identify mouse-controllable entities
	}, Controllable)
	return instance
end

-- Sets the current mouse position in world coordinates.
-- Called from love.update before Controllable:update when mouse button is held.
---@param worldX number Mouse X in world coordinates
---@param worldY number Mouse Y in world coordinates
function Controllable:setMousePosition(worldX, worldY)
	self.mouseX = worldX
	self.mouseY = worldY
end

-- Calculates speed multiplier based on distance to mouse.
-- Returns 1.0 at slowdownRadius or greater, decreases linearly to 0.0 at distance 0.
-- Formula: speedMultiplier = distance / slowdownRadius (clamped 0-1)
local function calculateSpeedMultiplier(distance, slowdownRadius)
	if not slowdownRadius or slowdownRadius <= 0 then
		return 1.0
	end
	-- Clamp to 0-1 range: full speed at slowdownRadius, zero at distance 0
	return math.max(0, math.min(1, distance / slowdownRadius))
end

-- Updates parent position based on keyboard input and held mouse button.
-- Modifies parent.x/y directly; sets animator "Run"/"Idle" animation state.
-- Guard against missing parent/components to survive hot-reload edge cases.
-- Diagonal movement is normalized to prevent ~1.414x speed boost.
function Controllable:update(dt)
	if not self.parent or not self.parent.components then
		return
	end

	-- Check if mouse control should override keyboard
	-- Mouse has priority when button is held and character is stopped or moving toward cursor
	local keyboardInputX, keyboardInputY = 0, 0
	local keyboardActive = false
	if love.keyboard.isDown(self.keys.up) then
		keyboardInputY = keyboardInputY - 1
		keyboardActive = true
	end
	if love.keyboard.isDown(self.keys.down) then
		keyboardInputY = keyboardInputY + 1
		keyboardActive = true
	end
	if love.keyboard.isDown(self.keys.left) then
		keyboardInputX = keyboardInputX - 1
		keyboardActive = true
	end
	if love.keyboard.isDown(self.keys.right) then
		keyboardInputX = keyboardInputX + 1
		keyboardActive = true
	end

	-- Mouse control: follow held mouse button position
	-- Use mouse when button held, unless keyboard is actively providing input
	local mouseActive = self.mouseControl and self.mouseX and self.mouseY and not keyboardActive

	-- Accumulate input direction vector
	local inputX, inputY = keyboardInputX, keyboardInputY
	if mouseActive then
		local dx = self.mouseX - self.parent.x
		local dy = self.mouseY - self.parent.y
		local distance = math.sqrt(dx * dx + dy * dy)

		if distance > 1 then
			local moveAngle = math.atan2(dy, dx)
			inputX = math.cos(moveAngle)
			inputY = math.sin(moveAngle)
		end
	end

	-- Mouse control speed factor
	local effectiveSpeed = self.speed
	if mouseActive then
		local dx = self.mouseX - self.parent.x
		local dy = self.mouseY - self.parent.y
		local distance = math.sqrt(dx * dx + dy * dy)
		effectiveSpeed = self.speed * calculateSpeedMultiplier(distance, self.mouseControl.slowdownRadius)
	end

	-- Normalize diagonal movement to prevent ~1.414x speed boost
	local len = math.sqrt(inputX * inputX + inputY * inputY)
	local moveX, moveY = 0, 0
	if len > 0 then
		moveX, moveY = inputX / len, inputY / len
	end

	-- Apply movement
	if len > 0 then
		self.parent.y = self.parent.y + moveY * effectiveSpeed * dt
		self.parent.x = self.parent.x + moveX * effectiveSpeed * dt
	end

	-- Updates animator component
	for _, comp in ipairs(self.parent.components) do
		if comp.type == "animator" then
			-- Set animation based on movement
			if len > 0 then
				-- Handle horizontal flip based on movement direction
				-- For mouse control: use horizontal position relative to mouse for flip
				-- For keyboard control: use input direction for flip
				local shouldFlip = false
				if mouseActive then
					-- Mouse control: flip based on horizontal position relative to mouse
					shouldFlip = self.mouseX < self.parent.x
				else
					-- Keyboard control: flip based on input direction (moving left)
					shouldFlip = inputX < 0
				end

				-- Trigger flip tween only when direction actually changes
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
