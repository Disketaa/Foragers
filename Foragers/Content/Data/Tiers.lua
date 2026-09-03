local Tiers = {
	bronze = {
		maxLevel = 5,
		colors = {
			{ 0.93, 0.7, 0.61 },
			{ 0.9, 0.54, 0.21 },
			{ 0.88, 0.44, 0.52 },
			{ 0.69, 0.32, 0.4 },
			{ 0.56, 0.32, 0.73 },
		},
	},

	silver = {
		maxLevel = 10,
		colors = {
			{ 0.78, 0.83, 0.99 },
			{ 0.53, 0.63, 0.73 },
			{ 0.7, 0.9, 0.79 },
			{ 0.52, 0.77, 0.6 },
			{ 0.36, 0.6, 0.47 },
		},
	},

	gold = {
		maxLevel = 15,
		colors = {
			{ 1, 0.94, 0.53 },
			{ 0.97, 0.77, 0.22 },
			{ 0.93, 0.86, 0.56 },
			{ 0.98, 0.64, 0.43 },
			{ 0.77, 0.53, 0.33 },
		},
	},

	diamond = {
		maxLevel = 20,
		colors = {
			{ 0.94, 0.94, 1 },
			{ 0.45, 0.93, 0.9 },
			{ 0.68, 0.91, 0.87 },
			{ 0.54, 0.76, 0.76 },
			{ 0.25, 0.74, 0.9 },
		},
	},

	nebular = {
		maxLevel = 25,
		colors = {
			{ 0.98, 0.83, 1 },
			{ 0.83, 0.5, 0.73 },
			{ 0.8, 0.66, 0.92 },
			{ 0.75, 0.56, 0.66 },
			{ 0.56, 0.32, 0.73 },
		},
	},
}

-- Ordered list for index lookup; matches Tiers iteration order.
local TIER_ORDER = { "bronze", "silver", "gold", "diamond", "nebular" }

--- Returns 1-based tier index for a level. Iterates maxLevel thresholds.
---@param level number
---@return number tierIndex (1=bronze, 2=silver, etc.)
function Tiers.tierForLevel(level)
	for i, name in ipairs(TIER_ORDER) do
		local def = Tiers[name]
		if def and def.maxLevel and level < def.maxLevel then
			return i
		end
	end
	return #TIER_ORDER
end

--- Returns the top (brightest) tier color for a level.
---@param level number
---@return number, number, number r, g, b
function Tiers.tierColor(level)
	local idx = Tiers.tierForLevel(level)
	local name = TIER_ORDER[idx]
	local def = Tiers[name]
	if def and def.colors and def.colors[1] then
		return unpack(def.colors[1])
	end
	return 1, 1, 1
end

return Tiers
