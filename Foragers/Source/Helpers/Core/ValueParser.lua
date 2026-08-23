-- Key handlers (e.g. "text" -> localization) are injected at boot via
-- registerKeyHandler so this generic parser stays decoupled from any specific
-- subsystem. Without a registered handler a key is parsed normally.
--
-- BOOT-ORDER CONTRACT: handlers must be registered before the first
-- ValueParser.table call. Register in love.load (see Main.lua) before
-- initGame/sprite loading; the registry is singleton state on this module, so
-- a single early registration covers every later parse. A "text" key parsed
-- before its handler is registered degrades silently (the raw string is kept
-- untouched), so never call ValueParser.table at module top-level scope.

local Log = require("Source.Helpers.Core.Log")

local ValueParser = {}

-- Injected handlers keyed by string field name. Populated at boot; see Main.lua.
ValueParser._keyHandlers = {}

--- When ValueParser.table meets this key it routes the value through `fn`
--- instead of the default string/table parse. Used to wire localization (text)
--- without coupling this module to I18n/TextParser.
---@param key string
---@param fn fun(value: any): any
function ValueParser.registerKeyHandler(key, fn)
	if ValueParser._keyHandlers[key] and ValueParser._keyHandlers[key] ~= fn then
		Log.write("ValueParser", "key handler '" .. key .. "' overwritten")
	end
	ValueParser._keyHandlers[key] = fn
end

local function pickChoice(value)
	local parts = {}
	for part in string.gmatch(value, "[^|]+") do
		local trimmed = string.match(part, "^%s*(.-)%s*$")
		local num = tonumber(trimmed)
		if num then
			table.insert(parts, num)
		end
	end
	if #parts > 0 then
		return parts[love.math.random(1, #parts)]
	end
	return nil
end

local function parseRangeStr(value)
	local min, max = value:match("^(%-?%d+%.?%d*)%.%.%s*(%-?%d+%.?%d*)$")
	if min and max then
		return tonumber(min), tonumber(max)
	end
	return nil, nil
end

local function parseValue(value)
	local r = { val = value, min = value, max = value }
	if type(value) == "string" then
		if string.find(value, "|") then
			local result = pickChoice(value)
			if result then
				r = { val = result, min = result, max = result }
			end
		else
			local min, max = parseRangeStr(value)
			if min and max then
				r = { val = love.math.random(min, max), min = min, max = max }
			else
				local n = tonumber(value)
				if n then
					r = { val = n, min = n, max = n }
				end
			end
		end
	end
	return r
end

function ValueParser.value(value)
	return parseValue(value).val
end

--- Re-rolls if __raw stored, otherwise returns resolved value.
---@param tbl table
---@param field string
---@return any
function ValueParser.call(tbl, field)
	local raw = tbl.__raw
	if raw then
		local rawVal = raw[field]
		if rawVal ~= nil then
			return ValueParser.value(rawVal)
		end
	end
	return tbl[field]
end

function ValueParser.range(value)
	local r = parseValue(value)
	return r.min, r.max
end

--- Parse "7>17" -> 7, 17. Default "0>24" (always valid). Handles optional whitespace.
---@param raw string|nil
---@return number, number
function ValueParser.parseSpawnTime(raw)
	if raw then
		local a, b = raw:match("^%s*(%d+)%s*>%s*(%d+)%s*$")
		if a and b then
			return assert(tonumber(a)), assert(tonumber(b))
		end
	end
	return 0, 24
end

--- Re-rolls range from __raw, otherwise returns resolved range.
---@param tbl table
---@param field string
---@return number, number
function ValueParser.callRange(tbl, field)
	local raw = tbl.__raw
	if raw then
		local rawVal = raw[field]
		if rawVal ~= nil then
			return ValueParser.range(rawVal)
		end
	end
	return ValueParser.range(tbl[field])
end

-- Stores originals in tbl.__raw so values can be re-rolled later.
-- Skips __-prefixed keys so repeated calls are idempotent. `seen` guards
-- against self-referential / cyclic tables (a shared sub-table is visited once).
---@param tbl table
---@param seen table|nil internal: visited tables for cycle protection
---@return table
function ValueParser.table(tbl, seen)
	if tbl.__raw then
		return tbl
	end
	seen = seen or {}
	if seen[tbl] then
		return tbl
	end
	seen[tbl] = true
	for k, v in pairs(tbl) do
		local kstr = type(k) == "string" and k or nil
		-- __-prefixed keys are internal bookkeeping; never parse them.
		if not (kstr and kstr:sub(1, 2) == "__") then
			local handler = kstr and ValueParser._keyHandlers[kstr]
			if handler then
				-- Injected handler (e.g. text -> localization). It passes literal
				-- strings and dynamic values through unchanged so glyph rendering
				-- stays intact; only translatable forms get transformed. We don't
				-- recurse into a {key=...} table (ValueParser.value would mangle the
				-- key). When the form changed we keep the original in __raw so a live
				-- language switch can re-resolve it.
				local resolved = handler(v)
				if resolved ~= v then
					tbl.__raw = tbl.__raw or {}
					tbl.__raw[k] = v
				end
				tbl[k] = resolved
			elseif type(v) == "string" then
				local resolved = ValueParser.value(v)
				if resolved ~= v then
					tbl.__raw = tbl.__raw or {}
					tbl.__raw[k] = v
				end
				tbl[k] = resolved
			elseif type(v) == "table" then
				ValueParser.table(v, seen)
			end
		end
	end
	return tbl
end

return ValueParser
