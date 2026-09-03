---@class Cursor
---@field parent Sprite|nil Parent sprite reference
---@field canvas Canvas|nil Live render canvas (offset/scale) for mouse->canvas mapping
---@field hideDelay number Seconds of no mouse movement before hiding
---@field moveThreshold number Pixel-distance threshold to count as movement
---@field type "cursor"
---@field cursorType string Visual cursor kind: "arrow" | "hand"
---@field defaultType string Base kind restored when nothing is hovered
---@field _images table<string, love.Image> Loaded cursor sprites keyed by kind
---@field _hoverClaimed boolean Raised by Hover on the frame the pointer is over a target
local Cursor = {}
Cursor.__index = Cursor

-- Live cursor instance, assigned by Main on the real cursor so hover-driven
-- components can switch its kind without depending on Main's locals.
Cursor.active = nil

local CURSOR_IMAGES = {
	arrow = "Content/Assets/Sprites/UI/Cursors/Arrow.png",
	hand = "Content/Assets/Sprites/UI/Cursors/Hand.png",
}

---@param data table
---@return Cursor
function Cursor.new(data)
	local images = {}
	for kind, path in pairs(CURSOR_IMAGES) do
		local ok, img = pcall(love.graphics.newImage, path)
		if ok then images[kind] = img end
	end
	return setmetatable({
		canvas = nil,
		hideDelay = data.hideDelay or 5.5,
		moveThreshold = data.moveThreshold or 1.5,
		cursorType = data.type or "arrow",
		defaultType = data.type or "arrow",
		_images = images,
		_state = "visible",
		_idleTimer = 0,
		_lastX = nil,
		_lastY = nil,
		type = "cursor",
		_hoverClaimed = false,
	}, Cursor)
end

--- Unknown kinds are ignored, so callers may pass any string safely.
---@param kind string
function Cursor:setType(kind)
	if self._images[kind] then
		self.cursorType = kind
	end
end

function Cursor:update(dt)
	local mx, my = love.mouse.getPosition()

	-- Restore the base kind unless a Hover claimed the pointer this
	-- frame; claims are raised during sprite updates and cleared here.
	if not self._hoverClaimed then
		self.cursorType = self.defaultType
	end
	self._hoverClaimed = false

	local img = self._images[self.cursorType]
	if img then
		self.parent.image = img
	end

	if self.canvas then
		self.parent.x = (mx - self.canvas.offsetX) / self.canvas.scale
		self.parent.y = (my - self.canvas.offsetY) / self.canvas.scale
	end

	if self.parent.tweens.alpha and not self.parent.tweens.alpha:isFinished() then
		self.parent.alpha = self.parent.tweens.alpha:getValue()
	end

	if not self._lastX then
		self._lastX, self._lastY = mx, my
	end
	local moved = (mx - self._lastX) ^ 2 + (my - self._lastY) ^ 2 > self.moveThreshold ^ 2
	self._lastX, self._lastY = mx, my

	self._tween = self._tween or self.parent:findComponent("tween")
	if not self._tween then
		return
	end

	if moved then
		self._idleTimer = 0
		if self._state == "hidden" then
			self._state = "visible"
			self._tween:triggerTag("show")
		end
	else
		self._idleTimer = self._idleTimer + dt
		if self._state == "visible" and self._idleTimer >= self.hideDelay then
			self._state = "hidden"
			self._tween:triggerTag("hide")
		end
	end
end

return Cursor

