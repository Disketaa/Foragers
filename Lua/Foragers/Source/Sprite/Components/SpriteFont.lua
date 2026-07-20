local SpriteFont = {}
SpriteFont.__index = SpriteFont

function SpriteFont.new(data)
	if not data or not data.chars then
		return setmetatable({ type = "spritefont", text = "" }, SpriteFont)
	end

	local self = setmetatable({
		type = "spritefont",
		text = data.text or "",
		chars = data.chars,
		spacing = data.spacing or {},
		charSpacing = data.charSpacing or 0,
		color = data.color and { unpack(data.color) } or { 0, 0, 0, 1 },
		_charIndex = {},
		_charWidth = {},
	}, SpriteFont)

	for i = 1, #self.chars do
		local c = self.chars:sub(i, i)
		self._charIndex[c] = i
	end

	for _, entry in ipairs(self.spacing) do
		local w = entry[1]
		local chars = entry[2]
		for i = 1, #chars do
			self._charWidth[chars:sub(i, i)] = w
		end
	end

	return self
end

function SpriteFont:attach() end

function SpriteFont:update(dt) end

function SpriteFont:draw(x, y)
	if not self.parent or not self.chars then
		return
	end

	local spritesheet
	for _, comp in ipairs(self.parent.components) do
		if comp.type == "spritesheet" and comp.quads and comp.image then
			spritesheet = comp
			break
		end
	end
	if not spritesheet then
		return
	end

	local image = spritesheet.image
	local frameW = spritesheet.frameWidth
	local frameH = spritesheet.frameHeight
	local pivotX = spritesheet.pivotX or 0
	local pivotY = spritesheet.pivotY or 0
	local ox = frameW * pivotX
	local oy = frameH * pivotY

	local col = self.color
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(col[1], col[2], col[3], col[4] or 1)

	local cx = x
	local cy = y

	for i = 1, #self.text do
		local c = self.text:sub(i, i)
		if c == " " then
			cx = cx + frameW + self.charSpacing
		else
			local idx = self._charIndex[c]
			if idx then
				local quad = spritesheet.quads[idx]
				if quad then
					love.graphics.draw(image, quad, math.floor(cx + 0.5), math.floor(cy + 0.5), 0, 1, 1, ox, oy)
				end
			end
			local charW = self._charWidth[c] or frameW
			cx = cx + charW + self.charSpacing
		end
	end

	love.graphics.setColor(r, g, b, a)
end

return SpriteFont
