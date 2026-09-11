local Rarities = require("Content.Data.Rarities")

local ORDER = {}
for name in pairs(Rarities) do
	table.insert(ORDER, name)
end
table.sort(ORDER)

local TOTAL = 0
for _, name in ipairs(ORDER) do
	TOTAL = TOTAL + (Rarities[name].weight or 1)
end

---@return string rarity name
function Rarities.pick()
	local roll = love.math.random(1, TOTAL)
	local cumulative = 0
	for _, name in ipairs(ORDER) do
		cumulative = cumulative + (Rarities[name].weight or 1)
		if roll <= cumulative then
			return name
		end
	end
	return ORDER[#ORDER]
end

local SCALE = {
	common = 1,
	uncommon = 2,
	rare = 4,
	legendary = 6,
}

---@param name string
---@return number rarity multiplier
function Rarities.scale(name)
	return SCALE[name] or 1
end

---@param name string
---@return number weight
function Rarities.weight(name)
	return Rarities[name] and Rarities[name].weight or 1
end

---@return number total weight sum
function Rarities.total()
	return TOTAL
end

return Rarities