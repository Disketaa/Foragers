local Log = require("Source.Helpers.Core.Log")

local Font = {}
Font.__index = Font

--- Default raster size (px). Matches the old 8x8 spritefont cell height so
--- existing layout/positions stay close. Tune per-label via `fontSize` data.
Font.DEFAULT_SIZE = 8

local cache = {}

--- `path` is a real .ttf file path (not a module path), e.g.
--- "Content/Assets/Sprites/UI/Fonts/Tinylorder.ttf".
---@param path string
---@param size number|nil
---@return love.Font|nil
function Font.load(path, size)
	size = size or Font.DEFAULT_SIZE
	local key = path .. "@" .. size
	if cache[key] ~= nil then
		return cache[key] or nil
	end
	local ok, f = pcall(love.graphics.newFont, path, size)
	if not ok or not f then
		cache[key] = false
		Log.error("Font", "failed to load font '%s' (size %s): %s", path, tostring(size), tostring(f))
		return nil
	end
	-- Pixel-retro: keep glyph edges crisp, no bilinear smoothing on the raster.
	f:setFilter("nearest", "nearest")
	cache[key] = f
	return f
end

--- Count visual UTF-8 characters (LuaJIT 5.1 has no utf8 module).
---@param str string
---@return integer
local function utf8Len(str)
	local n = 0
	local i = 1
	local len = #str
	while i <= len do
		n = n + 1
		local b = str:byte(i)
		if b >= 0x80 then
			if b < 0xC0 then i = i + 1
			elseif b < 0xE0 then i = i + 2
			elseif b < 0xF0 then i = i + 3
			else i = i + 4 end
		else
			i = i + 1
		end
	end
	return n
end

--- Iterate visual UTF-8 characters (codepoints) of `str`, yielding
--- (char, charWidth). Multi-byte glyphs land as a single char.
---@param font love.Font
---@param str string
---@return function
local function eachChar(font, str)
	local i = 1
	local len = #str
	return function()
		if i > len then
			return nil
		end
		local b = str:byte(i)
		local n = 1
		if b >= 0x80 then
			if b < 0xC0 then n = 1
			elseif b < 0xE0 then n = 2
			elseif b < 0xF0 then n = 3
			else n = 4 end
		end
		local c = str:sub(i, i + n - 1)
		i = i + n
		return c, font:getWidth(c)
	end
end

---@param ref table {font=love.Font, charSpacing=number|nil}
---@param text string
---@param x number
---@param y number
---@param opts table|nil {color=rgba, alpha, scale, horizontalAlign, verticalAlign}
function Font.drawText(ref, text, x, y, opts)
	opts = opts or {}
	local font = ref and ref.font
	if not font or not text or #text == 0 then
		return
	end
	local scale = opts.scale or 1
	local charSpacing = ref.charSpacing or 0

	local prevFont = love.graphics.getFont()
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

	love.graphics.setFont(font)

	local n = utf8Len(text)
	local totalW = (font:getWidth(text) + charSpacing * math.max(0, n - 1)) * scale
	local totalH = font:getHeight() * scale

	local cx = x
	local cy = y
	if opts.horizontalAlign == "center" then
		cx = cx - totalW / 2
	elseif opts.horizontalAlign == "right" then
		cx = cx - totalW
	end
	if opts.verticalAlign == "center" then
		cy = cy - totalH / 2
	elseif opts.verticalAlign == "bottom" then
		cy = cy - totalH
	end

	if charSpacing == 0 then
		-- Fast path: single print handles \n natively and matches totalW exactly.
		love.graphics.print(text, math.floor(cx + 0.5), math.floor(cy + 0.5), 0, scale, scale)
	else
		-- Per-char draw so charSpacing actually applies and alignment stays true.
		local px = math.floor(cx + 0.5)
		local py = math.floor(cy + 0.5)
		local lineH = math.floor(font:getHeight() * scale + 0.5)
		for c, w in eachChar(font, text) do
			if c == "\n" then
				px = math.floor(cx + 0.5)
				py = py + lineH
			else
				love.graphics.print(c, px, py, 0, scale, scale)
				px = px + math.floor((w + charSpacing) * scale + 0.5)
			end
		end
	end

	if opts.color or opts.alpha then
		love.graphics.setColor(pr, pg, pb, pa)
	end
	if prevFont then
		love.graphics.setFont(prevFont)
	end
end

return Font
