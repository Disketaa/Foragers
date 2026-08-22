---@class Hover
---@field parent Sprite|nil Sprite whose bounds trigger the cursor swap
---@field type "hover"
---@field cursorKind string Cursor kind applied while the pointer is over the parent (e.g. "hand")
local Hover = {}
Hover.__index = Hover

local Pivot = require("Source.Helpers.Core.Pivot")
local Cursor = require("Source.Sprite.Components.Cursor")

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
	if not p then return end
	local w = p.frameWidth or (p.image and p.image:getWidth()) or 0
	local h = p.frameHeight or (p.image and p.image:getHeight()) or 0
	local left = p.x - Pivot.px(p.pivotX, w, 0)
	local top = p.y - Pivot.px(p.pivotY, h, 0)

	if cx >= left and cx <= left + w and cy >= top and cy <= top + h then
		cursor:setType(self.cursorKind)
		cursor._hoverClaimed = true
	end
end

return Hover
