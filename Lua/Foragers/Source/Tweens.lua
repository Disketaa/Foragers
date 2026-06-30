---@class Tween
---@field target string Property being tweened
---@field from number Start value
---@field to number End value
---@field duration number Duration in seconds
---@field curve function Easing function
---@field timer number Elapsed time
local Tween = {}
Tween.__index = Tween

---@param target string
---@param from number
---@param to number
---@param duration number
---@param curve function
---@return Tween
function Tween.new(target, from, to, duration, curve)
	return setmetatable({
		target = target,
		from = from,
		to = to,
		duration = duration,
		curve = curve,
		timer = 0,
	}, Tween)
end

function Tween:start()
	self.timer = 0
end

function Tween:update(dt)
	self.timer = math.min(self.timer + dt, self.duration)
end

function Tween:getValue()
	local t = self.duration > 0 and self.timer / self.duration or 1
	t = math.min(math.max(t, 0), 1)
	return self.from + (self.to - self.from) * self.curve(t)
end

function Tween:isFinished()
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

---@param target string
---@param from number
---@param to number
---@param duration number
---@param curve function
---@return Tween
function Tweens.create(target, from, to, duration, curve)
	return Tween.new(target, from, to, duration, curve or Tweens.BackOut)
end

return Tweens
