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

---@class Tweens
local Tweens = {}

---@param t number
---@return number
function Tweens.BackOut(t)
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * ((t - 1) ^ 3) + c1 * ((t - 1) ^ 2)
end

--- Quarter-sine ease-in: 0 -> 1 over [0, 1].
--- Use with loop + pingPong for continuous smooth oscillation.
---@param t number
---@return number
function Tweens.Sine(t)
	return math.sin(t * math.pi * 0.5)
end

---@param target string
---@param from number
---@param to number
---@param duration number
---@param curve function|nil
---@param loop boolean|nil
---@param pingPong boolean|nil
---@return Tween
function Tweens.create(target, from, to, duration, curve, loop, pingPong)
	return Tween.new(target, from, to, duration, curve or Tweens.BackOut, loop, pingPong)
end

return Tweens
