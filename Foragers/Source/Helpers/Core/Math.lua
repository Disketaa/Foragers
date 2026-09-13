-- Random-value parsing migrated to Source/Helpers/Resolve.lua.
local Math = {}

function Math.expSmooth(dt, smoothness)
	if smoothness and smoothness > 0 then
		return 1 - math.exp(-dt / smoothness)
	end
	return 1
end

--- Project a bbox onto a direction vector.
--- Returns the min/max scalar projection across the 4 corners, normalized to [0,1] by canvas size.
---@param anchorX number bbox center x (canvas pixels)
---@param anchorY number bbox center y (canvas pixels)
---@param w number bbox width (canvas pixels)
---@param h number bbox height (canvas pixels)
---@param angle number direction angle in radians
---@param fw number canvas width for normalization
---@param fh number canvas height for normalization
---@return number lo, number hi
function Math.projectBBoxRange(anchorX, anchorY, w, h, angle, fw, fh)
	local halfW = w * 0.5
	local halfH = h * 0.5
	local left = (anchorX - halfW) / fw
	local right = (anchorX + halfW) / fw
	local top = (anchorY - halfH) / fh
	local bottom = (anchorY + halfH) / fh
	local dx, dy = math.cos(angle), math.sin(angle)
	local lo, hi = math.huge, -math.huge
	for _, c in ipairs({ { left, top }, { right, top }, { left, bottom }, { right, bottom } }) do
		local proj = c[1] * dx + c[2] * dy
		lo = math.min(lo, proj)
		hi = math.max(hi, proj)
	end
	return lo, hi
end

return Math