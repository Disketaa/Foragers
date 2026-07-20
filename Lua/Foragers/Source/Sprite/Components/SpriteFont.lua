local SpriteFont = {}
SpriteFont.__index = SpriteFont

-- LuaJIT (Lua 5.1) has no utf8 module; string ops are byte-based. The font
-- `chars` string contains multi-byte UTF-8 (Cyrillic), so we must iterate by
-- visual character, not byte, when building the char->cell index.
local function utf8Next(str, i)
	local n = #str
	if i > n then
		return nil
	end
	local b = str:byte(i)
	local len = 1
	if b >= 0x80 then
		if b < 0xC0 then
			len = 1 -- stray continuation byte: treat as 1 byte
		elseif b < 0xE0 then
			len = 2
		elseif b < 0xF0 then
			len = 3
		else
			len = 4
		end
	end
	return i + len, str:sub(i, i + len - 1)
end

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

	local vi = 0
	local i = 1
	while i <= #self.chars do
		local nextI, c = utf8Next(self.chars, i)
		self._charIndex[c] = vi + 1
		vi = vi + 1
		i = nextI
	end

	for _, entry in ipairs(self.spacing) do
		local w = entry[1]
		local chars = entry[2]
		local ci = 1
		while ci <= #chars do
			local nextCi, c = utf8Next(chars, ci)
			self._charWidth[c] = w
			ci = nextCi
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
