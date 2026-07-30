local Path = {}

function Path.lua(str)
	return (str:gsub("^[/\\]", ""):gsub("[/\\]", "."):gsub("%.lua$", ""))
end

function Path.png(str)
	return (str:gsub("%.lua$", "") .. ".png")
end

function Path.moduleToPath(str)
	return (str:gsub("%.", "/"))
end

--- Recursively scan a directory for .lua files, calling callback(fullPath, item) for each.
---@param path string Directory path
---@param callback fun(fullPath: string, item: string)
function Path.scanDirectory(path, callback)
	local items = love.filesystem.getDirectoryItems(path)
	for _, item in ipairs(items) do
		local fullPath = path .. "/" .. item
		local info = love.filesystem.getInfo(fullPath)
		if info and info.type == "directory" then
			Path.scanDirectory(fullPath, callback)
		elseif item:match("%.lua$") then
			callback(fullPath, item)
		end
	end
end

return Path
