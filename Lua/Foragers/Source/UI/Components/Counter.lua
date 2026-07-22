local Events = require("Source.Helpers.Events")
local Easing = require("Source.Sprite.Components.Tween").Easing

--- Maps source component value to spritesheet frame. Event-driven, opt-in smooth tween.
--- Optional `label` block renders a text overlay (e.g. level number) via font spritesheet.
local Counter = {}
Counter.__index = Counter

function Counter.new(data)
	local self = setmetatable({
		type = "counter",
		mode = data.mode or "fraction",
		field = data.field or "experience",
		maxField = data.maxField,
		sourceType = data.sourceType or "player_stats",
		frames = data.frames,
		smoothness = data.smoothness or 0,
		curve = data.curve or "OutBack",
		_labelText = "",
		_displayProgress = 0,
		_fromProgress = 0,
		_targetProgress = 0,
		_tweenTime = 0,
		_tweenDuration = 0,
	}, Counter)

	if data.label then
		self._labelFont = data.label.font or "Content.Assets.Sprites.UI.Fonts.Tinylorder"
		self._labelColor = data.label.color and { unpack(data.label.color) } or { 1, 1, 1 }
		self._labelCharSpacing = data.label.charSpacing
		self._labelOffsetX = data.label.offsetX or 0
		self._labelOffsetY = data.label.offsetY or 0
		self._labelHAlign = data.label.hAlign or "center"
		self._labelVAlign = data.label.vAlign or "center"
	end

	return self
end

function Counter:attach()
	if not self._labelFont then
		return
	end
	local Path = require("Source.Helpers.Path")
	local SpriteLoader = require("Source.Sprite.SpriteLoader")
	local luaPath = Path.moduleToPath(self._labelFont)
	local pngPath = luaPath .. ".png"
	local ok, fontData = pcall(require, self._labelFont)
	if not ok or not fontData then
		self._labelFont = nil
		return
	end
	local sprite = SpriteLoader.instantiate(fontData, 0, 0, pngPath)
	if not sprite then
		self._labelFont = nil
		return
	end
	for _, comp in ipairs(sprite.components) do
		if comp.type == "spritesheet" then
			self._labelImage = comp.image
			self._labelQuads = comp.quads
			self._labelFrameW = comp.frameWidth
			self._labelFrameH = comp.frameHeight
			self._labelPivotX = comp.pivotX or 0.5
			self._labelPivotY = comp.pivotY or 0.5
		elseif comp.type == "spritefont" then
			self._labelCharIndex = comp._charIndex
			self._labelCharWidth = comp._charWidth
			-- label charSpacing overrides font default if set
			if self._labelCharSpacing == nil then
				self._labelCharSpacing = comp.charSpacing
			end
		end
	end
	-- Require both spritesheet and spritefont for label to work
	if not self._labelImage or not self._labelCharIndex then
		self._labelFont = nil
	end
end

--- Pass the sprite that holds the source component (e.g. player sprite).
--- Subscribes to VALUE_CHANGED and reads initial value.
---@param sprite table
function Counter:setPlayerSprite(sprite)
	if not sprite then
		return
	end
	sprite:on(Events.VALUE_CHANGED, function(data)
		self:onValueChanged(data)
	end, 5)

	-- Initial sync: no animation, jump to current value
	for _, comp in ipairs(sprite.components or {}) do
		if comp.type == self.sourceType then
			local value = comp[self.field]
			if value ~= nil then
				local maxValue
				if self.mode == "progress" then
					maxValue = comp:xpForNextLevel()
				elseif self.maxField then
					maxValue = comp[self.maxField]
				end
				if maxValue and maxValue > 0 then
					local p = math.max(0, math.min(1, value / maxValue))
					self._displayProgress = p
					self._targetProgress = p
					self:_setFrame(p)
				end
				if self._labelFont then
					self._labelText = tostring(comp.level or "")
				end
			end
			break
		end
	end
end

---@param data { sourceType:string, field:string, value:number, maxValue:number, level:number }
function Counter:onValueChanged(data)
	if data.level ~= nil and self._labelFont then
		self._labelText = tostring(data.level)
	end
	if data.field ~= self.field then
		return
	end
	local maxValue = data.maxValue
	if not maxValue or maxValue <= 0 then
		return
	end
	local target = math.max(0, math.min(1, data.value / maxValue))
	if self.smoothness and self.smoothness > 0 then
		self._fromProgress = self._displayProgress
		self._targetProgress = target
		self._tweenTime = 0
		self._tweenDuration = self.smoothness
	else
		self._displayProgress = target
		self._fromProgress = target
		self._targetProgress = target
		self._tweenDuration = 0
		self:_setFrame(target)
	end
end

function Counter:update(dt)
	if self._tweenDuration <= 0 then
		return
	end
	self._tweenTime = self._tweenTime + dt
	if self._tweenTime >= self._tweenDuration then
		self._displayProgress = self._targetProgress
		self._tweenDuration = 0
	else
		local p = self._tweenTime / self._tweenDuration
		local eased = (Easing[self.curve] or Easing.OutBack)(p)
		self._displayProgress = self._fromProgress + (self._targetProgress - self._fromProgress) * eased
	end
	self:_setFrame(self._displayProgress)
end

---@param progress number 0-1
function Counter:_setFrame(progress)
	local spritesheet
	for _, comp in ipairs(self.parent.components or {}) do
		if comp.type == "spritesheet" then
			spritesheet = comp
			break
		end
	end
	if not spritesheet or not spritesheet.quads then
		return
	end
	local numFrames = self.frames or spritesheet.columns or 1
	-- frame 1 = 0%, frame N = 100%
	spritesheet._currentIndex = math.floor(math.max(0, math.min(1, progress)) * (numFrames - 1)) + 1
end

function Counter:draw(x, y)
	if not self._labelFont or not self._labelImage or not self._labelQuads or not self._labelCharSpacing then
		return
	end
	local text = self._labelText
	if #text == 0 then
		return
	end

	-- First pass: compute total text width for horizontal alignment
	local totalW = 0
	for i = 1, #text do
		local c = text:sub(i, i)
		if c == " " then
			totalW = totalW + self._labelFrameW
		else
			totalW = totalW + (self._labelCharWidth[c] or self._labelFrameW)
		end
		if i < #text then
			totalW = totalW + self._labelCharSpacing
		end
	end

	local pr, pg, pb, pa = love.graphics.getColor()
	love.graphics.setColor(self._labelColor[1], self._labelColor[2], self._labelColor[3], self._labelColor[4] or 1)

	local ox = self._labelFrameW * self._labelPivotX
	local oy = self._labelFrameH * self._labelPivotY

	-- Horizontal: compute left edge from alignment
	local leftEdge = x + self._labelOffsetX
	if self._labelHAlign == "center" then
		leftEdge = leftEdge - totalW / 2
	elseif self._labelHAlign == "right" then
		leftEdge = leftEdge - totalW
	end

	-- Vertical: compute draw Y from alignment
	local cy = y + self._labelOffsetY
	if self._labelVAlign == "top" then
		cy = cy + self._labelFrameH * self._labelPivotY
	elseif self._labelVAlign == "bottom" then
		cy = cy - self._labelFrameH * (1 - self._labelPivotY)
	end

	for i = 1, #text do
		local c = text:sub(i, i)
		if c == " " then
			leftEdge = leftEdge + self._labelFrameW + self._labelCharSpacing
		else
			local idx = self._labelCharIndex[c]
			if idx then
				local quad = self._labelQuads[idx]
				if quad then
					-- Character draw point = leftEdge + pivot offset
					local cxDraw = leftEdge + ox
					love.graphics.draw(
						self._labelImage,
						quad,
						math.floor(cxDraw + 0.5),
						math.floor(cy + 0.5),
						0,
						1,
						1,
						ox,
						oy
					)
				end
			end
			local charW = self._labelCharWidth[c] or self._labelFrameW
			leftEdge = leftEdge + charW + self._labelCharSpacing
		end
	end
	love.graphics.setColor(pr, pg, pb, pa)
end

return Counter
