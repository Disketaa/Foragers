---@class ModLoader
local ModLoader = {}

-- Loads single mod module. Returns nil on any error (file not found, syntax error, or no return value).
---@param path string Full module path (e.g., "Mods.MyMod.Mod")
---@return table|nil mod Mod table or nil if loading failed
function ModLoader.loadMod(path)
	local success, mod = pcall(require, path)
	if not success or type(mod) ~= "table" then
		return nil
	end
	return mod
end

-- Scans mods folder, loads all Mod.lua files.
-- Silently skips malformed mods to prevent one mod from breaking the game.
---@param modsPath string Path to Mods folder
---@return table<string, table> mods Table of loaded mods keyed by mod name
function ModLoader.loadAllMods(modsPath)
	local mods = {}
	pcall(function()
		local modList = love.filesystem.getDirectoryItems(modsPath)
		if not modList then return end
		for _, modName in ipairs(modList) do
			local fullPath = modsPath .. "/" .. modName
			local info = love.filesystem.getInfo(fullPath)
			if info and info.type == "directory" then
				local ok, mod = pcall(ModLoader.loadMod, fullPath .. "/Mod")
				if ok and mod then
					mods[modName] = mod
				end
			end
		end
	end)
	return mods
end

-- Calls reload() on all mods if they define it.
-- Used after hot-reload to notify mods of content updates.
---@param mods table<string, table> Table of mods from loadAllMods
function ModLoader.reloadAll(mods)
	for _, mod in pairs(mods or {}) do
		if type(mod.reload) == "function" then
			mod.reload()
		end
	end
end

return ModLoader
