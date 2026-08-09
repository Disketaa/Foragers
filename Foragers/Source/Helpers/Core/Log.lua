--- Central log sink. Mirrors every print to a timestamped log file in the LÖVE
--- save directory (Logs/Latest.txt) in addition to stdout. Rewrites the file on
--- each run. Uses love.filesystem so it works everywhere without spawning a
--- console or needing a writable source dir.
local Log = {}

local saveDir = nil
local originalPrint = print

--- Prepare the log file: create Logs/, truncate any previous run's file and
--- write a timestamped header. Must run once at startup before any logging.
function Log.init()
	if not (love and love.filesystem) then
		return
	end
	saveDir = love.filesystem.getSaveDirectory()
	love.filesystem.createDirectory("Logs")
	local lines = {
		"-- Foragers log --",
		"-- Started: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"-- Path: " .. saveDir .. "/Logs/Latest.txt",
	}
	local ok = love.filesystem.write("Logs/Latest.txt", table.concat(lines, "\n") .. "\n")
	if not ok then
		saveDir = nil
	end
end

function Log.write(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring(select(i, ...))
	end
	local line = table.concat(parts, "\t")
	originalPrint(line)
	if saveDir then
		love.filesystem.append("Logs/Latest.txt", "[" .. os.date("%H:%M:%S") .. "] " .. line .. "\n")
	end
end

function Log.error(msg)
	Log.write("[ERROR]", msg)
end

-- Universal: route every global print through the log sink so no caller needs
-- to opt in. `print` is the single choke point used by every module.
_G.print = function(...)
	Log.write(...)
end

return Log
