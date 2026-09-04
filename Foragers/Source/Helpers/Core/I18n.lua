-- Missing translations return the raw key so gaps stay visible during development.
local Path = require("Source.Helpers.Core.Path")
local Log = require("Source.Helpers.Core.Log")

local I18n = {}

I18n.DEFAULT_LANG = "English"
I18n._langs = {}        -- code -> table
I18n._current = I18n.DEFAULT_LANG
I18n._pending = nil     -- language requested before _langs was loaded (deferred)
I18n._listeners = {}
local _warned = {}      -- dedupe missing-key / load warnings

--- Register a callback for language changes; used to re-resolve already-built
--- text for a live switch without a reload.
---@param cb fun(code: string)
function I18n.onLanguageChange(cb)
	table.insert(I18n._listeners, cb)
end

--- Safe to call once at boot; subsequent calls refresh the language tables.
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
			Log.error("I18n", "failed to load language '" .. code .. "': " .. tostring(data))
		end
	end)
	if not I18n._langs[I18n.DEFAULT_LANG] then
		-- Without the canonical table every lookup degrades to the raw key.
		I18n._langs[I18n.DEFAULT_LANG] = {}
	end
	-- Decoupled via pcall so I18n never forces an Options load order or import
	-- cycle. A genuine failure is logged once so a broken Options import isn't
	-- masked as "defaults to en".
	local ok, Options = pcall(require, "Source.Helpers.Systems.Options")
	if ok and Options and Options.language then
		I18n.setLanguage(Options.language)
	elseif not ok then
		Log.error("I18n", "Options load failed (language defaulted to '" .. I18n._current .. "'): " .. tostring(Options))
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

---@param code string|nil
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
		if not _warned["lang:" .. code] then
			_warned["lang:" .. code] = true
			Log.write("I18n", "unknown language '" .. code .. "'; using '" .. I18n._current .. "'")
		end
	end
end

function I18n.getLanguage()
	return I18n._current
end

--- Flat language tables use the full dotted key ("card.durability") as the
--- table key, so lookup is a direct index (Minecraft-style lang files).
---@param tbl table
---@param key string
---@return any
local function lookup(tbl, key)
	return tbl[key]
end

--- Integers render without a decimal; non-integers keep up to 2 decimals with
--- trailing zeros stripped, so buff values never show as "+2.0 damage".
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

--- Replace {name} placeholders (e.g. "{n}") using the params table.
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
			Log.write("I18n", "missing key '" .. key .. "' in '" .. I18n._current .. "' and '" .. I18n.DEFAULT_LANG .. "'")
		end
		return key
	end
	if type(str) ~= "string" then
		return tostring(str)
	end
	return interpolate(str, params)
end

return I18n