local SpriteFont = {}
SpriteFont.__index = SpriteFont

local Pivot = require("Source.Helpers.Core.Pivot")
local Log = require("Source.Helpers.Core.Log")

-- LuaJIT (Lua 5.1) has no utf8 module; string ops are byte-based. The font
-- `chars` string contains multi-byte UTF-8 (Cyrillic), so we must iterate by
-- visual character, not byte, when building the char->cell index.
---@param str string
---@param i integer
---@return integer, string
local function utf8Next(str, i)
	local n = #str
	if i > n then
		return i, ""
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

--- Returns the glyph's ink bounding columns and pixel width, or 0 if the quad
--- is fully transparent. Uses a > 0 as the ink test: correct for hard-alpha
--- pixel fonts, where no semi-transparent fringe exists.
---@param imageData love.ImageData
---@param quad love.Quad
---@param frameW integer
---@param frameH integer
---@return integer width rightmost ink column + 1 (0 if empty)
---@return integer inkLeft leftmost ink column
---@return integer inkRight rightmost ink column
local function measureGlyphWidth(imageData, quad, frameW, frameH)
	local qx, qy = quad:getViewport()
	local minX, maxX = frameW, -1
	for x = frameW - 1, 0, -1 do
		for y = 0, frameH - 1 do
			local _, _, _, a = imageData:getPixel(qx + x, qy + y)
			if a > 0 then
				if x > maxX then maxX = x end
				if x < minX then minX = x end
			end
		end
	end
	if maxX < 0 then return 0, 0, 0 end
	return maxX + 1, minX, maxX
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
		autoTrim = data.autoTrim or false,
		color = data.color and { unpack(data.color) } or { 0, 0, 0, 1 },
		_charIndex = {},
		_charWidth = {},
		_charInkLeft = {},
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

--- Measure rendered width of text (chars + spacing), no draw.
---@param ref table {frameW, charWidth, charSpacing}
---@param text string
---@param charSpacing number|nil
---@return number width in font frame units (unscaled)
function SpriteFont.measureText(ref, text, charSpacing)
	charSpacing = charSpacing or ref.charSpacing or 0
	local w = 0
	local i = 1
	local n = #text
	-- Advance must match drawText exactly: every glyph advances by
	-- (charWidth + charSpacing), so charSpacing is added n times (including
	-- the trailing gap). Adding it only (n-1) times overcounts the real
	-- rendered width by -charSpacing, which falsely trips maxWidth overflow
	-- (and the ping-pong scroll) on text that visually fits.
	while i <= n do
		local nextI, c = utf8Next(text, i)
		w = w + (ref.charWidth[c] or ref.frameW)
		w = w + charSpacing
		i = nextI
	end
	return w
end

--- Single shared text renderer for SpriteFont, Counter, and TextEmitter so
--- glyph alignment and styling stay consistent across all three.
---@param ref table {image, quads, charIndex, charWidth, charSpacing, frameW, frameH, pivotX, pivotY}
---@param text string
---@param x number
---@param y number
---@param opts table|nil {color=rgba, alpha, scale, horizontalAlign, verticalAlign}
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
	if opts.horizontalAlign then
		totalW = SpriteFont.measureText(ref, text, charSpacing)
	end

	local cx = x
	local cy = y
	if opts.horizontalAlign == "center" then
		-- totalW includes trailing charSpacing after the last glyph (needed
		-- for maxWidth overflow checks), but that phantom gap shifts the ink
		-- block right by charSpacing/2.  Subtract it so the ink – not the
		-- advance block – is centred on x.
		cx = cx - totalW / 2 - charSpacing / 2
	elseif opts.horizontalAlign == "right" then
		cx = cx - totalW
	end
	if opts.verticalAlign == "top" then
		cy = cy + oy
	elseif opts.verticalAlign == "bottom" then
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

	local i = 1
	local n = #text
	while i <= n do
		local nextI, c = utf8Next(text, i)
		if c ~= " " then
			local idx = ref.charIndex[c]
			if idx then
				local quad = ref.quads[idx]
				if quad then
					love.graphics.draw(image, quad, math.floor(cx + 0.5), math.floor(cy + 0.5), 0, scale, scale, ox, oy)
				end
			end
		end
		cx = cx + (ref.charWidth[c] or frameW) + charSpacing
		i = nextI
	end

	if opts.color or opts.alpha then
		love.graphics.setColor(pr, pg, pb, pa)
	end
end

--- Derives per-glyph widths from the spritesheet pixels. Requires the sibling
--- "spritesheet" component to already be attached to self.parent (it reads
--- ss.image / ss.quads). Runs only when data.autoTrim is true; hand-tuned
--- data.spacing entries take precedence (see the loop below).
function SpriteFont:attach()
	if not self.autoTrim then return end
	local ss = self.parent and self.parent:findComponent("spritesheet")
	if not ss or not ss.image or not ss.quads then return end
	local imageData = ss._imageData
	if not imageData then
		Log.write("SpriteFont", "autoTrim skipped: _imageData not available (GPU-side texture, no ImageData)")
		return
	end
	-- charWidth = gw - 1 so advance (charWidth + charSpacing) matches ink edge.
	local offset = -1
	for c, idx in pairs(self._charIndex) do
		if not self._charWidth[c] then -- data.spacing overrides win
			local quad = ss.quads[idx]
			if quad then
				local gw, inkLeft = measureGlyphWidth(imageData, quad, ss.frameWidth, ss.frameHeight)
				if gw > 0 then
					self._charWidth[c] = gw + offset
					self._charInkLeft[c] = inkLeft
				else
					Log.write("SpriteFont", "autoTrim: char '%s' measured 0 width; falling back to frameWidth", c)
				end
			end
		end
	end
end

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