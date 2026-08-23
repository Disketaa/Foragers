local Path = require("Source.Helpers.Core.Path")
local SpriteFont = require("Source.Sprite.Components.SpriteFont")
local Pivot = require("Source.Helpers.Core.Pivot")
local TextParser = require("Source.Helpers.Core.TextParser")
local I18n = require("Source.Helpers.Core.I18n")

-- Active labels, for live language switching. Weak-KEYED so GC'd labels don't
-- accumulate. A single I18n listener re-resolves every live label on change.
local instances = setmetatable({}, { __mode = "k" })
local _listenerReady = false
local function ensureLanguageListener()
	if _listenerReady then return end
	_listenerReady = true
	I18n.onLanguageChange(function()
		for lbl in pairs(instances) do
			if lbl._rawText ~= nil then
				lbl:setText(TextParser.resolve(lbl._rawText))
			end
		end
	end)
end

--- Static text label rendered with an external sprite-font atlas (not the
--- parent's own spritesheet). Draws on top of the host sprite; offsets are in
--- canvas pixels from the sprite CENTRE (sprite.x/y is the centre for
--- centre-pivoted sprites). By default the label is baked into a card-sized
--- canvas and drawn through the parent's skew shader, so it warps with the
--- EXACT same perspective as the card: one skew source of truth, no separate
--- affine shear that can drift from / rotate against the card.
---@class Label
---@field parent Sprite|nil
---@field type "text"
---@field text string
---@field font string
---@field color table
---@field charSpacing number|nil
---@field offsetX number
---@field offsetY number
---@field horizontalAlign string
---@field verticalAlign string
---@field scale number
---@field skewWithParent boolean
---@field dropshadowColor table|nil @ dropshadow renders only when this is set
---@field maxWidth number|nil @ nil disables clip/scroll
---@field scrollSpeed number @ px/sec text travels while scrolling
---@field scrollPause number @ sec dwell at each scroll end
---@field scrollEdgePad number @ px overshoot so glyph ink reaches window edge
---@field _scrollT number @ accumulated scroll time
---@field _textW number|nil @ cached rendered width for overflow check
local Label = {}
Label.__index = Label

--- Default scroll tuning shared by every scrolling label.
Label.SCROLL_SPEED = 30 -- px/sec the text travels
Label.SCROLL_PAUSE = 0.6 -- sec dwell at each scroll end

---@param data table {text, font, color, charSpacing, offsetX, offsetY, horizontalAlign, verticalAlign, scale, dropshadowColor}
---@return Label
function Label.new(data)
	local self = setmetatable({
		type = "text",
		-- Keep the original translatable form so a live language switch can
		-- re-resolve this label (data.text is already resolved by ValueParser).
		_rawText = (data.__raw and data.__raw.text) or data.text or "",
		text = data.text or "",
		font = data.font or "Content.Assets.Sprites.UI.SpriteFonts.Tinylorder",
		color = data.color and { unpack(data.color) } or { 1, 1, 1, 1 },
		charSpacing = data.charSpacing,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		horizontalAlign = data.horizontalAlign or "center",
		verticalAlign = data.verticalAlign or "center",
		scale = data.scale or 1,
		dropshadowColor = data.dropshadowColor and { unpack(data.dropshadowColor) } or nil,
		skewWithParent = data.skewWithParent ~= false,
		maxWidth = data.maxWidth,
		scrollSpeed = data.scrollSpeed or Label.SCROLL_SPEED,
		scrollPause = data.scrollPause or Label.SCROLL_PAUSE,
		scrollEdgePad = data.scrollEdgePad or 1,
		_scrollT = 0,
		_textW = nil,
	}, Label)
	instances[self] = true
	ensureLanguageListener()
	return self
end

---@param dt number
function Label:update(dt)
	if self.maxWidth and self._textW and self._textW > self.maxWidth then
		self._scrollT = self._scrollT + dt
	end
end

--- Scroll position ping-pongs 0..range with a dwell at each end.
---@param range number total travel distance in rendered px
---@return number offset in rendered px (0..range)
function Label:scrollOffset(range)
	if range <= 0 then
		return 0
	end
	local moveDur = range / self.scrollSpeed
	local pause = self.scrollPause
	local cycle = (moveDur + pause) * 2
	local t = self._scrollT % cycle
	if t < pause then
		return 0
	elseif t < pause + moveDur then
		return (t - pause) / moveDur * range
	elseif t < pause + moveDur + pause then
		return range
	else
		local t2 = t - (pause * 2 + moveDur)
		return range - (t2 / moveDur) * range
	end
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

---@param cx number card centre x (screen)
---@param cy number card centre y (screen)
---@param fw number card frame width
---@param fh number card frame height
---@return love.Canvas|nil
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
	love.graphics.translate(-(cx - fw * 0.5), -(cy - fh * 0.5))
	local anchorX = math.floor(cx + self.offsetX + 0.5)
	local anchorY = math.floor(cy + self.offsetY + 0.5)
	local ox = Pivot.px(self._pivotX, self._frameW, "center")
	local ref = {
		image = self._image,
		quads = self._quads,
		charIndex = self._charIndex,
		charWidth = self._charWidth,
		charSpacing = self._charSpacing,
		frameW = self._frameW,
		frameH = self._frameH,
		pivotX = self._pivotX,
		pivotY = self._pivotY,
	}

	local baseX = anchorX + ox
	local textW = SpriteFont.measureText(ref, self.text, self._charSpacing)
	local renderedW = textW * self.scale
	self._textW = renderedW

	local drawAlign = self.horizontalAlign
	local drawX = baseX
	local clip = self.maxWidth and renderedW > self.maxWidth
	if clip then
		-- Clip window is centred on the label's natural centre (anchorX),
		-- so a scrolling label lines up with a non-scrolling one. Glyphs
		-- draw pivot-centred, so the visual box is offset by ox from drawX;
		-- shift the text (not the window) to sweep it through. A small
		-- overshoot (scrollEdgePad) lets glyph ink reach the window edge
		-- instead of leaving the frame's transparent padding as a gap.
		local range = renderedW - self.maxWidth
		local pad = self.scrollEdgePad
		local f = range > 0 and (self:scrollOffset(range) / range) or 0
		local scrollShift = (range * 0.5 - pad) - f * (range - 2 * pad)
		drawX = baseX + scrollShift
		-- Scissor is raw canvas pixels (unaffected by the translate above).
		local winLeft = anchorX - self.maxWidth * 0.5
		local canvasWinX = math.floor(winLeft - (cx - fw * 0.5) + 0.5)
		love.graphics.setScissor(canvasWinX, 0, math.ceil(self.maxWidth), fh)
	end

	local opts = {
		color = self.color,
		horizontalAlign = drawAlign,
		verticalAlign = self.verticalAlign,
		scale = self.scale,
	}
	if self.dropshadowColor then
		SpriteFont.drawText(ref, self.text, drawX + 1, anchorY + 1, {
			color = self.dropshadowColor,
			horizontalAlign = drawAlign,
			verticalAlign = self.verticalAlign,
			scale = self.scale,
		})
	end
	SpriteFont.drawText(ref, self.text, drawX, anchorY, opts)

	if clip then
		love.graphics.setScissor()
	end
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

	local scrolling = self.maxWidth and self._textW and self._textW > self.maxWidth
	if not self._canvas or scrolling then
		self._canvas = self:buildCanvas(math.floor(x + 0.5), math.floor(y + 0.5), fw, fh)
	end
	if not self._canvas then
		return
	end

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
