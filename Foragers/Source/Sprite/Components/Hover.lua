---@class Hover
---@field parent Sprite|nil Sprite whose bounds trigger the cursor swap
---@field type "hover"
---@field cursorKind string Cursor kind applied while the pointer is over the parent (e.g. "hand")
---@field _hovered boolean Was hovered last frame (detect enter/exit)
---@field _lastMX number|nil Mouse X last frame (detect real movement)
---@field _lastMY number|nil Mouse Y last frame
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
		_lastMX = nil,
		_lastMY = nil,
	}, Hover)
end

function Hover:update()
	local cursor = Cursor.active
	if not cursor or not cursor.canvas then return end

	local mx, my = love.mouse.getPosition()
	local mouseMoved = (self._lastMX ~= nil) and ((mx ~= self._lastMX) or (my ~= self._lastMY))
	self._lastMX, self._lastMY = mx, my
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
		if GridNav.active then
			local current = GridNav.active:current()
			if current and current.sprite == p then
				if not self._hovered then
					-- Re-enter same card after mouse unhover: re-apply select.
					self._hovered = true
					GridNav.active:_setSelected(current, true)
				else
					self._hovered = true
				end
			elseif not GridNav.active._keyboardEverUsed or mouseMoved then
				-- Nearest-center: avoid jitter when cursor between overlapping cards.
				-- Only switch if this card's center is closer than current selection.
				local cur = current and current.sprite
				if not cur then
					self._hovered = true
					GridNav.active:focusSprite(p)
				else
					local dxSelf = cx - p.x
					local dySelf = cy - p.y
					local distSelf = dxSelf * dxSelf + dySelf * dySelf
					local dxCur = cx - cur.x
					local dyCur = cy - cur.y
					local distCur = dxCur * dxCur + dyCur * dyCur
					if distSelf < distCur then
						self._hovered = true
						GridNav.active:focusSprite(p)
					end
				end
			end
		elseif not self._hovered then
			self._hovered = true
			local tw = p:findComponent("tween")
			if tw then tw:triggerTag("select") end
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
