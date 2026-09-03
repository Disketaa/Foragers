local Tiers = require("Content.Data.Tiers")

local TIER_ORDER = {}
for name in pairs(Tiers) do
	table.insert(TIER_ORDER, name)
end
table.sort(TIER_ORDER, function(a, b) return Tiers[a].maxLevel < Tiers[b].maxLevel end)

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

--- Returns the tier name for a level.
---@param level number
---@return string tierName
function Tiers.tierNameForLevel(level)
	local idx = Tiers.tierForLevel(level)
	return TIER_ORDER[idx]
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
