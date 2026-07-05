---@class Follow
---@field parent Sprite|nil
---@field followTarget Sprite|nil
---@field offsetX number
---@field offsetY number
---@field smoothnessX number Seconds to reach target on X (0 = instant)
---@field smoothnessY number Seconds to reach target on Y (0 = instant)
---@field leanAngle number Degrees to tilt when moving (flip-aware)
---@field leanThreshold number Min pixel-delta per frame to trigger lean (lower = more sensitive)
---@field type "follow"
local Follow = {}
Follow.__index = Follow

---@param data table
---@return Follow
function Follow.new(data)
	return setmetatable({
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		smoothnessX = data.smoothnessX or 0,
		smoothnessY = data.smoothnessY or 0,
		leanAngle = data.leanAngle or 0,
		leanThreshold = data.leanThreshold or 0.5,
		type = "follow",
	}, Follow)
end

---@param target Sprite
function Follow:setFollowTarget(target)
	self.followTarget = target
end

---@param dt number
function Follow:update(dt)
	if not self.followTarget or not self.parent then
		return
	end

	local dir = self.followTarget.flipX and -1 or 1
	local liveX = self.followTarget.x + dir * self.offsetX
	local liveY = self.followTarget.y + self.offsetY

	if self._followX == nil then
		self._followX = liveX
		self._followY = liveY
		self._prevLiveX = liveX
		self._prevLiveY = liveY
		self._currentAngle = 0
	end

	local moving = math.abs(liveX - self._prevLiveX) > self.leanThreshold
	self._prevLiveX = liveX
	self._prevLiveY = liveY

	local easeX = self.smoothnessX > 0 and (1 - math.exp(-dt / self.smoothnessX)) or 1
	local easeY = self.smoothnessY > 0 and (1 - math.exp(-dt / self.smoothnessY)) or 1
	self._followX = self._followX + (liveX - self._followX) * easeX
	self._followY = self._followY + (liveY - self._followY) * easeY

	local targetAngle = moving and (self.leanAngle * dir) or 0
	self._currentAngle = self._currentAngle + (targetAngle - self._currentAngle) * easeX

	self.parent.x = self._followX
	self.parent.y = self._followY

	if self.parent.tweens and self.parent.tweens.y then
		self.parent.y = self.parent.y + self.parent.tweens.y:getValue()
	end
end

---@param x number
---@param y number
function Follow:draw(x, y)
	if not self.parent or not self.parent.image then
		return
	end
	local img = self.parent.image
	love.graphics.draw(
		img,
		math.floor(x + 0.5),
		math.floor(y + 0.5),
		math.rad(self._currentAngle or 0),
		1,
		1,
		(self.parent.frameWidth or img:getWidth()) * (self.parent.pivotX or 0.5),
		(self.parent.frameHeight or img:getHeight()) * (self.parent.pivotY or 1)
	)
end

return Follow
