--- Camera zoom. Eases current toward target with the same Math.expSmooth the
--- camera offset uses, so a future programmatic zoom animates consistently.
--- Clamped to [1, max] — never below 1, so zoom=1 is the maximum view and zooming
--- in can't reveal edges/background. UI/cursor draw outside the world canvas, so
--- they are unaffected. Numeric state survives Reset.all() (only array fields cleared).
local Math = require("Source.Helpers.Core.Math")

local Zoom = {}
Zoom.current = 1
Zoom.target = 1
Zoom.max = 8
-- Seconds to reach target (matches camera smoothing scale).
Zoom.smoothness = 0.5

---@param dt number
function Zoom.update(dt)
	if Zoom.current == Zoom.target then
		return
	end
	local ease = Math.expSmooth(dt, Zoom.smoothness)
	Zoom.current = Zoom.current + (Zoom.target - Zoom.current) * ease
	if math.abs(Zoom.current - Zoom.target) < 0.001 then
		Zoom.current = Zoom.target
	end
end

--- Back to the default 1x view. Called on restart — scalar fields are skipped by
--- Reset.all(), so this module resets itself explicitly.
function Zoom.reset()
	Zoom.current = 1
	Zoom.target = 1
end

return Zoom