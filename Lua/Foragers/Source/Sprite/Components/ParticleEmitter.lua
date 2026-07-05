local Animation = require("Source.Sprite.Components.Animation")
local Events = require("Source.Helpers.Events")

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
		_emittingStates = data.emittingStates or { moving = true },
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
	local data = self._particleData
	if not data then
		return
	end

	local particle = {
		x = self.parent.x + self.offsetX,
		y = self.parent.y + self.offsetY,
		_age = 0,
	}

	if data.components and #data.components > 0 then
		---@cast data.components -nil
		local compData = {}
		for k, v in pairs(data.components[1]) do
			compData[k] = v
		end
		compData.frameWidth = data.frameWidth
		compData.frameHeight = data.frameHeight
		compData.pivotX = data.pivotX
		compData.pivotY = data.pivotY

		local ok, anim = pcall(Animation.new, compData)
		if not ok then
			return
		end

		anim.currentAnim = next(anim.animations)
		if not anim.currentAnim then
			return
		end

		anim.parent = {
			flipX = self._cachedFlipX,
			emit = function(event, ...)
				if self.parent then
					self.parent:emit(event, ...)
				end
			end,
		}

		local config = anim.animations[anim.currentAnim]
		if not config then
			return
		end

		particle.anim = anim
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

	table.insert(self._particles, particle)
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

return ParticleEmitter
