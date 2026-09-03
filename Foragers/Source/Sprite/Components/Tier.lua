local Tiers = require("Content.Data.Tiers")

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
		print("[Tier DEBUG] attach: no parent")
		return
	end
	self._shader = self.parent:findComponent("shader")
	print(string.format("[Tier DEBUG] attach parent=%s shader=%s", tostring(self.parent.object), tostring(self._shader and self._shader.name or "nil")))
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
	print(string.format("[Tier DEBUG] setLevel called level=%s", tostring(level)))
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
	local bestName = nil
	local bestMax = math.huge
	for name, def in pairs(Tiers) do
		if type(def) == "table" and def.maxLevel then
			if self.level < def.maxLevel and def.maxLevel < bestMax then
				bestMax = def.maxLevel
				bestName = name
			end
		end
	end
	if bestName then
		self.tier = bestName
	else
		self.tier = "bronze"
	end
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
	-- DEBUG: no-tick, prints once per tier apply
	local parentType = self.parent and self.parent.object or "unknown"
	print(string.format("[Tier DEBUG] parent=%s tier=%s level=%s u_tier_1=%s", parentType, tostring(self.tier), tostring(self.level), tostring(def.colors[1])))
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
