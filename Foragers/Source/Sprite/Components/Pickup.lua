local Events = require("Source.Helpers.Core.Events")

---@class Pickup
---@field parent Sprite|nil
---@field xp number XP granted on collection
---@field type "pickup"
---@field satiety number|nil Satiety restored on collection (nil = grant XP instead)
local Pickup = {}
Pickup.__index = Pickup

---@param data table
---@return Pickup
function Pickup.new(data)
	return setmetatable({
		xp = data.xp or 1,
		satiety = data.satiety,
		_pending = false,
		type = "pickup",
	}, Pickup)
end

function Pickup:attach()
	if not self.parent then
		return
	end
	self.parent:on(Events.FOLLOW_ARRIVED, function()
		self._pending = true
	end, 5)

	self.parent:on(Events.TWEEN_COMPLETED, function()
		if not self._pending or not self.parent then
			return
		end
		self._pending = false
		local follow = self.parent:findComponent("follow")
		if follow and follow.followTarget then
			local pstats = follow.followTarget:findComponent("player_stats")
			if pstats then
				if self.satiety then
					pstats:restoreSatiety(self.satiety)
				else
					pstats:addExperience(self.xp)
				end
			end
		end
	end, 5)
end

return Pickup