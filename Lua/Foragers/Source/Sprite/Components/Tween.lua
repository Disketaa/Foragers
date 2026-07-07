local Events = require("Source.Helpers.Events")

---@class Tween
---@field target string Property being tweened
---@field from number Start value
---@field to number End value
---@field duration number Duration in seconds
---@field curve function Easing function
---@field timer number Elapsed time
---@field loop boolean If true, replay from start on finish
---@field pingPong boolean If true, oscillate forward then backward
local Tween = {}
Tween.__index = Tween

---@param target string
---@param from number
---@param to number
---@param duration number
---@param curve function
---@param loop boolean|nil
---@param pingPong boolean|nil
---@return Tween
function Tween.new(target, from, to, duration, curve, loop, pingPong)
	return setmetatable({
		target = target,
		from = from,
		to = to,
		duration = duration,
		curve = curve,
		timer = 0,
		loop = loop or false,
		pingPong = pingPong or false,
	}, Tween)
end

function Tween:start()
	self.timer = 0
end

function Tween:update(dt)
	if self.pingPong then
		local period = self.duration * 2
		if self.loop then
			self.timer = (self.timer + dt) % period
		else
			self.timer = math.min(self.timer + dt, period)
		end
	elseif self.loop then
		if self.duration > 0 then
			self.timer = (self.timer + dt) % self.duration
		end
	else
		self.timer = math.min(self.timer + dt, self.duration)
	end
end

function Tween:getValue()
	local t
	if self.pingPong then
		local period = self.duration * 2
		local elapsed = math.min(self.timer, period)
		local progress = period > 0 and elapsed / period or 0
		if progress <= 0.5 then
			t = progress * 2
		else
			t = (1 - progress) * 2
		end
	else
		t = self.duration > 0 and self.timer / self.duration or 1
	end
	t = math.min(math.max(t, 0), 1)
	return self.from + (self.to - self.from) * self.curve(t)
end

function Tween:isFinished()
	if self.loop then
		return false
	end
	if self.pingPong then
		return self.timer >= self.duration * 2
	end
	return self.timer >= self.duration
end

local Easing = {}

local _c1 = 1.70158
local _c2 = _c1 * 1.525
local _c3 = _c1 + 1
local _c4 = (2 * math.pi) / 3
local _c5 = (2 * math.pi) / 4.5

local function _bounceOut(x)
	if x < 1 / 2.75 then
		return 7.5625 * x * x
	elseif x < 2 / 2.75 then
		x = x - 1.5 / 2.75
		return 7.5625 * x * x + 0.75
	elseif x < 2.5 / 2.75 then
		x = x - 2.25 / 2.75
		return 7.5625 * x * x + 0.9375
	else
		x = x - 2.625 / 2.75
		return 7.5625 * x * x + 0.984375
	end
end

function Easing.Linear(x) return x end

function Easing.InSine(x) return 1 - math.cos((x * math.pi) / 2) end

function Easing.OutSine(x) return math.sin((x * math.pi) / 2) end

function Easing.InOutSine(x) return -(math.cos(math.pi * x) - 1) / 2 end

function Easing.InQuad(x) return x * x end

function Easing.OutQuad(x) return 1 - (1 - x) * (1 - x) end

function Easing.InOutQuad(x)
	return x < 0.5 and 2 * x * x or 1 - ((-2 * x + 2) ^ 2) / 2
end

function Easing.InCubic(x) return x * x * x end

function Easing.OutCubic(x) return 1 - ((1 - x) ^ 3) end

function Easing.InOutCubic(x)
	return x < 0.5 and 4 * x * x * x or 1 - ((-2 * x + 2) ^ 3) / 2
end

function Easing.InQuart(x) return x * x * x * x end

function Easing.OutQuart(x) return 1 - ((1 - x) ^ 4) end

function Easing.InOutQuart(x)
	return x < 0.5 and 8 * x * x * x * x or 1 - ((-2 * x + 2) ^ 4) / 2
end

function Easing.InQuint(x) return x * x * x * x * x end

function Easing.OutQuint(x) return 1 - ((1 - x) ^ 5) end

function Easing.InOutQuint(x)
	return x < 0.5 and 16 * x * x * x * x * x or 1 - ((-2 * x + 2) ^ 5) / 2
end

function Easing.InExpo(x)
	if x == 0 then return 0 end
	return 2 ^ (10 * x - 10)
end

function Easing.OutExpo(x)
	if x == 1 then return 1 end
	return 1 - 2 ^ (-10 * x)
end

function Easing.InOutExpo(x)
	if x == 0 then return 0 end
	if x == 1 then return 1 end
	if x < 0.5 then
		return (2 ^ (20 * x - 10)) / 2
	else
		return (2 - (2 ^ (-20 * x + 10))) / 2
	end
end

function Easing.InCirc(x)
	return 1 - math.sqrt(1 - x ^ 2)
end

function Easing.OutCirc(x)
	return math.sqrt(1 - (x - 1) ^ 2)
end

function Easing.InOutCirc(x)
	return x < 0.5
		and (1 - math.sqrt(1 - (2 * x) ^ 2)) / 2
		or (math.sqrt(1 - ((-2 * x + 2) ^ 2)) + 1) / 2
end

function Easing.InBack(x)
	return _c3 * x * x * x - _c1 * x * x
end

function Easing.OutBack(x)
	return 1 + _c3 * ((x - 1) ^ 3) + _c1 * ((x - 1) ^ 2)
end

function Easing.InOutBack(x)
	return x < 0.5
		and ((2 * x) ^ 2 * ((_c2 + 1) * 2 * x - _c2)) / 2
		or (((2 * x - 2) ^ 2) * ((_c2 + 1) * (x * 2 - 2) + _c2) + 2) / 2
end

function Easing.InElastic(x)
	if x == 0 then return 0 end
	if x == 1 then return 1 end
	return -(2 ^ (10 * x - 10)) * math.sin((x * 10 - 10.75) * _c4)
end

function Easing.OutElastic(x)
	if x == 0 then return 0 end
	if x == 1 then return 1 end
	return (2 ^ (-10 * x)) * math.sin((x * 10 - 0.75) * _c4) + 1
end

function Easing.InOutElastic(x)
	if x == 0 then return 0 end
	if x == 1 then return 1 end
	return x < 0.5
		and -((2 ^ (20 * x - 10)) * math.sin((20 * x - 11.125) * _c5)) / 2
		or ((2 ^ (-20 * x + 10)) * math.sin((20 * x - 11.125) * _c5)) / 2 + 1
end

function Easing.InBounce(x)
	return 1 - _bounceOut(1 - x)
end

function Easing.OutBounce(x)
	return _bounceOut(x)
end

function Easing.InOutBounce(x)
	return x < 0.5
		and (1 - _bounceOut(1 - 2 * x)) / 2
		or (1 + _bounceOut(2 * x - 1)) / 2
end

local function createTween(target, from, to, duration, curve, loop, pingPong)
	return Tween.new(target, from, to, duration, curve or Easing.OutBack, loop, pingPong)
end

---@param value string|number
local function parseRandomValue(value)
	if type(value) == "string" and string.find(value, "|") then
		local parts = {}
		for part in string.gmatch(value, "[^|]+") do
			local trimmed = string.match(part, "^%s*(.-)%s*$")
			local num = tonumber(trimmed)
			if num then
				table.insert(parts, num)
			end
		end
		if #parts > 0 then
			return parts[love.math.random(1, #parts)]
		end
	end
	return tonumber(value) or value
end

local function applyTweens(self, tweenSet)
	for _, tweenData in pairs(tweenSet) do
		local from = parseRandomValue(tweenData.from)
		local to = parseRandomValue(tweenData.to)
		local curveFunc = Easing[tweenData.curve] or Easing.OutBack
		if not self.parent.tweens[tweenData.target] then
			self.parent.tweens[tweenData.target] = createTween(
				tweenData.target,
				from,
				to,
				tweenData.duration,
				curveFunc,
				tweenData.loop,
				tweenData.pingPong
			)
		end
		local tween = self.parent.tweens[tweenData.target]
		tween.from = from
		tween.to = to
		tween.duration = tweenData.duration
		tween.curve = curveFunc
		tween.loop = tweenData.loop or false
		tween.pingPong = tweenData.pingPong or false
		tween:start()
	end
end

---@class TweenComponent
---@field parent Sprite|nil Parent sprite reference
---@field tweens table[] Array of tween configurations
---@field tags table<string, table> Tween sets keyed by flip change or state
---@field type "tween"
local TweenComponent = {}
TweenComponent.__index = TweenComponent

---@param data table
---@return TweenComponent
function TweenComponent.new(data)
	return setmetatable({
		tweens = data.tweens or {},
		tags = data.tags or {},
		type = "tween",
	}, TweenComponent)
end

function TweenComponent:attach()
	applyTweens(self, self.tweens)

	self.parent:on(Events.FLIPPED, function()
		if self.tags.flip then
			applyTweens(self, self.tags.flip)
		end
	end, 10)

	self.parent:on(Events.STATE_CHANGED, function(newState, oldState)
		if self.tags.splash and oldState and (oldState == "swimming") ~= (newState == "swimming") then
			applyTweens(self, self.tags.splash)
		end
	end, 10)

	self.parent:on(Events.SLOWDOWN_ENTER, function()
		if self.tags.bush_touch then
			applyTweens(self, self.tags.bush_touch)
		end
	end, 10)

	self.parent:on(Events.PROP_HIT, function()
		if self.tags.prop_hit then
			applyTweens(self, self.tags.prop_hit)
		end
	end, 10)
end

function TweenComponent:update(dt)
	if self.parent then
		for _, tweenData in ipairs(self.tweens) do
			local key = tweenData.target
			if not self.parent.tweens[key] then
				local from = parseRandomValue(tweenData.from)
				local to = parseRandomValue(tweenData.to)
				local curveFunc = Easing[tweenData.curve] or Easing.OutBack
				self.parent.tweens[key] = createTween(key, from, to, tweenData.duration, curveFunc, tweenData.loop,
					tweenData.pingPong)
				self.parent.tweens[key]:start()
			end
		end
	end
	for _, tween in pairs(self.parent and self.parent.tweens or {}) do
		tween:update(dt)
	end
end

return {
	Component = TweenComponent,
	Tween = Tween,
	Easing = Easing,
}
