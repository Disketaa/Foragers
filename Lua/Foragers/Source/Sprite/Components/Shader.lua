local ShaderLoader = require("Source.Helpers.ShaderLoader")

local ShaderComponent = {}
ShaderComponent.__index = ShaderComponent

function ShaderComponent.new(data)
	local names
	if data.shaders then
		names = data.shaders
	else
		names = { data.shaderName or "Brightness" }
	end
	return setmetatable({
		type = "shader",
		shaderNames = names,
		brightness = data.brightness or 0.5,
		_uniformWhitelist = {},
		_uniformValues = {},
	}, ShaderComponent)
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

	local brightnessTween = self.parent.tweens and self.parent.tweens.brightness
	if brightnessTween and self._uniformWhitelist.u_brightness then
		self:_setUniform("u_brightness", brightnessTween:getValue())
	elseif self._uniformWhitelist.u_brightness then
		self:_setUniform("u_brightness", self.brightness)
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
