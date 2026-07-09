local Events = require("Source.Helpers.Events")
local Path = require("Source.Helpers.Path")
local Merge = require("Source.Helpers.Merge")
local Log = require("Source.Helpers.Log")
local Math = require("Source.Helpers.Math")

local pendingDrops = {}

local Drop = {}
Drop.__index = Drop

function Drop.new(data)
	if not data.sprite then
		Log.error("Drop component missing required field 'sprite'")
	end
	return setmetatable({
		sprite = data.sprite,
		amount = data.amount or "1",
		type = "drop",
	}, Drop)
end

function Drop:attach()
	if not self.sprite then return end
	self.parent:on(Events.PROP_BROKEN, function()
		local SpriteLoader = require("Source.Sprite.SpriteLoader")
		local count = Math.parseRandomValue(self.amount)
		local luaPath = Path.lua(self.sprite)
		local ok, dropData = pcall(require, luaPath)
		if ok and dropData then
			if dropData.extends then
				dropData = Merge.resolveExtends(dropData)
			end
			local pngPath = self.sprite .. ".png"
			for i = 1, count do
				local newSprite = SpriteLoader.instantiate(dropData, self.parent.x, self.parent.y, pngPath)
				if newSprite then
					newSprite._dropBaseX = self.parent.x
					newSprite._dropBaseY = self.parent.y
					newSprite:addComponent({
						type = "drop_pos",
						update = function(self_, dt)
							local p = self_.parent
							if p and p.tweens and p.tweens.x then
								p.x = p._dropBaseX + p.tweens.x:getValue()
							end
							if p and p.tweens and p.tweens.y then
								p.y = p._dropBaseY + p.tweens.y:getValue()
							end
						end,
					})
					table.insert(pendingDrops, newSprite)
				end
			end
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

return Drop
