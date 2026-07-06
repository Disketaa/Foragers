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

local Collision = require("Source.Sprite.Components.Collision")
local Control = require("Source.Sprite.Components.Control")
local Spritesheet = require("Source.Sprite.Components.Spritesheet")
local TweenModule = require("Source.Sprite.Components.Tween")
local Sound = require("Source.Sprite.Components.Sound")
local ParticleEmitter = require("Source.Sprite.Components.ParticleEmitter")
local Follow = require("Source.Sprite.Components.Follow")
local Destructible = require("Source.Sprite.Components.Destructible")
local Weapon = require("Source.Sprite.Components.Weapon")

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
	return TweenModule.Component.new(data)
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
ComponentRegistry.register("destructible", function(data)
	return Destructible.Component.new(data)
end)
ComponentRegistry.register("weapon", function(data)
	return Weapon.new(data)
end)

return ComponentRegistry
