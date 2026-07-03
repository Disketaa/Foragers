---@class Tweenable
---@field parent Sprite|nil Parent sprite reference
---@field tweens table[] Array of tween configurations
---@field tags table<string, table> Tween sets keyed by flip change or state
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
		tags = data.tags or {},
		_prevFlip = false,
		type = "tweenable",
	}, Tweenable)
end

function Tweenable:update(dt)
	if self.tags.flip and self.parent then
		local currFlip = self.parent.flipX
		if currFlip ~= nil and currFlip ~= self._prevFlip then
			for _, tweenData in pairs(self.tags.flip) do
				local curveFunc = Tweens[tweenData.curve] or Tweens.BackOut
				if not self.parent.tweens[tweenData.target] then
					self.parent.tweens[tweenData.target] =
						Tweens.create(tweenData.target, tweenData.from, tweenData.to, tweenData.duration, curveFunc)
				end
				local tween = self.parent.tweens[tweenData.target]
				tween.from = tweenData.from
				tween.to = tweenData.to
				tween.duration = tweenData.duration
				tween.curve = curveFunc
				tween:start()
			end
		end
		self._prevFlip = currFlip or false
	end

	for _, tween in pairs(self.parent and self.parent.tweens or {}) do
		tween:update(dt)
	end
end

return Tweenable
