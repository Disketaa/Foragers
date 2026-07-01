---@class Tweenable
---@field parent Sprite|nil Parent sprite reference
---@field tweens table[] Array of tween configurations
---@field _prevFlip boolean Previous flip state
---@field type "tweenable"
local Tweenable = {}
Tweenable.__index = Tweenable

local Tweens = require("Source.Tweens")

---@param data table
---@return Tweenable
function Tweenable.new(data)
	return setmetatable({
		tweens = data.tweens or {},
		_prevFlip = false,
		type = "tweenable",
	}, Tweenable)
end

function Tweenable:update(dt)
	if self.tweens and self.parent then
		local currFlip = self.parent.flipX
		if currFlip ~= self._prevFlip then
			for _, tweenData in pairs(self.tweens) do
				local curveFunc = Tweens[tweenData.curve] or Tweens.BackOut
				if not self.parent.tweens[tweenData.target] then
					self.parent.tweens[tweenData.target] =
						Tweens.create(tweenData.target, tweenData.from, tweenData.to, tweenData.duration, curveFunc)
				end
				local tween = self.parent.tweens[tweenData.target]
				tween.from = tweenData.from or tween.from
				tween.to = tweenData.to or tween.to
				tween.duration = tweenData.duration or tween.duration
				tween.curve = curveFunc
				tween:start()
			end
		end
		self._prevFlip = currFlip
	end

	for _, tween in pairs(self.parent and self.parent.tweens or {}) do
		tween:update(dt)
	end
end

return Tweenable
