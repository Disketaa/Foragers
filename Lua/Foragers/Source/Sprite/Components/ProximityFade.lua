---@class ProximityFade
---@field parent Sprite|nil
---@field radius number Distance from player that triggers fade
---@field fadeAlpha number Target alpha when player is within radius
---@field smoothness number Transition speed (higher = faster)
---@field _currentAlpha number Current interpolated alpha
---@field type "proximity_fade"
local ProximityFade = {}
ProximityFade.__index = ProximityFade

---@type Sprite|nil
local playerRef = nil

function ProximityFade.setPlayer(sprite)
	playerRef = sprite
end

---@param data table
---@return ProximityFade
function ProximityFade.new(data)
	return setmetatable({
		radius = data.radius or 32,
		fadeAlpha = data.fadeAlpha or 0.3,
		smoothness = data.smoothness or 0.2,
		_currentAlpha = 1.0,
		type = "proximity_fade",
	}, ProximityFade)
end

---@param dt number
function ProximityFade:update(dt)
	if not self.parent or not playerRef then
		return
	end

	local dx = self.parent.x - playerRef.x
	local dy = self.parent.y - playerRef.y
	local dist = math.sqrt(dx * dx + dy * dy)

	local target = 1.0
	if dist < self.radius then
		target = self.fadeAlpha
	end

	local speed = self.smoothness > 0 and (1 - math.exp(-dt / self.smoothness)) or 1
	self._currentAlpha = self._currentAlpha + (target - self._currentAlpha) * speed
	self.parent.alpha = self._currentAlpha
end

return ProximityFade
