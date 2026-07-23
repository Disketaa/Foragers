-- Load-time: ValueParser.table(tbl) resolves all strings, stores originals in tbl.__raw.
-- Per-event: ValueParser.call(tbl, field) re-rolls if __raw exists, else returns resolved.
-- Single:    ValueParser.value(str) | ValueParser.range(str) -> (min,max)

local ValueParser = {}

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

---@param value any
---@return any
function ValueParser.value(value)
	if type(value) == "number" then
		return value
	end
	if type(value) == "string" then
		if string.find(value, "|") then
			local result = pickChoice(value)
			if result then
				return result
			end
		end
		local min, max = parseRangeStr(value)
		if min and max then
			return love.math.random(min, max)
		end
		local n = tonumber(value)
		if n then
			return n
		end
	end
	return value
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

---@param value any
---@return number, number
function ValueParser.range(value)
	if type(value) == "number" then
		return value, value
	end
	if type(value) == "string" then
		if string.find(value, "|") then
			local result = pickChoice(value)
			if result then
				return result, result
			end
		end
		local min, max = parseRangeStr(value)
		if min and max then
			return min, max
		end
		local n = tonumber(value)
		if n then
			return n, n
		end
	end
	return value, value
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

-- Resolves all strings in-place. Stores originals in tbl.__raw for re-rolling.
-- Skips __-prefixed keys so repeated calls are idempotent.
---@param tbl table
---@return table
function ValueParser.table(tbl)
	if tbl.__raw then
		return tbl
	end
	for k, v in pairs(tbl) do
		local kstr = type(k) == "string" and k or nil
		if not (kstr and kstr:sub(1, 2) == "__") then
			if type(v) == "string" then
				local resolved = ValueParser.value(v)
				if resolved ~= v then
					tbl.__raw = tbl.__raw or {}
					tbl.__raw[k] = v
				end
				tbl[k] = resolved
			elseif type(v) == "table" then
				ValueParser.table(v)
			end
		end
	end
	return tbl
end

return ValueParser
