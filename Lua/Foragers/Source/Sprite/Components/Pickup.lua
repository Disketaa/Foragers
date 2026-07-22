local Events = require("Source.Helpers.Events")

---@class Pickup
---@field parent Sprite|nil
---@field xp number XP granted on collection
---@field type "pickup"
local Pickup = {}
Pickup.__index = Pickup

---@param data table
---@return Pickup
function Pickup.new(data)
	return setmetatable({
		xp = data.xp or 1,
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
		for _, comp in ipairs(self.parent.components) do
			if comp.type == "follow" and comp.followTarget then
				for _, pcomp in ipairs(comp.followTarget.components) do
					if pcomp.type == "player_stats" then
						pcomp:addExperience(self.xp)
						break
					end
				end
				break
			end
		end
	end, 5)
end

return Pickup