local Events = require("Source.Helpers.Events")

local orphanParticles = {}

local function parseRange(value)
	if type(value) == "number" then
		return value, value
	end
	if type(value) == "string" then
		local min, max = value:match("^(%-?%d+%.?%d*)%.%.%.%s*(%-?%d+%.?%d*)$")
		if min and max then
			return tonumber(min), tonumber(max)
		end
	end
	return value, value
end

local ParticleEmitter = {}
ParticleEmitter.__index = ParticleEmitter

function ParticleEmitter.new(data)
	local self = setmetatable({
		particle = data.particle,
		stepInterval = data.stepInterval or 2,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		inheritFlip = data.inheritFlip ~= false,
		maxParticles = data.maxParticles or 20,
		drawBehind = data.layer == "below",
		burstCount = data.burstCount or 1,
		burstRadius = data.burstRadius or 0,
		count = data.count,
		angle = data.angle,
		cone = data.cone or 0,

		_emittingStates = data.emittingStates or { moving = true },
		_burstOn = data.burstOn or {},
		_particles = {},
		_stepCounter = 0,
		_emitting = false,
		_cachedFlipX = false,
		_particleData = nil,
		type = "particle_emitter",
	}, ParticleEmitter)

	local luaPath = self.particle:gsub("[/\\]", "."):gsub("%.lua$", "")
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
		drawBehind = self.drawBehind,
	}

	if data.components and #data.components > 0 then
		local compData = {}
		for k, v in pairs(data.components[1]) do
			compData[k] = v
		end
		compData.frameWidth = data.frameWidth
		compData.frameHeight = data.frameHeight
		compData.pivotX = data.pivotX
		compData.pivotY = data.pivotY

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
		local pngPath = self.particle:gsub("%.lua$", ".png")
		local pngInfo = love.filesystem.getInfo(pngPath)
		if not pngInfo then
			return
		end

		local ok, image = pcall(function() return love.graphics.newImage(pngPath) end)
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

function ParticleEmitter:attach()
	self.parent:on(Events.STATE_CHANGED, function(newState)
		self._emitting = self._emittingStates[newState] or false
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

	for eventName, shouldBurst in pairs(self._burstOn) do
		if shouldBurst then
			self.parent:on(eventName, function()
				if not self._particleData then
					return
				end

				local count
				if self.count then
					local cmin, cmax = parseRange(self.count)
					count = math.floor(cmin + math.random() * (cmax - cmin + 1))
				else
					count = self.burstCount
				end

				local hx = self.parent._lastHitX or self.parent.x
				local hy = self.parent._lastHitY or self.parent.y
				local radius = self.burstRadius
				local angleMin, angleMax
				if self.angle then
					angleMin, angleMax = parseRange(self.angle)
				end
				local coneMin, coneMax
				if self.cone then
					coneMin, coneMax = parseRange(self.cone)
				end

				for i = 1, count do
					local baseAngleDeg = angleMin and (angleMin + math.random() * (angleMax - angleMin)) or 0
					local cone = coneMin and math.rad(coneMin + math.random() * (coneMax - coneMin)) or 0
					local spread = -cone / 2 + math.random() * cone
					local angle = math.rad(baseAngleDeg) + spread
					local px = hx + self.offsetX + math.random(-radius, radius)
					local py = hy + self.offsetY + math.random(-radius, radius)
					local p = self:_createParticle(px, py, angle)
					if p then
						table.insert(orphanParticles, p)
					end
				end
			end, 5)
		end
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
end

function ParticleEmitter:_spawn()
	local p = self:_createParticle(self.parent.x + self.offsetX, self.parent.y + self.offsetY)
	if p then
		table.insert(self._particles, p)
	end
end

function ParticleEmitter:draw()
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
end

function ParticleEmitter.updateOrphans(dt)
	for i = #orphanParticles, 1, -1 do
		local p = orphanParticles[i]
		if p.anim then
			p.anim:update(dt)
		end
		p._age = p._age + dt
		if p._age >= p._duration then
			table.remove(orphanParticles, i)
		end
	end
end

function ParticleEmitter.drawOrphans(behind)
	for _, p in ipairs(orphanParticles) do
		if p.drawBehind == behind then
			if p.anim then
				p.anim:draw(p.x, p.y)
			else
				local sx = p.flipX and -1 or 1
				local ox = p.frameWidth * p.pivotX
				local oy = p.frameHeight * p.pivotY
				love.graphics.draw(p.image, math.floor(p.x + 0.5), math.floor(p.y + 0.5), 0, sx, 1, ox, oy)
			end
		end
	end
end

return ParticleEmitter
