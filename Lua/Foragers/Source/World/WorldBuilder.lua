local SpriteLoader = require("Source.Sprite.SpriteLoader")
local TileData = require("Content.Assets.Sprites.Tiles.GrassTiles")
local TilePalette = require("Source.World.TilePalette")
local Collision = require("Source.Sprite.Components.Collision")
local Merge = require("Source.Helpers.Merge")
local WorldConfig = require("Content.Data.World") or {}

local private = {}

for k, v in pairs(WorldConfig) do
	private[k] = v
end

local tilePngPath
for k, v in pairs(package.loaded) do
	if v == TileData then
		tilePngPath = k:gsub("%.", "/") .. ".png"
		break
	end
end

local function computeMask(world, x, y)
	local top = world[y - 1] and world[y - 1][x] and world[y - 1][x].active
	local right = world[y][x + 1] and world[y][x + 1].active
	local bottom = world[y + 1] and world[y + 1][x] and world[y + 1][x].active
	local left = world[y][x - 1] and world[y][x - 1].active
	return (top and 1 or 0) + (right and 2 or 0) + (bottom and 4 or 0) + (left and 8 or 0)
end

local function buildTerrain(worldData, spawnCallback)
	local sprites = {}

	Collision.resetTerrain()

	for y = 0, private.height - 1 do
		for x = 0, private.width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				local sprite = SpriteLoader.instantiate(TileData, tile.x, tile.y, tilePngPath)

				local sx, sy = spawnCallback(tile)
				if sx then
					sprite.x = sx
				end
				if sy then
					sprite.y = sy
				end

				local adj = TileData.adjacency or {}
				local tileIndex = TilePalette.resolve(computeMask(worldData, x, y), adj.tileMap)
				tileIndex = TilePalette.resolveVariant(tileIndex, adj.variants, tile.seed)

				for _, comp in ipairs(sprite.components) do
					if comp.type == "spritesheet" then
						comp:setFrame(tileIndex)
					elseif comp.type == "collision" then
						comp:registerAsTerrain()
					end
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

local function spawnProps(worldData)
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

	local oldLow, oldHigh = love.math.getRandomSeed()
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

	love.math.setRandomSeed(oldLow, oldHigh)

	return props
end

local function build(worldData, spawnCallback)
	local terrain = buildTerrain(worldData, spawnCallback)
	local props = spawnProps(worldData) or {}
	return { terrain = terrain, props = props }
end

return {
	build = build,
}
