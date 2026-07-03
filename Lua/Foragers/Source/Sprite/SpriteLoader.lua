local Sprite = require("Source.Sprite.Sprite")
local Animatable = require("Source.Sprite.Components.Animatable")
local Controllable = require("Source.Sprite.Components.Controllable")
local Tileable = require("Source.World.Components.Tileable")
local Tweenable = require("Source.Sprite.Components.Tweenable")

local SpriteLoader = {}

---@type table<string, function(table):table> Component factory functions
local componentFactories = {
	animatable = function(compData)
		return Animatable.new(compData)
	end,
	controllable = function(compData)
		return Controllable.new(compData)
	end,
	tileable = function(compData)
		return Tileable.new(compData)
	end,
	tweenable = function(compData)
		return Tweenable.new(compData)
	end,
}

---@param assetsPath string
---@param spawnCallback function|nil
---@return table[]
function SpriteLoader.loadAll(assetsPath, spawnCallback)
	local objects = {}

	local function scan(path)
		local items = love.filesystem.getDirectoryItems(path)
		if not items then
			return
		end

		for _, item in ipairs(items) do
			local fullPath = path .. "/" .. item
			local info = love.filesystem.getInfo(fullPath)

			if info and info.type == "directory" then
				scan(fullPath)
			elseif item:match("%.lua$") then
				local luaPath = fullPath:gsub("^/", ""):gsub("/", "."):gsub("%.lua$", "")
				local success, data = pcall(require, luaPath)
				if success and type(data) == "table" then
					local obj = Sprite.new(0, 0)
					obj.frameWidth = data.frameWidth
					obj.frameHeight = data.frameHeight
					obj.pivotX = data.pivotX
					obj.pivotY = data.pivotY

					for _, compData in ipairs(data.components or {}) do
						if type(compData) == "table" then
							local factory = componentFactories[compData.component]
							if factory then
								compData.frameWidth = obj.frameWidth
								compData.frameHeight = obj.frameHeight
								compData.pivotX = obj.pivotX
								compData.pivotY = obj.pivotY
								obj:addComponent(factory(compData))
							end
						end
					end

					if not next(data.components or {}) then
						local pngPath = fullPath:gsub("%.lua$", ".png")
						local pngInfo = love.filesystem.getInfo(pngPath)
						if pngInfo then
							local image = love.graphics.newImage(pngPath)
							obj.image = image
							obj.type = "StaticSprite"
						end
					end

					if spawnCallback then
						local x, y = spawnCallback(data)
						if x then
							obj.x = x
						end
						if y then
							obj.y = y
						end
					end

					table.insert(objects, { path = fullPath, data = data, instance = obj })
					package.loaded[luaPath] = nil
				end
			end
		end
	end

	scan(assetsPath)
	return objects
end

return SpriteLoader
