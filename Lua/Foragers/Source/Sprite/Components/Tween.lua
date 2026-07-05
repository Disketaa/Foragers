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

function Easing.BackOut(t)
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * ((t - 1) ^ 3) + c1 * ((t - 1) ^ 2)
end

function Easing.Sine(t)
	return math.sin(t * math.pi * 0.5)
end

local function createTween(target, from, to, duration, curve, loop, pingPong)
	return Tween.new(target, from, to, duration, curve or Easing.BackOut, loop, pingPong)
end

---@param self TweenComponent
---@param tweenSet table[]
local function applyTweens(self, tweenSet)
	for _, tweenData in pairs(tweenSet) do
		local curveFunc = Easing[tweenData.curve] or Easing.BackOut
		if not self.parent.tweens[tweenData.target] then
			self.parent.tweens[tweenData.target] =
				createTween(tweenData.target, tweenData.from, tweenData.to, tweenData.duration, curveFunc, tweenData.loop, tweenData.pingPong)
		end
		local tween = self.parent.tweens[tweenData.target]
		tween.from = tweenData.from
		tween.to = tweenData.to
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
end

function TweenComponent:update(dt)
	for _, tween in pairs(self.parent and self.parent.tweens or {}) do
		tween:update(dt)
	end
end

return {
	Component = TweenComponent,
	Tween = Tween,
	Easing = Easing,
}
