local ComponentRegistry = {}

---@type table<string, function(table):table>
local factories = {}

---@param name string
---@param factory function
function ComponentRegistry.register(name, factory)
	factories[name] = factory
end

---@param name string
---@param data table
---@return table|nil
function ComponentRegistry.create(name, data)
	local factory = factories[name]
	if factory then
		return factory(data)
	end
	return nil
end

local Animation = require("Source.Sprite.Components.Animation")
local Collision = require("Source.Sprite.Components.Collision")
local Control = require("Source.Sprite.Components.Control")
local Spritesheet = require("Source.Sprite.Components.Spritesheet")
local Tween = require("Source.Sprite.Components.Tween")
local Sound = require("Source.Sprite.Components.Sound")
local ParticleEmitter = require("Source.Sprite.Components.ParticleEmitter")
local Follow = require("Source.Sprite.Components.Follow")

ComponentRegistry.register("animation", function(data)
	return Animation.new(data)
end)
ComponentRegistry.register("collision", function(data)
	return Collision.new(data)
end)
ComponentRegistry.register("control", function(data)
	return Control.new(data)
end)
ComponentRegistry.register("spritesheet", function(data)
	return Spritesheet.new(data)
end)
ComponentRegistry.register("tween", function(data)
	return Tween.new(data)
end)
ComponentRegistry.register("sound", function(data)
	return Sound.new(data)
end)
ComponentRegistry.register("particle_emitter", function(data)
	return ParticleEmitter.new(data)
end)
ComponentRegistry.register("follow", function(data)
	return Follow.new(data)
end)

return ComponentRegistry
