local SpriteLoader = require("Source.Sprite.SpriteLoader")
local TileData = require("Content.Assets.Sprites.Tiles.GrassTiles")
local TilePalette = require("Source.World.TilePalette")
local Collision = require("Source.Sprite.Components.Collision")
local Merge = require("Source.Helpers.Merge")
local Path = require("Source.Helpers.Path")
local WorldConfig = require("Content.Data.World") or {}

local private = {}

for k, v in pairs(WorldConfig) do
	private[k] = v
end

local function rectsOverlap(a, b)
	return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y
end

local tilePngPath = Path.moduleToPath("Content.Assets.Sprites.Tiles.GrassTiles") .. ".png"

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

				local ss = sprite:findComponent("spritesheet")
				if ss then
					ss:setFrame(tileIndex)
				end
				local col = sprite:findComponent("collision")
				if col then
					col:registerAsTerrain()
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

local function spawnProps(worldData, playerSprite)
	local props = {}
	local propConfigs = private.props or {}
	local coverage = private.propCoverage or 0.3
	local tileSize = private.tileSize or 8

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
			local pngPath = Path.moduleToPath(cfg.data) .. ".png"
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

	local activeTiles = {}
	for y = 0, private.height - 1 do
		for x = 0, private.width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				local skip = false
				if playerSprite then
					local tileRect = { x = tile.x, y = tile.y, w = tileSize, h = tileSize }
					for _, comp in
						ipairs(playerSprite:getComponents("collision", function(c)
							return c.getRect
						end))
					do
						if rectsOverlap(tileRect, comp:getRect()) then
							skip = true
							break
						end
					end
				end
				if not skip then
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

		local ss = sprite:findComponent("spritesheet")
		if ss then
			local numFrames = ss.columns or 1
			local frameIndex = math.abs(tile.seed + 5000) % numFrames
			ss:setFrame(frameIndex)
		end
		local col = sprite:findComponent("collision")
		if col then
			if col.mode == "slowdown" then
				col:registerAsSlowdown()
			else
				col:registerAsSolid()
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

local function buildBorder()
	local borderTileOffset = private.borderTileOffset or 0
	local borderSize = math.min(private.width, private.height) + 2 * borderTileOffset
	if borderSize <= 0 then
		return
	end

	local tileSize = private.tileSize or 8
	local borderLeft = math.floor((private.width - borderSize) / 2)
	local borderTop = math.floor((private.height - borderSize) / 2)

	local rects = {
		{ x = borderLeft * tileSize, y = borderTop * tileSize, w = borderSize * tileSize, h = tileSize },
		{
			x = borderLeft * tileSize,
			y = (borderTop + borderSize - 1) * tileSize,
			w = borderSize * tileSize,
			h = tileSize,
		},
		{ x = borderLeft * tileSize, y = borderTop * tileSize, w = tileSize, h = borderSize * tileSize },
		{
			x = (borderLeft + borderSize - 1) * tileSize,
			y = borderTop * tileSize,
			w = tileSize,
			h = borderSize * tileSize,
		},
	}

	for _, rect in ipairs(rects) do
		Collision.addSolid(rect)
	end
end

local function build(worldData, spawnCallback, playerSprite)
	local terrain = buildTerrain(worldData, spawnCallback)
	local props = spawnProps(worldData, playerSprite) or {}
	buildBorder()
	return { terrain = terrain, props = props }
end

return {
	build = build,
}
