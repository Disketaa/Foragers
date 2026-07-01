---@class Sprite
---@field x number World X position
---@field y number World Y position
---@field frameWidth number|nil Sprite width in pixels for static sprites
---@field frameHeight number|nil Sprite height in pixels for static sprites
---@field pivotX number|nil Normalized X origin (0-1)
---@field pivotY number|nil Normalized Y origin (0-1)
---@field image love.Image|nil Image for StaticSprite mode
---@field type string|nil "StaticSprite" for auto-generated sprites
---@field components table<object> Component instances
---@field _state string|nil Current sprite state ("moving", "idle", etc)
---@field flipX boolean|nil Horizontal flip state
---@field tweens table<string, Tween>|nil Runtime tweens on sprite
---@field animSpeedFactor number Animation speed multiplier (used by Animatable)
local Sprite = {}
Sprite.__index = Sprite

---@param x number|nil
---@param y number|nil
---@return Sprite
function Sprite.new(x, y)
	return setmetatable({
		x = x or 0,
		y = y or 0,
		components = {},
		tweens = {},
		animSpeedFactor = 1,
	}, Sprite)
end

---@param target string
---@param from number
---@param to number
---@param duration number
---@param curve function
function Sprite:triggerTween(target, from, to, duration, curve)
	for _, comp in ipairs(self.components) do
		if comp.triggerTween then
			comp:triggerTween(target, from, to, duration, curve)
			break
		end
	end
end

---@param component table
function Sprite:addComponent(component)
	table.insert(self.components, component)
	component.parent = self
end

---@param dt number
function Sprite:update(dt)
	for _, component in ipairs(self.components) do
		if component.update then
			component:update(dt)
		end
	end
end

function Sprite:draw()
	if self.type == "StaticSprite" and self.image then
		local ox = (self.frameWidth or self.image:getWidth()) * (self.pivotX or 0)
		local oy = (self.frameHeight or self.image:getHeight()) * (self.pivotY or 0)
		love.graphics.draw(self.image, math.floor(self.x + 0.5), math.floor(self.y + 0.5), 0, 1, 1, ox, oy)
		return
	end
	for _, component in ipairs(self.components) do
		if component.draw then
			component:draw(self.x, self.y)
		end
	end
end

return Sprite
