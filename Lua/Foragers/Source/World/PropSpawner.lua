local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Collision = require("Source.Sprite.Components.Collision")
local Events = require("Source.Helpers.Events")
local Merge = require("Source.Helpers.Merge")
local Path = require("Source.Helpers.Path")

local _tileSize
local _activeTiles = {}
local _loadedProps = {}
local _totalWeight = 0
local _timer
local _interval
local _playerSprite = nil

local function pointInRect(px, py, rect)
	return px >= rect.x and px < rect.x + rect.w and py >= rect.y and py < rect.y + rect.h
end

local function isTileOccupied(tilePixelX, tilePixelY)
	local tileRect = {
		x = tilePixelX,
		y = tilePixelY,
		w = _tileSize,
		h = _tileSize,
	}

	local solids = Collision.getSolidColliders()
	for _, r in ipairs(solids) do
		if r.sprite and pointInRect(r.sprite.x, r.sprite.y, tileRect) then
			return true
		end
	end

	local slowdowns = Collision.getSlowdownColliders()
	for _, r in ipairs(slowdowns) do
		if r.sprite and pointInRect(r.sprite.x, r.sprite.y, tileRect) then
			return true
		end
	end

	if _playerSprite and pointInRect(_playerSprite.x, _playerSprite.y, tileRect) then
		return true
	end

	return false
end

local function getAvailableTiles()
	local available = {}
	for _, tile in ipairs(_activeTiles) do
		if not isTileOccupied(tile.x, tile.y) then
			table.insert(available, tile)
		end
	end
	return available
end

---@param worldData table  2D grid of tile data from WorldGen
---@param worldConfig table  Content/Data/World.lua table
---@param opts table|nil  {playerSprite}
local function init(worldData, worldConfig, opts)
	opts = opts or {}
	_tileSize = worldConfig.tileSize or 8
	_interval = worldConfig.propSpawnInterval or 3
	_timer = _interval
	_playerSprite = opts.playerSprite

	local width = worldConfig.width or 20
	local height = worldConfig.height or 20
	local propConfigs = worldConfig.props or {}

	_activeTiles = {}

	_loadedProps = {}
	_totalWeight = 0
	for _, cfg in ipairs(propConfigs) do
		local ok, propData = pcall(require, cfg.data)
		if ok and type(propData) == "table" then
			if propData.extends then
				propData = Merge.resolveExtends(propData)
			end
			local propName = cfg.data:match("([^%.]+)$"):lower()
			local pngPath = Path.moduleToPath(cfg.data) .. ".png"
			table.insert(_loadedProps, {
				name = propName,
				weight = cfg.weight or 1,
				data = propData,
				pngPath = pngPath,
			})
			_totalWeight = _totalWeight + (cfg.weight or 1)
		end
	end

	if _totalWeight == 0 then
		return
	end

	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				table.insert(_activeTiles, {
					x = tile.x,
					y = tile.y,
					seed = tile.seed,
				})
			end
		end
	end
end

--- Advance spawn timer and return newly spawned sprite when interval elapses.
---@param dt number
---@return table|nil  spawned sprite instance, or nil if nothing spawned
local function update(dt)
	if _totalWeight == 0 or #_activeTiles == 0 then
		return nil
	end

	_timer = _timer + dt
	if _timer < _interval then
		return nil
	end
	_timer = 0

	local available = getAvailableTiles()
	if #available == 0 then
		return nil
	end

	local tile = available[love.math.random(1, #available)]

	local pick = love.math.random(1, _totalWeight)
	local cumulative = 0
	local chosen = _loadedProps[1]
	for _, p in ipairs(_loadedProps) do
		cumulative = cumulative + p.weight
		if pick <= cumulative then
			chosen = p
			break
		end
	end

	local sprite = SpriteLoader.instantiate(chosen.data, tile.x, tile.y, chosen.pngPath)

	sprite:emit(Events.PROP_SPAWNED)

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

	return sprite
end

return {
	init = init,
	update = update,
}
