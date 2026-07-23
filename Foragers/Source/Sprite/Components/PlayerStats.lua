---@class PlayerStats
---@field parent Sprite|nil
---@field critChance number Critical hit chance (0–1)
---@field critMult number Critical hit multiplier
---@field level number Current level
---@field experience number Current XP
---@field xpCurve {base:number, growth:number} XP-per-level formula
---@field satiety number Current satiety
---@field maxSatiety number Maximum satiety
---@field type string
local Events = require("Source.Helpers.Events")
local PlayerStats = {}
PlayerStats.__index = PlayerStats

---@param data table
---@return PlayerStats
function PlayerStats.new(data)
	local xpCurve = data.xpCurve or {}
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
		type = "player_stats",
	}, PlayerStats)
end

function PlayerStats:attach()
	if not self.parent then
		return
	end
	self.parent:on(Events.PROP_HIT, function()
		self:consumeSatiety(1)
	end, 5)
end

---@return number XP required for the current level
function PlayerStats:xpForNextLevel()
	return math.floor(self.xpCurve.base * self.xpCurve.growth ^ (self.level - 1))
end

---@param amount number
---@return boolean leveledUp
function PlayerStats:addExperience(amount)
	self.experience = self.experience + amount
	local leveledUp = false
	while self.experience >= self:xpForNextLevel() do
		self.experience = self.experience - self:xpForNextLevel()
		self.level = self.level + 1
		leveledUp = true
	end
	if self.parent then
		self.parent:emit(Events.VALUE_CHANGED, {
			sourceType = "player_stats",
			field = "experience",
			value = self.experience,
			maxValue = self:xpForNextLevel(),
			level = self.level,
		})
	end
	return leveledUp
end

---@param amount number
function PlayerStats:consumeSatiety(amount)
	self.satiety = math.max(0, self.satiety - amount)
	if self.parent then
		self.parent:emit(Events.VALUE_CHANGED, {
			sourceType = "player_stats",
			field = "satiety",
			value = self.satiety,
			maxValue = self.maxSatiety,
			level = self.level,
		})
	end
end

---@param amount number
function PlayerStats:restoreSatiety(amount)
	self.satiety = math.min(self.maxSatiety, self.satiety + amount)
	if self.parent then
		self.parent:emit(Events.VALUE_CHANGED, {
			sourceType = "player_stats",
			field = "satiety",
			value = self.satiety,
			maxValue = self.maxSatiety,
			level = self.level,
		})
	end
end

return PlayerStats
