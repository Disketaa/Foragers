local ComponentRegistry = {}

---@type table<string, fun(table):table>
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
local SpriteSheet = require("Source.Sprite.Components.SpriteSheet")
local TweenModule = require("Source.Sprite.Components.Tween")
local Sound = require("Source.Sprite.Components.Sound")
local ParticleEmitter = require("Source.Sprite.Components.ParticleEmitter")
local Follow = require("Source.Sprite.Components.Follow")
local Destructible = require("Source.Sprite.Components.Destructible")
local Weapon = require("Source.Sprite.Components.Weapon")
local Shake = require("Source.Sprite.Components.Shake")
local ShaderComponent = require("Source.Sprite.Components.Shader")
local Drop = require("Source.Sprite.Components.Drop")
local ScrollTo = require("Source.Sprite.Components.ScrollTo")
local Shadow = require("Source.Sprite.Components.Shadow")
local SpriteFont = require("Source.Sprite.Components.SpriteFont")
local TextEmitter = require("Source.UI.Components.TextEmitter")
local Counter = require("Source.UI.Components.Counter")
local UI = require("Source.UI.Components.UI")
local PlayerStats = require("Source.Sprite.Components.PlayerStats")
local Pickup = require("Source.Sprite.Components.Pickup")
local Silhouette = require("Source.Sprite.Components.Silhouette")

local registry = {
	collision = Collision,
	control = Control,
	spritesheet = SpriteSheet,
	tween = TweenModule.Component,
	sound = Sound,
	particle_emitter = ParticleEmitter,
	follow = Follow,
	destructible = Destructible,
	weapon = Weapon,
	shake = Shake,
	shader = ShaderComponent,
	drop = Drop,
	scroll_to = ScrollTo,
	shadow = Shadow,
	spritefont = SpriteFont,
	text_emitter = TextEmitter,
	counter = Counter,
	ui = UI,
	player_stats = PlayerStats,
	pickup = Pickup,
	silhouette = Silhouette,
}
for name, module in pairs(registry) do
	ComponentRegistry.register(name, function(data) return module.new(data) end)
end

return ComponentRegistry
