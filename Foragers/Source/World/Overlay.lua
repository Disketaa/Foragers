-- Hosted-child wiring: spawn an overlay food (berry) on a host sprite and wire
-- the guard + host-claim lifecycle. Part of the host/overlay world system
-- (HostRegistry, PropWire). Not a data-declared sprite component — the overlay
-- config (object, offsets, inheritFrame) is per-food, chosen probabilistically
-- by PropPicker at plan time, so it lives in World.lua items, not host data.

local Events = require("Source.Helpers.Core.Events")
local Path = require("Source.Helpers.Core.Path")
local Merge = require("Source.Helpers.Core.Merge")
local HostRegistry = require("Source.World.HostRegistry")
local Log = require("Source.Helpers.Core.Log")

local Overlay = {}
Overlay.__index = Overlay

function Overlay.new(data)
	return setmetatable({
		object = data.object,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		hostType = data.hostType,
		hostKey = data.hostKey,
		inheritFrame = data.inheritFrame or false,
		child = nil,
		type = "overlay",
	}, Overlay)
end

function Overlay:attach()
	local SpriteLoader = require("Source.Sprite.SpriteLoader")
	local ok, data = pcall(require, Path.lua(self.object))
	if not ok or not data then
		return
	end
	if data.extends then
		data = Merge.resolveExtends(data)
	end
	local child = SpriteLoader.instantiate(data, self.parent.x + self.offsetX, self.parent.y + self.offsetY, Path.moduleToPath(self.object) .. ".png")
	if not child then
		return
	end
	self.child = child

	-- Reference back to the host so gameplay targeting (crosshair) can use the
	-- host's position instead of the child's offset position.
	child.hostParent = self.parent

	-- Draw the child with its host, not on a fixed layer: inherit the host's
	-- layer and sort just after it (sortY = y + sortOffsetY). A tree in front of
	-- the bush (higher sortY) then covers the berry too, instead of the berry
	-- always drawing above every layer-0 prop.
	child.layer = self.parent.layer
	-- Sub-pixel step, not +1: a full sortY step would cross a sprite (player)
	-- standing at the bush's footline, splitting bush and berry around it.
	child.sortOffsetY = self.parent.sortOffsetY + 0.01 - self.offsetY

	-- Mirror the host's flip so a flipped bush faces its berries the same way.
	-- Host flip is static (set once at spawn), so copying at attach stays in sync.
	child.flipX = self.parent.flipX

	-- Optionally start the child on the host's current animation frame so a
	-- bush at frame 3 spawns berries that also begin at frame 3.
	if self.inheritFrame then
		local hostSS = self.parent:findComponent("spritesheet")
		local childSS = child:findComponent("spritesheet")
		if hostSS and childSS then
			childSS:setAnimFrameIndex(hostSS:getAnimFrameIndex())
		end
	end

	-- Fire the spawn pop (sound + scale-in tween) the same way a standalone
	-- prop gets it. Listener components subscribed during instantiate above.
	child:emit(Events.PROP_SPAWNED)

	local col = child:findComponent("collision")
	if col then
		if col.mode == "slowdown" then
			col:registerAsSlowdown()
		elseif col.mode == "solid" then
			col:registerAsSolid()
		elseif col.mode == "detect" or col.mode == "solid_and_detect" then
			Log.write("Collision", "overlay child uses dynamic-only collision mode '%s'; not baking a static collider", tostring(col.mode))
		else
			Log.error("Collision", "overlay child has unknown collision mode '%s'; not baking a static collider", tostring(col.mode))
		end
	end

	-- Guard the host while its fruit is alive: the host is not a valid attack
	-- target until the fruit is destroyed. Universal for bush/berries,
	-- tree/apples, rock/snails, stump/mushrooms.
	local hostDC = self.parent:findComponent("destructible")
	if hostDC then
		hostDC.guarded = true
	end

	child:on(Events.PROP_BROKEN, function()
		if self.hostType then
			HostRegistry.release(self.hostType, self.hostKey)
		end
		if hostDC then
			hostDC.guarded = false
		end
		self.child = nil
	end, 3)

	-- Parent dies -> child dies too (routes through normal dead-sprite flow).
	self.parent:on(Events.PROP_BROKEN, function()
		if self.child then
			local dc = self.child:findComponent("destructible")
			if dc then
				dc:takeDamage(9999)
			end
		end
	end, 3)
end

--- Spawn an overlay food (berry) on a host sprite and wire the guard + host-claim
--- lifecycle. Returns the spawned child so the caller can register it in the
--- object list.
---@param hostSprite table
---@param object string  child data module path
---@param offsetX number
---@param offsetY number
---@param hostType string
---@param hostKey string
---@param inheritFrame boolean|nil  start child on host's current animation frame
---@return table|nil
function Overlay.spawnOnHost(hostSprite, object, offsetX, offsetY, hostType, hostKey, inheritFrame)
	local overlay = Overlay.new({
		object = object,
		offsetX = offsetX,
		offsetY = offsetY,
		hostType = hostType,
		hostKey = hostKey,
		inheritFrame = inheritFrame,
	})
	hostSprite:addComponent(overlay)
	return overlay.child
end

return Overlay