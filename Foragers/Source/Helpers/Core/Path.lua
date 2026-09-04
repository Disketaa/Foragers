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
	Path._scanDirectory(path, callback, 0)
end

--- Inside a .love archive getInfo can misreport a .lua file as a "directory", so a
--- plain recursion descends into the file itself and overflows the stack. Check the
--- extension first and only recurse into real directories; MAX_DEPTH is a backstop.
--- Also skip empty/dot entries: in the archive getDirectoryItems can return "" (or
--- "."), and path.."/".."" resolves back to the same dir, causing re-descent that
--- scans every file many times over.
local MAX_DEPTH = 12
function Path._scanDirectory(path, callback, depth)
	if depth > MAX_DEPTH then return end
	local items = love.filesystem.getDirectoryItems(path)
	for _, item in ipairs(items) do
		if item ~= "" and item ~= "." and item ~= ".." then
			local fullPath = path:gsub("/+$", "") .. "/" .. item
			if item:match("%.lua$") then
				callback(fullPath, item)
			else
				local info = love.filesystem.getInfo(fullPath)
				if info and info.type == "directory" then
					Path._scanDirectory(fullPath, callback, depth + 1)
				end
			end
		end
	end
end

return Path