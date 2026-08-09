local Merge = require("Source.Helpers.Core.Merge")
local Path = require("Source.Helpers.Core.Path")

-- Shared prop-type picker used by both WorldBuilder.buildPropPlan (initial
-- coverage plan) and PropSpawner (runtime streaming). Owns the vegetable cap
-- and the Dota-2-style deterministic-random (PRD) accumulator so both spawn
-- paths share one counter and never exceed the cap.

local _vegProps = {}
local _nonVegProps = {}
local _vegWeight = 0
local _nonVegWeight = 0
local _vegCap = 0
local _vegSpawned = 0
local _prdStreak = 0
local _pseudoRandomChance = 0.2
local _initialized = false

local function resolve(data)
	if data.extends then
		return Merge.resolveExtends(data)
	end
	return data
end

local function load(propConfigs)
	_vegProps = {}
	_nonVegProps = {}
	_vegWeight = 0
	_nonVegWeight = 0
	for _, cfg in ipairs(propConfigs) do
		local ok, data = pcall(require, cfg.data)
		if ok and type(data) == "table" then
			data = resolve(data)
			local pngPath = Path.moduleToPath(cfg.data) .. ".png"
			local entry = { data = data, pngPath = pngPath, weight = cfg.weight or 1 }
			if data.object == "vegetable" then
				table.insert(_vegProps, entry)
				_vegWeight = _vegWeight + entry.weight
			else
				table.insert(_nonVegProps, entry)
				_nonVegWeight = _nonVegWeight + entry.weight
			end
		end
	end
end

--- Call once, before buildPropPlan, so both spawn paths share the same quota
--- and streak.
---@param worldConfig table  Content/Data/World.lua table
---@param activeTileCount number  tiles available for prop placement
local function init(worldConfig, activeTileCount)
	local props = worldConfig.props or {}
	local vegCfg = props.vegetables or {}
	load(props.items or {})

	local density = vegCfg.density or 0
	_vegCap = math.floor(activeTileCount * density)
	_vegSpawned = 0
	_prdStreak = 0
	_pseudoRandomChance = vegCfg.pseudoRandomChance or 0.2
	_initialized = true
end

local function pickWeighted(props, totalWeight)
	if totalWeight <= 0 or #props == 0 then
		return nil
	end
	local pick = love.math.random(1, totalWeight)
	local cumulative = 0
	for _, p in ipairs(props) do
		cumulative = cumulative + p.weight
		if pick <= cumulative then
			return p
		end
	end
	return props[#props]
end

--- Guarantees a vegetable within ~1/pseudoRandomChance tries, avoiding long
--- droughts without skewing the long-run average.
---@return number
local function prdChance()
	return math.min(1, _pseudoRandomChance * (_prdStreak + 1))
end

---@param remainingSlots number|nil  prop slots left INCLUDING this one (used by
---   the initial plan to force the remaining veg quota); nil for unbounded runtime
---@return table|nil  { data, pngPath } entry
local function pick(remainingSlots)
	if _nonVegWeight == 0 and _vegWeight == 0 then
		return nil
	end

	local vegQuota = _vegCap - _vegSpawned
	local chooseVeg = false

	if vegQuota > 0 and _vegWeight > 0 then
		if remainingSlots and remainingSlots <= vegQuota then
			-- Not enough slots left to reach the cap any other way.
			chooseVeg = true
		elseif _nonVegWeight == 0 then
			chooseVeg = true
		elseif love.math.random() <= prdChance() then
			chooseVeg = true
		end
	end

	if chooseVeg then
		_prdStreak = 0
		_vegSpawned = _vegSpawned + 1
		return pickWeighted(_vegProps, _vegWeight)
	end

	_prdStreak = _prdStreak + 1
	return pickWeighted(_nonVegProps, _nonVegWeight)
end

--- Free one vegetable quota slot. Called when a vegetable prop is destroyed;
--- without this, the initial plan fills the whole cap and runtime respawns are
--- permanently gated by `vegQuota > 0`, regardless of pseudoRandomChance.
local function onVegDestroyed()
	_vegSpawned = math.max(0, _vegSpawned - 1)
end

local function isInitialized()
	return _initialized
end

local function vegStats()
	return { spawned = _vegSpawned, cap = _vegCap }
end

return {
	init = init,
	pick = pick,
	onVegDestroyed = onVegDestroyed,
	isInitialized = isInitialized,
	vegStats = vegStats,
}
