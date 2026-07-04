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

local Animatable = require("Source.Sprite.Components.Animatable")
local Collidable = require("Source.Sprite.Components.Collidable")
local Controllable = require("Source.Sprite.Components.Controllable")
local Tileable = require("Source.Sprite.Components.Tileable")
local Tweenable = require("Source.Sprite.Components.Tweenable")
local Soundable = require("Source.Sprite.Components.Soundable")

ComponentRegistry.register("animatable", function(data)
	return Animatable.new(data)
end)
ComponentRegistry.register("collidable", function(data)
	return Collidable.new(data)
end)
ComponentRegistry.register("controllable", function(data)
	return Controllable.new(data)
end)
ComponentRegistry.register("tileable", function(data)
	return Tileable.new(data)
end)
ComponentRegistry.register("tweenable", function(data)
	return Tweenable.new(data)
end)
ComponentRegistry.register("soundable", function(data)
	return Soundable.new(data)
end)

return ComponentRegistry
