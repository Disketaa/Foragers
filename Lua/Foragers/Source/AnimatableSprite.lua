-- Animated sprite component.
local AnimatableSprite = {}
AnimatableSprite.__index = AnimatableSprite

-- data.spriteSheet - path to spritesheet image
-- data.frameWidth, data.frameHeight - frame dimensions
-- data.animations - array: { name, row, frames, speed, loop }
function AnimatableSprite.new(data)
	local self = setmetatable({}, AnimatableSprite)
	self.image = love.graphics.newImage(data.spriteSheet)
	self.frameWidth = data.frameWidth
	self.frameHeight = data.frameHeight
	self.animations = {}
	self.quads = {}
	self.flipX = false
	self.currentAnim = data.animations[1] and data.animations[1].name
	self.currentTime = 0
	self.type = "animator"
	self:_buildQuads(data.animations)
	return self
end

-- Builds quads for each animation from spritesheet.
-- Frames arranged left-to-right, rows bottom-to-top.
function AnimatableSprite:_buildQuads(animList)
	local sheetWidth = self.image:getWidth()
	local sheetHeight = self.image:getHeight()
	for i, anim in ipairs(animList) do
		local name = anim.name
		local row = anim.row or i
		self.animations[name] = anim
		self.quads[name] = {}
		for col = 0, anim.frames - 1 do
			local x = col * self.frameWidth
			local y = (row - 1) * self.frameHeight
			self.quads[name][col + 1] =
				love.graphics.newQuad(x, y, self.frameWidth, self.frameHeight, sheetWidth, sheetHeight)
		end
	end
end

-- Switches current animation. Resets animation time.
function AnimatableSprite:setAnimation(name)
	if self.animations[name] and self.currentAnim ~= name then
		self.currentAnim = name
		self.currentTime = 0
	end
end

-- Updates animation time. Loop or one-shot mode.
function AnimatableSprite:update(dt)
	local anim = self.animations[self.currentAnim]
	if anim.loop then
		self.currentTime = self.currentTime + dt
		local cycleTime = anim.frames / anim.speed
		self.currentTime = self.currentTime % cycleTime
	else
		local maxTime = (anim.frames - 1) / anim.speed
		self.currentTime = self.currentTime + dt
		if self.currentTime > maxTime then
			self.currentTime = maxTime
		end
	end
end

-- Draws current frame. Supports X-axis flip.
function AnimatableSprite:draw(x, y)
	local anim = self.animations[self.currentAnim]
	local frameIndex = math.floor(self.currentTime * anim.speed) + 1
	if frameIndex > #self.quads[self.currentAnim] then
		frameIndex = #self.quads[self.currentAnim]
	end
	local quad = self.quads[self.currentAnim][frameIndex]
	local sx = self.flipX and -1 or 1
	local ox = self.flipX and self.frameWidth or 0
	love.graphics.draw(self.image, quad, x, y, 0, sx, 1, ox, 0)
end

return AnimatableSprite
