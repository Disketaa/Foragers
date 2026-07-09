---@class ModLoader
local ModLoader = {}

---@param path string
---@return table|nil
local function loadMod(path)
	local success, mod = pcall(require, path)
	if not success or type(mod) ~= "table" then
		return nil
	end
	return mod
end

---@param modsPath string
---@return table<string, table>
function ModLoader.loadAllMods(modsPath)
	local mods = {}
	pcall(function()
		local modList = love.filesystem.getDirectoryItems(modsPath)
		if not modList then
			return
		end
		for _, modName in ipairs(modList) do
			local fullPath = modsPath .. "/" .. modName
			local info = love.filesystem.getInfo(fullPath)
			if info and info.type == "directory" then
				local ok, mod = pcall(loadMod, fullPath .. "/Mod")
				if ok and mod then
					mods[modName] = mod
				end
			end
		end
	end)
	return mods
end

return ModLoader
