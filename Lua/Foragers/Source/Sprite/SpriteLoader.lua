local Sprite = require("Source.Sprite.Sprite")
local Animatable = require("Source.Sprite.Components.Animatable")
local Controllable = require("Source.Sprite.Components.Controllable")

local SpriteLoader = {}

---@type table<string, function(table):table> Component factory functions
local componentFactories = {
	animatable = function(compData)
		return Animatable.new(compData)
	end,
	controllable = function(compData)
		return Controllable.new(compData)
	end,
}

---@param assetsPath string
---@param spawnCallback function|nil
---@return table[]
function SpriteLoader.loadAll(assetsPath, spawnCallback)
	local objects = {}

	local function scan(path)
		local items = love.filesystem.getDirectoryItems(path)
		if not items then return end

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
					if data.frameWidth then obj.frameWidth = data.frameWidth end
					if data.frameHeight then obj.frameHeight = data.frameHeight end
					if data.pivotX then obj.pivotX = data.pivotX end
					if data.pivotY then obj.pivotY = data.pivotY end

					for _, compData in ipairs(data.components or {}) do
						if type(compData) == "table" then
							local factory = componentFactories[compData.component]
							if factory then
								if obj.frameWidth then compData.frameWidth = obj.frameWidth end
								if obj.frameHeight then compData.frameHeight = obj.frameHeight end
								if obj.pivotX then compData.pivotX = obj.pivotX end
								if obj.pivotY then compData.pivotY = obj.pivotY end
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
						if x then obj.x = x end
						if y then obj.y = y end
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

---@param objects table[]
---@param assetsPath string
---@param spawnCallback function|nil
---@return table[]
function SpriteLoader.reload(objects, assetsPath, spawnCallback)
	for _, entry in ipairs(objects or {}) do
		local luaPath = entry.path:gsub("^/", ""):gsub("/", "."):gsub("%.lua$", "")
		package.loaded[luaPath] = nil
	end
	return SpriteLoader.loadAll(assetsPath, spawnCallback)
end

return SpriteLoader