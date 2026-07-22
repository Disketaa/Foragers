local WorldConfig = require("Content.Data.World") or {}
local TileData = require("Content.Assets.Sprites.Tiles.GrassTiles")

local private = {}
local tileSize = WorldConfig.tileSize or (TileData and TileData.frameWidth) or 8

for k, v in pairs(WorldConfig) do
	private[k] = v
end

function private.generate()
	local world = {}
	local centerX = private.width / 2
	local centerY = private.height / 2
	local radius = math.min(centerX, centerY) - 0.5

	local effectiveSeed = private.seed
	if effectiveSeed < 0 then
		effectiveSeed = love.math.random(1, 999999)
	end

	for y = 0, private.height - 1 do
		world[y] = {}
		for x = 0, private.width - 1 do
			local dx = x - centerX
			local dy = y - centerY
			local dist = math.sqrt(dx * dx + dy * dy)
			local normalizedDist = dist / radius

			-- 3D simplex noise: seed as z-dimension for deterministic variation per seed
			local island = love.math.noise(x * private.scale, y * private.scale, effectiveSeed)
			local detail = love.math.noise(x * private.scale * 2 + 5, y * private.scale * 2 + 5, effectiveSeed + 1000)
			local noiseVal = island + detail * private.detail

			local rawNoise = noiseVal * 0.5 + 0.5
			local inCircle = normalizedDist < 1
			local active = rawNoise > private.density and inCircle

			world[y][x] = {
				x = x * tileSize,
				y = y * tileSize,
				active = active,
				seed = effectiveSeed + x * private.height + y,
			}
		end
	end

	return world
end

return {
	generate = private.generate,
}