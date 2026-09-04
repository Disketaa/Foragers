local WorldConfig = require("Content.Data.World") or {}
local TileData = require("Content.Assets.Sprites.Tiles.GrassTiles")

local private = {}
local tileSize = WorldConfig.tileSize or (TileData and TileData.frameWidth) or 8

-- Last generated world seed, exposed via getSeed() for the debug `seed` command.
-- Persists across the world lifetime so the command reads the current world's seed.
local lastSeed = nil

for k, v in pairs(WorldConfig) do
	private[k] = v
end

function private.generate()
	local world = {}
	local centerX = private.width / 2
	local centerY = private.height / 2
	local radius = math.min(centerX, centerY) - 0.5

	local noise = private.noise or {}
	local effectiveSeed = private.seed or -1
	if effectiveSeed < 0 then
		effectiveSeed = love.math.random(1, 999999)
	end
	lastSeed = effectiveSeed

	for y = 0, private.height - 1 do
		world[y] = {}
		for x = 0, private.width - 1 do
			local dx = x - centerX
			local dy = y - centerY
			local dist = math.sqrt(dx * dx + dy * dy)
			local normalizedDist = dist / radius

			-- 3D simplex noise: seed as z-dimension for deterministic variation per seed
			local island = love.math.noise(x * noise.scale, y * noise.scale, effectiveSeed)
			local detail = love.math.noise(x * noise.scale * 2 + 5, y * noise.scale * 2 + 5, effectiveSeed + 1000)
			local noiseVal = island + detail * noise.detail

			local rawNoise = noiseVal * 0.5 + 0.5
			local inCircle = normalizedDist < 1
			local active = rawNoise > noise.density and inCircle

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
	---@return number|nil The seed of the most recently generated world (nil before first generate).
	getSeed = function() return lastSeed end,
}