---@class Hover
---@field parent Sprite|nil Sprite whose bounds trigger the cursor swap
---@field type "hover"
---@field cursorKind string Cursor kind applied while the pointer is over the parent (e.g. "hand")
local Hover = {}
Hover.__index = Hover

local Cursor = require("Source.Sprite.Components.Cursor")
local Bounds = require("Source.Helpers.Core.Bounds")

---@param data table
---@return Hover
function Hover.new(data)
	return setmetatable({
		cursorKind = data.type or "hand",
		type = "hover",
	}, Hover)
end

function Hover:update()
	local cursor = Cursor.active
	if not cursor or not cursor.canvas then return end

	local mx, my = love.mouse.getPosition()
	local cv = cursor.canvas
	local cx = (mx - cv.offsetX) / cv.scale
	local cy = (my - cv.offsetY) / cv.scale

	local p = self.parent
	if not p or (p.alpha ~= nil and p.alpha <= 0) then return end
	local left, top, w, h = Bounds.spriteBounds(p)

	if cx >= left and cx <= left + w and cy >= top and cy <= top + h then
		cursor:setType(self.cursorKind)
		cursor._hoverClaimed = true
	end
end

return Hover
