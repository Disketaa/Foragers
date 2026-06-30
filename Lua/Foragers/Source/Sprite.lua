local Sprite = {}
Sprite.__index = Sprite

function Sprite.new(data)
	local self = setmetatable({}, Sprite)
	self.image = love.graphics.newImage(data.spriteSheet)
	self.frameWidth = data.frameWidth
	self.frameHeight = data.frameHeight
	self.animations = data.animations
	self.flipX = false
	self:_buildQuads()
	self.currentAnim = "idle"
	self.currentTime = 0
	return self
end

function Sprite:_buildQuads()
	self.quads = {}
	local sheetWidth = self.image:getWidth()
	local sheetHeight = self.image:getHeight()
	local cols = sheetWidth / self.frameWidth
	for name, anim in pairs(self.animations) do
		self.quads[name] = {}
		local row = anim.row
		for col = 0, anim.frames - 1 do
			local x = col * self.frameWidth
			local y = row * self.frameHeight
			self.quads[name][col + 1] = love.graphics.newQuad(
				x, y, self.frameWidth, self.frameHeight, sheetWidth, sheetHeight
			)
		end
	end
end

function Sprite:setAnimation(name)
	if self.animations[name] and self.currentAnim ~= name then
		self.currentAnim = name
		self.currentTime = 0
	end
end

function Sprite:update(dt)
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

function Sprite:draw(x, y)
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

return Sprite