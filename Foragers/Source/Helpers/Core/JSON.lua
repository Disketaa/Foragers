-- json.lua (rxi, MIT) — vendored pure-Lua JSON codec. LÖVE's love.data has no
-- JSON container, so this is the system-level helper DiscordRPC uses for the IPC
-- frame payloads. https://github.com/rxi/json.lua
-- Copyright (c) 2020 rxi
-- MIT License — permission notice must be retained.

local json = { _version = "0.1.2" }

local encode_escape_sequences = {
	[ "\\" ] = "\\\\",
	[ "\"" ] = "\\\"",
	[ "\b" ] = "\\b",
	[ "\f" ] = "\\f",
	[ "\n" ] = "\\n",
	[ "\r" ] = "\\r",
	[ "\t" ] = "\\t",
}

local function encode_escape_sequences_replace(char)
	return encode_escape_sequences[char] or string.format("\\u%04x", char:byte())
end

local encode_string = function(string)
	return '"' .. string.gsub(string, '[%z\1-\31"\\]', encode_escape_sequences_replace) .. '"'
end

local encode_number = function(number)
	if math.huge == number then
		return "1e+9999"
	end
	if -math.huge == number then
		return "-1e+9999"
	end
	return string.format("%.14g", number)
end

local encode_value
local encode_table

local function is_array(table)
	local count = 0
	local index = 0
	for k, _ in pairs(table) do
		if type(k) == "number" then
			if k > index then
				index = k
			end
			count = count + 1
		else
			return false
		end
	end
	if index ~= count then
		return false
	end
	return true
end

encode_table = function(table)
	local is_empty_table = true
	local result = {}
	if is_array(table) then
		for _, v in ipairs(table) do
			result[#result + 1] = encode_value(v)
			is_empty_table = false
		end
	else
		for k, v in pairs(table) do
			if type(k) == "string" then
				result[#result + 1] = encode_string(k) .. ":" .. encode_value(v)
				is_empty_table = false
			end
		end
	end
	if is_empty_table then
		return "{}"
	end
	local delimiter = is_array(table) and "," or ","
	return (is_array(table) and "[" or "{") .. table.concat(result, delimiter) .. (is_array(table) and "]" or "}")
end

encode_value = function(value)
	if type(value) == "string" then
		return encode_string(value)
	end
	if type(value) == "number" then
		return encode_number(value)
	end
	if type(value) == "table" then
		return encode_table(value)
	end
	if type(value) == "boolean" then
		return value and "true" or "false"
	end
	if type(value) == "nil" then
		return "null"
	end
	error("Cannot encode value of type " .. type(value))
end

json.encode = function(value)
	return encode_value(value)
end

local parse

local function skip_delimiters(str, pos)
	while pos <= #str do
		local sub = str:sub(pos, pos)
		if sub:match("%s") then
			pos = pos + 1
		else
			break
		end
	end
	return pos
end

local escape_map = {
	[ '"' ] = '"',
	[ "\\" ] = "\\",
	[ "/" ] = "/",
	[ "b" ] = "\b",
	[ "f" ] = "\f",
	[ "n" ] = "\n",
	[ "r" ] = "\r",
	[ "t" ] = "\t",
}

local function parse_str_val(str, pos)
	pos = pos + 1
	local buffer = ""
	while true do
		local c = str:sub(pos, pos)
		if c == '"' then
			return buffer, pos + 1
		elseif c == "\\" then
			local esc = str:sub(pos + 1, pos + 1)
			if esc == "u" then
				local hex = str:sub(pos + 2, pos + 5)
				local code = tonumber(hex, 16)
				buffer = buffer .. utf8.char(code)
				pos = pos + 6
			else
				buffer = buffer .. (escape_map[esc] or esc)
				pos = pos + 2
			end
		else
			buffer = buffer .. c
			pos = pos + 1
		end
	end
end

local function parse_number(str, pos)
	local match, end_pos = string.find(str, "[+-]?%d+%.?%d*[eE]?[+-]?%d*", pos)
	return tonumber(match), end_pos + 1
end

local function parse_literal(str, pos, literal, value)
	local match, end_pos = string.find(str, "^" .. literal, pos)
	if match then
		return value, end_pos + 1
	else
		return nil, pos
	end
end

local function parse_array(str, pos)
	local result = {}
	pos = pos + 1
	pos = skip_delimiters(str, pos)
	if str:sub(pos, pos) == "]" then
		return result, pos + 1
	end
	local value
	while true do
		value, pos = parse(str, pos)
		result[#result + 1] = value
		pos = skip_delimiters(str, pos)
		local sub = str:sub(pos, pos)
		if sub == "," then
			pos = skip_delimiters(str, pos + 1)
		elseif sub == "]" then
			return result, pos + 1
		else
			error("Unexpected character at " .. pos)
		end
	end
end

local function parse_object(str, pos)
	local result = {}
	pos = pos + 1
	pos = skip_delimiters(str, pos)
	if str:sub(pos, pos) == "}" then
		return result, pos + 1
	end
	local key, value
	while true do
		key, pos = parse_str_val(str, pos)
		pos = skip_delimiters(str, pos)
		local sub = str:sub(pos, pos)
		if sub ~= ":" then
			error("Expected ':' at " .. pos)
		end
		pos = skip_delimiters(str, pos + 1)
		value, pos = parse(str, pos)
		result[key] = value
		pos = skip_delimiters(str, pos)
		local sub2 = str:sub(pos, pos)
		if sub2 == "," then
			pos = skip_delimiters(str, pos + 1)
		elseif sub2 == "}" then
			return result, pos + 1
		else
			error("Unexpected character at " .. pos)
		end
	end
end

parse = function(str, pos)
	pos = skip_delimiters(str, pos)
	local sub = str:sub(pos, pos)
	if sub == "{" then
		return parse_object(str, pos)
	end
	if sub == "[" then
		return parse_array(str, pos)
	end
	if sub == '"' then
		return parse_str_val(str, pos)
	end
	if sub:match("[+-]?%d") then
		return parse_number(str, pos)
	end
	if sub == "t" then
		return parse_literal(str, pos, "true", true)
	end
	if sub == "f" then
		return parse_literal(str, pos, "false", false)
	end
	if sub == "n" then
		return parse_literal(str, pos, "null", nil)
	end
	error("Unexpected character at " .. pos)
end

json.decode = function(str)
	local result, pos = parse(str, 1)
	pos = skip_delimiters(str, pos)
	if pos <= #str then
		error("Unexpected trailing characters at " .. pos)
	end
	return result
end

return json
