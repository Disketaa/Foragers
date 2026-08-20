local GameState = require("Source.Helpers.Systems.GameState")
local DayCycle = require("Source.Helpers.Systems.DayCycle")
local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Merge = require("Source.Helpers.Core.Merge")
local Path = require("Source.Helpers.Core.Path")
local Lifecycle = require("Source.Helpers.Systems.Lifecycle")
local ValueParser = require("Source.Helpers.Core.ValueParser")

local AmbientSpawner = {
	groups = {},
}

---@param ambientConfig table Ambient config table from World.lua (whole `ambient` section)
function AmbientSpawner.init(ambientConfig)
	AmbientSpawner.groups = {}
	if not ambientConfig then
		return
	end
	for name, cfg in pairs(ambientConfig) do
		AmbientSpawner.groups[name] = {
			config = cfg,
			sprites = {},
			cooldown = 0,
		}
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
	local isDay = sunData.isDay
	local spawnAtNight = cfg.spawnAtNight or false
	if (spawnAtNight and isDay) or (not spawnAtNight and not isDay) then
		return
	end

	group.cooldown = group.cooldown - dt
	if group.cooldown > 0 then
		return
	end
	group.cooldown = cfg.spawnInterval or 2

	if #list >= (cfg.maxCount or 8) then
		return
	end

	local typePath = cfg.types[love.math.random(1, #cfg.types)]

	local margin = cfg.spawnMargin or 40
	local wx = -camPixelX - margin + love.math.random() * (canvasWidth + margin * 2)
	local wy = -camPixelY - margin + love.math.random() * (canvasHeight + margin * 2)

	local worldW = GameState.worldPixelWidth or 10000
	local worldH = GameState.worldPixelHeight or 10000
	wx = math.max(0, math.min(worldW, wx))
	wy = math.max(0, math.min(worldH, wy))

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

	-- Re-roll interval on spawn so each firefly/butterfly has fresh timings
	local ambient = sprite:findComponent("ambient")
	if ambient and ambient.__raw and ambient.__raw.interval then
		ambient.interval = ValueParser.value(ambient.__raw.interval)
		ambient._dirTimer = 0
	end

	local entry = { instance = sprite, data = data }
	table.insert(list, entry)
	table.insert(objects, entry)
	table.insert(dynamicObjects, entry)
end

return AmbientSpawner