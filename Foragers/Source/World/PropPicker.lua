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
			local entry = {
				data = data,
				pngPath = pngPath,
				weight = cfg.weight or 1,
				modulePath = cfg.data,
				host = cfg.host,
				offsetX = cfg.offsetX or 0,
				offsetY = cfg.offsetY or 0,
				inheritFrame = cfg.inheritFrame or false,
			}
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

---@param tileSeed number|nil  per-tile seed for deterministic prop choice (nil = global RNG)
---@param remainingSlots number|nil  prop slots left INCLUDING this one (used by
---   the initial plan to force the remaining veg quota); nil for unbounded runtime
---@param hostProvider function|nil  (hostType) -> host, hostKey; resolves the host
---   an overlay food (berry) attaches to. Given => immediate resolution (runtime);
---   nil => defer (plan-time), returns { pending = true, hostType, ... } for
---   resolvePending() once plannedHosts is complete.
---@return table|nil  { data, pngPath, modulePath, host?, hostKey?, hostType?, offsetX?, offsetY?, pending? }
local function pick(tileSeed, remainingSlots, hostProvider)
	if _nonVegWeight == 0 and _vegWeight == 0 then
		return nil
	end

	local vegQuota = _vegCap - _vegSpawned
	local chooseVeg = false

	-- Deterministic per-tile RNG when tileSeed given (initial plan, seeded from
	-- world seed via tile.seed); global RNG stream for runtime spawns (nil seed).
	-- Matches WorldBuilder's setRandomSeed/getRandomState isolation pattern.
	local savedState
	if tileSeed then
		savedState = love.math.getRandomState()
		love.math.setRandomSeed(tileSeed)
	end

	if vegQuota > 0 and _vegWeight > 0 then
		if remainingSlots and remainingSlots <= vegQuota
			or _nonVegWeight == 0
			or love.math.random() <= prdChance()
		then
			chooseVeg = true
		end
	end

	local result
	if chooseVeg then
		local entry = pickWeighted(_vegProps, _vegWeight)
		if not entry then
			_prdStreak = _prdStreak + 1
			result = pickWeighted(_nonVegProps, _nonVegWeight)
		elseif entry.host then
			if hostProvider then
				-- Immediate resolution: runtime spawns (live sprites via
				-- HostRegistry.find), where there is no second pass.
				local host, hostKey = hostProvider(entry.host)
				if not host then
					_prdStreak = _prdStreak + 1
					result = pickWeighted(_nonVegProps, _nonVegWeight)
				else
					_prdStreak = 0
					_vegSpawned = _vegSpawned + 1
					result = {
						data = entry.data, pngPath = entry.pngPath, modulePath = entry.modulePath,
						host = host, hostType = entry.host, hostKey = hostKey,
						offsetX = entry.offsetX, offsetY = entry.offsetY, inheritFrame = entry.inheritFrame,
					}
				end
			else
				-- Deferred: commit quota/streak NOW, once, so this decision is
				-- fixed and can never be re-rolled by a later pass. The actual
				-- host lookup happens in resolvePending() after plannedHosts
				-- is complete.
				_prdStreak = 0
				_vegSpawned = _vegSpawned + 1
				result = {
					pending = true,
					data = entry.data, pngPath = entry.pngPath, modulePath = entry.modulePath,
					hostType = entry.host,
					offsetX = entry.offsetX, offsetY = entry.offsetY, inheritFrame = entry.inheritFrame,
				}
			end
		else
			_prdStreak = 0
			_vegSpawned = _vegSpawned + 1
			result = entry
		end
	else
		_prdStreak = _prdStreak + 1
		result = pickWeighted(_nonVegProps, _nonVegWeight)
	end

	if savedState then
		love.math.setRandomState(savedState)
	end

	return result
end

--- Resolve a pending host-needing entry once plannedHosts is complete.
--- Pure lookup for the host; the fallback re-roll is tile-seeded for
--- reproducibility but never touches _vegSpawned/_prdStreak — that decision
--- was already committed in pick().
---@return {data: table, pngPath: string|nil, modulePath: string|nil, host: any, hostType: string|nil, hostKey: any, offsetX:number, offsetY:number, inheritFrame: boolean|nil}
local function resolvePending(pending, hostProvider, tileSeed)
	local savedState
	if tileSeed then
		savedState = love.math.getRandomState()
		love.math.setRandomSeed(tileSeed)
	end

	local host, hostKey
	if hostProvider then
		host, hostKey = hostProvider(pending.hostType)
	end

	local result
	if not host then
		-- No host of this type exists anywhere in the plan (more berries
		-- than bushes) — deterministic non-veg fallback.
		result = pickWeighted(_nonVegProps, _nonVegWeight)
	else
		result = {
			data = pending.data, pngPath = pending.pngPath, modulePath = pending.modulePath,
			host = host, hostType = pending.hostType, hostKey = hostKey,
			offsetX = pending.offsetX, offsetY = pending.offsetY, inheritFrame = pending.inheritFrame,
		}
	end

	if savedState then
		love.math.setRandomState(savedState)
	end
	return result --[[@as {data: table, pngPath: string|nil, modulePath: string|nil, host: any, hostType: string|nil, hostKey: any, offsetX: number, offsetY: number, inheritFrame: boolean|nil}]]
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
	resolvePending = resolvePending,
	onVegDestroyed = onVegDestroyed,
	isInitialized = isInitialized,
	vegStats = vegStats,
}