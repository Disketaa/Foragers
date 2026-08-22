local Font = require("Source.Sprite.Components.Font")

--- Static text label rendered with a TTF font. Draws on top of the host
--- sprite; offsets are in canvas pixels from the sprite CENTRE (sprite.x/y is
--- the centre for centre-pivoted sprites). By default the label is baked into a
--- card-sized canvas and drawn through the parent's skew shader, so it warps
--- with the EXACT same perspective as the card: one skew source of truth, no
--- separate affine shear that can drift from / rotate against the card.
---@class Label
---@field parent Sprite|nil
---@field type "text"
---@field text string
---@field font string
---@field fontSize number
---@field color table
---@field charSpacing number|nil
---@field offsetX number
---@field offsetY number
---@field horizontalAlign string
---@field verticalAlign string
---@field scale number
---@field skewWithParent boolean
---@field dropshadow boolean
---@field dropshadowColor table
local Label = {}
Label.__index = Label

---@param data table {text, font, fontSize, color, charSpacing, offsetX, offsetY, horizontalAlign, verticalAlign, scale, dropshadow, dropshadowColor}
---@return Label
function Label.new(data)
	return setmetatable({
		type = "text",
		text = data.text or "",
		font = data.font or "Content/Assets/Sprites/UI/Fonts/Tinylorder.ttf",
		fontSize = data.fontSize or Font.DEFAULT_SIZE,
		color = data.color and { unpack(data.color) } or { 1, 1, 1, 1 },
		charSpacing = data.charSpacing,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		horizontalAlign = data.horizontalAlign or "center",
		verticalAlign = data.verticalAlign or "center",
		scale = data.scale or 1,
		dropshadow = data.dropshadow or false,
		dropshadowColor = data.dropshadowColor and { unpack(data.dropshadowColor) } or { 0, 0, 0, 0.5 },
		skewWithParent = data.skewWithParent ~= false,
	}, Label)
end

function Label:attach()
	self._font = Font.load(self.font, self.fontSize)
end

---@param text string
function Label:setText(text)
	self.text = text or ""
	self._canvas = nil
end

--@param cx number card centre x (screen)
--@param cy number card centre y (screen)
--@param fw number card frame width
--@param fh number card frame height
--@return love.Canvas|nil
function Label:buildCanvas(cx, cy, fw, fh)
	if not self._font then
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
	local ref = { font = self._font, charSpacing = self.charSpacing or 0 }
	local opts = {
		color = self.color,
		horizontalAlign = self.horizontalAlign,
		verticalAlign = self.verticalAlign,
		scale = self.scale,
	}
	if self.dropshadow then
		Font.drawText(ref, self.text, anchorX + 1, anchorY + 1, {
			color = self.dropshadowColor,
			horizontalAlign = self.horizontalAlign,
			verticalAlign = self.verticalAlign,
			scale = self.scale,
		})
	end
	Font.drawText(ref, self.text, anchorX, anchorY, opts)
	love.graphics.pop()
	love.graphics.setCanvas(prev)
	return canvas
end

function Label:draw(x, y)
	if not self._font then
		return
	end
	if #self.text == 0 then
		return
	end

	local fw = self.parent and self.parent.frameWidth or 64
	local fh = self.parent and self.parent.frameHeight or 104

	if not self._canvas then
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
