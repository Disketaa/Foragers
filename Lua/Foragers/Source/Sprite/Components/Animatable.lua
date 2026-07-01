---@class Animatable
---@field image love.Image
---@field frameWidth number
---@field frameHeight number
---@field pivotX number
---@field pivotY number
---@field animations table<string, table>
---@field quads table<string, table<number, love.Quad>>
---@field currentAnim string|nil
---@field currentTime number
---@field type "animatable"
---@field tags table<string, string>|nil State to animation name mapping
local Animatable = {}
Animatable.__index = Animatable

---@param data table
---@return Animatable
function Animatable.new(data)
	local self = setmetatable({}, Animatable)
	self.image = love.graphics.newImage(data.spriteSheet)
	self.frameWidth = data.frameWidth or 16
	self.frameHeight = data.frameHeight or 16
	self.animations = {}
	self.quads = {}
	self.type = "animatable"
	self.pivotX = data.pivotX or 0.5
	self.pivotY = data.pivotY or 0.5
	self.tags = data.tags
	self:_buildQuads(data.animations or {})
	for name in pairs(self.animations) do
		self.currentAnim = name
		break
	end
	return self
end

---@param animList table<string, table>
function Animatable:_buildQuads(animList)
	local sheetWidth, sheetHeight = self.image:getWidth(), self.image:getHeight()
	local rowIndex = 1
	for name, anim in pairs(animList) do
		local row = anim.row or rowIndex
		rowIndex = rowIndex + 1
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

function Animatable:update(dt)
	local state = self.parent and self.parent._state
	if state and self.tags then
		local animName = self.tags[state]
		if animName and self.currentAnim ~= animName then
			self.currentAnim = animName
			self.currentTime = 0
		end
	end

	if self.currentAnim then
		local anim = self.animations[self.currentAnim]
		if anim then
			local speedMult = (self.parent and self.parent.animSpeedFactor) or 1
			if anim.loop then
				self.currentTime = (self.currentTime + dt * speedMult) % (anim.frames / anim.speed)
			else
				local maxTime = (anim.frames - 1) / anim.speed
				self.currentTime = math.min(self.currentTime + dt * speedMult, maxTime)
			end
		end
	end
end

---@param x number
---@param y number
function Animatable:draw(x, y)
	if not self.currentAnim then
		return
	end
	local anim = self.animations[self.currentAnim]
	local quads = self.quads[self.currentAnim]
	if not anim or not quads or #quads == 0 then
		return
	end

	local frameIndex = math.min(math.floor(self.currentTime * anim.speed) + 1, #quads)
	local quad = quads[frameIndex]

	local sx, sy = 1, 1
	local tweenTbl = self.parent and self.parent.tweens
	if tweenTbl then
		if tweenTbl.scale_x then
			sx = tweenTbl.scale_x:getValue()
		end
		if tweenTbl.scale_y then
			sy = tweenTbl.scale_y:getValue()
		end
	end

	local ox = self.frameWidth * self.pivotX
	local oy = self.frameHeight * self.pivotY

	if self.parent and self.parent.flipX then
		sx = -sx
	end

	love.graphics.draw(self.image, quad, math.floor(x + 0.5), math.floor(y + 0.5), 0, sx, sy, ox, oy)
end

return Animatable
