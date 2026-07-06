---@class Follow
---@field parent Sprite|nil
---@field followTarget Sprite|nil
---@field offsetX number
---@field offsetY number
---@field smoothnessX number Seconds to reach target on X (0 = instant)
---@field smoothnessY number Seconds to reach target on Y (0 = instant)
---@field leanAngle number Degrees to tilt (flip-aware, based on weapon pos vs target)
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
		_tempOffsetX = 0,
		_tempOffsetY = 0,
		type = "follow",
	}, Follow)
end

---@param target Sprite
function Follow:setFollowTarget(target)
	self.followTarget = target
end

function Follow:deployTo(target, offsetX, offsetY, smoothness, dir)
	self._tempTarget = target
	self._tempOffsetX = offsetX or 0
	self._tempOffsetY = offsetY or 0
	self._deploySmoothness = smoothness or 0.02
	self._deployDir = dir or (self.parent and ((self.parent.x < target.x) and -1 or 1) or 1)
end

function Follow:recall()
	self._tempTarget = nil
	self._tempOffsetX = 0
	self._tempOffsetY = 0
	self._deploySmoothness = nil
end

---@param dt number
function Follow:update(dt)
	if not self.parent then
		return
	end

	local useTarget = self._tempTarget or self.followTarget
	if not useTarget then
		return
	end

	local dir = self._tempTarget and self._deployDir or ((self.parent.x < useTarget.x) and -1 or 1)
	local liveX, liveY
	if self._tempTarget then
		liveX = self._tempTarget.x + dir * self._tempOffsetX
		liveY = self._tempTarget.y + self._tempOffsetY
	else
		liveX = self.followTarget.x + dir * self.offsetX
		liveY = self.followTarget.y + self.offsetY
	end

	if self._followX == nil then
		self._followX = liveX
		self._followY = liveY
		self._prevLiveX = liveX
		self._prevLiveY = liveY
		self._currentAngle = 0
	end

	local sx = self._tempTarget and (self._deploySmoothness or 0.02) or self.smoothnessX
	local sy = self._tempTarget and (self._deploySmoothness or 0.02) or self.smoothnessY
	local easeX = sx > 0 and (1 - math.exp(-dt / sx)) or 1
	local easeY = sy > 0 and (1 - math.exp(-dt / sy)) or 1

	if self._tempTarget then
		self._currentAngle = 0
	else
		local moving = math.abs(liveX - self._prevLiveX) > self.leanThreshold
		self._prevLiveX = liveX
		self._prevLiveY = liveY
		local targetAngle = moving and (self.leanAngle * dir) or 0
		self._currentAngle = self._currentAngle + (targetAngle - self._currentAngle) * easeX
	end

	self._followX = self._followX + (liveX - self._followX) * easeX
	self._followY = self._followY + (liveY - self._followY) * easeY

	self.parent.x = self._followX
	self.parent.y = self._followY

	if self.parent.tweens then
		local function applyOffset(key)
			local tween = self.parent.tweens[key]
			if not tween then
				return 0
			end
			local raw = tween:getValue()
			if tween._smoothness and tween._smoothness > 0 then
				local sm = string.format("_sm_%s", key)
				self[sm] = self[sm] or raw
				self[sm] = self[sm] + (raw - self[sm]) * (1 - math.exp(-dt / tween._smoothness))
				return self[sm]
			end
			return raw
		end
		self.parent.x = self.parent.x + applyOffset("x")
		self.parent.y = self.parent.y + applyOffset("y")
	end
end

---@param x number
---@param y number
function Follow:draw(x, y)
	if not self.parent or not self.parent.image then
		return
	end
	local img = self.parent.image
	local rot = math.rad(self._currentAngle or 0)
	if self.parent.tweens and self.parent.tweens.swing_angle then
		rot = rot + math.rad(self.parent.tweens.swing_angle:getValue())
	end
	love.graphics.draw(
		img,
		math.floor(x + 0.5),
		math.floor(y + 0.5),
		rot,
		1,
		1,
		(self.parent.frameWidth or img:getWidth()) * (self.parent.pivotX or 0.5),
		(self.parent.frameHeight or img:getHeight()) * (self.parent.pivotY or 1)
	)
end

return Follow
