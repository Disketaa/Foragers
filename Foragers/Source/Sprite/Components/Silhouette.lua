---@class Silhouette
---@field parent Sprite|nil
---@field type "silhouette"
---@field mode "'silhouette'|'mask'" `"silhouette"`=player captured; `"mask"`=foliage reveals
local Silhouette = {}
Silhouette.__index = Silhouette

---@param data table
---@return Silhouette
function Silhouette.new(data)
	return setmetatable({
		type = "silhouette",
		mode = data.mode or "silhouette",
		color = data.color or { 0, 0, 0, 0.75 },
	}, Silhouette)
end

return Silhouette