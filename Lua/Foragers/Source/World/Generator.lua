local Sprite = require("Source.Sprite.Sprite")

local private = {}

private.width = 20
private.height = 20
private.tileSize = 8
private.seed = 42

function private.generate()
	local world = {}
	local centerX = private.width / 2
	local centerY = private.height / 2
	local radius = math.min(centerX, centerY) - 0.5

	love.math.setRandomSeed(private.seed)

	for y = 0, private.height - 1 do
		world[y] = {}
		for x = 0, private.width - 1 do
			local dx = x - centerX
			local dy = y - centerY
			local dist = math.sqrt(dx * dx + dy * dy)
			local normalizedDist = dist / radius

			local island = love.math.noise(x * 0.15, y * 0.15)
			local detail = love.math.noise(x * 0.35 + 5, y * 0.35 + 5)
			local noiseVal = island + detail * 0.4

			local rawNoise = noiseVal * 0.5 + 0.5
			local circleMask = normalizedDist < 1 and (1 - normalizedDist ^ 2.5) or 0
			local elevation = rawNoise * circleMask
			local active = rawNoise > 0.75 and circleMask > 0.05

			world[y][x] = {
				x = x * private.tileSize,
				y = y * private.tileSize,
				elevation = elevation,
				noise = noiseVal,
				dist = normalizedDist,
				active = active,
			}
		end
	end

	return world
end

function private.buildWorldSprites(worldData, spawnCallback)
	local sprites = {}
	local offsetX = (480 - private.width * private.tileSize) / 2
	local offsetY = (270 - private.height * private.tileSize) / 2

	for y = 0, private.height - 1 do
		for x = 0, private.width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				local sprite = Sprite.new(tile.x + offsetX, tile.y + offsetY)
				sprite.frameWidth = private.tileSize
				sprite.frameHeight = private.tileSize
				sprite.pivotX = 0.5
				sprite.pivotY = 0.5
				sprite.type = "StaticSprite"
				sprite.image = love.graphics.newImage("Content/Assets/Sprites/World/TileDebug.png")

				local sx, sy = spawnCallback(tile)
				if sx then
					sprite.x = sx + offsetX
				end
				if sy then
					sprite.y = sy + offsetY
				end

				table.insert(sprites, {
					path = "World/" .. x .. "_" .. y,
					data = tile,
					instance = sprite,
				})
			end
		end
	end
	return sprites
end

return {
	generate = private.generate,
	buildWorldSprites = private.buildWorldSprites,
}
