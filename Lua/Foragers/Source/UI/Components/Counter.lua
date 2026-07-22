local Events = require("Source.Helpers.Events")
local Easing = require("Source.Sprite.Components.Tween").Easing

--- Maps source component value to spritesheet frame. Event-driven, opt-in smooth tween.
local Counter = {}
Counter.__index = Counter

function Counter.new(data)
	return setmetatable({
		type = "counter",
		mode = data.mode or "fraction",
		field = data.field or "experience",
		maxField = data.maxField,
		sourceType = data.sourceType or "player_stats",
		frames = data.frames,
		smoothness = data.smoothness or 0,
		curve = data.curve or "OutBack",
		_displayProgress = 0,
		_fromProgress = 0,
		_targetProgress = 0,
		_tweenTime = 0,
		_tweenDuration = 0,
	}, Counter)
end

function Counter:attach() end

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
			end
			break
		end
	end
end

---@param data { sourceType:string, field:string, value:number, maxValue:number }
function Counter:onValueChanged(data)
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

function Counter:draw(x, y) end

return Counter
