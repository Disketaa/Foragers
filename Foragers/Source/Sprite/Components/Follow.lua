local Events = require("Source.Helpers.Events")
local Math = require("Source.Helpers.Math")
local Pivot = require("Source.Helpers.Pivot")

---@class Follow
---@field parent Sprite|nil
---@field followTarget Sprite|nil
---@field offsetX number
---@field offsetY number
---@field smoothnessX number Seconds to reach target on X (0 = instant)
---@field smoothnessY number Seconds to reach target on Y (0 = instant)
---@field followRadius number|nil Max distance to follow — nil = always follow
---@field followDelay number|nil Seconds to wait before starting follow (scatter first)
---@field leanAngle number Degrees to tilt (flip-aware, based on weapon pos vs target)
---@field leanThreshold number Min pixel-delta per frame to trigger lean (lower = more sensitive)
---@field leanSmoothness number Seconds to ease lean angle (0 = instant; defaults to smoothnessX)
---@field type "follow"
local Follow = {}
Follow.__index = Follow

---@param data table
---@return Follow
function Follow.new(data)
	return setmetatable({
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		smoothnessX = data.smoothnessX or data.smoothness or 0,
		smoothnessY = data.smoothnessY or data.smoothness or 0,
		followRadius = data.followRadius or nil,
		followDelay = data.followDelay or nil,
		leanAngle = data.leanAngle or 0,
		leanThreshold = data.leanThreshold or 0.5,
		leanSmoothness = data.leanSmoothness,
		accelerate = data.accelerate or 0,
		rotate = data.rotate == true,
		arrivedThreshold = data.arrivedThreshold or 3,
		_arrivedEmitted = false,
		_tempOffsetX = 0,
		_tempOffsetY = 0,
		type = "follow",
	}, Follow)
end

function Follow:attach()
	if not self.parent then
		return
	end
	self._hasSpritesheet = self.parent:findComponent("spritesheet") and true or false
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

	-- Check if outside activation radius (deploy always overrides)
	local outsideRadius = not self._tempTarget
		and self.followRadius
		and (self.parent.x - liveX) ^ 2 + (self.parent.y - liveY) ^ 2 > self.followRadius ^ 2

	-- Apply tweens outside radius from fixed base (scatter visible, not cumulative)
	if outsideRadius then
		self._arrivedEmitted = false
		self._elapsedFollowTime = nil
		if not self._scatterBaseX then
			local tx, ty = 0, 0
			if self.parent.tweens then
				tx = self.parent.tweens.x and self.parent.tweens.x:getValue() or 0
				ty = self.parent.tweens.y and self.parent.tweens.y:getValue() or 0
			end
			self._scatterBaseX = self.parent.x - tx
			self._scatterBaseY = self.parent.y - ty
		end
		local tx = self.parent.tweens and self.parent.tweens.x and self.parent.tweens.x:getValue() or 0
		local ty = self.parent.tweens and self.parent.tweens.y and self.parent.tweens.y:getValue() or 0
		self.parent.x = self._scatterBaseX + tx
		self.parent.y = self._scatterBaseY + ty
		return
	end

	if self.followDelay and not self._delayElapsed then
		self._delayElapsed = 0
	end
	if self.followDelay and self._delayElapsed then
		self._delayElapsed = self._delayElapsed + dt
		if self._delayElapsed < self.followDelay then
			if not self._scatterBaseX then
				local tx, ty = 0, 0
				if self.parent.tweens then
					tx = self.parent.tweens.x and self.parent.tweens.x:getValue() or 0
					ty = self.parent.tweens.y and self.parent.tweens.y:getValue() or 0
				end
				self._scatterBaseX = self.parent.x - tx
				self._scatterBaseY = self.parent.y - ty
			end
			local tx = self.parent.tweens and self.parent.tweens.x and self.parent.tweens.x:getValue() or 0
			local ty = self.parent.tweens and self.parent.tweens.y and self.parent.tweens.y:getValue() or 0
			self.parent.x = self._scatterBaseX + tx
			self.parent.y = self._scatterBaseY + ty
			return
		end
		self._scatterBaseX = nil
		self._scatterBaseY = nil
	end

	-- Inside radius: initialize follow from current position (tween offset already baked in)
	if self._followX == nil then
		if self.followRadius then
			-- Radius mode: start from current position for smooth entry
			self._followX = self.parent.x
			self._followY = self.parent.y
		else
			-- Standard mode (tools): snap to target position
			self._followX = liveX
			self._followY = liveY
		end
		self._prevParentX = self.parent.x
		self._currentAngle = 0
		self._elapsedFollowTime = 0
		self.parent.angle = 0
		-- Clear scatter base so tweens don't teleport on re-entry
		self._scatterBaseX = nil
		self._scatterBaseY = nil
	end

	self._elapsedFollowTime = (self._elapsedFollowTime or 0) + dt
	local accelFactor = 1 + self.accelerate * self._elapsedFollowTime

	-- Spin faster as acceleration builds, stops when outside radius (early return above)
	if self.rotate and not self._arrivedEmitted and accelFactor > 1 then
		self.parent.angle = (self.parent.angle or 0) + (accelFactor - 1) * dt * 180
	end

	local sx = (self._tempTarget and (self._deploySmoothness or 0.02) or self.smoothnessX) / accelFactor
	local sy = (self._tempTarget and (self._deploySmoothness or 0.02) or self.smoothnessY) / accelFactor
	local easeX = Math.expSmooth(dt, sx)
	local easeY = Math.expSmooth(dt, sy)
	local leanEase = Math.expSmooth(dt, self.leanSmoothness or sx)

	-- Lean toward travel direction; deploy flight moves too, so keep lean live there.
	local dx = self.parent.x - (self._prevParentX or self.parent.x)
	self._prevParentX = self.parent.x
	local moving = math.abs(dx) > self.leanThreshold
	local targetAngle = moving and (self.leanAngle * dir) or 0
	self._currentAngle = self._currentAngle + (targetAngle - self._currentAngle) * leanEase

	self._followX = self._followX + (liveX - self._followX) * easeX
	self._followY = self._followY + (liveY - self._followY) * easeY

	self.parent.x = self._followX
	self.parent.y = self._followY

	if not self._tempTarget and not self._arrivedEmitted then
		local dist = math.abs(self.parent.x - liveX) + math.abs(self.parent.y - liveY)
		if dist < (self.arrivedThreshold or 3) then
			self._arrivedEmitted = true
			self.parent:emit(Events.FOLLOW_ARRIVED)
		end
	end
end

---@param x number
---@param y number
function Follow:draw(x, y)
	if not self.parent then
		return
	end
	if self._hasSpritesheet then
		return
	end
	local parent = self.parent
	if not parent.image then
		return
	end
	local hadShader = parent.applyShader and parent:applyShader() or false
	local img = parent.image
	local rot = math.rad(self._currentAngle or 0)
	if parent.tweens and parent.tweens.swing_angle then
		rot = rot + math.rad(parent.tweens.swing_angle:getValue())
	end
	love.graphics.draw(
		img,
		math.floor(x + 0.5),
		math.floor(y + 0.5),
		rot,
		1,
		1,
		Pivot.px(parent.pivotX, parent.frameWidth or img:getWidth(), "center"),
		Pivot.px(parent.pivotY, parent.frameHeight or img:getHeight(), "bottom")
	)
	if hadShader then
		love.graphics.setShader()
	end
end

return Follow
