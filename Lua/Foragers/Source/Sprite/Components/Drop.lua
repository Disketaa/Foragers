local Events = require("Source.Helpers.Events")
local Path = require("Source.Helpers.Path")
local Merge = require("Source.Helpers.Merge")
local Log = require("Source.Helpers.Log")
local Math = require("Source.Helpers.Math")

local pendingDrops = {}

local Drop = {}
Drop.__index = Drop

function Drop.new(data)
	local drops = {}
	if data.drops then
		for _, d in ipairs(data.drops) do
			if d.sprite then
				table.insert(drops, { sprite = d.sprite, amount = d.amount or "1" })
			else
				Log.error("Drop entry missing required field 'sprite'")
			end
		end
	elseif data.sprite then
		table.insert(drops, { sprite = data.sprite, amount = data.amount or "1" })
	end
	if #drops == 0 then
		Log.error("Drop component has no drops defined")
	end
	return setmetatable({
		drops = drops,
		type = "drop",
	}, Drop)
end

function Drop:attach()
	if #self.drops == 0 then
		return
	end
	self.parent:on(Events.PROP_BROKEN, function()
		local SpriteLoader = require("Source.Sprite.SpriteLoader")
		for _, dropDef in ipairs(self.drops) do
			local count = Math.parseRandomValue(dropDef.amount)
			local luaPath = Path.lua(dropDef.sprite)
			local ok, dropData = pcall(require, luaPath)
			if ok and dropData then
				if dropData.extends then
					dropData = Merge.resolveExtends(dropData)
				end
				local pngPath = dropDef.sprite .. ".png"
				for _ = 1, count do
					local newSprite = SpriteLoader.instantiate(dropData, self.parent.x, self.parent.y, pngPath)
					if newSprite then
						-- Skip drop_pos when follow component is present —
						-- follow already applies tween x/y offsets
						local hasFollow = false
						for _, comp in ipairs(newSprite.components) do
							if comp.type == "follow" then
								hasFollow = true
								break
							end
						end
						if not hasFollow then
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
						end
						table.insert(pendingDrops, newSprite)
					end
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
