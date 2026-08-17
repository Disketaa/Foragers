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

-- Arity-based dispatch keeps legacy single-arg calls working during migration:
--   Log.write(msg)            -> msg as-is (legacy)
--   Log.write(tag, msg)       -> "[tag] msg" (no string.format; safe on stray %)
--   Log.write(tag, fmt, ...)  -> "[tag] " .. string.format(fmt, ...)
local function buildLine(tag, fmt, ...)
	local n = select("#", ...)
	if fmt == nil then
		return tostring(tag)
	elseif n == 0 then
		return "[" .. tostring(tag) .. "] " .. tostring(fmt)
	else
		return "[" .. tostring(tag) .. "] " .. string.format(fmt, ...)
	end
end

local function emit(msg)
	originalPrint(msg)
	if saveDir then
		love.filesystem.append("Logs/Latest.txt", "[" .. os.date("%H:%M:%S") .. "] " .. msg .. "\n")
	end
end

---@param tag string|nil  Category tag, e.g. "Collision". Optional for legacy calls.
---@param fmt string|nil  Plain message, or a string.format pattern when extra args follow.
function Log.write(tag, fmt, ...)
	emit(buildLine(tag, fmt, ...))
end

---@param tag string|nil  Category tag, e.g. "Sprite". Optional for legacy calls.
---@param fmt string|nil  Plain message, or a string.format pattern when extra args follow.
function Log.error(tag, fmt, ...)
	local n = select("#", ...)
	local msg
	if fmt == nil then
		msg = "[ERROR] " .. tostring(tag)
	else
		local body = n == 0 and tostring(fmt) or string.format(fmt, ...)
		msg = "[ERROR][" .. tostring(tag) .. "] " .. body
	end
	emit(msg)
end

-- Universal: route every global print through the log sink so no caller needs
-- to opt in. `print` is the single choke point used by every module. Keeps the
-- original tab-joined behavior (not the tag arity dispatch) so multi-arg
-- print(...) calls are unaffected.
_G.print = function(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring(select(i, ...))
	end
	emit(table.concat(parts, "\t"))
end

return Log
