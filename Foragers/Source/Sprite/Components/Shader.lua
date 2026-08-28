local ShaderLoader = require("Source.Helpers.Graphics.ShaderLoader")

local ShaderComponent = {}
ShaderComponent.__index = ShaderComponent

function ShaderComponent.new(data)
	local specs = {}
	local names = {}
	if data.shaders then
		for _, s in ipairs(data.shaders) do
			local spec
			if type(s) == "string" then
				spec = { name = s }
			elseif s.name then
				spec = s
			else
				-- compact form: { ShaderName = { u_* = ... } }
				local name, params = next(s)
				spec = { name = name }
				if type(params) == "table" then
					for k, v in pairs(params) do
						spec[k] = v
					end
				end
			end
			table.insert(specs, spec)
			table.insert(names, spec.name)
		end
	else
		table.insert(specs, { name = data.shaderName or "Brightness" })
		table.insert(names, specs[1].name)
	end
	local self = setmetatable({
		type = "shader",
		shaderNames = names,
		shaderSpecs = specs,
		brightness = data.brightness or 0.5,
		_uniformWhitelist = {},
		_uniformValues = {},
	}, ShaderComponent)
	-- Pull per-shader uniform overrides (u_*) onto the component so attach()
	-- can read them via self[name]. Later specs override earlier ones.
	for _, spec in ipairs(specs) do
		for k, v in pairs(spec) do
			if k ~= "name" then
				self[k] = v
			end
		end
	end
	return self
end

function ShaderComponent:attach()
	local loaded = ShaderLoader.compose(self.shaderNames)
	if not loaded then
		return
	end

	self.parent.shader = loaded.shader

	if not self.parent.shaderData then
		self.parent.shaderData = {}
	end

	for name, default in pairs(loaded.uniforms or {}) do
		if self.parent.shader:hasUniform(name) then
			self._uniformWhitelist[name] = true
			local v = self[name] ~= nil and self[name] or default
			self._uniformValues[name] = v
			self.parent.shaderData[name] = v
		end
	end
	-- u_seed: per-instance variation. If not explicitly set, derive from position
	-- so multiple props of the same type sway out of phase.
	if self._uniformWhitelist.u_seed and self.u_seed == nil then
		local seed = (self.parent.x or 0) * 0.13 + (self.parent.y or 0) * 0.27
		self._uniformValues.u_seed = seed
		self.parent.shaderData.u_seed = seed
	end
	self.parent._shaderDirty = true
end

function ShaderComponent:setBrightness(value)
	self.brightness = math.max(0, math.min(1, value))
	if self._uniformWhitelist.u_brightness then
		self:_setUniform("u_brightness", self.brightness)
	end
end

function ShaderComponent:_setUniform(name, value)
	if not self._uniformWhitelist[name] then
		return
	end
	self._uniformValues[name] = value
	self.parent.shaderData[name] = value
	self.parent._shaderDirty = true
end

function ShaderComponent:update()
	if not self.parent then
		return
	end

	if self._uniformWhitelist.u_time then
		self:_setUniform("u_time", ShaderLoader.time)
	end

	if self._uniformWhitelist then
		for uniformName in pairs(self._uniformWhitelist) do
			if uniformName ~= "u_time" then
				local target = uniformName:match("^u_(.+)$")
				if target then
					local tween = self.parent.tweens and self.parent.tweens[target]
					local value = tween and tween:getValue() or self._uniformValues[uniformName]
					self:_setUniform(uniformName, value)
				end
			end
		end
	end
end

function ShaderComponent:setEnabled(enabled)
	if enabled then
		self.parent._shaderBroken = nil
		local loaded = ShaderLoader.compose(self.shaderNames)
		if loaded then
			self.parent.shader = loaded.shader
		end
	else
		self.parent.shader = nil
	end
end

return ShaderComponent
