---@class Emissive
---@field parent Sprite|nil
---@field intensity number 0..1 — how strongly the sprite is exempt from the day/night grade (1 = fully self-lit, 0 = graded normally)
---@field type "emissive"
local Emissive = {}
Emissive.__index = Emissive

-- Marker component: the sprite is still drawn normally into the world canvas
-- (so it receives Darken / CircleMask / Saturation), but Emissive.renderLayer
-- also records its coverage into a mask canvas that DayNightGrade samples to
-- skip the grade on those pixels (Minecraft-style exemption: the sprite keeps
-- its ungraded color through day/night). No per-frame logic of its own.
function Emissive.new(data)
	return setmetatable({
		intensity = data.intensity ~= nil and data.intensity or 1,
		type = "emissive",
	}, Emissive)
end

return Emissive
