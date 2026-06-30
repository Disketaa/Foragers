-- Loads mods from Mods/{ModName}/Mod.lua.
local ModLoader = {}

-- Loads single mod by path. Returns nil on error.
function ModLoader.loadMod(path)
	local success, mod = pcall(require, path)
	if not success then
		return nil
	end
	return mod
end

-- Scans mods folder, loads all Mod.lua files.
-- Returns table: { ModName = mod, ... }.
function ModLoader.loadAllMods(modsPath)
	local mods = {}
	pcall(function()
		local modList = love.filesystem.getDirectoryItems(modsPath)
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

-- Calls reload() on all mods if defined.
function ModLoader.reloadAll(mods)
	for name, mod in pairs(mods) do
		if mod.reload then
			mod.reload()
		end
	end
end

return ModLoader
