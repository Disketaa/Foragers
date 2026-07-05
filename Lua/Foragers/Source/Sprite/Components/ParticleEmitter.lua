local Animatable = require("Source.Sprite.Components.Animatable")

local ParticleEmitter = {}
ParticleEmitter.__index = ParticleEmitter

function ParticleEmitter.new(data)
	return setmetatable({
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
end

function ParticleEmitter:attach()
	self.parent:on("state_changed", function(newState)
		self._emitting = self._emittingStates[newState] or false
		self._stepCounter = 0
	end, 8)

	self.parent:on("flipped", function(newFlip)
		self._cachedFlipX = newFlip
	end, 12)

	self.parent:on("anim_frame", function()
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
	if not self._particleData then
		local luaPath = self.particle:gsub("[/\\]", "."):gsub("%.lua$", "")
		local success, data = pcall(require, luaPath)
		if success then
			self._particleData = data
		end
	end

	for i = #self._particles, 1, -1 do
		local p = self._particles[i]
		p.anim:update(dt)
		local anim = p.anim.animations[p.anim.currentAnim]
		if anim and not anim.loop then
			local maxTime = (anim.frames - 1) / anim.speed
			if p.anim.currentTime >= maxTime then
				if p._scheduledForRemoval then
					table.remove(self._particles, i)
				else
					p._scheduledForRemoval = true
				end
			end
		end
	end
end

function ParticleEmitter:_spawn()
	local data = self._particleData
	if not data or not data.components or #data.components == 0 then
		return
	end

	local compData = {}
	for k, v in pairs(data.components[1]) do
		compData[k] = v
	end
	compData.frameWidth = data.frameWidth
	compData.frameHeight = data.frameHeight
	compData.pivotX = data.pivotX
	compData.pivotY = data.pivotY

	local anim = Animatable.new(compData)
	anim.currentAnim = next(anim.animations)
	anim.parent = {
		flipX = self._cachedFlipX,
		emit = function() end,
	}

	table.insert(self._particles, {
		x = self.parent.x + self.offsetX,
		y = self.parent.y + self.offsetY,
		anim = anim,
	})
end

function ParticleEmitter:draw()
	for _, p in ipairs(self._particles) do
		p.anim:draw(p.x, p.y)
	end
end

return ParticleEmitter
