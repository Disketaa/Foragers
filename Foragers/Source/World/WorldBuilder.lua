local SpriteLoader = require("Source.Sprite.SpriteLoader")
local TileData = require("Content.Assets.Sprites.Tiles.GrassTiles")
local TilePalette = require("Source.World.TilePalette")
local Collision = require("Source.Sprite.Components.Collision")
local Path = require("Source.Helpers.Core.Path")
local Pivot = require("Source.Helpers.Core.Pivot")
local PropPicker = require("Source.World.PropPicker")
local WorldConfig = require("Content.Data.World") or {}

local private = {}

for k, v in pairs(WorldConfig) do
	private[k] = v
end

local function rectsOverlap(a, b)
	return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y
end

local tilePngPath = Path.moduleToPath("Content.Assets.Sprites.Tiles.GrassTiles") .. ".png"

-- SpriteBatch built incrementally as terrain tiles stream in (see
-- instantiateTerrainTile). Drawn via getTerrainBatch().
local terrainBatch = nil

local function computeMask(world, x, y)
	local top = world[y - 1] and world[y - 1][x] and world[y - 1][x].active
	local right = world[y][x + 1] and world[y][x + 1].active
	local bottom = world[y + 1] and world[y + 1][x] and world[y + 1][x].active
	local left = world[y][x - 1] and world[y][x - 1].active
	return (top and 1 or 0) + (right and 2 or 0) + (bottom and 4 or 0) + (left and 8 or 0)
end

--- Collapse each row's contiguous active tiles into one wide AABB. The union of
--- side-by-side solid tiles is itself a rectangle, so one merged rect collides
--- identically to the individual tiles. Grounded scans stay O(#runs) not O(#tiles).
local function mergeTerrainRects(worldData)
	local rects = {}
	local width, height = private.width, private.height
	local tileSize = private.tileSize
	for y = 0, height - 1 do
		local row = worldData[y]
		local x = 0
		while x < width do
			local tile = row[x]
			if tile and tile.active then
				local startX = x
				while x < width and row[x] and row[x].active do
					x = x + 1
				end
				rects[#rects + 1] = {
					-- Tiles are pivot-centered: sprite.x sits on the grid point and
					-- the old per-tile rect spanned ±tileSize/2 around it. Center each
					-- merged run the same way so the union matches the original AABBs.
					x = startX * tileSize - tileSize / 2,
					y = y * tileSize - tileSize / 2,
					w = (x - startX) * tileSize,
					h = tileSize,
				}
			else
				x = x + 1
			end
		end
	end
	return rects
end

--- Build the terrain plan: which active tiles and their frame, computed once
--- (mask + palette only, no sprite creation). Collision is set synchronously so
--- the player has ground immediately; tile sprites/batch are streamed over
--- frames by the caller, nearest-player-first.
local function buildTerrainPlan(worldData, spawnCallback, playerSprite)
	terrainBatch = nil
	Collision.setTerrain(mergeTerrainRects(worldData))
	local adj = TileData.adjacency or {}
	local plan = {}
	for y = 0, private.height - 1 do
		for x = 0, private.width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				local sx, sy = spawnCallback(tile)
				local tileIndex = TilePalette.resolve(computeMask(worldData, x, y), adj.tileMap)
				tileIndex = TilePalette.resolveVariant(tileIndex, adj.variants, tile.seed)
				plan[#plan + 1] = {
					data = tile,
					path = "World/" .. x .. "_" .. y,
					x = sx or tile.x,
					y = sy or tile.y,
					tileIndex = tileIndex,
				}
			end
		end
	end

	if playerSprite then
		local px, py = playerSprite.x, playerSprite.y
		table.sort(plan, function(a, b)
			local dax, day = a.x - px, a.y - py
			local dbx, dby = b.x - px, b.y - py
			return dax * dax + day * day < dbx * dbx + dby * dby
		end)
	end

	return plan
end

--- Instantiate + wire one terrain tile from a plan entry: set its frame and add
--- it to the shared terrain SpriteBatch. Returns the sprite.
---@param spec table { data, path, x, y, tileIndex }
---@return table|nil
local function instantiateTerrainTile(spec)
	local sprite = SpriteLoader.instantiate(TileData, spec.x, spec.y, tilePngPath)
	local ss = sprite and sprite:findComponent("spritesheet")
	if ss then
		ss:setFrame(spec.tileIndex)
		local quad = ss:_getQuad()
		if quad then
			if not terrainBatch then
				terrainBatch = love.graphics.newSpriteBatch(ss.image, private.width * private.height)
			end
			local ox = Pivot.px(ss.pivotX, ss.frameWidth, 0)
			local oy = Pivot.px(ss.pivotY, ss.frameHeight, 0)
			terrainBatch:add(quad, sprite.x, sprite.y, 0, 1, 1, ox, oy)
		end
	end
	return sprite
end

--- Build the initial prop plan: which tiles get which prop type, computed once
--- (RNG + shuffle only, no sprite/audio/image work). Actual instantiation is
--- streamed over frames by the caller so large worlds don't block load.
local function buildPropPlan(worldData, playerSprite)
	Collision.resetSolids()
	Collision.resetSlowdown()

	local props = private.props or {}
	local coverage = props.coverage or 0.3
	local tileSize = private.tileSize or 8

	local activeTiles = {}
	for y = 0, private.height - 1 do
		for x = 0, private.width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				local skip = false
				if playerSprite then
					local tileRect = { x = tile.x, y = tile.y, w = tileSize, h = tileSize }
					for _, comp in
						ipairs(playerSprite:getComponents("collision", function(c) return c.getRect end))
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

	-- Recompute the cap now that the real active-tile count is known.
	PropPicker.init(private, #activeTiles)

	local numProps = math.floor(#activeTiles * coverage)
	if numProps == 0 then
		return {}
	end

	-- Save the full RNG STATE, not the seed: setRandomSeed(oldLow, oldHigh)
	-- would restart the generator at that seed, so the next WorldGen call gets
	-- the same first random value and the world repeats across restarts.
	local savedState = love.math.getRandomState()
	love.math.setRandomSeed(numProps > 0 and activeTiles[1].seed or 0)

	local plan = {}
	for i = 1, math.min(numProps, #activeTiles) do
		local j = love.math.random(i, #activeTiles)
		activeTiles[i], activeTiles[j] = activeTiles[j], activeTiles[i]
		local tile = activeTiles[i]

		local chosen = PropPicker.pick(numProps - i + 1)
		if not chosen then
			break
		end

		plan[#plan + 1] = {
			data = chosen.data,
			pngPath = chosen.pngPath,
			x = tile.x,
			y = tile.y,
			seed = tile.seed,
		}
	end

	love.math.setRandomState(savedState)

	-- Spawn nearest the player first so the visible area fills immediately while
	-- off-screen props stream in over later frames.
	if playerSprite then
		local px, py = playerSprite.x, playerSprite.y
		table.sort(plan, function(a, b)
			local dax, day = a.x - px, a.y - py
			local dbx, dby = b.x - px, b.y - py
			return dax * dax + day * day < dbx * dbx + dby * dby
		end)
	end

	return plan
end

--- Instantiate + wire one prop from a plan entry (flip, frame, collision).
---@param spec table { data, pngPath, x, y, seed }
---@return table|nil The sprite, or nil if instantiation failed.
local function instantiateProp(spec)
	local sprite = SpriteLoader.instantiate(spec.data, spec.x, spec.y, spec.pngPath)
	if not sprite then
		return nil
	end

	sprite.flipX = math.abs(spec.seed + 7777) % 2 == 0
	local ss = sprite:findComponent("spritesheet")
	if ss then
		local numFrames = ss.columns or 1
		ss:setFrame(math.abs(spec.seed + 5000) % numFrames)
	end
	local col = sprite:findComponent("collision")
	if col then
		if col.mode == "slowdown" then
			col:registerAsSlowdown()
		else
			col:registerAsSolid()
		end
	end
	return sprite
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
	local t0 = love.timer.getTime()
	local terrainPlan = buildTerrainPlan(worldData, spawnCallback, playerSprite)
	print(string.format("🚩   buildTerrain: %d tiles in %.1fms", #terrainPlan, (love.timer.getTime() - t0) * 1000))
	local t1 = love.timer.getTime()
	local propPlan = buildPropPlan(worldData, playerSprite)
	print(string.format("🚩   propPlan: %d props in %.1fms", #propPlan, (love.timer.getTime() - t1) * 1000))
	buildBorder()
	return { terrainPlan = terrainPlan, propPlan = propPlan }
end

return {
	build = build,
	instantiateProp = instantiateProp,
	instantiateTerrainTile = instantiateTerrainTile,
	getTerrainBatch = function() return terrainBatch end,
}
