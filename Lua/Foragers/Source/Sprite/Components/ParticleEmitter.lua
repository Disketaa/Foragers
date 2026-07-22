local Events = require("Source.Helpers.Events")
local Path = require("Source.Helpers.Path")
local Math = require("Source.Helpers.Math")

local eventNames = {}
for _, name in pairs(Events) do
	eventNames[name] = true
end

local burstParticles = {}

local ParticleEmitter = {}
ParticleEmitter.__index = ParticleEmitter

function ParticleEmitter.new(data)
	local self = setmetatable({
		particle = data.particle,
		stepInterval = data.stepInterval or 2,
		interval = data.interval or 0,
		moving = data.moving or false,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		inheritFlip = data.inheritFlip ~= false,
		maxParticles = data.maxParticles or 20,
		drawBehind = data.layer == "below",
		count = data.count or 1,
		angle = data.angle,
		cone = data.cone or 0,
		radius = data.radius or data.burstRadius or 0,

		_spawnOn = data.spawnOn or {},
		_particles = {},
		_stepCounter = 0,
		_intervalTimer = 0,
		_lastParentX = nil,
		_lastParentY = nil,
		_emitting = false,
		_cachedFlipX = false,
		_particleData = nil,
		type = "particle_emitter",
	}, ParticleEmitter)

	local luaPath = Path.lua(self.particle)
	local success, particleData = pcall(require, luaPath)
	if success then
		self._particleData = particleData
	end

	return self
end

function ParticleEmitter:_createParticle(px, py, angle)
	local data = self._particleData
	if not data then
		return
	end

	local particle = {
		x = px,
		y = py,
		_age = 0,
		angle = angle or 0,
	}

	if data.components and #data.components > 0 then
		local compData
		for _, comp in ipairs(data.components) do
			if comp.component == "spritesheet" then
				compData = {}
				for k, v in pairs(comp) do
					compData[k] = v
				end
				break
			end
		end
		if not compData then
			return
		end
		compData.frameWidth = data.frameWidth
		compData.frameHeight = data.frameHeight
		compData.pivotX = data.pivotX
		compData.pivotY = data.pivotY
		if not compData.spriteSheet then
			compData.spriteSheet = Path.png(self.particle)
		end

		local ok, sp = pcall(function()
			return require("Source.Helpers.ComponentRegistry").create("spritesheet", compData)
		end)
		if not ok or not sp then
			return
		end

		sp.currentAnim = next(sp.animations)
		if not sp.currentAnim then
			return
		end

		sp.parent = {
			flipX = self._cachedFlipX,
			angle = angle or 0,
			emit = function(event, ...)
				if self.parent then
					self.parent:emit(event, ...)
				end
			end,
		}

		local config = sp.animations[sp.currentAnim]
		if not config then
			return
		end

		particle.anim = sp
		particle._duration = config.frames / config.speed
	else
		local pngPath = Path.png(self.particle)
		local pngInfo = love.filesystem.getInfo(pngPath)
		if not pngInfo then
			return
		end

		local ok, image = pcall(function()
			return love.graphics.newImage(pngPath)
		end)
		if not ok then
			return
		end

		particle.image = image
		particle.frameWidth = data.frameWidth or 16
		particle.frameHeight = data.frameHeight or 16
		particle.pivotX = data.pivotX or 0.5
		particle.pivotY = data.pivotY or 0.5
		particle.flipX = self._cachedFlipX
		particle._duration = data.lifetime or 0.5
	end

	return particle
end

function ParticleEmitter:_burst()
	if not self._particleData then
		return
	end

	local cmin, cmax = Math.parseRange(self.count)
	local count = math.floor(cmin + love.math.random() * (cmax - cmin + 1))

	local hx = self.parent._lastHitX or self.parent.x
	local hy = self.parent._lastHitY or self.parent.y

	local angleMin, angleMax
	if self.angle then
		angleMin, angleMax = Math.parseRange(self.angle)
	end

	for _ = 1, count do
		local baseAngleDeg = angleMin and (angleMin + love.math.random() * (angleMax - angleMin)) or 0
		local coneAng = math.rad(self.cone)
		local spread = -coneAng / 2 + love.math.random() * coneAng
		local ang = math.rad(baseAngleDeg) + spread
		local px = hx + self.offsetX + love.math.random(-self.radius, self.radius)
		local py = hy + self.offsetY + love.math.random(-self.radius, self.radius)
		local p = self:_createParticle(px, py, ang)
		if p then
			p.drawBehind = self.drawBehind
			table.insert(burstParticles, p)
		end
	end
end

function ParticleEmitter.updateBursts(dt)
	for i = #burstParticles, 1, -1 do
		local p = burstParticles[i]
		if p.anim then
			p.anim:update(dt)
		end
		p._age = p._age + dt
		if p._age >= p._duration then
			table.remove(burstParticles, i)
		end
	end
end

local function drawParticle(p)
	if p.anim then
		p.anim:draw(p.x, p.y)
	else
		local sx = p.flipX and -1 or 1
		local ox = p.frameWidth * p.pivotX
		local oy = p.frameHeight * p.pivotY
		love.graphics.draw(p.image, math.floor(p.x + 0.5), math.floor(p.y + 0.5), 0, sx, 1, ox, oy)
	end
end

function ParticleEmitter.drawBurstsBehind()
	local prevShader = love.graphics.getShader()
	love.graphics.setShader()
	for _, p in ipairs(burstParticles) do
		if p.drawBehind then
			drawParticle(p)
		end
	end
	love.graphics.setShader(prevShader)
end

function ParticleEmitter.drawBursts()
	local prevShader = love.graphics.getShader()
	love.graphics.setShader()
	for _, p in ipairs(burstParticles) do
		if not p.drawBehind then
			drawParticle(p)
		end
	end
	love.graphics.setShader(prevShader)
end

function ParticleEmitter:attach()
	for trigger, val in pairs(self._spawnOn) do
		if val and eventNames[trigger] then
			self.parent:on(trigger, function()
				self:_burst()
			end, 5)
		end
	end

	self.parent:on(Events.STATE_CHANGED, function(newState)
		self._emitting = self._spawnOn[newState] or false
		self._stepCounter = 0
		if self._emitting then
			self:_spawn()
		end
	end, 8)

	self.parent:on(Events.FLIPPED, function(newFlip)
		if self.inheritFlip then
			self._cachedFlipX = newFlip
		end
	end, 12)

	self.parent:on(Events.ANIM_FRAME, function()
		if not self._emitting or not self._particleData or #self._particles >= self.maxParticles then
			return
		end
		local interval = self.stepInterval
		if interval > 1 then
			self._stepCounter = self._stepCounter + 1
			if self._stepCounter % interval == 0 then
				self:_spawn()
			end
		else
			self:_spawn()
		end
	end, 13)
end

function ParticleEmitter:_spawn()
	local p = self:_createParticle(self.parent.x + self.offsetX, self.parent.y + self.offsetY)
	if p then
		table.insert(self._particles, p)
	end
end

function ParticleEmitter:update(dt)
	for i = #self._particles, 1, -1 do
		local p = self._particles[i]
		if p.anim then
			p.anim:update(dt)
		end
		p._age = p._age + dt
		if p._age >= p._duration then
			table.remove(self._particles, i)
		end
	end

	if self.interval and self.interval > 0 and self._particleData then
		local shouldAccumulate = true
		if self.moving then
			if not self.parent then
				shouldAccumulate = false
			else
				shouldAccumulate = self.parent.x ~= self._lastParentX or self.parent.y ~= self._lastParentY
				self._lastParentX = self.parent.x
				self._lastParentY = self.parent.y
			end
		end
		if shouldAccumulate then
			self._intervalTimer = self._intervalTimer + dt
			while self._intervalTimer >= self.interval do
				self._intervalTimer = self._intervalTimer - self.interval
				if #self._particles < self.maxParticles then
					self:_spawn()
				end
			end
		end
	end
end

function ParticleEmitter:draw()
	local prevShader = love.graphics.getShader()
	love.graphics.setShader()
	for _, p in ipairs(self._particles) do
		if p.anim then
			p.anim:draw(p.x, p.y)
		else
			local sx = p.flipX and -1 or 1
			local ox = p.frameWidth * p.pivotX
			local oy = p.frameHeight * p.pivotY
			love.graphics.draw(p.image, math.floor(p.x + 0.5), math.floor(p.y + 0.5), 0, sx, 1, ox, oy)
		end
	end
	love.graphics.setShader(prevShader)
end

return ParticleEmitter