local Math = require("Source.Helpers.Core.Math")

local TimeScale = {}
TimeScale.scale = 1
TimeScale.target = 1
TimeScale.smoothness = 0.3

--- Snap scale (and target) to a value — used for instant changes (satiety
--- slow-mo, restart), not eased.
function TimeScale.set(scale)
	TimeScale.scale = scale
	TimeScale.target = scale
end

--- Ease scale toward target (used for the death anim's slow-mo → full return).
function TimeScale.update(dt)
	local ease = Math.expSmooth(dt, TimeScale.smoothness)
	TimeScale.scale = TimeScale.scale + (TimeScale.target - TimeScale.scale) * ease
	if math.abs(TimeScale.scale - TimeScale.target) < 0.001 then
		TimeScale.scale = TimeScale.target
	end
end

return TimeScale