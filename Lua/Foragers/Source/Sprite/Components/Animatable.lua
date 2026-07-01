---@class Animatable
---@field image love.Image
---@field frameWidth number
---@field frameHeight number
---@field pivotX number
---@field pivotY number
---@field animations table<string, table>
---@field quads table<string, table<number, love.Quad>>
---@field flipX boolean
---@field currentAnim string|nil
---@field currentTime number
---@field type "animatable"
---@field tweens table<string, Tween>
---@field animationSpeedFactor number Current animation playback speed multiplier
local Animatable = {}
Animatable.__index = Animatable

local Tweens = require("Source.Tweens")

---@param data table
---@return Animatable
function Animatable.new(data)
	local self = setmetatable({}, Animatable)
	self.image = love.graphics.newImage(data.spriteSheet)
	self.frameWidth = data.frameWidth or 16
	self.frameHeight = data.frameHeight or 16
	self.animations = {}
	self.quads = {}
	self.flipX = false
	self.currentAnim = data.animations and data.animations[1] and data.animations[1].name
	self.currentTime = 0
	self.type = "animatable"
	self.tweens = {}
	self.pivotX = data.pivotX or 0.5
	self.pivotY = data.pivotY or 0.5
	self.animationSpeedFactor = 1
	self:_buildQuads(data.animations or {})
	return self
end

---@param target string
---@param from number
---@param to number
---@param duration number
---@param curve function
function Animatable:triggerTween(target, from, to, duration, curve)
	if not self.tweens[target] then
		self.tweens[target] = Tweens.create(target, from, to, duration, curve)
	end
	local tween = self.tweens[target]
	tween.from = from
	tween.to = to
	tween.duration = duration
	tween.curve = curve
	tween:start()
end

function Animatable:OnFlip()
	self:triggerTween("scale_x", 0.75, 1.0, 0.3, Tweens.BackOut)
	self:triggerTween("scale_y", 1.25, 1.0, 0.3, Tweens.BackOut)
end

---@param animList table
function Animatable:_buildQuads(animList)
	local sheetWidth, sheetHeight = self.image:getWidth(), self.image:getHeight()
	for i, anim in ipairs(animList) do
		if anim.name then
			local name = anim.name
			local row = anim.row or i
			self.animations[name] = anim
			self.quads[name] = {}
			for col = 0, (anim.frames or 1) - 1 do
				local x = col * self.frameWidth
				local y = (row - 1) * self.frameHeight
				self.quads[name][col + 1] =
					love.graphics.newQuad(x, y, self.frameWidth, self.frameHeight, sheetWidth, sheetHeight)
			end
		end
	end
end

---@param speed number Animation speed multiplier
function Animatable:setSpeed(speed)
	self.animationSpeedFactor = speed
end

---@param name string
function Animatable:setAnimation(name)
	if self.animations[name] and self.currentAnim ~= name then
		self.currentAnim = name
		self.currentTime = 0
	end
end

function Animatable:update(dt)
	local anim = self.animations[self.currentAnim]
	if not anim then return end
	if anim.loop then
		self.currentTime = (self.currentTime + dt * self.animationSpeedFactor) % (anim.frames / anim.speed)
	else
		local maxTime = (anim.frames - 1) / anim.speed
		self.currentTime = math.min(self.currentTime + dt * self.animationSpeedFactor, maxTime)
	end
	for _, tween in pairs(self.tweens) do
		tween:update(dt)
	end
end

---@param x number
---@param y number
function Animatable:draw(x, y)
	local anim = self.animations[self.currentAnim]
	if not anim then
		return
	end
	local quads = self.quads[self.currentAnim]
	if not quads or #quads == 0 then
		return
	end
	local frameIndex = math.min(math.floor(self.currentTime * anim.speed) + 1, #quads)
	local quad = quads[frameIndex]

	local sx, sy = 1, 1
	if self.tweens.scale_x then
		sx = self.tweens.scale_x:getValue()
	end
	if self.tweens.scale_y then
		sy = self.tweens.scale_y:getValue()
	end

	local ox = self.frameWidth * self.pivotX
	local oy = self.frameHeight * self.pivotY

	if self.flipX then
		sx = -sx
	end

	love.graphics.draw(self.image, quad, math.floor(x + 0.5), math.floor(y + 0.5), 0, sx, sy, ox, oy)
end

return Animatable
