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
---@field tweens table<string, Tween> Active tweens by target name
local AnimatableSprite = {}
AnimatableSprite.__index = AnimatableSprite

local Tweens = require("Source.Tweens")

-- Creates animated sprite component from data definition.
-- Loads tween config from Assets/System/Tweens/flip.lua for modding support.
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
	-- Load tween config for flip animation; fallback to defaults if missing/corrupted
	self.flipTweenConfig = AnimatableSprite._loadFlipTweenConfig()
	self.tweens = {}
	self:_buildQuads(data.animations or {})
	return self
end

-- Loads flip tween configuration from data file. Returns default values on any error.
function AnimatableSprite._loadFlipTweenConfig()
	local configPath = "Assets.System.Tweens.flip"
	package.loaded[configPath] = nil
	local config = require(configPath)
	if type(config) ~= "table" then
		config = {}
	end
	return config
end

-- Triggers a tween on specified target property. Creates new tween or restarts existing.
-- Target follows TweenTarget pattern: "scale_x", "scale_y", "x", "y".
---@param target string Property name from TweenTarget enum
---@param from number Start value
---@param to number End value
---@param duration number Duration in seconds
---@param curve function Easing function
function AnimatableSprite:triggerTween(target, from, to, duration, curve)
	if not self.tweens[target] then
		self.tweens[target] = Tweens.create(target, from, to, duration, curve)
	end
	-- Reset and start/restart the tween
	local tween = self.tweens[target]
	tween.from = from
	tween.to = to
	tween.duration = duration
	tween.curve = curve
	tween:start()
end

-- Called when flipX changes direction. Triggers scale tweens for flip effect.
-- Scale tweens control absolute scale values; animation plays from "squash" to "normal" state.
function AnimatableSprite:OnFlip()
	-- Get tween config values (always same animation: squash → normal)
	local sxConfig = self.flipTweenConfig.scaleX or { from = 0.5, to = 1.0, duration = 0.3, curve = "back_out" }
	local syConfig = self.flipTweenConfig.scaleY or { from = 1.5, to = 1.0, duration = 0.3, curve = "back_out" }

	-- Resolve curve using Tweens.resolveCurve to support string or function
	local curveFunc = Tweens.resolveCurve(sxConfig.curve)

	-- Tween always plays from "squash" state to "normal" state
	self:triggerTween("scale_x", sxConfig.from, sxConfig.to, sxConfig.duration, curveFunc)
	-- Note: syConfig may have its own curve, check separately
	if syConfig.curve and syConfig.curve ~= sxConfig.curve then
		self:triggerTween("scale_y", syConfig.from, syConfig.to, syConfig.duration, Tweens.resolveCurve(syConfig.curve))
	else
		self:triggerTween("scale_y", syConfig.from, syConfig.to, syConfig.duration, curveFunc)
	end
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

-- Reloads tween config from data file. Safe to call during hot-reload.
-- Does not reset active tweens (values apply to next flip).
function AnimatableSprite:reloadTweenConfig()
	self.flipTweenConfig = AnimatableSprite._loadFlipTweenConfig()
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

	-- Apply flipX: negative scale for left-facing
	local ox = 0
	if self.flipX then
		sx = -sx
		-- OffsetX shifts quad origin for horizontal flip: full width to align flipped sprite at same X
		ox = self.frameWidth
	end

	love.graphics.draw(self.image, quad, x, y, 0, sx, sy, ox, 0)
end

return AnimatableSprite
