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

---Triggers a tween tag on the parent sprite if a tween component exists.
---@param p Sprite|nil Parent sprite
---@param tag string Tween tag to trigger
function Hover:_triggerTween(p, tag)
	if not p then return end
	local tw = p:findComponent("tween")
	if tw then tw:triggerTag(tag) end
end

---Handles parent invisible/unhovered logic. Returns false if processing should stop.
---@param p Sprite|nil Parent sprite
---@return boolean continueProcessing
function Hover:_handleParentInvisible(p)
	if not p or (p.alpha ~= nil and p.alpha <= 0) then
		if self._hovered then
			self._hovered = false
			if p and not GridNav.active then
				self:_triggerTween(p, "unselect")
			end
		end
		return false
	end
	return true
end

---GridNav hover focus: sets _hovered and focuses sprite when it should become
---the active selection based on nearest-center distance.
---@param cx number Canvas-space mouse X
---@param cy number Canvas-space mouse Y
---@param p Sprite|nil Parent sprite under the cursor
---@param mouseMoved boolean Whether the mouse actually moved this frame
function Hover:_gridNavFocus(cx, cy, p, mouseMoved)
	if not p then return end
	local current = GridNav.active:current()
	if current and current.sprite == p then
		-- Already the selected entry. Leaving its bounds never unselects
		-- while GridNav is active, so re-entering must not re-trigger
		-- select (that would replay the pop tween and CARD_SELECTED).
		self._hovered = true
		return
	end

	if not GridNav.active._keyboardEverUsed or mouseMoved then
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
end

---Handles the cursor-inside-bounds branch: sets cursor kind, claims hover,
---and dispatches to GridNav focus or plain select tween.
---@param p Sprite Parent sprite under the cursor
---@param cx number Canvas-space mouse X
---@param cy number Canvas-space mouse Y
---@param mouseMoved boolean Whether the mouse actually moved this frame
function Hover:_handleInsideBounds(p, cx, cy, mouseMoved)
    local cursor = Cursor.active
    cursor:setType(self.cursorKind)
    cursor._hoverClaimed = true
    if GridNav.active then
        self:_gridNavFocus(cx, cy, p, mouseMoved)
    elseif not self._hovered then
        self._hovered = true
        self:_triggerTween(p, "select")
    end
end

function Hover:update()
	local cursor = Cursor.active
	if not cursor or not cursor.canvas then return end
	if cursor._state == "hidden" then return end

	local mx, my = love.mouse.getPosition()
	local mouseMoved = (self._lastMX ~= nil) and ((mx ~= self._lastMX) or (my ~= self._lastMY))
	self._lastMX, self._lastMY = mx, my
	local cv = cursor.canvas
	local cx = (mx - cv.offsetX) / cv.scale
	local cy = (my - cv.offsetY) / cv.scale

	local p = self.parent
	if not self:_handleParentInvisible(p) then return end
	if not p then return end

	if _G._cardSelectHiding then
		return
	end
	local left, top, w, h = Bounds.spriteBounds(p)

	local inside = cx >= left and cx <= left + w and cy >= top and cy <= top + h
	if inside then
		self:_handleInsideBounds(p, cx, cy, mouseMoved)
	elseif self._hovered then
		self._hovered = false
		if not GridNav.active then
			self:_triggerTween(p, "unselect")
		end
	end
end

return Hover