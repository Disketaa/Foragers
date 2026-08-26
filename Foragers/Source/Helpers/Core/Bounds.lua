local Pivot = require("Source.Helpers.Core.Pivot")

local Bounds = {}

--- Compute sprite bounding box in its own coordinate space (pivot-aware).
--- Shared by Hover (cursor swap) and click detection (card picking).
---@param sprite table Sprite instance
---@return number left, number top, number width, number height
function Bounds.spriteBounds(sprite)
	local w = sprite.frameWidth or (sprite.image and sprite.image:getWidth()) or 0
	local h = sprite.frameHeight or (sprite.image and sprite.image:getHeight()) or 0
	local left = sprite.x - Pivot.px(sprite.pivotX, w, 0)
	local top = sprite.y - Pivot.px(sprite.pivotY, h, 0)
	return left, top, w, h
end

return Bounds