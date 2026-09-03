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
	if not self._shader then
		return
	end
	local def = Tiers and Tiers[self.tier]
	if not def or not def.colors then
		return
	end
	for i = 1, 5 do
		local color = def.colors[i] or def.colors[1]
		self._shader:_setUniform("u_tier_" .. i, color)
	end
end

return Tier
