-- Universal in-game localization.
-- Loads every Content/Data/I18n/<Language>.lua table, resolves dotted
-- keys via I18n.t(key, params), falls back to "English", and returns the key
-- itself when a translation is missing (so gaps stay visible during development).
local Path = require("Source.Helpers.Core.Path")

local I18n = {}

I18n.DEFAULT_LANG = "English"
I18n._langs = {}        -- code -> table
I18n._current = I18n.DEFAULT_LANG
I18n._pending = nil     -- language requested before _langs was loaded (deferred)
I18n._listeners = {}    -- callbacks fired on language change (live switch)
local _warned = {}      -- dedupe missing-key / load warnings

--- Register a callback invoked when the active language changes. Used to
--- re-resolve already-built text (live language switch without a reload).
---@param cb fun(code: string)
function I18n.onLanguageChange(cb)
	table.insert(I18n._listeners, cb)
end

--- Scan the I18n directory and require each <Language>.lua table.
--- Safe to call once at boot; subsequent calls refresh.
function I18n.load()
	I18n._langs = {}
	Path.scanDirectory("Content/Data/I18n", function(fullPath)
		local code = fullPath:match("([^/\\]+)%.lua$")
		if not code then return end
		local ok, data = pcall(require, Path.lua(fullPath))
		if ok and type(data) == "table" then
			I18n._langs[code] = data
		elseif not ok then
			-- Syntax/require error in a language file: surface it, don't silently
			-- drop the table (a broken English.lua would degrade every key to raw).
			print("[I18n] failed to load language '" .. code .. "': " .. tostring(data))
		end
	end)
	if not I18n._langs[I18n.DEFAULT_LANG] then
		-- Without the canonical table every lookup degrades to the raw key.
		I18n._langs[I18n.DEFAULT_LANG] = {}
	end
	-- Adopt the user's language from Options if present (decoupled: pcall so
	-- I18n never forces an Options load order or import cycle). Log a genuine
	-- failure once so a broken Options import isn't masked as "defaults to en".
	local ok, Options = pcall(require, "Source.Helpers.Systems.Options")
	if ok and Options and Options.language then
		I18n.setLanguage(Options.language)
	elseif not ok then
		print("[I18n] Options load failed (language defaulted to '" .. I18n._current .. "'): " .. tostring(Options))
	end
	-- An explicit setLanguage() issued before langs were ready takes precedence
	-- over the Options default (explicit runtime override wins).
	if I18n._pending then
		local pending = I18n._pending
		I18n._pending = nil
		I18n.setLanguage(pending)
	end
	return I18n
end

---@param code string|nil Language code (e.g. "English", "Russian"). Falls back to default.
function I18n.setLanguage(code)
	if not code then return end
	-- Langs may not be loaded yet (e.g. an explicit setLanguage before boot
	-- finished loading). Defer the preference so it isn't dropped as "unknown"
	-- and isn't clobbered by the Options read inside load().
	if not next(I18n._langs) then
		I18n._pending = code
		return
	end
	if I18n._langs[code] then
		if I18n._current ~= code then
			I18n._current = code
			-- Live switch: let already-built text re-resolve against the new language.
			for _, cb in ipairs(I18n._listeners) do
				cb(code)
			end
		end
	else
		-- Unknown code: keep default but note it once.
		if not _warned["lang:" .. code] then
			_warned["lang:" .. code] = true
			print("[I18n] unknown language '" .. code .. "'; using '" .. I18n._current .. "'")
		end
	end
end

function I18n.getLanguage()
	return I18n._current
end

--- Walk a dotted key ("card.durability") inside a language table.
---@param tbl table
---@param key string
---@return any
local function lookup(tbl, key)
	local node = tbl
	for seg in key:gmatch("[^.]+") do
		if type(node) ~= "table" then return nil end
		node = node[seg]
	end
	return node
end

--- Format a placeholder value for display. Integers render without a decimal
--- (2.0 -> "2"); non-integers keep up to 2 decimals with trailing zeros stripped
--- (so computed buff values never show as "+2.0 damage").
---@param v any
---@return string
local function formatParam(v)
	if type(v) == "number" then
		if math.floor(v) == v then
			return tostring(math.floor(v))
		end
		local s = string.format("%.2f", v)
		s = s:gsub("%.?0+$", "")
		return s
	end
	return tostring(v)
end

--- Replace {name} placeholders ("{n}") from the params table.
---@param str string
---@param params table|nil
---@return string
local function interpolate(str, params)
	if not params then return str end
	return (str:gsub("%{([%w_]+)%}", function(name)
		local v = params[name]
		if v == nil then return "" end
		return formatParam(v)
	end))
end

--- Resolve a translation key into the active language string.
---@param key string Dotted key path
---@param params table|nil Placeholder values
---@return string
function I18n.t(key, params)
	if not next(I18n._langs) then
		I18n.load()
	end
	local active = I18n._langs[I18n._current]
	local str = lookup(active, key)
	if str == nil then
		str = lookup(I18n._langs[I18n.DEFAULT_LANG], key)
	end
	if str == nil then
		if not _warned[key] then
			_warned[key] = true
			print("[I18n] missing key '" .. key .. "' in '" .. I18n._current .. "' and '" .. I18n.DEFAULT_LANG .. "'")
		end
		return key
	end
	if type(str) ~= "string" then
		return tostring(str)
	end
	return interpolate(str, params)
end

return I18n
