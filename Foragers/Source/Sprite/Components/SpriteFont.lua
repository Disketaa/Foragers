local SpriteFont = {}
SpriteFont.__index = SpriteFont

local Pivot = require("Source.Helpers.Pivot")

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

--- Shared char-by-char text renderer.
--- Built from the same pattern in SpriteFont, Counter, and TextEmitter.
---@param ref table {image, quads, charIndex, charWidth, charSpacing, frameW, frameH, pivotX, pivotY}
---@param text string
---@param x number
---@param y number
---@param opts table|nil {color=rgba, alpha, scale, hAlign, vAlign}
function SpriteFont.drawText(ref, text, x, y, opts)
	opts = opts or {}
	local image = ref.image
	local frameW = ref.frameW
	local frameH = ref.frameH
	local charSpacing = ref.charSpacing or 0
	local ox = Pivot.px(ref.pivotX, frameW, "center")
	local oy = Pivot.px(ref.pivotY, frameH, "center")
	local scale = opts.scale or 1

	local totalW
	if opts.hAlign then
		totalW = 0
		for i = 1, #text do
			local c = text:sub(i, i)
			totalW = totalW + (c == " " and frameW or (ref.charWidth[c] or frameW))
			if i < #text then
				totalW = totalW + charSpacing
			end
		end
	end

	local cx = x
	local cy = y
	if opts.hAlign == "center" then
		cx = cx - totalW / 2
	elseif opts.hAlign == "right" then
		cx = cx - totalW
	end
	if opts.vAlign == "top" then
		cy = cy + oy
	elseif opts.vAlign == "bottom" then
		cy = cy - (frameH - oy)
	end

	local pr, pg, pb, pa
	if opts.color or opts.alpha then
		pr, pg, pb, pa = love.graphics.getColor()
		local r, g, b, a = pr, pg, pb, pa
		if opts.color then
			r, g, b = opts.color[1], opts.color[2], opts.color[3]
			a = opts.color[4] or a
		end
		if opts.alpha then
			a = opts.alpha
		end
		love.graphics.setColor(r, g, b, a)
	end

	for i = 1, #text do
		local c = text:sub(i, i)
		if c == " " then
			cx = cx + frameW + charSpacing
		else
			local idx = ref.charIndex[c]
			if idx then
				local quad = ref.quads[idx]
				if quad then
					love.graphics.draw(image, quad, math.floor(cx + 0.5), math.floor(cy + 0.5), 0, scale, scale, ox, oy)
				end
			end
			cx = cx + (ref.charWidth[c] or frameW) + charSpacing
		end
	end

	if opts.color or opts.alpha then
		love.graphics.setColor(pr, pg, pb, pa)
	end
end

function SpriteFont:attach() end

function SpriteFont:update(dt) end

function SpriteFont:draw(x, y)
	if not self.parent or not self.chars then
		return
	end

	local spritesheet = self.parent:findComponent("spritesheet")
	if not spritesheet or not spritesheet.quads or not spritesheet.image then
		return
	end

	SpriteFont.drawText({
		image = spritesheet.image,
		quads = spritesheet.quads,
		charIndex = self._charIndex,
		charWidth = self._charWidth,
		charSpacing = self.charSpacing,
		frameW = spritesheet.frameWidth,
		frameH = spritesheet.frameHeight,
		pivotX = spritesheet.pivotX or "center",
		pivotY = spritesheet.pivotY or "center",
	}, self.text, x, y, { color = self.color })
end

return SpriteFont
