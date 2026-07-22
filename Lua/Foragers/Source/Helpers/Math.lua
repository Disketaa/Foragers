local Math = {}

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
	local min, max = value:match("^(%-?%d+%.?%d*)%.%.%.%s*(%-?%d+%.?%d*)$")
	if min and max then
		return tonumber(min), tonumber(max)
	end
	return nil, nil
end

--- Parse a value that may be a number, a `"min|max|..."` choice string,
--- or a `"min...max"` range string. Returns a single number.
---@param value any
---@return number
function Math.parseRandomValue(value)
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

--- Parse a value that may be a number, a `"min|max|..."` choice string,
--- or a `"min...max"` range string. Returns min, max.
--- For `|` choice strings, picks one choice and returns it as both min and max.
---@param value any
---@return number, number
function Math.parseRange(value)
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

function Math.expSmooth(dt, smoothness)
	if smoothness and smoothness > 0 then
		return 1 - math.exp(-dt / smoothness)
	end
	return 1
end

return Math
