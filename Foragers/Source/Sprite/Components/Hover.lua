---@class Hover
---@field parent Sprite|nil Sprite whose bounds trigger the cursor swap
---@field type "hover"
---@field cursorKind string Cursor kind applied while the pointer is over the parent (e.g. "hand")
---@field _hovered boolean Was hovered last frame (detect enter/exit)
local Hover = {}
Hover.__index = Hover

local Cursor = require("Source.Sprite.Components.Cursor")
local Bounds = require("Source.Helpers.Core.Bounds")
local GridNav = require("Source.Helpers.UI.GridNav")

---@param data table
---@return Hover
function Hover.new(data)
	return setmetatable({
		cursorKind = data.type or "hand",
		type = "hover",
		_hovered = false,
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
	if not p or (p.alpha ~= nil and p.alpha <= 0) then
		if self._hovered then
			self._hovered = false
			if p and not GridNav.active then
				local tw = p:findComponent("tween")
				if tw then tw:triggerTag("unselect") end
			end
		end
		return
	end
	local left, top, w, h = Bounds.spriteBounds(p)

	local inside = cx >= left and cx <= left + w and cy >= top and cy <= top + h
	if inside then
		cursor:setType(self.cursorKind)
		cursor._hoverClaimed = true
		if not self._hovered then
			self._hovered = true
			if GridNav.active and not GridNav.active._keyboardActive then
				GridNav.active:focusSprite(p)
			elseif not GridNav.active then
				local tw = p:findComponent("tween")
				if tw then tw:triggerTag("select") end
			end
		end
	elseif self._hovered then
		self._hovered = false
		if not GridNav.active then
			local tw = p:findComponent("tween")
			if tw then tw:triggerTag("unselect") end
		end
	end
end

return Hover
