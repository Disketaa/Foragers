local Events = require("Source.Helpers.Core.Events")
local ValueParser = require("Source.Helpers.Core.ValueParser")
local Pivot = require("Source.Helpers.Core.Pivot")

local SpriteSheet = {}
SpriteSheet.__index = SpriteSheet

-- Share one Image + quad array per prop type instead of re-decoding a texture
-- per spawn. Cache lives forever: ModLoader registers content only at startup,
-- nothing mutates an Image, and frame changes index the shared quad array (never
-- mutate a quad viewport). Module locals, so Reset.all() doesn't clear them.
-- ASSUMPTION: if a prop type's PNG can ever change between resets (runtime mods,
-- hot-reload, reskins), add an invalidation path or this serves stale textures.
local imageCache = {}
local quadCache = {}

--- Map a currentTime (seconds) to its frame index 1..anim.frames, walking the
--- per-frame duration weights (cum boundaries in frame units).
local function frameIndexAt(anim, currentTime)
	local tc = currentTime * anim.speed
	local i = 1
	while i < anim.frames and tc >= anim.cum[i] do
		i = i + 1
	end
	return i
end

function SpriteSheet.new(data)
	if not data or not data.spriteSheet then
		return setmetatable({}, SpriteSheet)
	end

	local image = imageCache[data.spriteSheet]
	if not image then
		local ok
		ok, image = pcall(love.graphics.newImage, data.spriteSheet)
		if not ok or not image then
			return setmetatable({}, SpriteSheet)
		end
		imageCache[data.spriteSheet] = image
	end

	local self = setmetatable({
		image = image,
		type = "spritesheet",
		frameWidth = data.frameWidth or 8,
		frameHeight = data.frameHeight or 8,
		pivotX = data.pivotX or "center",
		pivotY = data.pivotY or "center",
	}, SpriteSheet)

	local imageW, imageH = image:getWidth(), image:getHeight()

	local columns = data.columns or math.floor(imageW / self.frameWidth)
	local rows = data.rows or math.floor(imageH / self.frameHeight)

	if data.columns then
		assert(
			imageW == data.columns * self.frameWidth,
			string.format(
				"SpriteSheet '%s': columns=%d * frameWidth=%d = %d, but imageWidth=%d",
				data.spriteSheet,
				data.columns,
				self.frameWidth,
				data.columns * self.frameWidth,
				imageW
			)
		)
	end
	if data.rows then
		assert(
			imageH == data.rows * self.frameHeight,
			string.format(
				"SpriteSheet '%s': rows=%d * frameHeight=%d = %d, but imageHeight=%d",
				data.spriteSheet,
				data.rows,
				self.frameHeight,
				data.rows * self.frameHeight,
				imageH
			)
		)
	end

	self.columns = columns
	self.rows = rows

	local quadKey = data.spriteSheet .. "#" .. self.frameWidth .. "x" .. self.frameHeight
	self.quads = quadCache[quadKey]
	if not self.quads then
		self.quads = {}
		for row = 0, rows - 1 do
			for col = 0, columns - 1 do
				self.quads[#self.quads + 1] = love.graphics.newQuad(
					col * self.frameWidth,
					row * self.frameHeight,
					self.frameWidth,
					self.frameHeight,
					imageW,
					imageH
				)
			end
		end
		quadCache[quadKey] = self.quads
	end

	if data.animations then
		self.animations = {}
		for name, animDef in pairs(data.animations) do
			local numFrames = math.min(animDef.frames or columns, columns)
			-- Per-frame hold weights (`duration`, default all 1s). cum[i] is the
			-- weight-sum before frame i, so frame i spans [cum[i-1], cum[i]) in
			-- frame units; maxTime = total / speed keeps currentTime in seconds.
			local dur = animDef.duration or {}
			local cum = { 0 }
			for i = 1, numFrames do
				cum[i + 1] = cum[i] + (tonumber(dur[i]) or 1)
			end
			local speed = ValueParser.call(animDef, "speed") or 1
			self.animations[name] = {
				startIdx = (animDef.row - 1) * columns + 1,
				frames = numFrames,
				speed = speed,
				cum = cum,
				maxTime = cum[numFrames] / speed,
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

function SpriteSheet:attach()
	if self.parent then
		-- Reflect the true per-frame size and pivot onto the sprite; data may omit
		-- them (props derive size from imageW / columns and default pivot to 0.5),
		-- leaving sprite.frameWidth/pivotX nil and misaligning draw vs boundaries.
		self.parent.frameWidth = self.frameWidth
		self.parent.frameHeight = self.frameHeight
		self.parent.pivotX = self.pivotX
		self.parent.pivotY = self.pivotY
	end
	self.parent:on(Events.STATE_CHANGED, function(newState)
		local animName = self.tags and self.tags[newState] or newState
		if self.animations[animName] and animName ~= self.currentAnim then
			self.currentAnim = animName
			self.currentTime = 0
			self._lastFrame = nil
		end
	end, 5)
end

function SpriteSheet:update(dt)
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
		self.currentTime = (self.currentTime + dt * speedMult) % anim.maxTime
	else
		self.currentTime = math.min(self.currentTime + dt * speedMult, anim.maxTime)
	end

	local frameIndex = frameIndexAt(anim, self.currentTime)
	if frameIndex ~= self._lastFrame then
		self._lastFrame = frameIndex
		if self.parent then
			self.parent:emit(Events.ANIM_FRAME, frameIndex)
		end
	end
end

function SpriteSheet:setFrame(index)
	if not self.quads then
		return
	end
	if index >= 0 and index < #self.quads then
		self._currentIndex = index + 1
	end
end

function SpriteSheet:_getQuad()
	if not self.quads then
		return nil
	end

	local quad
	if self.currentAnim then
		local anim = self.animations[self.currentAnim]
		if not anim then
			return nil
		end
		local frameIndex = frameIndexAt(anim, self.currentTime)
		quad = self.quads[anim.startIdx + frameIndex - 1]
	elseif self._currentIndex then
		quad = self.quads[self._currentIndex]
	elseif #self.quads > 0 then
		quad = self.quads[1]
	end

	return quad
end

function SpriteSheet:draw(x, y)
	if not self.quads then
		return
	end

	local quad = self:_getQuad()

	if not quad then
		return
	end

	local parent = self.parent
	local hadShader = parent and parent.applyShader and parent:applyShader() or false
	local sx, sy, rot, alpha = 1, 1, 0, 1
	if parent and parent.getDrawContext then
		sx, sy, rot, alpha = parent:getDrawContext()
	elseif parent and parent.flipX then
		sx = -sx
	end
	local ox = Pivot.px(self.pivotX, self.frameWidth, 0)
	local oy = Pivot.px(self.pivotY, self.frameHeight, 0)
	if alpha < 1 then
		love.graphics.setColor(1, 1, 1, alpha)
	end
	love.graphics.draw(self.image, quad, math.floor(x + 0.5), math.floor(y + 0.5), rot, sx, sy, ox, oy)
	if alpha < 1 then
		love.graphics.setColor(1, 1, 1, 1)
	end
	if hadShader then
		love.graphics.setShader()
	end
end

--- Draw current frame at position without shader/tween handling.
---@param x number
---@param y number
---@param rot number|nil Rotation in radians (0 if nil)
function SpriteSheet:drawCurrentFrame(x, y, rot)
	if not self.quads then
		return
	end

	local quad = self:_getQuad()

	if not quad then
		return
	end

	local sx, sy = 1, 1
	if self.parent and self.parent.flipX then
		sx = -sx
	end

	local ox = Pivot.px(self.pivotX, self.frameWidth, 0)
	local oy = Pivot.px(self.pivotY, self.frameHeight, 0)
	love.graphics.draw(self.image, quad, math.floor(x + 0.5), math.floor(y + 0.5), rot or 0, sx, sy, ox, oy)
end

return SpriteSheet
