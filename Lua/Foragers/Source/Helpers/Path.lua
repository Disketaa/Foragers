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

return Path
