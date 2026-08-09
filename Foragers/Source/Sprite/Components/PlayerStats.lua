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
		level = data.level or 1,
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

---@return number XP required for the current level
function PlayerStats:xpForNextLevel()
	return math.floor(self.xpCurve.base * self.xpCurve.growth ^ (self.level - 1))
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

---@param amount number
---@return boolean leveledUp
function PlayerStats:addExperience(amount)
	if self.dead then
		return false
	end
	self.experience = self.experience + amount
	local leveledUp = false
	while self.experience >= self:xpForNextLevel() do
		self.experience = self.experience - self:xpForNextLevel()
		self.level = self.level + 1
		leveledUp = true
	end
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
		total = total + math.floor(self.xpCurve.base * self.xpCurve.growth ^ (lv - 1))
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
	local remaining = math.max(0, value)
	-- Recompute level from the cumulative thresholds, as addExperience does for
	-- incremental grants. `self.level` must advance so xpForNextLevel() moves too.
	self.level = 1
	while remaining >= self:xpForNextLevel() do
		remaining = remaining - self:xpForNextLevel()
		self.level = self.level + 1
	end
	self.experience = remaining
	self:_emitStats("experience", self.experience, self:xpForNextLevel())
end

---@param amount number
function PlayerStats:addLevels(amount)
	if self.dead then
		return
	end
	self.level = math.max(1, self.level + amount)
	self:_emitStats("level", self.experience, self:xpForNextLevel())
end

---@param amount number
function PlayerStats:subtractLevels(amount)
	if self.dead then
		return
	end
	self.level = math.max(1, self.level - amount)
	self:_emitStats("level", self.experience, self:xpForNextLevel())
end

---@param value number
function PlayerStats:setLevel(value)
	if self.dead then
		return
	end
	self.level = math.max(1, value)
	self:_emitStats("level", self.experience, self:xpForNextLevel())
end

---@param amount number
function PlayerStats:consumeSatiety(amount)
	if self.dead then
		return
	end
	self.satiety = math.max(0, self.satiety - amount)
	self:_emitStats("satiety", self.satiety, self.maxSatiety)
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
	local f = self.satiety / math.max(1, self.maxSatiety)
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
	self.satiety = math.min(self.maxSatiety, self.satiety + amount)
	if self.satiety >= (self.lowSatietyPercent or 33) / 100 * self.maxSatiety then
		self._warned = 0
	end
	self:_emitStats("satiety", self.satiety, self.maxSatiety)
end

---@param value number
function PlayerStats:setSatiety(value)
	if self.dead then
		return
	end
	self.satiety = math.max(0, math.min(self.maxSatiety, value))
	if self.satiety >= (self.lowSatietyPercent or 33) / 100 * self.maxSatiety then
		self._warned = 0
	end
	self:_emitStats("satiety", self.satiety, self.maxSatiety)
	if self.satiety <= 0 then
		self.dead = true
		if self.parent then
			self.parent:emit(Events.DEATH)
		end
	end
end

return PlayerStats
