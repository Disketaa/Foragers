local Sprite = require("Source.Sprite.Sprite")
local SpriteLoader = require("Source.Sprite.SpriteLoader")
local TileData = require("Content.Assets.Sprites.Tiles.GrassTiles")
local TilePalette = require("Source.World.TilePalette")
local ComponentRegistry = require("Source.Helpers.ComponentRegistry")
local Collision = require("Source.Sprite.Components.Collision")
local Merge = require("Source.Helpers.Merge")
local WorldConfig = require("Content.Data.World") or {}

local private = {}
local tileSize = TileData and TileData.frameWidth or 8
local compData = TileData and TileData.components and TileData.components[1] or {}
local collidableData = nil
if TileData and TileData.components then
	for _, cd in ipairs(TileData.components) do
		if cd.component == "collision" then
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
	return (top and 1 or 0) + (right and 2 or 0) + (bottom and 4 or 0) + (left and 8 or 0)
end

function private.buildWorldSprites(worldData, spawnCallback)
	local sprites = {}

	Collision.resetTerrain()

	for y = 0, private.height - 1 do
		for x = 0, private.width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				local sprite = Sprite.new(tile.x, tile.y)
				sprite.frameWidth = tileSize
				sprite.frameHeight = tileSize
				sprite.pivotX = TileData.pivotX
				sprite.pivotY = TileData.pivotY

				local sx, sy = spawnCallback(tile)
				if sx then
					sprite.x = sx
				end
				if sy then
					sprite.y = sy
				end

				local component = ComponentRegistry.create("spritesheet", compData) or {}
				local mask = computeMask(worldData, x, y)
				local adj = TileData.adjacency or {}
				local tileIndex = TilePalette.resolve(mask, adj.tileMap)
				tileIndex = TilePalette.resolveVariant(tileIndex, adj.variants, tile.seed)
				component:setFrame(tileIndex)
				sprite:addComponent(component)

				if collidableData then
					local collidableComp = Collision.new(collidableData)
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

function private.spawnProps(worldData)
	local props = {}
	local propConfigs = private.props or {}
	local coverage = private.propCoverage or 0.3

	Collision.resetSolids()
	Collision.resetSlowdown()

	local loadedProps = {}
	for _, cfg in ipairs(propConfigs) do
		local ok, propData = pcall(require, cfg.data)
		if ok and type(propData) == "table" then
			if propData.extends then
				propData = Merge.resolveExtends(propData)
			end
			local propName = cfg.data:match("([^%.]+)$"):lower()
			local pngPath = cfg.data:gsub("%.", "/") .. ".png"
			table.insert(loadedProps, {
				name = propName,
				weight = cfg.weight or 1,
				data = propData,
				pngPath = pngPath,
			})
		end
	end

	if #loadedProps == 0 then
		return props
	end

	local totalWeight = 0
	for _, p in ipairs(loadedProps) do
		totalWeight = totalWeight + p.weight
	end

	local centerTileX = math.floor(private.width / 2)
	local centerTileY = math.floor(private.height / 2)
	local spawnClearance = private.spawnClearance or 1
	local activeTiles = {}
	for y = 0, private.height - 1 do
		for x = 0, private.width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				local dx = x - centerTileX
				local dy = y - centerTileY
				if math.abs(dx) > spawnClearance or math.abs(dy) > spawnClearance then
					table.insert(activeTiles, tile)
				end
			end
		end
	end

	local numProps = math.floor(#activeTiles * coverage)
	if numProps == 0 then
		return props
	end

	local oldSeed = love.math.getRandomSeed()
	love.math.setRandomSeed(numProps > 0 and activeTiles[1].seed or 0)

	for i = 1, math.min(numProps, #activeTiles) do
		local j = love.math.random(i, #activeTiles)
		activeTiles[i], activeTiles[j] = activeTiles[j], activeTiles[i]
		local tile = activeTiles[i]

		local pick = love.math.random(1, totalWeight)
		local cumulative = 0
		local chosen = loadedProps[1]
		for _, p in ipairs(loadedProps) do
			cumulative = cumulative + p.weight
			if pick <= cumulative then
				chosen = p
				break
			end
		end

		local sprite = SpriteLoader.instantiate(chosen.data, tile.x, tile.y, chosen.pngPath)

		sprite.flipX = math.abs(tile.seed + 7777) % 2 == 0

		for _, comp in ipairs(sprite.components) do
			if comp.type == "spritesheet" then
				local numFrames = comp.columns or 1
				local frameIndex = math.abs(tile.seed + 5000) % numFrames
				comp:setFrame(frameIndex)
			elseif comp.type == "collision" then
				if comp.mode == "slowdown" then
					comp:registerAsSlowdown()
				else
					comp:registerAsSolid()
				end
			end
		end

		table.insert(props, {
			path = chosen.name .. "_" .. tile.x .. "_" .. tile.y,
			data = tile,
			instance = sprite,
		})
	end

	love.math.setRandomSeed(oldSeed)

	return props
end

return {
	buildWorldSprites = private.buildWorldSprites,
	spawnProps = private.spawnProps,
}
