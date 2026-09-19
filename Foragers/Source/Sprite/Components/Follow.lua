local Events = require("Source.Helpers.Core.Events")
local Math = require("Source.Helpers.Core.Math")
local Pivot = require("Source.Helpers.Core.Pivot")

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
---@field accelerate number Acceleration factor applied to follow speed over time
---@field rotate boolean Whether the followed tool spins while accelerating
---@field arrivedThreshold number Distance (px) under which FOLLOW_ARRIVED emits
local Follow = {}
Follow.__index = Follow

---@param data table
---@return Follow
function Follow.new(data)
	return setmetatable({
		offsetX = tonumber(data.offsetX) or 0,
		offsetY = tonumber(data.offsetY) or 0,
		smoothnessX = tonumber(data.smoothnessX or data.smoothness) or 0,
		smoothnessY = tonumber(data.smoothnessY or data.smoothness) or 0,
		followRadius = tonumber(data.followRadius),
		followDelay = tonumber(data.followDelay),
		leanAngle = tonumber(data.leanAngle) or 0,
		leanThreshold = tonumber(data.leanThreshold) or 0.5,
		leanSmoothness = tonumber(data.leanSmoothness),
		accelerate = tonumber(data.accelerate) or 0,
		rotate = data.rotate == true,
		arrivedThreshold = tonumber(data.arrivedThreshold) or 3,
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

---@param smoothness number|nil Override the return-trip smoothing (seconds); defaults to the
--- component's base `smoothnessX`/`smoothnessY`. `AttackSystem` passes a value scaled by
--- attack speed so a faster swing also recalls the tool faster.
function Follow:recall(smoothness)
	self._tempTarget = nil
	self._tempOffsetX = 0
	self._tempOffsetY = 0
	self._deploySmoothness = nil
	self._recallSmoothness = smoothness
end

function Follow:_initScatterBase()
	if not self._scatterBaseX or not self._scatterBaseY then
		local tx = self.parent.tweens and self.parent.tweens.x and self.parent.tweens.x:getValue() or 0
		local ty = self.parent.tweens and self.parent.tweens.y and self.parent.tweens.y:getValue() or 0
		self._scatterBaseX = self.parent.x - tx
		self._scatterBaseY = self.parent.y - ty
	end
end

function Follow:_applyScatter()
	if not self._scatterBaseX or not self._scatterBaseY then
		self:_initScatterBase()
	end
	local tx = self.parent.tweens and self.parent.tweens.x and self.parent.tweens.x:getValue() or 0
	local ty = self.parent.tweens and self.parent.tweens.y and self.parent.tweens.y:getValue() or 0
	self.parent.x = self._scatterBaseX + tx
	self.parent.y = self._scatterBaseY + ty
end

function Follow:_isOutsideRadius(liveX, liveY)
	return not self._tempTarget
		and self.followRadius
		and (self.parent.x - liveX) ^ 2 + (self.parent.y - liveY) ^ 2 > self.followRadius ^ 2
end

function Follow:_tickDelay(dt)
	if not self.followDelay then
		return false
	end
	self._delayElapsed = (self._delayElapsed or 0) + dt
	if self._delayElapsed < self.followDelay then
		self:_initScatterBase()
		self:_applyScatter()
		return true
	end
	self._scatterBaseX = nil
	self._scatterBaseY = nil
	return false
end

function Follow:_updateLean(dt, dir, sx)
	local leanEase = Math.expSmooth(dt, self.leanSmoothness or sx)
	local dx = self.parent.x - (self._prevParentX or self.parent.x)
	self._prevParentX = self.parent.x
	local moving = math.abs(dx) > self.leanThreshold
	local targetAngle = moving and (self.leanAngle * dir) or 0
	self._currentAngle = self._currentAngle + (targetAngle - self._currentAngle) * leanEase
end

function Follow:_computeLiveTarget(dir)
	if self._tempTarget then
		return self._tempTarget.x + dir * self._tempOffsetX, self._tempTarget.y + self._tempOffsetY
	end
	return self.followTarget.x + dir * self.offsetX, self.followTarget.y + self.offsetY
end

function Follow:_initFollowEntry(liveX, liveY)
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

function Follow:_tryEmitArrived(liveX, liveY)
	if self._tempTarget or self._arrivedEmitted then
		return
	end
	local dist = math.abs(self.parent.x - liveX) + math.abs(self.parent.y - liveY)
	if dist < (self.arrivedThreshold or 3) then
		self._arrivedEmitted = true
		self.parent:emit(Events.FOLLOW_ARRIVED)
	end
end

function Follow:_resolveDir(useTarget)
	if self._tempTarget then
		return self._deployDir
	end
	return (self.parent.x < useTarget.x) and -1 or 1
end

function Follow:_baseSmoothnessFor(field)
	if self._tempTarget then
		return self._deploySmoothness or 0.02
	end
	return self._recallSmoothness or self[field]
end

function Follow:_applyRotation(dt, accelFactor)
	if self.rotate and not self._arrivedEmitted and accelFactor > 1 then
		self.parent.angle = (self.parent.angle or 0) + (accelFactor - 1) * dt * 180
	end
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

	local dir = self:_resolveDir(useTarget)
	local liveX, liveY = self:_computeLiveTarget(dir)

	-- Check if outside activation radius (deploy always overrides)
	if self:_isOutsideRadius(liveX, liveY) then
		self._arrivedEmitted = false
		self._elapsedFollowTime = nil
		self:_initScatterBase()
		self:_applyScatter()
		return
	end

	-- Delay before starting follow (scatter first)
	if self:_tickDelay(dt) then
		return
	end

	-- Inside radius: initialize follow from current position (tween offset already baked in)
	if self._followX == nil then
		self:_initFollowEntry(liveX, liveY)
	end

	self._elapsedFollowTime = (self._elapsedFollowTime or 0) + dt
	local accelFactor = 1 + self.accelerate * self._elapsedFollowTime

	-- Spin faster as acceleration builds, stops when outside radius (early return above)
	self:_applyRotation(dt, accelFactor)

	local sx = self:_baseSmoothnessFor("smoothnessX") / accelFactor
	local sy = self:_baseSmoothnessFor("smoothnessY") / accelFactor
	local easeX = Math.expSmooth(dt, sx)
	local easeY = Math.expSmooth(dt, sy)

	-- Lean toward travel direction; deploy flight moves too, so keep lean live there.
	self:_updateLean(dt, dir, sx)

	self._followX = self._followX + (liveX - self._followX) * easeX
	self._followY = self._followY + (liveY - self._followY) * easeY

	self.parent.x = self._followX
	self.parent.y = self._followY

	self:_tryEmitArrived(liveX, liveY)
end

function Follow:_computeDrawRotation()
	local rot = math.rad(self._currentAngle or 0)
	if self.parent.tweens and self.parent.tweens.swingAngle then
		rot = rot + math.rad(self.parent.tweens.swingAngle:getValue())
	end
	return rot
end

function Follow:_beginShader()
	return self.parent.applyShader and self.parent:applyShader() or false
end

function Follow:_endShader(hadShader)
	if hadShader then
		love.graphics.setShader()
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
	if not parent or not parent.image then
		return
	end
	local hadShader = self:_beginShader()
	local rot = self:_computeDrawRotation()
	love.graphics.draw(
		parent.image,
		math.floor(x + 0.5),
		math.floor(y + 0.5),
		rot,
		1,
		1,
		Pivot.px(parent.pivotX, parent.frameWidth or parent.image:getWidth(), "center"),
		Pivot.px(parent.pivotY, parent.frameHeight or parent.image:getHeight(), "bottom")
	)
	self:_endShader(hadShader)
end

return Follow