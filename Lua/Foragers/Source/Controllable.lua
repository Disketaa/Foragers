---@class Controllable
---@field parent Object|nil Reference to owning object, set by Object:addComponent
---@field keys { up: string, down: string, left: string, right: string }
---@field speed number Movement speed in pixels per second

local Controllable = {}
Controllable.__index = Controllable

-- Creates input control component.
-- @param data|nil - { keys: {up,down,left,right}, movementSpeed: number }
-- @return Controllable instance with configurable key bindings
function Controllable.new(data)
	data = data or {}
	return setmetatable({
		keys = data.keys or { up = "w", down = "s", left = "a", right = "d" },
		speed = data.movementSpeed or 64,
	}, Controllable)
end

-- Updates parent position based on keyboard input.
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

	-- Normalize diagonal movement to prevent ~1.414x speed boost
	local len = math.sqrt(inputX * inputX + inputY * inputY)
	local moveX, moveY = 0, 0
	if len > 0 then
		moveX, moveY = inputX / len, inputY / len
	end

	-- Y movement applies after vertical input check; X movement couples with animator (original structure)
	if len > 0 then
		self.parent.y = self.parent.y + moveY * self.speed * dt
	end

	for _, comp in ipairs(self.parent.components) do
		if comp.type == "animator" then
			if len > 0 then
				self.parent.x = self.parent.x + moveX * self.speed * dt
			end
			-- flipX only updates on horizontal input (preserves last facing when moving vertically)
			if inputX ~= 0 then
				comp.flipX = inputX < 0
			end
			if len > 0 then
				comp:setAnimation("Run")
			else
				comp:setAnimation("Idle")
			end
			break
		end
	end
end

return Controllable
