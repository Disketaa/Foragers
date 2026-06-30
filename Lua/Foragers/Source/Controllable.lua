local Controllable = {}
Controllable.__index = Controllable

function Controllable.new(data)
	data = data or {}
	return setmetatable({
		keys = data.keys or { up = "w", down = "s", left = "a", right = "d" },
		speed = data.movementSpeed or 64,
	}, Controllable)
end

function Controllable:update(dt)
	if not self.parent then
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
			if moving then
				comp:setAnimation("Run")
			else
				comp:setAnimation("Idle")
			end
			break
		end
	end
end

return Controllable
