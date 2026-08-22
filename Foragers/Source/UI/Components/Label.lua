local Path = require("Source.Helpers.Core.Path")
local SpriteFont = require("Source.Sprite.Components.SpriteFont")
local Pivot = require("Source.Helpers.Core.Pivot")

--- Static text label rendered with an external sprite-font atlas (not the
--- parent's own spritesheet). Draws on top of the host sprite; offsets are in
--- canvas pixels from the sprite CENTRE (sprite.x/y is the centre for
--- centre-pivoted sprites). By default the label is baked into a card-sized
--- canvas and drawn through the parent's skew shader, so it warps with the
--- EXACT same perspective as the card: one skew source of truth, no separate
--- affine shear that can drift from / rotate against the card.
---@class Label
local Label = {}
Label.__index = Label

---@param data table {text, font, color, charSpacing, offsetX, offsetY, horizontalAlign, verticalAlign, scale}
---@return Label
function Label.new(data)
	return setmetatable({
		type = "text",
		text = data.text or "",
		font = data.font or "Content.Assets.Sprites.UI.SpriteFonts.Tinylorder",
		color = data.color and { unpack(data.color) } or { 1, 1, 1, 1 },
		charSpacing = data.charSpacing,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		horizontalAlign = data.horizontalAlign or "center",
		verticalAlign = data.verticalAlign or "center",
		scale = data.scale or 1,
		-- Warp the label with the parent's perspective skew shader (e.g.
		-- CursorSkew) so it tilts with the card instead of staying flat.
		skewWithParent = data.skewWithParent ~= false,
	}, Label)
end

function Label:attach()
	local luaPath = Path.moduleToPath(self.font)
	local pngPath = luaPath .. ".png"
	local ok, fontData = pcall(require, self.font)
	if not ok or not fontData then
		return
	end
	local SpriteLoader = require("Source.Sprite.SpriteLoader")
	local sprite = SpriteLoader.instantiate(fontData, 0, 0, pngPath)
	if not sprite then
		return
	end
	local ss = sprite:findComponent("spritesheet")
	local sf = sprite:findComponent("spritefont")
	if not ss or not sf then
		return
	end
	self._image = ss.image
	self._quads = ss.quads
	self._charIndex = sf._charIndex
	self._charWidth = sf._charWidth
	self._charSpacing = self.charSpacing or sf.charSpacing
	self._frameW = ss.frameWidth
	self._frameH = ss.frameHeight
	self._pivotX = ss.pivotX or "center"
	self._pivotY = ss.pivotY or "center"
end

---@param text string
function Label:setText(text)
	self.text = text or ""
	self._canvas = nil
end

-- Bake the label into a card-sized canvas so it shares the card's UV space
-- (and therefore the card's skew shader) exactly. Canvas top-left maps to the
-- card's top-left; text is drawn at the same centre-relative coords it would
-- occupy live, so position is unchanged — only the skew mechanism is unified.
--@param cx number card centre x (screen)
--@param cy number card centre y (screen)
--@param fw number card frame width
--@param fh number card frame height
--@return Canvas|nil
function Label:buildCanvas(cx, cy, fw, fh)
	if not (self._image and self._quads and self._charIndex) then
		return nil
	end
	local canvas = love.graphics.newCanvas(fw, fh)
	canvas:setFilter("nearest", "nearest") -- match pixel-retro card sampling
	local prev = love.graphics.getCanvas()
	love.graphics.setCanvas(canvas)
	love.graphics.push()
	love.graphics.origin()
	love.graphics.clear(0, 0, 0, 0)
	-- Shift screen-space anchor into canvas space (canvas top-left == card top-left).
	love.graphics.translate(-(cx - fw * 0.5), -(cy - fh * 0.5))
	local anchorX = math.floor(cx + self.offsetX + 0.5)
	local anchorY = math.floor(cy + self.offsetY + 0.5)
	local ox = Pivot.px(self._pivotX, self._frameW, "center")
	SpriteFont.drawText(
		{
			image = self._image,
			quads = self._quads,
			charIndex = self._charIndex,
			charWidth = self._charWidth,
			charSpacing = self._charSpacing,
			frameW = self._frameW,
			frameH = self._frameH,
			pivotX = self._pivotX,
			pivotY = self._pivotY,
		},
		self.text,
		anchorX + ox,
		anchorY,
		{
			color = self.color,
			horizontalAlign = self.horizontalAlign,
			verticalAlign = self.verticalAlign,
			scale = self.scale,
		}
	)
	love.graphics.pop()
	love.graphics.setCanvas(prev)
	return canvas
end

function Label:draw(x, y)
	if not self._image or not self._quads or not self._charIndex then
		return
	end
	if #self.text == 0 then
		return
	end

	local fw = self.parent and self.parent.frameWidth or self._frameW or 64
	local fh = self.parent and self.parent.frameHeight or self._frameH or 104

	if not self._canvas then
		self._canvas = self:buildCanvas(math.floor(x + 0.5), math.floor(y + 0.5), fw, fh)
	end
	if not self._canvas then
		return
	end

	-- Draw exactly like the card: centred at (x,y) with the same pivot, through
	-- the same skew shader. uv 0.5 == card centre for both, so they warp as one.
	local shader = (self.skewWithParent and self.parent and self.parent.shader) or nil
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(1, 1, 1, 1)
	if shader then
		love.graphics.setShader(shader)
	end
	love.graphics.draw(self._canvas, math.floor(x + 0.5), math.floor(y + 0.5), 0, 1, 1, fw * 0.5, fh * 0.5)
	if shader then
		love.graphics.setShader()
	end
	love.graphics.setColor(r, g, b, a)
end

return Label
