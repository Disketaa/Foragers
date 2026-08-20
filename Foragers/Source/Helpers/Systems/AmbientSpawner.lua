local GameState = require("Source.Helpers.Systems.GameState")
local DayCycle = require("Source.Helpers.Systems.DayCycle")
local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Merge = require("Source.Helpers.Core.Merge")
local Path = require("Source.Helpers.Core.Path")
local Lifecycle = require("Source.Helpers.Systems.Lifecycle")
local ValueParser = require("Source.Helpers.Core.ValueParser")

local AmbientSpawner = {
	groups = {},
	_activeTiles = {},
	_tileSize = 8,
	_SPAWN_MARGIN = 40,
}

--- Group name → phase gate. "night" spawns at night, everything else during day.
local function groupIsNight(name)
	return name == "night"
end

---@param ambientConfig table Ambient config from World.lua (whole `ambient` section)
---@param worldData table 2D grid from WorldGen (worldData[y][x] with tile.active, tile.x, tile.y)
---@param worldConfig table Content/Data/World.lua
function AmbientSpawner.init(ambientConfig, worldData, worldConfig)
	AmbientSpawner.groups = {}
	AmbientSpawner._activeTiles = {}
	if not ambientConfig then
		return
	end

	local width = worldConfig.width or 20
	local height = worldConfig.height or 20

	AmbientSpawner._tileSize = worldConfig.tileSize or 8

	-- Build active (land) tiles list — same pattern as PropSpawner
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local tile = worldData[y][x]
			if tile.active then
				table.insert(AmbientSpawner._activeTiles, {
					x = tile.x,
					y = tile.y,
				})
			end
		end
	end

	-- Cap based on density × active land tiles (not total world area)
	local density = ambientConfig.density or 0.02
	local totalCap = math.max(1, math.floor(#AmbientSpawner._activeTiles * density))

	-- Split cap evenly across groups
	local groupNames = {}
	for name, cfg in pairs(ambientConfig) do
		if type(cfg) == "table" and cfg.types then
			groupNames[#groupNames + 1] = name
		end
	end
	local perGroup = math.max(1, math.floor(totalCap / math.max(1, #groupNames)))

	for name, cfg in pairs(ambientConfig) do
		if type(cfg) == "table" and cfg.types then
			AmbientSpawner.groups[name] = {
				config = cfg,
				name = name,
				maxCount = perGroup,
				sprites = {},
				cooldown = 0,
			}
		end
	end
end

---@param dt number
---@param objects table
---@param dynamicObjects table
---@param camPixelX number
---@param camPixelY number
---@param canvasWidth number
---@param canvasHeight number
function AmbientSpawner.update(dt, objects, dynamicObjects, camPixelX, camPixelY, canvasWidth, canvasHeight)
	local sunData = DayCycle.getSunData()

	for _, group in pairs(AmbientSpawner.groups) do
		local cfg = group.config
		if cfg and cfg.types and #cfg.types > 0 then
			AmbientSpawner._updateGroup(group, dt, objects, dynamicObjects, camPixelX, camPixelY, canvasWidth, canvasHeight, sunData)
		end
	end
end

function AmbientSpawner._updateGroup(group, dt, objects, dynamicObjects, camPixelX, camPixelY, canvasWidth, canvasHeight, sunData)
	local cfg = group.config
	local list = group.sprites

	-- Despawn finished or out-of-range ambient sprites
	for i = #list, 1, -1 do
		local entry = list[i]
		local ambient = entry.instance:findComponent("ambient")
		if ambient and ambient:isDespawned() then
			Lifecycle.destroySprite(entry.instance, objects, dynamicObjects)
			table.remove(list, i)
		elseif ambient then
			local margin = cfg.despawnMargin or 80
			local vx = -camPixelX - margin
			local vy = -camPixelY - margin
			local vw = canvasWidth + margin * 2
			local vh = canvasHeight + margin * 2
			local sx = entry.instance.x
			local sy = entry.instance.y
			if sx < vx or sx > vx + vw or sy < vy or sy > vy + vh then
				entry.instance.alpha = 0
				ambient:markDespawn()
				Lifecycle.destroySprite(entry.instance, objects, dynamicObjects)
				table.remove(list, i)
			end
		end
	end

	if GameState.state ~= "game" then
		return
	end

	-- Phase gate: group name determines day/night. "night" group spawns at night, everything else spawns during day.
	local isNight = groupIsNight(group.name)
	local isDay = sunData.isDay
	if (isNight and isDay) or (not isNight and not isDay) then
		return
	end

	group.cooldown = group.cooldown - dt
	if group.cooldown > 0 then
		return
	end
	group.cooldown = cfg.spawnInterval or 2

	if #list >= group.maxCount then
		return
	end

	local typePath = cfg.types[love.math.random(1, #cfg.types)]

	-- Pick random active (land) tile within camera view + margin, then jitter within tile
	local margin = AmbientSpawner._SPAWN_MARGIN
	local vx = -camPixelX - margin
	local vy = -camPixelY - margin
	local vw = canvasWidth + margin * 2
	local vh = canvasHeight + margin * 2
	local nearTiles = {}
	for _, tile in ipairs(AmbientSpawner._activeTiles) do
		if tile.x >= vx and tile.x <= vx + vw and tile.y >= vy and tile.y <= vy + vh then
			nearTiles[#nearTiles + 1] = tile
		end
	end
	if #nearTiles == 0 then
		return
	end
	local chosen = nearTiles[love.math.random(1, #nearTiles)]
	local wx = chosen.x + love.math.random() * AmbientSpawner._tileSize
	local wy = chosen.y + love.math.random() * AmbientSpawner._tileSize

	local luaPath = Path.lua(typePath)
	local ok, data = pcall(require, luaPath)
	if not ok or not data then
		return
	end
	if data.extends then
		data = Merge.resolveExtends(data)
	end
	local pngPath = Path.png(typePath)
	local sprite = SpriteLoader.instantiate(data, wx, wy, pngPath)
	if not sprite then
		return
	end

	-- Re-roll interval on spawn so each ambient sprite has fresh timings
	local ambient = sprite:findComponent("ambient")
	if ambient and ambient.__raw and ambient.__raw.changeDirectionInterval then
		ambient.changeDirectionInterval = ValueParser.value(ambient.__raw.changeDirectionInterval)
		ambient._dirTimer = 0
	end

	local entry = { instance = sprite, data = data }
	table.insert(list, entry)
	table.insert(objects, entry)
	table.insert(dynamicObjects, entry)
end

return AmbientSpawner