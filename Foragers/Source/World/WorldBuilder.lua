local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Log = require("Source.Helpers.Core.Log")
local TileData = require("Content.Assets.Sprites.Tiles.GrassTiles")
local TilePalette = require("Source.World.TilePalette")
local Collision = require("Source.Sprite.Components.Collision")
local Path = require("Source.Helpers.Core.Path")
local Pivot = require("Source.Helpers.Core.Pivot")
local PropPicker = require("Source.World.PropPicker")
local HostRegistry = require("Source.World.HostRegistry")
local PropWire = require("Source.World.PropWire")
local WorldConfig = require("Content.Data.World") or {}

local private = {}

for k, v in pairs(WorldConfig) do
	private[k] = v
end

local function rectsOverlap(a, b)
	return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y
end

local tilePngPath = Path.moduleToPath("Content.Assets.Sprites.Tiles.GrassTiles") .. ".png"

-- SpriteBatch built incrementally as terrain tiles stream in (reset in
-- buildTerrainPlan, filled in instantiateTerrainTile, read in getTerrainBatch).
-- Single owner per world build; reassigned only across a full rebuild.
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

	-- Shuffle once into a local array so the single pick pass uses a fixed order.
	local shuffledTiles = {}
	for i = 1, #activeTiles do
		shuffledTiles[i] = activeTiles[i]
	end
	for i = 1, math.min(numProps, #shuffledTiles) do
		local j = love.math.random(i, #shuffledTiles)
		shuffledTiles[i], shuffledTiles[j] = shuffledTiles[j], shuffledTiles[i]
	end

	-- plannedHosts: every host prop (bush/tree/rock/stump) the single pick pass
	-- decided will be placed. claimedHosts: each host claimed once so two berries
	-- never attach to the same bush during resolvePending.
	local plannedHosts = {} -- hostType -> { [coordKey] = true }
	local claimedHosts = {} -- hostType -> { [coordKey] = true }

	-- Deterministic host claim: iterate plannedHosts in sorted coordKey order so
	-- the same berry always binds to the same bush across restarts. Lua `pairs`
	-- order is unspecified for string keys, which made overlay positions
	-- reshuffle every run despite a fixed seed.
	local function hostProvider(hostType)
		local hosts = plannedHosts[hostType]
		if not hosts then
			return nil
		end
		local claims = claimedHosts[hostType] or {}
		local keys = {}
		for key in pairs(hosts) do
			keys[#keys + 1] = key
		end
		table.sort(keys)
		for _, key in ipairs(keys) do
			if not claims[key] then
				claims[key] = true
				claimedHosts[hostType] = claims
				return hostType, key
			end
		end
		return nil
	end

	-- _vegSpawned/_prdStreak mutate exactly once per tile here, so chooseVeg's
	-- threshold is identical regardless of later host resolution.
	local plan = {}
	local pendingIndices = {}
	for i = 1, math.min(numProps, #shuffledTiles) do
		local tile = shuffledTiles[i]
		local chosen = PropPicker.pick(tile.seed, numProps - i + 1) -- no hostProvider: identity only
		if not chosen then
			break
		end
		local entry = { data = chosen.data, pngPath = chosen.pngPath, x = tile.x, y = tile.y, seed = tile.seed }

		if chosen.pending then
			entry.pendingHostType = chosen.hostType
			entry.modulePath, entry.offsetX, entry.offsetY, entry.inheritFrame =
				chosen.modulePath, chosen.offsetX, chosen.offsetY, chosen.inheritFrame
			pendingIndices[#pendingIndices + 1] = #plan + 1
		elseif chosen.data.host then
			local key = HostRegistry.coordKey(tile.x, tile.y)
			plannedHosts[chosen.data.host] = plannedHosts[chosen.data.host] or {}
			plannedHosts[chosen.data.host][key] = true
		end

		plan[#plan + 1] = entry
	end

	-- plannedHosts is now complete — resolve every deferred berry against it.
	-- Pure lookup + seeded, quota-inert fallback; never re-rolls tile identity.
	for _, idx in ipairs(pendingIndices) do
		local entry = plan[idx]
		local resolved = PropPicker.resolvePending({
			data = entry.data, pngPath = entry.pngPath, modulePath = entry.modulePath,
			hostType = entry.pendingHostType,
			offsetX = entry.offsetX, offsetY = entry.offsetY, inheritFrame = entry.inheritFrame,
		}, hostProvider, entry.seed)

		entry.data, entry.pngPath = resolved.data, resolved.pngPath
		if resolved.host then
			entry.host, entry.hostKey = resolved.hostType, resolved.hostKey
			entry.modulePath, entry.offsetX, entry.offsetY, entry.inheritFrame =
				resolved.modulePath, resolved.offsetX, resolved.offsetY, resolved.inheritFrame
		end
		entry.pendingHostType = nil
	end

	love.math.setRandomState(savedState)

	-- Partition so host props (bushes) instantiate before the overlay foods that
	-- attach to them, then sort each group nearest the player first so the
	-- visible area fills immediately while off-screen props stream in later.
	local hosts, rest = {}, {}
	for _, entry in ipairs(plan) do
		if entry.data.host then
			table.insert(hosts, entry)
		else
			table.insert(rest, entry)
		end
	end

	if playerSprite then
		local px, py = playerSprite.x, playerSprite.y
		local function byDistance(a, b)
			local dax, day = a.x - px, a.y - py
			local dbx, dby = b.x - px, b.y - py
			return dax * dax + day * day < dbx * dbx + dby * dby
		end
		table.sort(hosts, byDistance)
		table.sort(rest, byDistance)
	end

	plan = {}
	for _, e in ipairs(hosts) do
		table.insert(plan, e)
	end
	for _, e in ipairs(rest) do
		table.insert(plan, e)
	end

	return plan
end

--- Instantiate + wire one prop from a plan entry. Host providers register in
--- HostRegistry; overlay foods (berries) attach to their paired host and return
--- the spawned child.
---@param spec table { data, pngPath, x, y, seed, host?, hostKey?, modulePath?, offsetX?, offsetY? }
---@return table|nil The sprite, or nil if instantiation failed.
local function instantiateProp(spec)
	-- Overlay food (berry): attach to its paired host. Hosts stream before
	-- berries, so the host is already registered.
	if spec.host then
		local host = HostRegistry.get(spec.host, spec.hostKey)
		if not host then
			return nil
		end
		return PropWire.onHost(host, spec)
	end

	return PropWire.standalone(spec.data, spec.pngPath, spec.x, spec.y, spec.seed)
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
	Log.write("Loading", "%-30s %8.1fms", "  buildTerrain: " .. #terrainPlan .. " tiles", (love.timer.getTime() - t0) * 1000)
	local t1 = love.timer.getTime()
	local propPlan = buildPropPlan(worldData, playerSprite)
	Log.write("Loading", "%-30s %8.1fms", "  propPlan: " .. #propPlan .. " props", (love.timer.getTime() - t1) * 1000)
	buildBorder()
	return { terrainPlan = terrainPlan, propPlan = propPlan }
end

return {
	build = build,
	instantiateProp = instantiateProp,
	instantiateTerrainTile = instantiateTerrainTile,
	getTerrainBatch = function() return terrainBatch end,
}
