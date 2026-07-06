---@class Weapon
---@field parent Sprite|nil
---@field range number Attack range in pixels
---@field cooldown number Seconds between attacks
---@field damage number HP per hit
---@field type "weapon"
local Weapon = {}
Weapon.__index = Weapon

function Weapon.new(data)
	return setmetatable({
		range = data.range or 20,
		cooldown = data.cooldown or 0.5,
		damage = data.damage or 1,
		type = "weapon",
	}, Weapon)
end

return Weapon
