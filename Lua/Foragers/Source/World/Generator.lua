local Sprite = require("Source.Sprite.Sprite")
local WorldConfig = require("Content.Data.World") or {}
local TileData = require("Content.Assets.Sprites.Tiles.GrassTiles")
local TilePalette = require("Source.World.TilePalette")
local Spritesheet = require("Source.Sprite.Components.Spritesheet")
local Collision = require("Source.Sprite.Components.Collision")

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

---@param worldData table
---@param spawnCallback function
---@return table
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

				local component = Spritesheet.new(compData)
				component.frameWidth = tileSize
				component.frameHeight = tileSize
				component.pivotX = TileData.pivotX
				component.pivotY = TileData.pivotY
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

	local loadedProps = {}
	for _, cfg in ipairs(propConfigs) do
		local ok, propData = pcall(require, cfg.data)
		if ok and type(propData) == "table" then
			local spritesheetData = nil
			local collidableData = nil
			for _, cd in ipairs(propData.components or {}) do
				if cd.component == "spritesheet" then
					spritesheetData = cd
				elseif cd.component == "collision" then
					collidableData = cd
				end
			end
			table.insert(loadedProps, {
				name = cfg.name,
				weight = cfg.weight or 1,
				data = propData,
				spritesheetData = spritesheetData,
				collidableData = collidableData,
				pngPath = cfg.data:gsub("%.", "/") .. ".png",
			})
		end
		package.loaded[cfg.data] = nil
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
				table.insert(activeTiles, tile)
			end
		end
	end

	local numProps = math.floor(#activeTiles * coverage)
	if numProps == 0 then
		return props
	end

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

		local sprite = Sprite.new(tile.x, tile.y)
		sprite.frameWidth = chosen.data.frameWidth
		sprite.frameHeight = chosen.data.frameHeight
		sprite.pivotX = chosen.data.pivotX
		sprite.pivotY = chosen.data.pivotY

		if chosen.spritesheetData then
			local component = Spritesheet.new(chosen.spritesheetData)
			component.frameWidth = chosen.data.frameWidth
			component.frameHeight = chosen.data.frameHeight
			component.pivotX = chosen.data.pivotX
			component.pivotY = chosen.data.pivotY
			local numFrames = chosen.spritesheetData.columns or 1
			local frameIndex = math.abs(tile.seed + 5000) % numFrames
			component:setFrame(frameIndex)
			sprite:addComponent(component)
		else
			sprite.image = love.graphics.newImage(chosen.pngPath)
			sprite.type = "StaticSprite"
		end

		if chosen.collidableData then
			local collidableComp = Collision.new(chosen.collidableData)
			sprite:addComponent(collidableComp)
			collidableComp:registerAsSolid()
		end

		table.insert(props, {
			path = chosen.name .. "_" .. tile.x .. "_" .. tile.y,
			data = tile,
			instance = sprite,
		})
	end

	return props
end

return {
	generate = private.generate,
	buildWorldSprites = private.buildWorldSprites,
	spawnProps = private.spawnProps,
}
