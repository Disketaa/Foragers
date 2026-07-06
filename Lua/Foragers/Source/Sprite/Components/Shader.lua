local ShaderLoader = require("Source.Helpers.ShaderLoader")

local ShaderComponent = {}
ShaderComponent.__index = ShaderComponent

function ShaderComponent.new(data)
	return setmetatable({
		type = "shader",
		shaderName = data.shaderName or "Brightness",
		brightness = data.brightness or 0.5,
		_uniformWhitelist = {},
	}, ShaderComponent)
end

function ShaderComponent:attach()
	local loaded = ShaderLoader.loadByName(self.shaderName)
	if not loaded then
		return
	end

	self.parent.shader = loaded.shader

	local expected = { "u_brightness" }
	for _, name in ipairs(expected) do
		if self.parent.shader:hasUniform(name) then
			self._uniformWhitelist[name] = true
		end
	end

	if not self.parent.shaderData then
		self.parent.shaderData = {}
	end
	if self._uniformWhitelist.u_brightness then
		self.parent.shaderData.u_brightness = self.brightness
	end
end

function ShaderComponent:setBrightness(value)
	self.brightness = math.max(0, math.min(1, value))
	if self._uniformWhitelist.u_brightness then
		self.parent.shaderData.u_brightness = self.brightness
	end
end

function ShaderComponent:setEnabled(enabled)
	if enabled then
		self.parent._shaderBroken = nil
		local loaded = ShaderLoader.loadByName(self.shaderName)
		if loaded then
			self.parent.shader = loaded.shader
		end
	else
		self.parent.shader = nil
	end
end

return ShaderComponent
