---@class AnimatableSprite
---@field image love.Image
---@field frameWidth number
---@field frameHeight number
---@field animations table<string, table>
---@field quads table<string, table<number, love.Quad>>
---@field flipX boolean
---@field currentAnim string|nil
---@field currentTime number
---@field type "animator"

local AnimatableSprite = {}
AnimatableSprite.__index = AnimatableSprite

-- Creates animated sprite component from data definition.
-- Requires: data.spriteSheet (string), data.frameWidth/Height (numbers), data.animations (array).
function AnimatableSprite.new(data)
	local self = setmetatable({}, AnimatableSprite)
	self.image = love.graphics.newImage(data.spriteSheet)
	self.frameWidth = data.frameWidth or 16
	self.frameHeight = data.frameHeight or 16
	self.animations = {}
	self.quads = {}
	self.flipX = false
	self.currentAnim = data.animations and data.animations[1] and data.animations[1].name
	self.currentTime = 0
	self.type = "animator"
	self:_buildQuads(data.animations or {})
	return self
end

-- Builds quads for each animation row from spritesheet.
-- Frames arranged left-to-right; rows numbered from bottom (row 1 = bottom row).
function AnimatableSprite:_buildQuads(animList)
	local sheetWidth, sheetHeight = self.image:getWidth(), self.image:getHeight()
	for i, anim in ipairs(animList) do
		if not anim.name then
			-- Skip animations without name to survive corrupted mod data
		else
			local name = anim.name
			local row = anim.row or i
			self.animations[name] = anim
			self.quads[name] = {}
			for col = 0, (anim.frames or 1) - 1 do
				local x = col * self.frameWidth
				local y = (row - 1) * self.frameHeight
				self.quads[name][col + 1] = love.graphics.newQuad(x, y, self.frameWidth, self.frameHeight, sheetWidth, sheetHeight)
			end
		end
	end
end

-- Switches to named animation if it exists.
-- Resets animation time to allow seamless transition.
---@param name string Animation identifier from data.animations
function AnimatableSprite:setAnimation(name)
	if self.animations[name] and self.currentAnim ~= name then
		self.currentAnim = name
		self.currentTime = 0
	end
end

-- Updates animation playback. Loop mode wraps; one-shot clamps to last frame.
-- Guard against nil currentAnim (e.g., corrupted mod data) to prevent runtime crash.
function AnimatableSprite:update(dt)
	local anim = self.animations[self.currentAnim]
	if not anim then return end
	if anim.loop then
		self.currentTime = (self.currentTime + dt) % (anim.frames / anim.speed)
	else
		local maxTime = (anim.frames - 1) / anim.speed
		self.currentTime = math.min(self.currentTime + dt, maxTime)
	end
end

-- Renders current frame with optional horizontal flip for left-facing.
-- Guard against nil animation/quad after hot-reload edge cases.
---@param x number Object X position
---@param y number Object Y position
function AnimatableSprite:draw(x, y)
	local anim = self.animations[self.currentAnim]
	if not anim then return end
	local quads = self.quads[self.currentAnim]
	if not quads or #quads == 0 then return end
	local frameIndex = math.min(math.floor(self.currentTime * anim.speed) + 1, #quads)
	local quad = quads[frameIndex]
	local sx = self.flipX and -1 or 1
	-- OffsetX shifts quad origin for horizontal flip: full width to align flipped sprite at same X
	local ox = self.flipX and self.frameWidth or 0
	love.graphics.draw(self.image, quad, x, y, 0, sx, 1, ox, 0)
end

return AnimatableSprite
