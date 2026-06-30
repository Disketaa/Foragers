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
function Controllable:update(dt)
	if not self.parent or not self.parent.components then
		return
	end

	local moving = false
	if love.keyboard.isDown(self.keys.up) then
		self.parent.y = self.parent.y - self.speed * dt
		moving = true
	end
	if love.keyboard.isDown(self.keys.down) then
		self.parent.y = self.parent.y + self.speed * dt
		moving = true
	end

	for _, comp in ipairs(self.parent.components) do
		if comp.type == "animator" then
			if love.keyboard.isDown(self.keys.left) then
				self.parent.x = self.parent.x - self.speed * dt
				comp.flipX = true
				moving = true
			end
			if love.keyboard.isDown(self.keys.right) then
				self.parent.x = self.parent.x + self.speed * dt
				comp.flipX = false
				moving = true
			end
			comp:setAnimation(moving and "Run" or "Idle")
			break
		end
	end
end

return Controllable
