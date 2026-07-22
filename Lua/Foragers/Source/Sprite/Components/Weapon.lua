---@class Weapon
---@field parent Sprite|nil
---@field range number Attack range in pixels
---@field cooldown number Seconds between attacks
---@field damage number HP per hit
---@field swing {angleFrom:number, angleTo:number, duration:number, lunge:number}
---@field type "weapon"
local Weapon = {}
Weapon.__index = Weapon

function Weapon.new(data)
	local swing = data.swing or {}
	return setmetatable({
		range = data.range or 20,
		cooldown = data.cooldown or 0.5,
		damage = data.damage or 1,
		swing = {
			angleFrom = swing.angleFrom or -30,
			angleTo = swing.angleTo or 30,
			duration = swing.duration or 0.15,
			offsetX = swing.offsetX or 0,
			offsetY = swing.offsetY or -8,
			curve = swing.curve or "OutSine",
			smoothness = swing.smoothness or 0,
		},
		type = "weapon",
	}, Weapon)
end

return Weapon