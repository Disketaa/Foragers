---@class Tweenable
---@field parent Sprite|nil Parent sprite reference
---@field tweens table[] Array of tween configurations
---@field type "tweenable"
local Tweenable = {}
Tweenable.__index = Tweenable

local Tweens = require("Source.Tweens")

---@param data table
---@return Tweenable
function Tweenable.new(data)
	return setmetatable({
		tweens = data.tweens or {},
		type = "tweenable",
	}, Tweenable)
end

---@param target string
---@param from number
---@param to number
---@param duration number
---@param curve function
function Tweenable:triggerTween(target, from, to, duration, curve)
	if not self.parent.tweens[target] then
		self.parent.tweens[target] = Tweens.create(target, from, to, duration, curve)
	end
	local tween = self.parent.tweens[target]
	tween.from = from
	tween.to = to
	tween.duration = duration
	tween.curve = curve
	tween:start()
end

function Tweenable:update(dt)
	if self.tweens and self.parent then
		local currFlip = self.parent.flipX
		local prevFlip = self._prevFlip
		if currFlip ~= prevFlip then
			for _, tweenData in pairs(self.tweens) do
				local curveFunc = Tweens[tweenData.curve] or Tweens.BackOut
				self:triggerTween(tweenData.target, tweenData.from, tweenData.to, tweenData.duration, curveFunc)
			end
		end
		self._prevFlip = currFlip
	end

	for _, tween in pairs(self.parent and self.parent.tweens or {}) do
		tween:update(dt)
	end
end

return Tweenable
