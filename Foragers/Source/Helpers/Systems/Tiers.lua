local Tiers = require("Content.Data.Tiers")

local TIER_ORDER = {}
for name in pairs(Tiers) do
	table.insert(TIER_ORDER, name)
end
table.sort(TIER_ORDER, function(a, b) return Tiers[a].maxLevel < Tiers[b].maxLevel end)

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

---@param level number
---@return string tierName
function Tiers.tierNameForLevel(level)
	local idx = Tiers.tierForLevel(level)
	return TIER_ORDER[idx]
end

---@param level number
---@return number, number, number
function Tiers.tierColor(level)
	local idx = Tiers.tierForLevel(level)
	local name = TIER_ORDER[idx]
	local def = Tiers[name]
	if def and def.colors and def.colors[1] then
		return def.colors[1][1], def.colors[1][2], def.colors[1][3]
	end
	return 1, 1, 1
end

return Tiers
