local Events = require("Source.Helpers.Core.Events")
local ValueParser = require("Source.Helpers.Core.ValueParser")
local DayCycle = require("Source.Helpers.Systems.DayCycle")

local Ambient = {}
Ambient.__index = Ambient

function Ambient.new(data)
	local winStart, winEnd = ValueParser.parseSpawnTime(data.spawnTime)
	local self = setmetatable({
		duration = data.duration or 20,
		fadeInDuration = data.fadeInDuration or 0.5,
		fadeOutDuration = data.fadeOutDuration or 1.5,
		changeDirectionInterval = data.changeDirectionInterval or 3,
		wanderingSpeed = data.wanderingSpeed or 10,
		spawnStart = winStart,
		spawnEnd = winEnd,
		_despawn = false,
		_entering = true,
		_fading = false,
		_fadeInTimer = 0,
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

	if self._hasRaw and self.__raw.changeDirectionInterval then
		self.changeDirectionInterval = ValueParser.value(self.__raw.changeDirectionInterval)
	end

	self.parent.alpha = 0

	self:_checkTime(DayCycle.getSunData())

	DayCycle.emitter:on(Events.TIME_CHANGED, function(data)
		if self._despawn or not self.parent then
			return
		end
		self:_checkTime(data)
	end)
end

--- Start fade-out if current time is outside the active window.
function Ambient:_checkTime(sunData)
	if self._despawn then
		return
	end
	local t = sunData.time
	local winStart, winEnd = self.spawnStart, self.spawnEnd
	local inside
	if winStart < winEnd then
		inside = t >= winStart and t < winEnd
	else
		inside = t >= winStart or t < winEnd
	end
	if not inside and not self._fading then
		self._entering = false
		self._fading = true
		self._fadeTimer = 0
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

	self:_checkTime(DayCycle.getSunData())

	if self._entering then
		self._fadeInTimer = self._fadeInTimer + dt
		local progress = math.min(1, self._fadeInTimer / self.fadeInDuration)
		self.parent.alpha = progress
		if progress >= 1 then
			self._entering = false
			self.parent.alpha = 1
		end
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
	if self._dirTimer >= self.changeDirectionInterval then
		self._dirTimer = 0
		if self._hasRaw and self.__raw.changeDirectionInterval then
			self.changeDirectionInterval = ValueParser.value(self.__raw.changeDirectionInterval)
		end
		self:_pickDirection()
	end

	self.parent.x = self.parent.x + self._velocityX * dt
	self.parent.y = self.parent.y + self._velocityY * dt
end

return Ambient