local Object = require("Source.Object")
local AnimatableSprite = require("Source.AnimatableSprite")
local Controllable = require("Source.Controllable")

local SpriteLoader = {}

local componentFactories = {
	AnimatableSprite = function(compData)
		return AnimatableSprite.new(compData)
	end,
	Controllable = function(compData)
		return Controllable.new()
	end,
}

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
				if success and data then
					local obj = Object.new(0, 0)

					for _, compData in ipairs(data.components or {}) do
						local compType = type(compData) == "table" and compData.type or compData
						local factory = componentFactories[compType]
						if factory then
							obj:addComponent(factory(compData))
						end
					end

					if spawnCallback then
						local x, y = spawnCallback(data)
						obj.x = x or obj.x
						obj.y = y or obj.y
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

function SpriteLoader.reload(objects, assetsPath, spawnCallback)
	for _, entry in ipairs(objects) do
		local luaPath = entry.path:gsub("^/", ""):gsub("/", "."):gsub("%.lua$", "")
		package.loaded[luaPath] = nil
	end
	return SpriteLoader.loadAll(assetsPath, spawnCallback)
end

return SpriteLoader
