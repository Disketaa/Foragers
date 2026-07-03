local Sprite = require("Source.Sprite.Sprite")
local WorldConfig = require("Content.Data.World") or {}
local TileData = require("Content.Assets.Sprites.World.GrassTiles")
local TilePalette = require("Source.World.TilePalette")
local Tileable = require("Source.Sprite.Components.Tileable")
local Collidable = require("Source.Sprite.Components.Collidable")

local private = {}
local tileSize = TileData and TileData.frameWidth or 8
local compData = TileData and TileData.components and TileData.components[1] or {}
local collidableData = nil
if TileData and TileData.components then
	for _, cd in ipairs(TileData.components) do
		if cd.component == "collidable" then
			collidableData = cd
			break
		end
	end
end

for k, v in pairs(WorldConfig) do
	private[k] = v
end

local function computeMask(world, x, y)
	local top = world[y - 1] and world[y - 1][x] and world[y - 1][x].active
	local right = world[y][x + 1] and world[y][x + 1].active
	local bottom = world[y + 1] and world[y + 1][x] and world[y + 1][x].active
	local left = world[y][x - 1] and world[y][x - 1].active
	return (top and 1 or 0) + (right and 2 or 0) + (bottom and 4 or 0) + (left and 8 or 0) -- + вместо |: LuaJIT
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

function private.buildWorldSprites(worldData, canvasWidth, canvasHeight, spawnCallback)
	local sprites = {}
	local offsetX = (canvasWidth - private.width * tileSize) / 2
	local offsetY = (canvasHeight - private.height * tileSize) / 2

	Collidable.resetTerrain()

	for y = 0, private.height - 1 do
		for x = 0, private.width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				local sprite = Sprite.new(tile.x + offsetX, tile.y + offsetY)
				sprite.frameWidth = tileSize
				sprite.frameHeight = tileSize
				sprite.pivotX = TileData.pivotX
				sprite.pivotY = TileData.pivotY

				local sx, sy = spawnCallback(tile)
				if sx then
					sprite.x = sx + offsetX
				end
				if sy then
					sprite.y = sy + offsetY
				end

				local component = Tileable.new(compData)
				component.frameWidth = tileSize
				component.frameHeight = tileSize
				component.pivotX = TileData.pivotX
				component.pivotY = TileData.pivotY
				local mask = computeMask(worldData, x, y)
				local tileIndex = TilePalette.resolve(mask, compData.tileMap)
				tileIndex = TilePalette.resolveVariant(tileIndex, compData.variants, tile.seed)
				component:setTile(tileIndex)
				sprite:addComponent(component)

				if collidableData then
					local collidableComp = Collidable.new(collidableData)
					sprite:addComponent(collidableComp)
					collidableComp.parent = sprite
					collidableComp:registerAsTerrain()
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
