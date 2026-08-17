-- Shared prop instantiation + wiring used by both WorldBuilder (initial plan)
-- and PropSpawner (runtime streaming). One place for flip/frame/collision/host
-- registration and the spawn pop, so the two spawn paths can't drift apart.

local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Events = require("Source.Helpers.Core.Events")
local HostRegistry = require("Source.World.HostRegistry")
local Overlay = require("Source.World.Overlay")
local Log = require("Source.Helpers.Core.Log")

local PropWire = {}

--- Wire a freshly instantiated standalone prop: flip, frame, collision, host
--- registration, and the spawn pop (sound + tween).
---@param sprite table
---@param data table  resolved prop data (carries `host`)
---@param seed number
---@return table sprite
local function wire(sprite, data, seed)
	sprite.flipX = math.abs(seed + 7777) % 2 == 0

	local ss = sprite:findComponent("spritesheet")
	if ss then
		local numFrames = ss.columns or 1
		ss:setFrame(math.abs(seed + 5000) % numFrames)
	end

	local col = sprite:findComponent("collision")
	if col then
		if col.mode == "slowdown" then
			col:registerAsSlowdown()
		elseif col.mode == "solid" then
			col:registerAsSolid()
		elseif col.mode == "detect" or col.mode == "solid_and_detect" then
			Log.write("Collision", "prop uses dynamic-only collision mode '%s'; not baking a static collider", tostring(col.mode))
		else
			Log.error("Collision", "prop has unknown collision mode '%s'; not baking a static collider", tostring(col.mode))
		end
	end

	if data.host then
		HostRegistry.register(data.host, sprite)
		sprite:on(Events.PROP_BROKEN, function()
			HostRegistry.unregister(data.host, sprite)
		end, 3)
	end

	sprite:emit(Events.PROP_SPAWNED)

	return sprite
end

--- Instantiate + wire a standalone prop at a tile. Returns the sprite.
---@param data table  resolved prop data
---@param pngPath string
---@param x number
---@param y number
---@param seed number
---@return table|nil
function PropWire.standalone(data, pngPath, x, y, seed)
	local sprite = SpriteLoader.instantiate(data, x, y, pngPath)
	if not sprite then
		return nil
	end
	return wire(sprite, data, seed)
end

--- Spawn an overlay food (berry) on a host sprite. Returns the spawned child.
---@param hostSprite table
---@param chosen table  { modulePath, offsetX, offsetY, hostType, hostKey, inheritFrame }
---@return table|nil
function PropWire.onHost(hostSprite, chosen)
	return Overlay.spawnOnHost(hostSprite, chosen.modulePath, chosen.offsetX, chosen.offsetY, chosen.hostType, chosen.hostKey, chosen.inheritFrame)
end

return PropWire