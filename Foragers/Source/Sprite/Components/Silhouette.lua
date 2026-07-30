---@class Silhouette
---@field parent Sprite|nil
---@field type "silhouette"
local Silhouette = {}
Silhouette.__index = Silhouette

---@return Silhouette
function Silhouette.new()
	return setmetatable({
		type = "silhouette",
	}, Silhouette)
end

return Silhouette
