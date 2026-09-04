local Log = require("Source.Helpers.Core.Log")
local ShaderLoader = require("Source.Helpers.Graphics.ShaderLoader")

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
---@field drawBehind boolean @ drawn in the sprite's first component pass, behind normal/onTop components
---@field parallax number|nil px the image slides toward the cursor at full deflection (parallax depth cue)
---@field parallaxSmoothing number easing rate of the parallax offset (higher = snappier)
---@field bob number|nil px amplitude of the vertical bob
---@field shader string|table|nil shader name or list of names to apply when baking this image to its canvas
local Image = {}
Image.__index = Image

---@param data table {image, offsetX, offsetY, scale, skewWithParent, parallax, parallaxSmoothing, bob, shader}
---@return Image
function Image.new(data)
	return setmetatable({
		type = "image",
		id = data.id,
		image = data.image,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		scale = data.scale or 1,
		skewWithParent = data.skewWithParent ~= false,
		drawBehind = data.layer == "below",
		parallax = data.parallax,
		parallaxSmoothing = data.parallaxSmoothing or 10,
		bob = data.bob,
		shader = data.shader,
		_bobT = 0,
		_shader = nil,
	}, Image)
end

function Image:update(dt)
	-- Advance the source sprite's own animation via its public update(); the
	-- spritesheet component then cycles frames, which draw() re-bakes.
	if self._animated and self._sprite then
		self._sprite:update(dt)
	end
	if self.bob then
		self._bobT = self._bobT + dt
	end
	if not self.parallax or not self.parent then
		return
	end
	-- Drive parallax from the card's skew angle so inner images lag behind the
	-- card's rotation, creating a depth cue. Falls back to {0,0} when unselected
	-- (no skewAngle tween). parallaxSmoothing eases the slide for the delay feel.
	local skew = self.parent.tweens and self.parent.tweens.skewAngle
	local uc = { 0, 0 }
	if skew then
		local a = skew:getValue()
		uc[1] = math.cos(a)
		uc[2] = math.sin(a)
	end
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
		Log.write("Image", "attach: failed to load '%s'%s", self.image, ok and "" or " (" .. tostring(spriteData) .. ")")
		return
	end
	-- Resolve extends so frames/backgrounds using inheritance get frameWidth
	-- and spritesheet component before instantiate.
	if spriteData.extends then
		local Merge = require("Source.Helpers.Core.Merge")
		spriteData = Merge.resolveExtends(spriteData)
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
	if self.shader then
		local names = type(self.shader) == "string" and { self.shader } or self.shader
		local loaded = ShaderLoader.compose(names)
		if loaded then
			self._shader = loaded.shader
			-- Seed defaults from the composed module uniforms so the GPU state
			-- matches Lua defaults before any tier uniforms are sent.
			for u, v in pairs(loaded.uniforms or {}) do
				self._shader:send(u, v)
			end
		end
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
	local hadImageShader = false
	if self._shader and self.parent and self.parent.shaderData then
		hadImageShader = true
		love.graphics.setShader(self._shader)
		-- Forward only uniforms that exist on this image's shader (e.g. u_tier_*
		-- from Palette), skipping parent sprite uniforms like u_brightness.
		for u, v in pairs(self.parent.shaderData) do
			if u:match("^u_") and self._shader:hasUniform(u) then
				self._shader:send(u, v)
			end
		end
	end
	if quad then
		love.graphics.draw(self._image, quad, dx, dy, 0, self.scale, self.scale, self._frameW * 0.5, self._frameH * 0.5)
	else
		love.graphics.draw(self._image, dx, dy, 0, self.scale, self.scale, self._frameW * 0.5, self._frameH * 0.5)
	end
	if hadImageShader then
		love.graphics.setShader()
	end
	love.graphics.pop()
	love.graphics.setCanvas(prev)
	return canvas
end

--- Select which spritesheet frame the emblem shows (level tier). Clears the
--- baked canvas so draw() re-bakes with the new quad.
function Image:setFrame(index)
	if not self._ss then
		return
	end
	self._ss._currentIndex = index
	self._canvas = nil
end

function Image:draw(x, y)
	if not self._image or not self._ss then
		return
	end
	-- Base anchor stays pixel-perfect (card is pixel-art); only the parallax,
	-- bob, and tween offsets are sub-pixel so motion is smooth and independent
	-- of the pixel grid.
	local tx = self.parent and self.parent.tweens and self.parent.tweens.x and self.parent.tweens.x:getValue() or 0
	local ty = self.parent and self.parent.tweens and self.parent.tweens.y and self.parent.tweens.y:getValue() or 0
	local bx = math.floor(x - tx + 0.5)
	local by = math.floor(y - ty + 0.5)
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
	-- Bob and parallax are additive draw offsets, so they never fight or cancel.
	local bobY = 0
	if self.bob then
		bobY = -math.cos(self._bobT * (math.pi * 0.5)) * self.bob
	end
	local dx = bx + (self._parX or 0) + tx
	local dy = by + (self._parY or 0) + bobY + ty
	local hadShader = self.parent and self.parent.applyShader and self.parent:applyShader() or false
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self._canvas, dx, dy, 0, 1, 1, fw * 0.5, fh * 0.5)
	if hadShader then
		love.graphics.setShader()
	end
	love.graphics.setColor(r, g, b, a)
end

return Image