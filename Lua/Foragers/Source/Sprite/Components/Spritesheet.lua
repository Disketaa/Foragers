local Events = require("Source.Helpers.Events")
local Math = require("Source.Helpers.Math")

local Spritesheet = {}
Spritesheet.__index = Spritesheet

function Spritesheet.new(data)
	if not data or not data.spriteSheet then
		return setmetatable({}, Spritesheet)
	end

	local ok, image = pcall(love.graphics.newImage, data.spriteSheet)
	if not ok or not image then
		return setmetatable({}, Spritesheet)
	end

	local self = setmetatable({
		image = image,
		type = "spritesheet",
		frameWidth = data.frameWidth or 8,
		frameHeight = data.frameHeight or 8,
		pivotX = data.pivotX or 0.5,
		pivotY = data.pivotY or 0.5,
	}, Spritesheet)

	local imageW, imageH = image:getWidth(), image:getHeight()

	local columns = data.columns or math.floor(imageW / self.frameWidth)
	local rows = data.rows or math.floor(imageH / self.frameHeight)

	if data.columns then
		assert(imageW == data.columns * self.frameWidth,
			string.format("Spritesheet '%s': columns=%d * frameWidth=%d = %d, but imageWidth=%d",
				data.spriteSheet, data.columns, self.frameWidth, data.columns * self.frameWidth, imageW))
	end
	if data.rows then
		assert(imageH == data.rows * self.frameHeight,
			string.format("Spritesheet '%s': rows=%d * frameHeight=%d = %d, but imageHeight=%d",
				data.spriteSheet, data.rows, self.frameHeight, data.rows * self.frameHeight, imageH))
	end

	self.columns = columns
	self.rows = rows

	self.quads = {}
	for row = 0, rows - 1 do
		for col = 0, columns - 1 do
			self.quads[#self.quads + 1] = love.graphics.newQuad(
				col * self.frameWidth,
				row * self.frameHeight,
				self.frameWidth,
				self.frameHeight,
				imageW, imageH
			)
		end
	end

	if data.animations then
		self.animations = {}
		for name, animDef in pairs(data.animations) do
			local numFrames = math.min(animDef.frames or columns, columns)
			self.animations[name] = {
				startIdx = (animDef.row - 1) * columns + 1,
				frames = numFrames,
				speed = animDef.speed and Math.parseRandomValue(animDef.speed) or 1,
				loop = animDef.loop ~= false,
			}
		end
		self.tags = data.tags
		self.currentAnim = (self.tags and self.tags.idle) or (self.animations.idle and "idle") or next(self.animations)
		self.currentTime = 0
		self._lastFrame = nil
	else
		self._currentIndex = nil
	end

	return self
end

function Spritesheet:attach()
	self.parent:on(Events.STATE_CHANGED, function(newState)
		local animName = self.tags and self.tags[newState] or newState
		if self.animations[animName] and animName ~= self.currentAnim then
			self.currentAnim = animName
			self.currentTime = 0
			self._lastFrame = nil
		end
	end, 5)
end

function Spritesheet:update(dt)
	if not self.currentAnim or not self.animations then
		return
	end
	local anim = self.animations[self.currentAnim]
	if not anim then
		return
	end

	local speedMult = (self.parent and self.parent.animSpeedFactor) or 1
	dt = math.min(dt, 0.1)
	if anim.loop then
		self.currentTime = (self.currentTime + dt * speedMult) % (anim.frames / anim.speed)
	else
		local maxTime = (anim.frames - 1) / anim.speed
		self.currentTime = math.min(self.currentTime + dt * speedMult, maxTime)
	end

	local frameIndex = math.min(math.floor(self.currentTime * anim.speed) + 1, anim.frames)
	if frameIndex ~= self._lastFrame then
		self._lastFrame = frameIndex
		if self.parent then
			self.parent:emit(Events.ANIM_FRAME, frameIndex)
		end
	end
end

function Spritesheet:setFrame(index)
	if not self.quads then
		return
	end
	if index >= 0 and index < #self.quads then
		self._currentIndex = index + 1
	end
end

function Spritesheet:draw(x, y)
	if not self.quads then
		return
	end

	local quad
	if self.currentAnim then
		local anim = self.animations[self.currentAnim]
		if not anim then
			return
		end
		local frameIndex = math.min(math.floor(self.currentTime * anim.speed) + 1, anim.frames)
		quad = self.quads[anim.startIdx + frameIndex - 1]
	elseif self._currentIndex then
		quad = self.quads[self._currentIndex]
	else
		return
	end

	if not quad then
		return
	end

	local sx, sy = 1, 1
	local rot = 0
	local tweenTbl = self.parent and self.parent.tweens
	if tweenTbl then
		if tweenTbl.scale_x then
			sx = tweenTbl.scale_x:getValue()
		end
		if tweenTbl.scale_y then
			sy = tweenTbl.scale_y:getValue()
		end
		if tweenTbl.angle then
			rot = math.rad(tweenTbl.angle:getValue())
		end
	end

	if self.parent and self.parent.flipX then
		sx = -sx
	end

	if not tweenTbl or not tweenTbl.angle then
		if self.parent and self.parent.angle then
			rot = self.parent.angle
		end
	end

	local alpha = (self.parent and self.parent.alpha) or 1
	if alpha < 1 then
		love.graphics.setColor(1, 1, 1, alpha)
	end
	local ox = self.frameWidth * self.pivotX
	local oy = self.frameHeight * self.pivotY
	love.graphics.draw(self.image, quad, math.floor(x + 0.5), math.floor(y + 0.5), rot, sx, sy, ox, oy)
	if alpha < 1 then
		love.graphics.setColor(1, 1, 1, 1)
	end
end

return Spritesheet
