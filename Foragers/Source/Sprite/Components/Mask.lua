---@class Mask
---@field parent Sprite|nil
---@field type "mask"
local Mask = {}
Mask.__index = Mask

---@return Mask
function Mask.new()
	return setmetatable({
		type = "mask",
	}, Mask)
end

return Mask
