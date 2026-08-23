--- Game options loader. `Content/Data/Options.lua` holds the defaults; this
--- module merges a local `Options.txt` (save dir) over them at load,
--- Minecraft-style, and exposes `save()` so runtime changes persist. Returns
--- the same live table every consumer reads, so loaded values are shared.
local Options = require("Content.Data.Options")

local FILE = "Options.txt"

--- Runtime-toggleable debug flag overrides collected from Options.txt. Debug
--- applies these to its own data table once it loads (it requires this module,
--- so it cannot read them during Options.load without a cycle).
Options._debug = {}

local function debugFlags()
	-- Only read flags if Debug already loaded; requiring it here mid-Options-load
	-- would cycle (Debug requires Options). First-run save thus omits debug lines,
	-- which the next explicit save (after a toggle) fills in.
	local Debug = package.loaded["Source.Helpers.Debug.Debug"]
	if Debug and Debug.serializeFlags then
		return Debug.serializeFlags()
	end
	return {}
end

local function toText(v)
	if v == true then
		return "true"
	elseif v == false then
		return "false"
	end
	return tostring(v)
end

--- Serialize the current options to `key=value` lines. Top-level scalars
--- (boolean/number/string, e.g. `language`) serialize directly so any new
--- option persists without touching this function; `keybinds` and debug flags
--- keep their special formats. Returns the text, does not write.
function Options.serialize()
	local lines = { "# Foragers options" }
	for k, v in pairs(Options) do
		if k == "_debug" or k == "keybinds" then
			-- serialized below / handled separately
		elseif type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
			lines[#lines + 1] = k .. "=" .. toText(v)
		end
	end
	for name, kb in pairs(Options.keybinds) do
		if kb.keyboard then
			lines[#lines + 1] = "keybind." .. name .. "=" .. table.concat(kb.keyboard, ",")
		end
	end
	for path, on in pairs(debugFlags()) do
		lines[#lines + 1] = "debug." .. path .. "=" .. toText(on)
	end
	return table.concat(lines, "\n") .. "\n"
end

--- Coerce a saved string back to its Lua type: boolean for "true"/"false",
--- number when numeric, otherwise the raw string (e.g. language names).
local function parseValue(s)
	if s == "true" then return true end
	if s == "false" then return false end
	local n = tonumber(s)
	if n then return n end
	return s
end

--- Apply one parsed `key=value` line onto the live options table.
local function apply(key, value)
	if key:match("^keybind%.") then
		local name = key:sub(9)
		local kb = Options.keybinds[name]
		if kb then
			kb.keyboard = {}
			for k in value:gmatch("[^,]+") do
				kb.keyboard[#kb.keyboard + 1] = k
			end
		end
	elseif key:match("^debug%.") then
		Options._debug[key:sub(7)] = value == "true"
	elseif Options[key] ~= nil then
		-- Known scalar option (fullscreen, maxFps, language, ...): coerce and set.
		Options[key] = parseValue(value)
	end
end

--- Write the current options to `Options.txt` in the save directory.
function Options.save()
	if not (love and love.filesystem) then
		return
	end
	love.filesystem.write(FILE, Options.serialize())
end

--- Read `Options.txt` if present and merge over the defaults; otherwise create
--- it from the defaults. Called once at load.
function Options.load()
	if not (love and love.filesystem) then
		return
	end
	if not love.filesystem.getInfo(FILE) then
		Options.save()
		return
	end
	for line in love.filesystem.lines(FILE) do
		local eq = line:find("=")
		if eq and line:sub(1, 1) ~= "#" then
			apply(line:sub(1, eq - 1), line:sub(eq + 1))
		end
	end
end

Options.load()

return Options
