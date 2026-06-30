-- Loads objects from Content/Assets/Sprites/{Name}/Character.lua.
-- Automatically builds components via registered factories.
local Object = require("Source.Object")
local AnimatableSprite = require("Source.AnimatableSprite")
local Controllable = require("Source.Controllable")

local SpriteLoader = {}

-- Component factories by type name. Mods can extend by adding to this table.
-- Each factory receives compData table (may be nil for string-based component refs).
local componentFactories = {
	AnimatableSprite = function(compData)
		return AnimatableSprite.new(compData)
	end,
	Controllable = function(compData)
		return Controllable.new(compData)
	end,
}

-- Scans folder recursively, creates objects from Character.lua files.
-- @param assetsPath string - Path to sprites folder (e.g., "Content/Assets/Sprites/Character")
-- @param spawnCallback function|nil - Receives data table, returns spawn (x, y)
-- @return table[] - Array of { path, data, instance } entries
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
					local obj = Object.new(0, 0)

					for _, compData in ipairs(data.components or {}) do
						if type(compData) ~= "table" then
							-- Skip non-table components (string-based refs not supported yet)
						else
							local compType = compData.type
							local factory = componentFactories[compType]
							if factory then
								obj:addComponent(factory(compData))
							end
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

-- Reloads all objects from disk. Clears require cache before loading.
-- Also reloads tween configuration for all existing animator components.
-- @param objects table[] - Previous objects array (for cache invalidation)
-- @param assetsPath string - Path to sprites folder
-- @param spawnCallback function|nil - Spawn position callback
-- @return table[] - New objects array
function SpriteLoader.reload(objects, assetsPath, spawnCallback)
	-- Invalidate tween config cache for hot-reload
	package.loaded["Assets.System.Tweens.flip"] = nil

	for _, entry in ipairs(objects or {}) do
		local luaPath = entry.path:gsub("^/", ""):gsub("/", "."):gsub("%.lua$", "")
		package.loaded[luaPath] = nil
		-- Reload tween config for existing animator components
		if entry.instance and entry.instance.components then
			for _, comp in ipairs(entry.instance.components) do
				if comp.type == "animator" and comp.reloadTweenConfig then
					comp:reloadTweenConfig()
				end
			end
		end
	end
	return SpriteLoader.loadAll(assetsPath, spawnCallback)
end

return SpriteLoader
