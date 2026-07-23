-- Math — exponential smoothing utility.
-- Random-value parsing migrated to Source/Helpers/Resolve.lua.

local Math = {}

function Math.expSmooth(dt, smoothness)
	if smoothness and smoothness > 0 then
		return 1 - math.exp(-dt / smoothness)
	end
	return 1
end

return Math
