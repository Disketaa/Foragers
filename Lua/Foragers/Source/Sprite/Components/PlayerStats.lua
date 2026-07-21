---@class PlayerStats
---@field parent Sprite|nil
---@field critChance number Critical hit chance (0–1)
---@field critMult number Critical hit multiplier
---@field level number Current level
---@field experience number Current XP
---@field xpCurve {base:number, growth:number} XP-per-level formula
---@field hunger number Current hunger
---@field maxHunger number Maximum hunger
---@field type string
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
		hunger = data.hunger or 100,
		maxHunger = data.maxHunger or 100,
		type = "player_stats",
	}, PlayerStats)
end

---@return number XP required for the current level
function PlayerStats:xpForNextLevel()
	return math.floor(self.xpCurve.base * self.xpCurve.growth ^ (self.level - 1))
end

---@param amount number
---@return boolean leveledUp
function PlayerStats:addExperience(amount)
	self.experience = self.experience + amount
	local needed = self:xpForNextLevel()
	if self.experience >= needed then
		self.experience = self.experience - needed
		self.level = self.level + 1
		return true
	end
	return false
end

---@return boolean
function PlayerStats:isHungry()
	return self.hunger <= 0
end

---@param amount number
function PlayerStats:consumeHunger(amount)
	self.hunger = math.max(0, self.hunger - amount)
end

---@param amount number
function PlayerStats:restoreHunger(amount)
	self.hunger = math.min(self.maxHunger, self.hunger + amount)
end

return PlayerStats
