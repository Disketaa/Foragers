local Events = require("Source.Helpers.Core.Events")

local deadSprites = {}

local Destructible = {}
Destructible.__index = Destructible

function Destructible.new(data)
	return setmetatable({
		hp = data.hp or 3,
		replaceWith = data.replaceWith,
		-- While guarded, this sprite is not a valid attack target. Set by
		-- Source/World/Overlay.lua so a host (bush/tree/rock) can't be hit until
		-- its fruit is destroyed.
		guarded = false,
		type = "destructible",
	}, Destructible)
end

function Destructible:takeDamage(amount)
	self.hp = self.hp - amount
	if self.hp <= 0 and self.parent then
		self.parent:emit(Events.PROP_BROKEN)
		if self.replaceWith then
			self.parent._replaceWith = self.replaceWith
		end
		deadSprites[self.parent] = true
	end
end

function Destructible.getDead()
	local list = {}
	for sprite in pairs(deadSprites) do
		table.insert(list, sprite)
	end
	return list
end

function Destructible.clearDead()
	for sprite in pairs(deadSprites) do
		deadSprites[sprite] = nil
	end
end

return Destructible