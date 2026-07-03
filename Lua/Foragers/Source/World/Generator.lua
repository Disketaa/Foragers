local Sprite = require("Source.Sprite.Sprite")
local WorldConfig = require("Content.Data.World")
local TileData = require("Content.Assets.Sprites.World.TileDebug")

local private = {}
local tileSize = TileData.frameWidth

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

			local island = love.math.noise(x * private.scale, y * private.scale)
			local detail = love.math.noise(x * private.scale * 2 + 5, y * private.scale * 2 + 5)
			local noiseVal = island + detail * private.detail

			local rawNoise = noiseVal * 0.5 + 0.5
			local inCircle = normalizedDist < 1
			local active = rawNoise > private.density and inCircle

			world[y][x] = {
				x = x * tileSize,
				y = y * tileSize,
				noise = noiseVal,
				dist = normalizedDist,
				active = active,
			}
		end
	end

	return world
end

function private.buildWorldSprites(worldData, canvasWidth, canvasHeight, spawnCallback)
	local sprites = {}
	local offsetX = (canvasWidth - private.width * tileSize) / 2
	local offsetY = (canvasHeight - private.height * tileSize) / 2

	for y = 0, private.height - 1 do
		for x = 0, private.width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				local sprite = Sprite.new(tile.x + offsetX, tile.y + offsetY)
				sprite.frameWidth = tileSize
				sprite.frameHeight = tileSize
				sprite.pivotX = TileData.pivotX
				sprite.pivotY = TileData.pivotY
				sprite.type = "StaticSprite"
				sprite.image = love.graphics.newImage(private.tileImage)

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
