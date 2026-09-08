local Path = require("Source.Helpers.Core.Path")
local SpriteFont = require("Source.Sprite.Components.SpriteFont")
local Pivot = require("Source.Helpers.Core.Pivot")
local TextParser = require("Source.Helpers.Core.TextParser")
local I18n = require("Source.Helpers.Core.I18n")

-- Weak-KEYED so GC'd labels don't accumulate.
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
---@field tierColors table|nil @ per-tier level text colors, indexed by emblem tier (1..5); consumed by CardSelect
---@field maxWidth number|nil @ nil disables clip/scroll
---@field maxHeight number|nil @ nil disables height clip; enables word-wrap when set
---@field scrollSpeed number @ px/sec text travels while scrolling
---@field scrollPause number @ sec dwell at each scroll end
---@field scrollEdgePad number @ px overshoot so glyph ink reaches window edge
---@field _scrollT number @ accumulated scroll time
---@field _textW number|nil @ cached rendered width for overflow check
---@field _textH number|nil @ cached rendered height for multiline check
local Label = {}
Label.__index = Label

Label.SCROLL_SPEED = 50
Label.SCROLL_PAUSE = 1

---@param data table {text, font, color, charSpacing, offsetX, offsetY, horizontalAlign, verticalAlign, scale, dropshadowColor}
---@return Label
function Label.new(data)
	local self = setmetatable({
		type = "text",
		id = data.id,
		-- Keep the original translatable form so a live language switch can
		-- re-resolve this label (data.text is already resolved by ValueParser).
		_rawText = (data.__raw and data.__raw.text) or data.text or "",
		text = data.text or "",
		font = data.font or "Content.Assets.Sprites.UI.SpriteFonts.Tinylorder",
		color = data.color and { unpack(data.color) } or { 1, 1, 1, 1 },
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		horizontalAlign = data.horizontalAlign or "center",
		verticalAlign = data.verticalAlign or "center",
		scale = data.scale or 1,
		dropshadowColor = data.dropshadowColor and { unpack(data.dropshadowColor) } or nil,
		skewWithParent = data.skewWithParent ~= false,
		maxWidth = data.maxWidth,
		maxHeight = data.maxHeight,
		scrollSpeed = data.scrollSpeed or Label.SCROLL_SPEED,
		scrollPause = data.scrollPause or Label.SCROLL_PAUSE,
		scrollEdgePad = data.scrollEdgePad or 1,
		charSpacing = data.charSpacing,
		_scrollT = 0,
		_textW = nil,
		_textH = nil,
		tierColors = data.tierColors,
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

---@param text string
---@param defaultColor table
---@return table segments @ {# {text, color}}
---@return table finalColor @ color state at end of text
function Label:parseColors(text, defaultColor)
	local segments = {}
	local currentColor = defaultColor or self.color or { 1, 1, 1, 1 }
	local pos = 1
	local len = #text
	while pos <= len do
		local char = text:sub(pos, pos)
		if char == "#" then
			if pos < len then
				local nextChar = text:sub(pos + 1, pos + 1)
			if nextChar == "#" then
				table.insert(segments, { text = "#", color = currentColor })
				pos = pos + 2
			else
			local start = pos + 1
			local match = text:match("^([%w_]+)", start)
			if match then
				-- Try longest prefix that is a known palette name or exact reset.
				local resolved = nil
			for i = #match, 1, -1 do
				local candidate = match:sub(1, i)
				if candidate == "r" then
						resolved = { reset = true }
						break
					end
					local palette = require("Content.Assets.Palettes.Text")
					if palette[candidate] then
						resolved = { color = palette[candidate], len = i }
						break
					end
			end
			if resolved and resolved.reset then
					currentColor = self.color or { 1, 1, 1, 1 }
					pos = start + 1
				elseif resolved and resolved.color then
					currentColor = resolved.color
					pos = start + resolved.len
				else
					local hex = text:sub(start, start + 5)
					if #hex == 6 and hex:match("^%x%x%x%x%x%x$") then
						local r = tonumber(hex:sub(1, 2), 16) / 255
						local g = tonumber(hex:sub(3, 4), 16) / 255
						local b = tonumber(hex:sub(5, 6), 16) / 255
						currentColor = { r, g, b, 1 }
						pos = start + 6
					else
						table.insert(segments, { text = "#", color = currentColor })
						pos = pos + 1
					end
				end
			else
				table.insert(segments, { text = "#", color = currentColor })
				pos = pos + 1
			end
			end
			else
				table.insert(segments, { text = "#", color = currentColor })
				pos = pos + 1
			end
		else
			local start = pos
			while pos <= len and text:sub(pos, pos) ~= "#" do
				pos = pos + 1
			end
			local chunk = text:sub(start, pos - 1)
			if #chunk > 0 then
				table.insert(segments, { text = chunk, color = currentColor })
			end
		end
	end
	return segments, currentColor
end

---@param text string
---@param maxWidth number|nil nil disables wrapping
---@param ref table font ref with measureText
---@param charSpacing number
---@return table lines @ {# {text, width}}
---@return number totalH @ total height in frame units (unscaled)
function Label:wrapText(text, maxWidth, ref, charSpacing)
	local lines = {}
	if not text or text == "" or not maxWidth then
		return lines, 0
	end

	local paragraphs = {}
	for paragraph in (text .. "\n"):gmatch("(.-)\n") do
		table.insert(paragraphs, paragraph)
	end

	for _, paragraph in ipairs(paragraphs) do
		local words = {}
		for word in paragraph:gmatch("%S+") do
			table.insert(words, word)
		end
		if #words == 0 then
			table.insert(lines, { text = "", width = 0 })
		else
			local currentLine = ""
			local currentWidth = 0
			for i, word in ipairs(words) do
				local trailingSpace = i < #words and " " or ""
				local wordWithSpace = word .. trailingSpace
				local wordWidth = SpriteFont.measureText(ref, wordWithSpace, charSpacing)
				if currentWidth + wordWidth <= maxWidth then
					currentLine = currentLine .. wordWithSpace
					currentWidth = currentWidth + wordWidth
				else
					if currentLine ~= "" then
						table.insert(lines, { text = currentLine, width = currentWidth })
					end
					currentLine = word .. " "
					currentWidth = SpriteFont.measureText(ref, word .. " ", charSpacing)
				end
			end
			if currentLine ~= "" then
				table.insert(lines, { text = currentLine, width = currentWidth })
			end
		end
	end

	local totalH = #lines * ref.frameH
	return lines, totalH
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

---@param color table {r, g, b, a}
function Label:setColor(color)
	if not color then
		return
	end
	self.color = { unpack(color) }
	-- Text is baked into a canvas; clear it so draw() re-bakes with the new color.
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

	if self.maxHeight then
		local maxH = self.maxHeight / self.scale
		local lines, totalH = self:wrapText(self.text, self.maxWidth, ref, self._charSpacing)
		self._textH = totalH * self.scale

		local lineH = ref.frameH * self.scale
		if self.verticalAlign == "center" then
			anchorY = anchorY - (totalH - ref.frameH) * 0.5
		elseif self.verticalAlign == "bottom" then
			anchorY = anchorY - (totalH - ref.frameH)
		end

		local visibleLines = 0
		if maxH > 0 and totalH > maxH then
			visibleLines = math.floor(maxH / ref.frameH)
			local winTop = anchorY - ref.frameH * 0.5 * self.scale
			local canvasWinY = math.floor(winTop - (cy - fh * 0.5) + 0.5)
			love.graphics.setScissor(0, canvasWinY, fw, maxH)
		end

		local drawY = anchorY
		local persistentColor = self.color
		for i, line in ipairs(lines) do
			if visibleLines > 0 and i > visibleLines then
				break
			end

			local coloredSegments, lineEndColor = self:parseColors(line.text, persistentColor)
			persistentColor = lineEndColor
			local totalW = 0
			for _, seg in ipairs(coloredSegments) do
				totalW = totalW + SpriteFont.measureText(ref, seg.text, self._charSpacing)
			end
			totalW = totalW * self.scale
			local segX = baseX - totalW * 0.5 - (self._charSpacing * self.scale) * 0.5
			for _, seg in ipairs(coloredSegments) do
				local color = seg.color or self.color
				if self.dropshadowColor then
					SpriteFont.drawText(ref, seg.text, segX + 1, drawY + 1, {
						color = self.dropshadowColor,
						horizontalAlign = "left",
						verticalAlign = "center",
						scale = self.scale,
					})
				end
				SpriteFont.drawText(ref, seg.text, segX, drawY, {
					color = color,
					horizontalAlign = "left",
					verticalAlign = "center",
					scale = self.scale,
				})
				segX = segX + SpriteFont.measureText(ref, seg.text, self._charSpacing) * self.scale
			end
			drawY = drawY + lineH
		end

		love.graphics.setScissor()
	else
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

		local coloredSegments, _ = self:parseColors(self.text, self.color)
		local totalW = 0
		for _, seg in ipairs(coloredSegments) do
			totalW = totalW + SpriteFont.measureText(ref, seg.text, self._charSpacing)
		end
		totalW = totalW * self.scale
		local segX = drawX - totalW * 0.5 - (self._charSpacing * self.scale) * 0.5
		for _, seg in ipairs(coloredSegments) do
			local color = seg.color or self.color
			if self.dropshadowColor then
				SpriteFont.drawText(ref, seg.text, segX + 1, anchorY + 1, {
					color = self.dropshadowColor,
					horizontalAlign = "left",
					verticalAlign = self.verticalAlign,
					scale = self.scale,
				})
			end
			SpriteFont.drawText(ref, seg.text, segX, anchorY, {
				color = color,
				horizontalAlign = "left",
				verticalAlign = self.verticalAlign,
				scale = self.scale,
			})
			segX = segX + SpriteFont.measureText(ref, seg.text, self._charSpacing) * self.scale
		end

		if clip then
			love.graphics.setScissor()
		end
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

	local tx = self.parent and self.parent.tweens and self.parent.tweens.x and self.parent.tweens.x:getValue() or 0
	local ty = self.parent and self.parent.tweens and self.parent.tweens.y and self.parent.tweens.y:getValue() or 0
	local bx = math.floor(x - tx + 0.5)
	local by = math.floor(y - ty + 0.5)

	local scrolling = self.maxWidth and not self.maxHeight and self._textW and self._textW > self.maxWidth
	if not self._canvas or scrolling then
		self._canvas = self:buildCanvas(bx, by, fw, fh)
	end
	if not self._canvas then
		return
	end

	local hadShader = self.parent and self.parent.applyShader and self.parent:applyShader() or false
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self._canvas, bx + tx, by + ty, 0, 1, 1, fw * 0.5, fh * 0.5)
	if hadShader then
		love.graphics.setShader()
	end
	love.graphics.setColor(r, g, b, a)
end

return Label