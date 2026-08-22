--- Image (optionally animated) drawn on top of the host sprite at a centre-relative offset.
--- Baked into a card-sized canvas and drawn through the parent's skew shader, so
--- it warps with the EXACT same perspective as the card (one skew source of
--- truth, matching the Label component) instead of skewing around its own centre.
---@class Image
---@field parent Sprite|nil
---@field type "image"
---@field image string|nil
---@field offsetX number
---@field offsetY number
---@field scale number
---@field skewWithParent boolean
---@field parallax number|nil px the image slides toward the cursor at full deflection (parallax depth cue)
---@field parallaxSmoothing number easing rate of the parallax offset (higher = snappier)
---@field bob number|nil px amplitude of the time-driven vertical bob (read from a tween)
---@field bobTween string|nil parent.tweens key the bob reads (default "imageBobY")
local Image = {}
Image.__index = Image

---@param data table {image, offsetX, offsetY, scale, skewWithParent, parallax, parallaxSmoothing, bob, bobTween}
---@return Image
function Image.new(data)
	return setmetatable({
		type = "image",
		image = data.image,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		scale = data.scale or 1,
		skewWithParent = data.skewWithParent ~= false,
		parallax = data.parallax,
		parallaxSmoothing = data.parallaxSmoothing or 10,
		bob = data.bob,
		bobTween = data.bobTween or "imageBobY",
	}, Image)
end

function Image:update(dt)
	-- Advance the source sprite's own animation via its public update(); the
	-- spritesheet component then cycles frames, which draw() re-bakes.
	if self._animated and self._sprite then
		self._sprite:update(dt)
	end
	if not self.parallax or not self.parent or not self.parent.shaderData then
		return
	end
	-- Ease toward the cursor-driven target so the slide is smooth (not a 1:1
	-- jump). dt-scaled so the feel is identical regardless of frame rate.
	local uc = self.parent.shaderData.u_cursor or { 0, 0 }
	local tx, ty = uc[1] * self.parallax, uc[2] * self.parallax
	local k = math.min(1, dt * self.parallaxSmoothing)
	self._parX = (self._parX or 0) + (tx - (self._parX or 0)) * k
	self._parY = (self._parY or 0) + (ty - (self._parY or 0)) * k
end

function Image:attach()
	if not self.image then
		return
	end
	local modPath = self.image:gsub("/", ".")
	local ok, spriteData = pcall(require, modPath)
	if not ok or not spriteData then
		return
	end
	local SpriteLoader = require("Source.Sprite.SpriteLoader")
	local pngPath = self.image .. ".png"
	local sprite = SpriteLoader.instantiate(spriteData, 0, 0, pngPath)
	if not sprite then
		return
	end
	local ss = sprite:findComponent("spritesheet")
	if not ss or not ss.image then
		return
	end
	self._ss = ss
	self._image = ss.image
	self._frameW = ss.frameWidth
	self._frameH = ss.frameHeight
	self._animated = not not ss.animations
	-- Owned source instance, driven via its public update() so an animated image
	-- actually cycles frames (no cross-component field reads).
	if self._animated then
		self._sprite = sprite
	end
end

---@param cx number card centre x (screen)
---@param cy number card centre y (screen)
---@param fw number card frame width
---@param fh number card frame height
---@return love.Canvas|nil
function Image:buildCanvas(cx, cy, fw, fh)
	if not self._image or not self._ss then
		return nil
	end
	local canvas = self._canvas
	if not canvas then
		canvas = love.graphics.newCanvas(fw, fh)
		canvas:setFilter("nearest", "nearest") -- match pixel-retro card sampling
	end
	local prev = love.graphics.getCanvas()
	love.graphics.setCanvas(canvas)
	love.graphics.push()
	love.graphics.origin()
	love.graphics.clear(0, 0, 0, 0)
	-- Canvas top-left maps to card top-left, so the image lands at the same
	-- centre-relative offset it would occupy live — only the skew is unified.
	love.graphics.translate(-(cx - fw * 0.5), -(cy - fh * 0.5))
	local dx = math.floor(cx + self.offsetX + 0.5)
	local dy = math.floor(cy + self.offsetY + 0.5)
	local quad = self._ss:_getQuad()
	if quad then
		love.graphics.draw(self._image, quad, dx, dy, 0, self.scale, self.scale, self._frameW * 0.5, self._frameH * 0.5)
	else
		love.graphics.draw(self._image, dx, dy, 0, self.scale, self.scale, self._frameW * 0.5, self._frameH * 0.5)
	end
	love.graphics.pop()
	love.graphics.setCanvas(prev)
	return canvas
end

function Image:draw(x, y)
	if not self._image or not self._ss then
		return
	end
	-- Base anchor stays pixel-perfect (card is pixel-art); only the parallax
	-- offset is sub-pixel so the slide is smooth and independent of the grid.
	local bx = math.floor(x + 0.5)
	local by = math.floor(y + 0.5)
	local fw = self.parent and self.parent.frameWidth or 64
	local fh = self.parent and self.parent.frameHeight or 104
	-- Re-bake only when the source frame changes (animated images) or first draw.
	local frame = self._animated and (self._ss:getAnimFrameIndex() or 1) or 1
	if not self._canvas or self._bakedFrame ~= frame then
		self._canvas = self:buildCanvas(bx, by, fw, fh)
		self._bakedFrame = frame
	end
	if not self._canvas then
		return
	end
	-- Time-driven bob (tween) stacks with the cursor parallax; both are just
	-- additive draw offsets, so they never fight or cancel each other.
	local bobY = 0
	if self.bob and self.parent and self.parent.tweens then
		local t = self.parent.tweens[self.bobTween]
		if t then
			bobY = t:getValue() * self.bob
		end
	end
	local dx = bx + (self._parX or 0)
	local dy = by + (self._parY or 0) + bobY
	local shader = (self.skewWithParent and self.parent and self.parent.shader) or nil
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(1, 1, 1, 1)
	if shader then
		love.graphics.setShader(shader)
	end
	love.graphics.draw(self._canvas, dx, dy, 0, 1, 1, fw * 0.5, fh * 0.5)
	if shader then
		love.graphics.setShader()
	end
	love.graphics.setColor(r, g, b, a)
end

return Image
