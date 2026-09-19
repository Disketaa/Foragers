local Events = require("Source.Helpers.Core.Events")
local Path = require("Source.Helpers.Core.Path")
local Merge = require("Source.Helpers.Core.Merge")
local Log = require("Source.Helpers.Core.Log")
local ValueParser = require("Source.Helpers.Core.ValueParser")
local GameState = require("Source.Helpers.Systems.GameState")

local pendingDrops = {}

local Drop = {}
Drop.__index = Drop

local function normalizeDropEntry(d)
	local entry = { sprite = d.sprite, amount = d.amount or "1" }
	if d.bonusStats then
		entry.bonusStats = d.bonusStats
	end
	if d.__raw then
		entry.__raw = d.__raw
	end
	return entry
end

function Drop.new(data)
	local drops = {}
	if data.drops then
		for _, d in ipairs(data.drops) do
			if d.sprite then
				table.insert(drops, normalizeDropEntry(d))
			else
				Log.error("Drop", "entry missing required field 'sprite'")
			end
		end
	elseif data.sprite then
		table.insert(drops, normalizeDropEntry(data))
	end
	if #drops == 0 then
		Log.error("Drop", "component has no drops defined")
	end
	return setmetatable({
		drops = drops,
		type = "drop",
	}, Drop)
end

function Drop:_resolveCount(dropDef)
	local count = ValueParser.call(dropDef, "amount")
	if dropDef.bonusStats then
		local stats = GameState.playerSprite and GameState.playerSprite:findComponent("player_stats")
		if stats then
			for _, statName in ipairs(dropDef.bonusStats) do
				local bonus = stats:resolveStat(stats[statName]) or 0
				if statName == "rockCrystalBonus" then
					count = count + bonus + math.floor(bonus / 4)
				else
					count = count + bonus
				end
			end
		end
	end
	return count
end

function Drop:_createDropPosComponent()
	return {
		type = "drop_pos",
		update = function(self_, _dt)
			local p = self_.parent
			if p and p.tweens and p.tweens.x then
				p.x = p._dropBaseX + p.tweens.x:getValue()
			end
			if p and p.tweens and p.tweens.y then
				p.y = p._dropBaseY + p.tweens.y:getValue()
			end
		end,
	}
end

function Drop:_spawnDrop(dropDef, count, parentX, parentY)
	local SpriteLoader = require("Source.Sprite.SpriteLoader")
	local luaPath = Path.lua(dropDef.sprite)
	local ok, dropData = pcall(require, luaPath)
	if ok and dropData then
		if dropData.extends then
			dropData = Merge.resolveExtends(dropData)
		end
		local pngPath = dropDef.sprite .. ".png"
		for _ = 1, count do
			local newSprite = SpriteLoader.instantiate(dropData, parentX, parentY, pngPath)
			if newSprite then
				local hasFollow = newSprite:findComponent("follow") and true or false
				if not hasFollow then
					newSprite._dropBaseX = parentX
					newSprite._dropBaseY = parentY
					newSprite:addComponent(self:_createDropPosComponent())
				end
				table.insert(pendingDrops, newSprite)
			end
		end
	end
end

function Drop:attach()
	if #self.drops == 0 then
		return
	end
	self.parent:on(Events.PROP_BROKEN, function()
		for _, dropDef in ipairs(self.drops) do
			local count = self:_resolveCount(dropDef)
			self:_spawnDrop(dropDef, count, self.parent.x, self.parent.y)
		end
	end, 3)
end

function Drop.getPending()
	local list = {}
	for _, sprite in ipairs(pendingDrops) do
		table.insert(list, sprite)
	end
	pendingDrops = {}
	return list
end

function Drop.reset()
	pendingDrops = {}
end

return Drop