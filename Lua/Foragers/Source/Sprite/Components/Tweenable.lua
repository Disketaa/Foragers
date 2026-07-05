---@class Tweenable
---@field parent Sprite|nil Parent sprite reference
---@field tweens table[] Array of tween configurations
---@field tags table<string, table> Tween sets keyed by flip change or state
---@field type "tweenable"
local Tweenable = {}
Tweenable.__index = Tweenable

local Tweens = require("Source.Helpers.Tweens")

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
function Tweenable.new(data)
	return setmetatable({
		tweens = data.tweens or {},
		tags = data.tags or {},
		type = "tweenable",
	}, Tweenable)
end

function Tweenable:attach()
	self.parent:on("flipped", function()
		if self.tags.flip then
			applyTweens(self, self.tags.flip)
		end
	end, 10)

	self.parent:on("state_changed", function(newState, oldState)
		-- XOR: fires on both entering and leaving water
		if self.tags.splash and oldState and (oldState == "swimming") ~= (newState == "swimming") then
			applyTweens(self, self.tags.splash)
		end
	end, 10)
end

---@param dt number
function Tweenable:update(dt)
	for _, tween in pairs(self.parent and self.parent.tweens or {}) do
		tween:update(dt)
	end
end

return Tweenable
