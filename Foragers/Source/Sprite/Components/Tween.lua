local Events = require("Source.Helpers.Core.Events")
local ValueParser = require("Source.Helpers.Core.ValueParser")

---@class Tween
---@field target string Property being tweened
---@field from number Start value
---@field to number End value
---@field duration number Duration in seconds
---@field curve function Easing function
---@field timer number Elapsed time
---@field loop boolean If true, replay from start on finish
---@field pingPong boolean If true, oscillate forward then backward
---@field destroyOnComplete boolean
---@field wait number|nil Delay before tween starts
---@field _destroyHandled boolean|nil Guard so TWEEN_COMPLETED emits once per finish
---@field _smoothness number|nil Attack swing smoothness override (set by AttackSystem)
local Tween = {}
Tween.__index = Tween

---@param target string
---@param from number
---@param to number
---@param duration number
---@param curve function
---@param loop boolean|nil
---@param pingPong boolean|nil
---@param destroyOnComplete boolean|nil
---@param wait number|nil Delay before tween starts
function Tween.new(target, from, to, duration, curve, loop, pingPong, destroyOnComplete, wait)
	return setmetatable({
		target = target,
		from = tonumber(from) or 0,
		to = tonumber(to) or 0,
		duration = tonumber(duration) or 0,
		curve = curve,
		timer = 0,
		loop = loop or false,
		pingPong = pingPong or false,
		destroyOnComplete = destroyOnComplete or false,
		wait = wait or 0,
	}, Tween)
end

function Tween:start()
	self.timer = 0
end

function Tween:update(dt)
	local w = self.wait or 0
	if w > 0 and self.timer < w then
		self.timer = math.min(self.timer + dt, w)
		return
	end
	local elapsed = self.timer - w
	if self.pingPong then
		local period = self.duration * 2
		if self.loop then
			elapsed = (elapsed + dt) % period
		else
			elapsed = math.min(elapsed + dt, period)
		end
	elseif self.loop then
		if self.duration > 0 then
			elapsed = (elapsed + dt) % self.duration
		end
	else
		elapsed = math.min(elapsed + dt, self.duration)
	end
	self.timer = self.wait + elapsed
end

function Tween:getValue()
	local elapsed = math.max(self.timer - (self.wait or 0), 0)
	local t
	if self.pingPong then
		local period = self.duration * 2
		local e = math.min(elapsed, period)
		local progress = period > 0 and e / period or 0
		if progress <= 0.5 then
			t = progress * 2
		else
			t = (1 - progress) * 2
		end
	else
		t = self.duration > 0 and elapsed / self.duration or 1
	end
	t = math.min(math.max(t, 0), 1)
	return self.from + (self.to - self.from) * self.curve(t)
end

function Tween:isFinished()
	if self.loop then
		return false
	end
	local elapsed = math.max(self.timer - (self.wait or 0), 0)
	if self.pingPong then
		return elapsed >= self.duration * 2
	end
	return elapsed >= self.duration
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

function Easing.Linear(x)
	return x
end

function Easing.InSine(x)
	return 1 - math.cos((x * math.pi) / 2)
end

function Easing.OutSine(x)
	return math.sin((x * math.pi) / 2)
end

function Easing.InOutSine(x)
	return -(math.cos(math.pi * x) - 1) / 2
end

function Easing.InQuad(x)
	return x * x
end

function Easing.OutQuad(x)
	return 1 - (1 - x) * (1 - x)
end

function Easing.InOutQuad(x)
	return x < 0.5 and 2 * x * x or 1 - ((-2 * x + 2) ^ 2) / 2
end

function Easing.InCubic(x)
	return x * x * x
end

function Easing.OutCubic(x)
	return 1 - ((1 - x) ^ 3)
end

function Easing.InOutCubic(x)
	return x < 0.5 and 4 * x * x * x or 1 - ((-2 * x + 2) ^ 3) / 2
end

function Easing.InQuart(x)
	return x * x * x * x
end

function Easing.OutQuart(x)
	return 1 - ((1 - x) ^ 4)
end

function Easing.InOutQuart(x)
	return x < 0.5 and 8 * x * x * x * x or 1 - ((-2 * x + 2) ^ 4) / 2
end

function Easing.InQuint(x)
	return x * x * x * x * x
end

function Easing.OutQuint(x)
	return 1 - ((1 - x) ^ 5)
end

function Easing.InOutQuint(x)
	return x < 0.5 and 16 * x * x * x * x * x or 1 - ((-2 * x + 2) ^ 5) / 2
end

function Easing.InExpo(x)
	if x == 0 then
		return 0
	end
	return 2 ^ (10 * x - 10)
end

function Easing.OutExpo(x)
	if x == 1 then
		return 1
	end
	return 1 - 2 ^ (-10 * x)
end

function Easing.InOutExpo(x)
	if x == 0 then
		return 0
	end
	if x == 1 then
		return 1
	end
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
	return x < 0.5 and (1 - math.sqrt(1 - (2 * x) ^ 2)) / 2 or (math.sqrt(1 - ((-2 * x + 2) ^ 2)) + 1) / 2
end

function Easing.InBack(x)
	return _c3 * x * x * x - _c1 * x * x
end

function Easing.OutBack(x)
	return 1 + _c3 * ((x - 1) ^ 3) + _c1 * ((x - 1) ^ 2)
end

function Easing.InOutBack(x)
	return x < 0.5 and ((2 * x) ^ 2 * ((_c2 + 1) * 2 * x - _c2)) / 2
		or (((2 * x - 2) ^ 2) * ((_c2 + 1) * (x * 2 - 2) + _c2) + 2) / 2
end

function Easing.InElastic(x)
	if x == 0 then
		return 0
	end
	if x == 1 then
		return 1
	end
	return -(2 ^ (10 * x - 10)) * math.sin((x * 10 - 10.75) * _c4)
end

function Easing.OutElastic(x)
	if x == 0 then
		return 0
	end
	if x == 1 then
		return 1
	end
	return (2 ^ (-10 * x)) * math.sin((x * 10 - 0.75) * _c4) + 1
end

function Easing.InOutElastic(x)
	if x == 0 then
		return 0
	end
	if x == 1 then
		return 1
	end
	return x < 0.5 and -((2 ^ (20 * x - 10)) * math.sin((20 * x - 11.125) * _c5)) / 2
		or ((2 ^ (-20 * x + 10)) * math.sin((20 * x - 11.125) * _c5)) / 2 + 1
end

function Easing.InBounce(x)
	return 1 - _bounceOut(1 - x)
end

function Easing.OutBounce(x)
	return _bounceOut(x)
end

function Easing.InOutBounce(x)
	return x < 0.5 and (1 - _bounceOut(1 - 2 * x)) / 2 or (1 + _bounceOut(2 * x - 1)) / 2
end

local _pendingDestroy = {}

local function createTween(target, from, to, duration, curve, loop, pingPong, destroyOnComplete, wait)
	return Tween.new(target, from, to, duration, curve or Easing.OutBack, loop, pingPong, destroyOnComplete, wait)
end

local function applyTweens(self, tweenSet)
	local active = {}
	for _, td in pairs(tweenSet) do
		if type(td) == "table" and td.target then
			active[td.target] = true
		end
	end
	-- Kill every existing tween whose target is NOT in this set, UNLESS the
	-- target is in the component-level persist list (e.g. idle y float).
	-- Universal reset: no tag leaks stale tweens (rimAngle, burn, angle).
	local persist = self.persist or {}
	for target, _ in pairs(self.parent.tweens) do
		if not active[target] and not persist[target] then
			self.parent.tweens[target] = nil
		end
	end
	local globalDestroyOnComplete = tweenSet.destroyOnComplete
	for _, tweenData in pairs(tweenSet) do
		if type(tweenData) == "table" and tweenData.target then
			if tweenData.set ~= nil then
				self.parent.tweens[tweenData.target] = nil
				self.parent[tweenData.target] = ValueParser.call(tweenData, "set")
			else
				local from = ValueParser.call(tweenData, "from")
				local to = ValueParser.call(tweenData, "to")
				local dur = ValueParser.call(tweenData, "duration")
				local curveFunc = Easing[tweenData.curve] or Easing.OutBack
				local destroyOnComplete = tweenData.destroyOnComplete ~= nil and tweenData.destroyOnComplete
					or globalDestroyOnComplete
				local wait = tweenData.wait or 0
				if not self.parent.tweens[tweenData.target] then
					self.parent.tweens[tweenData.target] = createTween(
						tweenData.target,
						from,
						to,
						dur,
						curveFunc,
						tweenData.loop,
						tweenData.pingPong,
						destroyOnComplete,
						wait
					)
				end
				local tween = self.parent.tweens[tweenData.target]
				tween.from = from
				tween.to = to
				tween.duration = dur
				tween.curve = curveFunc
				tween.loop = tweenData.loop or false
				tween.pingPong = tweenData.pingPong or false
				tween.destroyOnComplete = destroyOnComplete or false
				tween.wait = wait
				tween._destroyHandled = nil
				tween:start()
			end
		end
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
		persist = data.persist or {},
		_tweensInitialized = false,
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
		if self.tags.splash and oldState then
			local wasInWater = oldState == "swim" or oldState == "float"
			local isInWater = newState == "swim" or newState == "float"
			if wasInWater ~= isInWater then
				applyTweens(self, self.tags.splash)
			end
		end
	end, 10)

	self.parent:on(Events.SLOWDOWN_ENTER, function()
		if self.tags.prop_touch then
			applyTweens(self, self.tags.prop_touch)
		end
	end, 10)

	self.parent:on(Events.PROP_HIT, function()
		if self.tags.prop_hit then
			applyTweens(self, self.tags.prop_hit)
		end
	end, 10)

	self.parent:on(Events.FOLLOW_ARRIVED, function()
		if self.tags.arrived then
			applyTweens(self, self.tags.arrived)
		end
	end, 10)

	self.parent:on(Events.PROP_SPAWNED, function()
		if self.tags.prop_spawned then
			applyTweens(self, self.tags.prop_spawned)
		end
	end, 10)

	self.parent:on(Events.PICKUP, function()
		if self.tags.pickup then
			applyTweens(self, self.tags.pickup)
		end
	end, 10)

	self.parent:on(Events.TARGET_SELECTED, function()
		if self.tags.target_selected then
			applyTweens(self, self.tags.target_selected)
		end
	end, 10)

	self.parent:on(Events.COUNTER_TICK, function()
		if self.tags.counter_tick then
			applyTweens(self, self.tags.counter_tick)
		end
	end, 10)

	self.parent:on(Events.COUNTER_WRAP, function()
		if self.tags.counter_wrap then
			applyTweens(self, self.tags.counter_wrap)
		end
	end, 10)
end

--- Apply a tween tag by name. Used for externally driven tweens (e.g. the
--- loading hold) whose trigger isn't one of the standard events.
function TweenComponent:triggerTag(name)
	local tag = self.tags and self.tags[name]
	if tag then
		applyTweens(self, tag)
	end
end

function TweenComponent:update(dt)
	if self.parent and not self._tweensInitialized then
		self._tweensInitialized = true
		for _, tweenData in ipairs(self.tweens) do
			local key = tweenData.target
			if not self.parent.tweens[key] then
				local from = ValueParser.call(tweenData, "from")
				local to = ValueParser.call(tweenData, "to")
				local dur = ValueParser.call(tweenData, "duration")
				local curveFunc = Easing[tweenData.curve] or Easing.OutBack
				self.parent.tweens[key] = createTween(
					key,
					from,
					to,
					dur,
					curveFunc,
					tweenData.loop,
					tweenData.pingPong,
					tweenData.destroyOnComplete,
					tweenData.wait or 0
				)
				self.parent.tweens[key]:start()
			end
		end
	end
	for _, tween in pairs(self.parent and self.parent.tweens or {}) do
		tween:update(dt)
	end
	if self.parent then
		for _, tween in pairs(self.parent.tweens) do
			if tween.destroyOnComplete and tween:isFinished() and not tween._destroyHandled then
				tween._destroyHandled = true
				if not _pendingDestroy[self.parent] then
					self.parent:emit(Events.TWEEN_COMPLETED)
				end
				_pendingDestroy[self.parent] = true
			end
		end
	end
end

function TweenComponent.getPendingDestroy()
	local list = {}
	for sprite in pairs(_pendingDestroy) do
		table.insert(list, sprite)
	end
	return list
end

function TweenComponent.clearPendingDestroy()
	for sprite in pairs(_pendingDestroy) do
		_pendingDestroy[sprite] = nil
	end
end

return {
	Component = TweenComponent,
	Tween = Tween,
	Easing = Easing,
}