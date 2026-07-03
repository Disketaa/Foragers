---@class Tweenable
---@field parent Sprite|nil Parent sprite reference
---@field tweens table[] Array of tween configurations
---@field tags table<string, table> Tween sets keyed by flip change or state
---@field _prevFlip boolean Previous flip state
---@field _prevState string|nil Previous _state
---@field type "tweenable"
local Tweenable = {}
Tweenable.__index = Tweenable

local Tweens = require("Source.Tweens")

local function applyTweens(self, tweenSet)
	for _, tweenData in pairs(tweenSet) do
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

---@param data table
---@return Tweenable
---@param data table
---@return Tweenable
function Tweenable.new(data)
	return setmetatable({
		tweens = data.tweens or {},
		tags = data.tags or {},
		_prevFlip = false,
		_prevState = nil,
		type = "tweenable",
	}, Tweenable)
end

---@param dt number
function Tweenable:update(dt)
	if self.tags.flip and self.parent then
		local currFlip = self.parent.flipX
		if currFlip ~= nil and currFlip ~= self._prevFlip then
			applyTweens(self, self.tags.flip)
		end
		self._prevFlip = currFlip or false
	end

	if self.tags.splash and self.parent then
		local currState = self.parent._state
		local wasSwimming = self._prevState == "swimming"
		local isSwimming = currState == "swimming"
		if wasSwimming ~= isSwimming then
			applyTweens(self, self.tags.splash)
		end
		self._prevState = currState
	end

	for _, tween in pairs(self.parent and self.parent.tweens or {}) do
		tween:update(dt)
	end
end

return Tweenable
