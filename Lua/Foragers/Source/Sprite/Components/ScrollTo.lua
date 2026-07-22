local Math = require("Source.Helpers.Math")

---@class ScrollTo
---@field parent Sprite|nil
---@field followTarget Sprite|nil Target to follow (usually player)
---@field smoothness number Seconds to reach target (higher = slower)
---@field offsetX number Camera offset X from target center
---@field offsetY number Camera offset Y from target center
---@field chunkSize number World-unit size of a camera chunk; when > 0 the camera snaps to
--- chunk centers instead of tracking the target every frame (kills pixel-perfect jitter)
---@field type "scroll_to"
local ScrollTo = {}
ScrollTo.__index = ScrollTo

---@param data table
---@return ScrollTo
function ScrollTo.new(data)
	return setmetatable({
		smoothness = Math.parseRandomValue(data.smoothness) or 0.1,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		chunkSize = data.chunkSize or 0,
		_currentX = 0,
		_currentY = 0,
		type = "scroll_to",
	}, ScrollTo)
end

---@param target Sprite
function ScrollTo:setFollowTarget(target)
	self.followTarget = target
end

---@param dt number
function ScrollTo:update(dt)
	if not self.followTarget then
		return
	end

	local targetX = self.followTarget.x + self.offsetX
	local targetY = self.followTarget.y + self.offsetY

	-- Snap to chunk center so the camera stays static inside a chunk and pixel-perfect sprites don't sub-pixel-jitter.
	if self.chunkSize > 0 then
		targetX = math.floor(targetX / self.chunkSize) * self.chunkSize + self.chunkSize / 2
		targetY = math.floor(targetY / self.chunkSize) * self.chunkSize + self.chunkSize / 2
	end

	local ease = Math.expSmooth(dt, self.smoothness)
	self._currentX = self._currentX + (targetX - self._currentX) * ease
	self._currentY = self._currentY + (targetY - self._currentY) * ease
end

---@return number, number Camera X, Y
function ScrollTo:getCameraOffset()
	return self._currentX, self._currentY
end

return ScrollTo