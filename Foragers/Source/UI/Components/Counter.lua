local Events = require("Source.Helpers.Core.Events")
local Easing = require("Source.Sprite.Components.Tween").Easing
local Pivot = require("Source.Helpers.Core.Pivot")

--- Read a source field, resolving it through the component's curve resolver if
--- it is a `{base, gain}` table (e.g. a level-scaled `maxSatiety`).
local function readStat(comp, field)
	local v = comp[field]
	if type(v) == "table" and comp.resolveStat then
		v = comp:resolveStat(v)
	end
	return v
end

--- Maps source component value to spritesheet frame. Event-driven, opt-in smooth tween.
--- Level text is forwarded to a sibling `text` component (if present) so the
--- counter stays a pure progress mapper and the label owns its own render.
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
		_label = nil,
		_displayProgress = 0,
		_fromProgress = 0,
		_targetProgress = 0,
		_tweenTime = 0,
		_tweenDuration = 0,
		_lastLevel = nil,
	}, Counter)

	if data.icon then
		self._iconSprite = data.icon.sprite
		self._iconOffsetX = data.icon.offsetX or 0
		self._iconOffsetY = data.icon.offsetY or 0
	end
	self._iconCurrentIndex = 1

	return self
end

function Counter:attach()
	local Path = require("Source.Helpers.Core.Path")
	local SpriteLoader = require("Source.Sprite.SpriteLoader")

	if self._iconSprite then
		local luaPath = Path.moduleToPath(self._iconSprite)
		local pngPath = luaPath .. ".png"
		local ok, iconData = pcall(require, self._iconSprite)
		if ok and iconData then
			local sprite = SpriteLoader.instantiate(iconData, 0, 0, pngPath)
			if sprite then
				local ss = sprite:findComponent("spritesheet")
				if ss then
					self._iconImage = ss.image
					self._iconQuads = ss.quads
					self._iconFrameW = ss.frameWidth
					self._iconFrameH = ss.frameHeight
					self._iconPivotX = ss.pivotX or "center"
					self._iconPivotY = ss.pivotY or "center"
					self._iconColumns = ss.columns or 1
				end
			end
		end
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

	-- Forward the level to a sibling text component (if present) so the
	-- counter stays a pure progress mapper and the label owns its own render.
	self._label = self.parent and self.parent:findComponent("text")

	-- Initial sync: no animation, jump to current value
	local comp = sprite:findComponent(self.sourceType)
	if comp then
		local value = readStat(comp, self.field)
		if value ~= nil then
			local maxValue
			if self.mode == "progress" then
				maxValue = comp:xpForNextLevel()
			elseif self.maxField then
				maxValue = readStat(comp, self.maxField)
			end
			if maxValue and maxValue > 0 then
				local p = math.max(0, math.min(1, value / maxValue))
				self._displayProgress = p
				self._targetProgress = p
				self:_setFrame(p)
			end
			if self._label then
				self._label:setText(tostring(comp.level or ""))
			end
			self._lastLevel = comp.level
		end
	end
end

---@param data { sourceType:string, field:string, value:number, maxValue:number, level:number }
function Counter:onValueChanged(data)
	if data.level ~= nil and self._label then
		self._label:setText(tostring(data.level))
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
	-- Emit counter events on parent sprite for downstream effects (e.g. tween tint)
	if self.parent then
		if data.level ~= nil and self._lastLevel ~= nil and data.level ~= self._lastLevel then
			self.parent:emit(Events.COUNTER_WRAP)
		end
		self.parent:emit(Events.COUNTER_TICK)
		self._lastLevel = data.level
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
	local spritesheet = self.parent and self.parent:findComponent("spritesheet")
	if not spritesheet or not spritesheet.quads then
		return
	end
	local numFrames = self.frames or spritesheet.columns or 1
	-- Frame 1 = exactly 0; any positive value shows at least one segment so a
	-- low-but-alive value doesn't read as empty.
	local p = math.max(0, math.min(1, progress))
	local index = math.floor(p * (numFrames - 1)) + 1
	if p > 0 and numFrames > 1 then
		index = math.max(2, index)
	end
	spritesheet._currentIndex = index

	if self._iconQuads then
		local iconNumFrames = self._iconColumns or 1
		self._iconCurrentIndex = math.min(math.floor(progress * iconNumFrames) + 1, iconNumFrames)
	end
end

function Counter:draw(x, y)
	if self._iconImage and self._iconQuads then
		local quad = self._iconQuads[self._iconCurrentIndex]
		if quad then
			local ox = Pivot.px(self._iconPivotX, self._iconFrameW, "center")
			local oy = Pivot.px(self._iconPivotY, self._iconFrameH, "center")
			local ix = x + self._iconOffsetX
			local iy = y + self._iconOffsetY
			love.graphics.draw(self._iconImage, quad, math.floor(ix + 0.5), math.floor(iy + 0.5), 0, 1, 1, ox, oy)
		end
	end
end

return Counter