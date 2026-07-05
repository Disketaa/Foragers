local EventEmitter = require("Source.Helpers.EventEmitter")
local Log = require("Source.Helpers.Log")

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
---@field _state string|nil Current sprite state — render-only, do not read for logic
---@field flipX boolean|nil Horizontal flip state — render-only, do not read for logic
---@field tweens table<string, Tween>|nil Runtime tweens on sprite (Tween→Animation producer/consumer)
---@field animSpeedFactor number Animation speed multiplier (used by Animation)
---@field sortY number Y-sort key, updated each frame as y + sortOffsetY
---@field sortOffsetY number Per-sprite vertical offset for Y-sorting (foot position relative to origin)
---@field layer integer Draw layer: zKey = layer * 100000 + sortY
local Sprite = {}
Sprite.__index = Sprite

---@param x number|nil
---@param y number|nil
---@return Sprite
function Sprite.new(x, y)
	local self = setmetatable({
		x = x or 0,
		y = y or 0,
		sortY = 0,
		sortOffsetY = 0,
		layer = 0,
		components = {},
		tweens = {},
		animSpeedFactor = 1,
		_events = EventEmitter.new(),
	}, Sprite)
	return self
end

---@param event string
---@param callback function
---@param priority number|nil
function Sprite:on(event, callback, priority)
	self._events:on(event, callback, priority)
end

---@param event string
---@param ... any
function Sprite:emit(event, ...)
	self._events:emit(event, ...)
end

---@param event string
---@param callback function
function Sprite:removeListener(event, callback)
	self._events:removeListener(event, callback)
end

---@param component table
function Sprite:addComponent(component)
	table.insert(self.components, component)
	component.parent = self
	if component.attach then
		component:attach()
	end
end

---@param dt number
function Sprite:update(dt)
	for _, component in ipairs(self.components) do
		if not component._broken and component.update then
			local ok, err = xpcall(component.update, debug.traceback, component, dt)
			if not ok then
				Log.error(string.format("[%s] update: %s", component.type or "?", err))
				component._broken = true
			end
		end
	end
	self.sortY = self.y + (self.sortOffsetY or 0)
end

function Sprite:draw()
	if self.type == "StaticSprite" and self.image then
		local ox = (self.frameWidth or self.image:getWidth()) * (self.pivotX or 0)
		local oy = (self.frameHeight or self.image:getHeight()) * (self.pivotY or 0)
		local sx = self.flipX and -1 or 1
		love.graphics.draw(self.image, math.floor(self.x + 0.5), math.floor(self.y + 0.5), 0, sx, 1, ox, oy)
	end
	for _, component in ipairs(self.components) do
		if not component._broken and component.drawBehind and component.draw then
			local ok, err = xpcall(component.draw, debug.traceback, component, self.x, self.y)
			if not ok then
				Log.error(string.format("[%s] draw: %s", component.type or "?", err))
				component._broken = true
			end
		end
	end
	for _, component in ipairs(self.components) do
		if not component._broken and not component.drawBehind and not component.drawOnTop and component.draw then
			local ok, err = xpcall(component.draw, debug.traceback, component, self.x, self.y)
			if not ok then
				Log.error(string.format("[%s] draw: %s", component.type or "?", err))
				component._broken = true
			end
		end
	end
	for _, component in ipairs(self.components) do
		if not component._broken and component.drawOnTop and component.draw then
			local ok, err = xpcall(component.draw, debug.traceback, component, self.x, self.y)
			if not ok then
				Log.error(string.format("[%s] draw: %s", component.type or "?", err))
				component._broken = true
			end
		end
	end
end

return Sprite
