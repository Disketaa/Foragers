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
---@field tweens table<string, Tween> Active tweens indexed by target name
local AnimatableSprite = {}
AnimatableSprite.__index = AnimatableSprite

local Tweens = require("Source.Tweens")

---@param data table Component data with spriteSheet, frameWidth/Height, animations
---@return AnimatableSprite
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
	self.tweens = {}
	-- Pivot point as normalized coordinates (0-1): 0.5, 1 = bottom center
	self.pivotX = data.pivotX or 0.5
	self.pivotY = data.pivotY or 0.5
	self:_buildQuads(data.animations or {})
	return self
end

-- Triggers a tween on specified target property. Creates new tween or restarts existing.
---@param target string Property name ("scale_x", "scale_y", "x", "y")
---@param from number Start value
---@param to number End value
---@param duration number Duration in seconds
---@param curve function Easing function
function AnimatableSprite:triggerTween(target, from, to, duration, curve)
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

-- Called when flipX changes direction. Plays squash-stretch tween effect.
function AnimatableSprite:OnFlip()
	self:triggerTween("scale_x", 0.75, 1.0, 0.3, Tweens.BackOut)
	self:triggerTween("scale_y", 1.25, 1.0, 0.3, Tweens.BackOut)
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
				self.quads[name][col + 1] =
					love.graphics.newQuad(x, y, self.frameWidth, self.frameHeight, sheetWidth, sheetHeight)
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

-- Updates animation playback and active tweens.
-- Loop mode wraps; one-shot clamps to last frame.
-- Guard against nil currentAnim (e.g., corrupted mod data) to prevent runtime crash.
function AnimatableSprite:update(dt)
	local anim = self.animations[self.currentAnim]
	if not anim then
		return
	end
	if anim.loop then
		self.currentTime = (self.currentTime + dt) % (anim.frames / anim.speed)
	else
		local maxTime = (anim.frames - 1) / anim.speed
		self.currentTime = math.min(self.currentTime + dt, maxTime)
	end

	-- Update all active tweens
	for _, tween in pairs(self.tweens) do
		tween:update(dt)
	end
end

-- Renders current frame with optional horizontal flip for left-facing.
-- Applies active tweens to scale values. Guard against nil animation/quad after hot-reload edge cases.
---@param x number Object X position
---@param y number Object Y position
function AnimatableSprite:draw(x, y)
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

	-- Get tweened scale values, default to 1.0 if no tween active
	local sx = 1
	local sy = 1
	if self.tweens.scale_x then
		sx = self.tweens.scale_x:getValue()
	end
	if self.tweens.scale_y then
		sy = self.tweens.scale_y:getValue()
	end

	-- Pivot-based origin offset
	-- In LÖVE: (0,0) = top-left, (frameWidth, frameHeight) = bottom-right
	-- pivotY = 0 means top edge (oy = 0), pivotY = 1 means bottom edge (oy = frameHeight)
	local ox = self.frameWidth * self.pivotX
	local oy = self.frameHeight * self.pivotY

	-- Apply flipX: negative scale for left-facing
	if self.flipX then
		sx = -sx
	end

	-- Round to nearest pixel for pixel-perfect rendering
	-- See graphics/functions/draw.md for signature: draw(drawable, x, y, r, sx, sy, ox, oy)
	love.graphics.draw(self.image, quad, math.floor(x + 0.5), math.floor(y + 0.5), 0, sx, sy, ox, oy)
end

return AnimatableSprite
