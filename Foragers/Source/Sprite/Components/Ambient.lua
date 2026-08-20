local Events = require("Source.Helpers.Core.Events")
local ValueParser = require("Source.Helpers.Core.ValueParser")

local Ambient = {}
Ambient.__index = Ambient

function Ambient.new(data)
	local self = setmetatable({
		despawnOnDay = data.despawnOnDay or false,
		despawnOnNight = data.despawnOnNight ~= false,
		duration = data.duration or 20,
		fadeOutDuration = data.fadeOutDuration or 1.5,
		interval = data.interval or 3,
		wanderingSpeed = data.wanderingSpeed or 10,
		_despawn = false,
		_fading = false,
		_fadeTimer = 0,
		_age = 0,
		_velocityX = 0,
		_velocityY = 0,
		_dirTimer = 0,
		_hasRaw = data.__raw ~= nil,
		type = "ambient",
	}, Ambient)

	if self._hasRaw then
		self.__raw = data.__raw
	end

	return self
end

function Ambient:_pickDirection()
	local angle = love.math.random() * math.pi * 2
	self._velocityX = math.cos(angle) * self.wanderingSpeed
	self._velocityY = math.sin(angle) * self.wanderingSpeed
end

function Ambient:attach()
	self:_pickDirection()

	if self._hasRaw and self.__raw.interval then
		self.interval = ValueParser.value(self.__raw.interval)
	end

	if self.despawnOnNight or self.despawnOnDay then
		local DayCycle = require("Source.Helpers.Systems.DayCycle")
		local sunData = DayCycle.getSunData()
		if self.despawnOnNight and not sunData.isDay then
			self._fading = true
			self._fadeTimer = 0
		end
		if self.despawnOnDay and sunData.isDay then
			self._fading = true
			self._fadeTimer = 0
		end
		DayCycle.emitter:on(Events.TIME_CHANGED, function(data)
			if self._despawn or not self.parent then
				return
			end
			if (self.despawnOnNight and not data.isDay) or (self.despawnOnDay and data.isDay) then
				self._fading = true
				self._fadeTimer = 0
			end
		end)
	end
end

--- Public query: safe for cross-component read (no side effects, stable per frame).
function Ambient:isDespawned()
	return self._despawn
end

--- Public signal: spawner calls this when fading an entity out of range.
function Ambient:markDespawn()
	self._despawn = true
end

function Ambient:update(dt)
	if not self.parent or self._despawn then
		return
	end

	self._age = self._age + dt

	if self._age >= self.duration and not self._fading then
		self._fading = true
		self._fadeTimer = 0
	end

	if self._fading then
		self._fadeTimer = self._fadeTimer + dt
		local progress = math.min(1, self._fadeTimer / self.fadeOutDuration)
		self.parent.alpha = 1 - progress
		if progress >= 1 then
			self._despawn = true
		end
	end

	self._dirTimer = self._dirTimer + dt
	if self._dirTimer >= self.interval then
		self._dirTimer = 0
		if self._hasRaw and self.__raw.interval then
			self.interval = ValueParser.value(self.__raw.interval)
		end
		self:_pickDirection()
	end

	self.parent.x = self.parent.x + self._velocityX * dt
	self.parent.y = self.parent.y + self._velocityY * dt
end

return Ambient