local Palette = {}
Palette.__index = Palette

local CONFIGS = {
	tier = {
		dataModule = require("Source.Helpers.Systems.Tiers"),
		default = "bronze",
		invalidateCanvas = true,
	},

	rarity = {
		dataModule = require("Content.Assets.Palettes.Rarity"),
		default = "common",
		invalidateCanvas = false,
	},
}

function Palette.new(data)
	local scheme = data and data.scheme or "tier"
	local cfg = CONFIGS[scheme]
	assert(cfg, "unknown palette scheme: " .. tostring(scheme))

	local self = setmetatable({
		type = scheme,
		scheme = scheme,
		value = data and (data.tier or data.rarity) or cfg.default,
		level = data and data.level or nil,
		_shader = nil,
	}, Palette)
	return self
end

function Palette:attach()
	if not self.parent then
		return
	end
	self._shader = self.parent:findComponent("shader")
	if not self._shader then
		return
	end
	if self.parent and self.parent.data then
		if self.scheme == "rarity" and self.parent.data.rarity then
			self.value = self.parent.data.rarity
		elseif self.scheme == "tier" and self.parent.data.tier then
			self.value = self.parent.data.tier
		end
	end
	self:_resolve()
	self:_apply()
end

function Palette:setTier(name)
	self.scheme = "tier"
	self.value = name
	self:_apply()
end

function Palette:setRarity(name)
	self.scheme = "rarity"
	self.value = name
	self:_apply()
end

function Palette:setLevel(level)
	if self.level == level then
		return
	end
	self.level = level
	self:_resolve()
	self:_apply()
end

function Palette:_resolve()
	if not self.level then
		return
	end
	local cfg = CONFIGS[self.scheme]
	if self.scheme == "tier" then
		self.value = cfg.dataModule.tierNameForLevel(self.level)
	elseif self.scheme == "rarity" then
		self.value = cfg.dataModule.rarityNameForLevel(self.level)
	end
end

function Palette:_apply()
	local cfg = CONFIGS[self.scheme]
	local def = cfg.dataModule[self.value]
	if not def or not def.colors then
		return
	end
	local n = #def.colors
	for i = 1, n do
		local color = def.colors[i] or def.colors[1]
		local key = "u_tier_" .. i
		if self.parent and self.parent.shaderData then
			self.parent.shaderData[key] = color
		end
		if self._shader then
			self._shader:_setUniform(key, color)
		end
	end
	if self.scheme == "rarity" and self._shader then
		local lastColor = def.colors[4] or def.colors[1]
		if self.parent and self.parent.shaderData then
			self.parent.shaderData["u_tier_5"] = lastColor
		end
		self._shader:_setUniform("u_tier_5", lastColor)
	end
	if cfg.invalidateCanvas and self.parent and self.parent.components then
		for _, comp in ipairs(self.parent.components) do
			if comp.type == "image" and comp._canvas then
				comp._canvas = nil
			end
		end
	end
end

return Palette