local Collision = require("Source.Sprite.Components.Collision")
local PropPicker = require("Source.World.PropPicker")
local HostRegistry = require("Source.World.HostRegistry")
local PropWire = require("Source.World.PropWire")

local _tileSize
local _activeTiles = {}
local _timer
local _interval
local _playerSprite = nil

--- Available (unoccupied) active tiles. Builds an occupied-tile set in one
--- O(colliders) pass, then filters active tiles against it (O(activeTiles)).
--- Replaces the old per-tile O(colliders) scan, which was O(activeTiles ×
--- colliders) — ~17M checks per spawn at 80×80, stalling every spawn interval.
local function getAvailableTiles()
	local occupied = {}
	local ts = _tileSize
	for _, r in ipairs(Collision.getSolidColliders()) do
		if r.sprite then
			local ty = math.floor(r.sprite.y / ts)
			local row = occupied[ty] or {}
			occupied[ty] = row
			row[math.floor(r.sprite.x / ts)] = true
		end
	end
	for _, r in ipairs(Collision.getSlowdownColliders()) do
		if r.sprite then
			local ty = math.floor(r.sprite.y / ts)
			local row = occupied[ty] or {}
			occupied[ty] = row
			row[math.floor(r.sprite.x / ts)] = true
		end
	end
	if _playerSprite then
		local ty = math.floor(_playerSprite.y / ts)
		local row = occupied[ty] or {}
		occupied[ty] = row
		row[math.floor(_playerSprite.x / ts)] = true
	end

	local available = {}
	for _, tile in ipairs(_activeTiles) do
		local row = occupied[math.floor(tile.y / ts)]
		if not (row and row[math.floor(tile.x / ts)]) then
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
	_interval = (worldConfig.props or {}).spawnInterval or 3
	_timer = _interval
	_playerSprite = opts.playerSprite

	local width = worldConfig.width or 20
	local height = worldConfig.height or 20

	_activeTiles = {}

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
	if #_activeTiles == 0 then
		return nil
	end

	_timer = _timer + dt
	if _timer < _interval then
		return nil
	end
	_timer = 0

	-- Prop type decided by the shared PRD picker (vegetable cap + Dota-2-style
	-- accumulated chance), same state as the initial plan. Overlay foods (berries)
	-- resolve a live host here; a pick with no available host is skipped without
	-- resetting the PRD streak.
	local chosen = PropPicker.pick(nil, nil, HostRegistry.find)
	if not chosen then
		return nil
	end

	-- Overlay food (berry): attaches to a host, so it needs no free tile. A
	-- world where every tile is occupied (all-bush) can still respawn fruit.
	if chosen.host then
		return PropWire.onHost(chosen.host, chosen)
	end

	local available = getAvailableTiles()
	if #available == 0 then
		return nil
	end

	local tile = available[love.math.random(1, #available)]
	return PropWire.standalone(chosen.data, chosen.pngPath, tile.x, tile.y, tile.seed)
end

return {
	init = init,
	update = update,
}
