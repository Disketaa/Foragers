local ModLoader = {}

function ModLoader.loadMod(path)
	local success, mod = pcall(require, path)
	if not success then
		return nil
	end
	return mod
end

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

function ModLoader.reloadAll(mods)
	for name, mod in pairs(mods) do
		if mod.reload then
			mod.reload()
		end
	end
end

return ModLoader
