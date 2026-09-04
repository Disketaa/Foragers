local Tiers = require("Source.Helpers.Systems.Tiers")

local Tier = {}
Tier.__index = Tier

function Tier.new(data)
	local self = setmetatable({
		type = "tier",
		tier = data and data.tier or "bronze",
		level = data and data.level or nil,
		_shader = nil,
	}, Tier)
	return self
end

function Tier:attach()
	if not self.parent then
		return
	end
	self._shader = self.parent:findComponent("shader")
	if not self._shader then
		return
	end
	self:_resolve()
	self:_apply()
end

function Tier:setTier(name)
	if self.tier == name then
		return
	end
	self.tier = name
	self:_apply()
end

function Tier:setLevel(level)
	if self.level == level then
		return
	end
	self.level = level
	self:_resolve()
	self:_apply()
end

function Tier:_resolve()
	if not self.level then
		return
	end
	self.tier = Tiers.tierNameForLevel(self.level)
end

function Tier:_apply()
	local def = Tiers and Tiers[self.tier]
	if not def or not def.colors then
		return
	end
	for i = 1, 5 do
		local color = def.colors[i] or def.colors[1]
		-- Update parent shaderData directly so per-image Palette shaders can
		-- forward these uniforms without going through the sprite shader's
		-- whitelist (the sprite shader may not include Palette).
		if self.parent and self.parent.shaderData then
			self.parent.shaderData["u_tier_" .. i] = color
		end
		if self._shader then
			self._shader:_setUniform("u_tier_" .. i, color)
		end
	end
	-- Invalidate all Image component canvases on the parent so they re-bake
	-- with the new tier colors. Without this, the icon canvas stays cached
	-- with the old tier colors forever.
	if self.parent and self.parent.components then
		for _, comp in ipairs(self.parent.components) do
			if comp.type == "image" and comp._canvas then
				comp._canvas = nil
			end
		end
	end
end

return Tier