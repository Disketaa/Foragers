local EventEmitter = require("Source.Helpers.EventEmitter")
local Log = require("Source.Helpers.Log")
local Pivot = require("Source.Helpers.Pivot")

---@class Sprite
---@field x number World X position
---@field y number World Y position
---@field frameWidth number|nil Sprite width in pixels for static sprites
---@field frameHeight number|nil Sprite height in pixels for static sprites
---@field pivotX number|string|nil Pixel or keyword ("left"|"center"|"right") X origin
---@field pivotY number|string|nil Pixel or keyword ("top"|"center"|"bottom") Y origin
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
---@field object string|nil Gameplay identifier from data (e.g. "player", "tile")
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
		shader = nil,
		shaderData = nil,
		_shaderBroken = nil,
		_shaderDirty = false,
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

--- Find first component of given type, optionally matching predicate.
function Sprite:findComponent(type, predicate)
	for _, comp in ipairs(self.components or {}) do
		if comp.type == type and (not predicate or predicate(comp)) then
			return comp
		end
	end
end

--- Find all components of given type, optionally matching predicate.
function Sprite:getComponents(type, predicate)
	local result = {}
	for _, comp in ipairs(self.components or {}) do
		if comp.type == type and (not predicate or predicate(comp)) then
			table.insert(result, comp)
		end
	end
	return result
end

--- Fill a caller-provided buffer with matching components. Non-allocating
--- alternative to getComponents for per-frame hot paths (no fresh result table,
--- no per-call predicate if the caller hoists it). The caller must iterate the
--- buffer immediately and must not hold the reference across another call.
---@param type string
---@param predicate function|nil
---@param out table Scratch buffer to fill.
---@return table out
function Sprite:getComponentsInto(type, predicate, out)
	local n = 0
	for _, comp in ipairs(self.components or {}) do
		if comp.type == type and (not predicate or predicate(comp)) then
			n = n + 1
			out[n] = comp
		end
	end
	for i = n + 1, #out do
		out[i] = nil
	end
	return out
end

--- Bind parent shader if present. Returns true if shader was set.
---@return boolean
function Sprite:applyShader()
	if self.shader and not self._shaderBroken then
		local ok, err = xpcall(function()
			love.graphics.setShader(self.shader)
			if self._shaderDirty then
				for k, v in pairs(self.shaderData or {}) do
					self.shader:send(k, v)
				end
				self._shaderDirty = false
			end
		end, debug.traceback)
		if ok then
			return true
		end
		Log.error("[Sprite] shader: " .. tostring(err))
		love.graphics.setShader()
		self._shaderBroken = true
	end
	return false
end

--- Read tween transforms + flipX + alpha into draw parameters.
---@return number sx, number sy, number rot, number alpha
function Sprite:getDrawContext()
	local sx, sy = 1, 1
	local rot = 0
	if self.tweens then
		if self.tweens.scale_x then
			sx = self.tweens.scale_x:getValue()
		end
		if self.tweens.scale_y then
			sy = self.tweens.scale_y:getValue()
		end
		if self.tweens.angle then
			rot = math.rad(self.tweens.angle:getValue())
		end
	end
	if rot == 0 and self.angle then
		rot = math.rad(self.angle)
	end
	if self.flipX then
		sx = -sx
	end
	return sx, sy, rot, self.alpha or 1
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

local function drawComponents(sprite, predicate)
	for _, component in ipairs(sprite.components or {}) do
		if not component._broken and predicate(component) and component.draw then
			local ok, err = xpcall(component.draw, debug.traceback, component, sprite.x, sprite.y)
			if not ok then
				Log.error(string.format("[%s] draw: %s", component.type or "?", err))
				component._broken = true
			end
		end
	end
end

function Sprite:draw()
	if self.type == "StaticSprite" and self.image then
		local hadShader = self:applyShader()
		local sx, sy, rot, alpha = self:getDrawContext()
		if alpha < 1 then
			love.graphics.setColor(1, 1, 1, alpha)
		end
		local w = self.frameWidth or self.image:getWidth()
		local h = self.frameHeight or self.image:getHeight()
		local ox = Pivot.px(self.pivotX, w, 0)
		local oy = Pivot.px(self.pivotY, h, 0)
		love.graphics.draw(self.image, math.floor(self.x + 0.5), math.floor(self.y + 0.5), rot, sx, sy, ox, oy)
		if alpha < 1 then
			love.graphics.setColor(1, 1, 1, 1)
		end
		if hadShader then
			love.graphics.setShader()
		end
	end

	-- Component draws: shader is managed by SpriteSheet, not here.
	-- This ensures text overlays (counter label, spritefont, text_emitter)
	-- draw without the sprite's tint shader.
	drawComponents(self, function(c) return c.drawBehind end)

	drawComponents(self, function(c) return not c.drawBehind and not c.drawOnTop end)

	drawComponents(self, function(c) return c.drawOnTop end)
end

return Sprite
