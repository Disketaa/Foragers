---@class PlayerStats
---@field parent Sprite|nil
---@field critChance number Critical hit chance (0–1)
---@field critMult number Critical hit multiplier
---@field level number Current level
---@field experience number Current XP
---@field xpCurve {base:number, growth:number} XP-per-level formula
---@field satiety number Current satiety
---@field maxSatiety number Maximum satiety
---@field lowSatietyPercent number Percent of maxSatiety below which low-satiety effects start
---@field lowSatietyZoom number Output zoom when satiety reaches 0 (1 at the threshold)
---@field lowSatietyMaskRadius number Circle mask radius (canvas px) at zero satiety; full circle at the low threshold
---@field dead boolean Whether the player has died (satiety 0); blocks further consumption/restoration
---@field type string
local Events = require("Source.Helpers.Core.Events")
local PlayerStats = {}
PlayerStats.__index = PlayerStats

---@param data table
---@return PlayerStats
function PlayerStats.new(data)
	local xpCurve = data.xpCurve or {}
	local satietyDrain = data.satietyDrain or {}
	return setmetatable({
		critChance = data.critChance or 0,
		critMult = data.critMult or 1.5,
		damage = data.damage or 1,
		range = data.range or 20,
		attackSpeed = data.attackSpeed or 2,
		level = data.level or 1,
		maxLevel = data.maxLevel or 99,
		experience = data.experience or 0,
		xpCurve = {
			base = xpCurve.base or 10,
			growth = xpCurve.growth or 1.35,
		},
		satiety = data.satiety or 100,
		maxSatiety = data.maxSatiety or 100,
		lowSatietyPercent = data.lowSatietyPercent or 33,
		lowSatietyZoom = data.lowSatietyZoom or 2,
		lowSatietyWarnings = data.lowSatietyWarnings or 3,
		lowSatietyMaskRadius = data.lowSatietyMaskRadius or 24,
		dead = false,
		_warned = 0,
		satietyDrain = {
			run = satietyDrain.run or 0.5,
			swim = satietyDrain.swim or 0.75,
			idle = satietyDrain.idle or 0.1,
			float = satietyDrain.float or 0.1,
		},
		movementSpeed = data.movementSpeed or 50,
		swimmingSpeed = data.swimmingSpeed or 30,
		type = "player_stats",
	}, PlayerStats)
end

function PlayerStats:attach()
	if not self.parent then
		return
	end
	self._currentState = "idle"

	self.parent:on(Events.PROP_HIT, function()
		self:consumeSatiety(1)
	end, 5)

	self.parent:on(Events.STATE_CHANGED, function(newState)
		self._currentState = newState
	end, 5)

	self.parent:on(Events.ANIM_FRAME, function(frameIndex)
		local state = self._currentState
		local chance = self.satietyDrain[state] or 0
		local drain = (state == "run" and (frameIndex == 2 or frameIndex == 4))
			or state == "swim"
			or state == "idle"
			or state == "float"
		if drain and chance > 0 and love.math.random() < chance then
			self:consumeSatiety(1)
		end
	end, 5)
end

--- Resolve an XP-style curve (multiplicative): `base * growth^(level-1)`.
--- Used only by `xpCurve`; stats scale additively via `resolveStat`.
---@param curve {base:number, growth:number}
---@param level number|nil resolve at a specific level (defaults to current)
---@return number
function PlayerStats:resolveCurve(curve, level)
	level = level or self.level
	return math.floor(curve.base * curve.growth ^ (level - 1))
end

--- Resolve a stat defined as a flat number or an additive `{base, gain}`
--- curve: `base + gain * (level-1)`.
---@param stat number|{base:number, gain:number}
---@param level number|nil resolve at a specific level (defaults to current)
---@return number
function PlayerStats:resolveStat(stat, level)
	level = level or self.level
	if type(stat) == "table" then
		return math.floor(stat.base + (stat.gain or 0) * (level - 1))
	end
	return stat or 0
end

---@return number XP required for the current level
function PlayerStats:xpForNextLevel()
	return self:resolveCurve(self.xpCurve)
end

---@return number movement speed for the current level
function PlayerStats:getMovementSpeed()
	return self:resolveStat(self.movementSpeed)
end

---@return number swimming speed for the current level
function PlayerStats:getSwimmingSpeed()
	return self:resolveStat(self.swimmingSpeed)
end

---@return number damage for the current level
function PlayerStats:getDamage()
	return self:resolveStat(self.damage)
end

---@return number attack range for the current level
function PlayerStats:getRange()
	return self:resolveStat(self.range)
end

---@return number attack speed (attacks/sec) for the current level
function PlayerStats:getAttackSpeed()
	return self:resolveStat(self.attackSpeed)
end

---@return number attack speed (attacks/sec) at level 1 — the curve base. Used as the
--- reference so follow/swing travel scales up with level without changing the level-1 feel.
function PlayerStats:getBaseAttackSpeed()
	return self:resolveStat(self.attackSpeed, 1)
end

---@return number attack cooldown (sec) for the current level, derived from attack speed
function PlayerStats:getCooldown()
	return 1 / self:getAttackSpeed()
end

---@return number maximum satiety (capacity) for the current level
function PlayerStats:getMaxSatiety()
	return self:resolveStat(self.maxSatiety)
end

--- Emit VALUE_CHANGED to the parent (counter/HUD). One emit path so every
--- mutation — XP curve, debug commands, future scaling — reports the same shape.
---@param field string "experience"|"level"|"satiety"
---@param value number
---@param maxValue number
function PlayerStats:_emitStats(field, value, maxValue)
	if not self.parent then
		return
	end
	self.parent:emit(Events.VALUE_CHANGED, {
		sourceType = "player_stats",
		field = field,
		value = value,
		maxValue = maxValue,
		level = self.level,
	})
end

--- Preserve the satiety fraction when the level changes (Dota-style partial heal):
--- current scales by new max capacity / old max capacity, so leveling up is a small
--- reward rather than making the player relatively hungrier. Emits satiety so the HUD
--- bar tracks the new capacity. No-op when the level is unchanged.
function PlayerStats:_applyLevelChange(oldLevel)
	if self.level == oldLevel then
		return
	end
	local oldMax = self:resolveStat(self.maxSatiety, oldLevel)
	local newMax = self:getMaxSatiety()
	if oldMax > 0 then
		self.satiety = math.min(newMax, self.satiety * newMax / oldMax)
	end
	self:_emitStats("satiety", self.satiety, newMax)
end

---@param amount number
---@return boolean leveledUp
function PlayerStats:addExperience(amount)
	if self.dead then
		return false
	end
	local oldLevel = self.level
	self.experience = self.experience + amount
	local leveledUp = false
	while self.experience >= self:xpForNextLevel() do
		if self.level >= self.maxLevel then
			self.experience = self:xpForNextLevel()
			break
		end
		self.experience = self.experience - self:xpForNextLevel()
		self.level = self.level + 1
		leveledUp = true
	end
	self:_applyLevelChange(oldLevel)
	self:_emitStats("experience", self.experience, self:xpForNextLevel())
	return leveledUp
end

---@param amount number
function PlayerStats:subtractExperience(amount)
	if self.dead then
		return
	end
	-- Rebuild total earned (thresholds for all completed levels + current
	-- progress), subtract, then recompute level — mirrors setExperience so a
	-- `-N` on a high level actually drops levels.
	local total = 0
	for lv = 1, self.level - 1 do
		total = total + self:resolveCurve(self.xpCurve, lv)
	end
	total = total + self.experience
	self:setExperience(math.max(0, total - amount))
end

--- Set total XP and derive the level it maps to (same curve as addExperience).
--- The stored `experience` is progress toward the next level; `value` is treated
--- as total earned so the level is recomputed from the cumulative thresholds.
---@param value number
function PlayerStats:setExperience(value)
	if self.dead then
		return
	end
	local oldLevel = self.level
	local remaining = math.max(0, value)
	-- Recompute level from the cumulative thresholds, as addExperience does for
	-- incremental grants. `self.level` must advance so xpForNextLevel() moves too.
	self.level = 1
	while remaining >= self:xpForNextLevel() do
		if self.level >= self.maxLevel then
			remaining = 0
			break
		end
		remaining = remaining - self:xpForNextLevel()
		self.level = self.level + 1
	end
	self.experience = self.level >= self.maxLevel and self:xpForNextLevel() or remaining
	self:_applyLevelChange(oldLevel)
	self:_emitStats("experience", self.experience, self:xpForNextLevel())
end

---@param amount number
function PlayerStats:addLevels(amount)
	if self.dead then
		return
	end
	local oldLevel = self.level
	self.level = math.min(self.maxLevel, math.max(1, self.level + amount))
	self:_applyLevelChange(oldLevel)
	self:_emitStats("level", self.experience, self:xpForNextLevel())
end

---@param amount number
function PlayerStats:subtractLevels(amount)
	if self.dead then
		return
	end
	local oldLevel = self.level
	self.level = math.min(self.maxLevel, math.max(1, self.level - amount))
	self:_applyLevelChange(oldLevel)
	self:_emitStats("level", self.experience, self:xpForNextLevel())
end

---@param value number
function PlayerStats:setLevel(value)
	if self.dead then
		return
	end
	local oldLevel = self.level
	self.level = math.min(self.maxLevel, math.max(1, value))
	self:_applyLevelChange(oldLevel)
	self:_emitStats("level", self.experience, self:xpForNextLevel())
end

---@param amount number
function PlayerStats:consumeSatiety(amount)
	if self.dead then
		return
	end
	self.satiety = math.max(0, self.satiety - amount)
	self:_emitStats("satiety", self.satiety, self:getMaxSatiety())
	self:_checkHungerWarnings()
	if self.satiety <= 0 then
		self.dead = true
		if self.parent then
			self.parent:emit(Events.DEATH)
		end
	end
end

--- Emit LOW_SATIETY once per descending warning threshold crossed.
--- Threshold i (1..count) sits at low * (count - i + 1) / count, so with
--- lowSatietyPercent=33 and lowSatietyWarnings=3 the warns fire at 0.33,
--- 0.22, 0.11. Nothing fires at 0 — the player dies there. Restoring above
--- the low threshold resets the count so a later starvation re-warns.
function PlayerStats:_checkHungerWarnings()
	local count = self.lowSatietyWarnings or 3
	local low = (self.lowSatietyPercent or 33) / 100
	if count <= 0 or low <= 0 then
		return
	end
	local f = self.satiety / math.max(1, self:getMaxSatiety())
	if f >= low then
		return
	end
	local desired = math.floor((count + 1) - f * count / low)
	desired = math.max(0, math.min(count, desired))
	while self._warned < desired do
		self._warned = self._warned + 1
		if self.parent then
			self.parent:emit(Events.LOW_SATIETY)
		end
	end
end

---@param amount number
function PlayerStats:restoreSatiety(amount)
	if self.dead then
		return
	end
	self.satiety = math.min(self:getMaxSatiety(), self.satiety + amount)
	if self.satiety >= (self.lowSatietyPercent or 33) / 100 * self:getMaxSatiety() then
		self._warned = 0
	end
	self:_emitStats("satiety", self.satiety, self:getMaxSatiety())
end

---@param value number
function PlayerStats:setSatiety(value)
	if self.dead then
		return
	end
	self.satiety = math.max(0, math.min(self:getMaxSatiety(), value))
	if self.satiety >= (self.lowSatietyPercent or 33) / 100 * self:getMaxSatiety() then
		self._warned = 0
	end
	self:_emitStats("satiety", self.satiety, self:getMaxSatiety())
	if self.satiety <= 0 then
		self.dead = true
		if self.parent then
			self.parent:emit(Events.DEATH)
		end
	end
end

return PlayerStats
