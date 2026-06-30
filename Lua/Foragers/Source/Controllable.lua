---@class Controllable
---@field parent Object|nil Reference to owning object, set by Object:addComponent
---@field keys { up: string, down: string, left: string, right: string }
---@field speed number Movement speed in pixels per second
---@field mouseControl table|nil Mouse control config: { deadzone: number, speedFactor: number }
local Controllable = {}
Controllable.__index = Controllable

-- Creates input control component.
-- @param data|nil - { keys: {up,down,left,right}, movementSpeed: number, mouseControl: {deadzone, speedFactor} }
-- @return Controllable instance with configurable key bindings and optional mouse control
function Controllable.new(data)
	data = data or {}
	local instance = setmetatable({
		keys = data.keys or { up = "w", down = "s", left = "a", right = "d" },
		speed = data.movementSpeed or 64,
		mouseControl = data.mouseControl, -- { deadzone: number, speedFactor: number }
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

-- Calculates speed multiplier based on distance to target.
-- Returns 1.0 when far, decreases to speedFactor when within deadzone.
local function calculateSpeedMultiplier(distance, deadzone, speedFactor)
	if not deadzone or deadzone <= 0 then
		return 1.0
	end
	if not speedFactor or speedFactor >= 1 then
		return 1.0
	end
	if distance >= deadzone then
		return 1.0
	end
	-- Linear interpolation from speedFactor (at 0) to 1.0 (at deadzone)
	return speedFactor + (1.0 - speedFactor) * (distance / deadzone)
end

-- Updates parent position based on keyboard input and held mouse button.
-- Modifies parent.x/y directly; sets animator "Run"/"Idle" animation state.
-- Guard against missing parent/components to survive hot-reload edge cases.
-- Diagonal movement is normalized to prevent ~1.414x speed boost.
function Controllable:update(dt)
	if not self.parent or not self.parent.components then
		return
	end

	-- Accumulate input direction vector
	local inputX, inputY = 0, 0
	if love.keyboard.isDown(self.keys.up) then
		inputY = inputY - 1
	end
	if love.keyboard.isDown(self.keys.down) then
		inputY = inputY + 1
	end
	if love.keyboard.isDown(self.keys.left) then
		inputX = inputX - 1
	end
	if love.keyboard.isDown(self.keys.right) then
		inputX = inputX + 1
	end

	-- Mouse control: follow held mouse button position
	local effectiveSpeed = self.speed
	if self.mouseControl and self.mouseX and self.mouseY then
		local dx = self.mouseX - self.parent.x
		local dy = self.mouseY - self.parent.y
		local distance = math.sqrt(dx * dx + dy * dy)

		if distance > 1 then
			local moveAngle = math.atan2(dy, dx)
			inputX = math.cos(moveAngle)
			inputY = math.sin(moveAngle)

			-- Apply speed factor based on distance to target (slows down near cursor)
			effectiveSpeed = self.speed * calculateSpeedMultiplier(distance, self.mouseControl.deadzone, self.mouseControl.speedFactor)
		end
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
			-- Handle horizontal flip based on movement direction
			-- For mouse control: use horizontal position relative to mouse for flip
			-- For keyboard control: use input direction for flip
			local shouldFlip = false
			if self.mouseControl and self.mouseX and self.mouseY then
				-- Mouse control: flip based on horizontal position relative to mouse
				shouldFlip = self.mouseX < self.parent.x
			else
				-- Keyboard control: flip based on input direction (moving left)
				shouldFlip = inputX < 0
			end

			-- Update flipX when:
			-- - moving (keyboard or mouse)
			-- - mouse control active but not moving (mouse near character, but still facing direction matters)
			if len > 0 or (self.mouseControl and self.mouseX and self.mouseY) then
				-- Trigger flip tween only when direction actually changes
				if comp.flipX ~= shouldFlip then
					comp.flipX = shouldFlip
					if comp.OnFlip then
						comp:OnFlip()
					end
				end
			end

			-- Set animation based on movement
			if len > 0 then
				comp:setAnimation("run")
			else
				comp:setAnimation("idle")
			end
			break
		end
	end
end

return Controllable