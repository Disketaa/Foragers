--- Shared input-state + UTF-8 helpers.
---
--- Capture gate: when a text-input surface (chat, future consoles) owns the
--- keyboard it sets capture so gameplay input consumers (Control, etc.) skip
--- reading `love.keyboard.isDown` instead of moving the player while typing.
--- Single flag, set by the owner, read by consumers.
---
--- UTF-8 helpers: LuaJIT is Lua 5.1 — no built-in `utf8` module (see
--- ABSTRACTIONS.md), and LÖVE's font APIs throw on malformed sequences, so
--- byte-aware string ops must avoid splitting multibyte codepoints.
local Input = {}

-- Capture gate ---------------------------------------------------------------

local captured = false

function Input.setCaptured(value)
	captured = value == true
end

function Input.isCaptured()
	return captured
end

-- UTF-8 helpers --------------------------------------------------------------

-- True when byte `b` is a UTF-8 continuation byte (10xxxxxx = 0x80..0xBF).
local function isContinuation(b)
	return b >= 0x80 and b <= 0xBF
end

-- Byte length of the codepoint whose first byte is `b`.
local function codepointLen(b)
	if b < 0x80 then return 1 end
	if b < 0xE0 then return 2 end
	if b < 0xF0 then return 3 end
	return 4
end

-- Remove the final codepoint without splitting a multibyte sequence.
---@param s string
---@return string
function Input.removeLast(s)
	local len = #s
	if len == 0 then return s end
	local i = len
	while i > 1 and isContinuation(string.byte(s, i)) do
		i = i - 1
	end
	return string.sub(s, 1, i - 1)
end

-- Keep only complete, well-formed codepoints; drop any byte that isn't part of
-- a valid sequence. `love.textinput` is normally valid UTF-8, but a malformed or
-- font-incompatible sequence must never reach `font:getWidth` (it throws).
---@param s string
---@return string
function Input.sanitize(s)
	local len = #s
	if len == 0 then return s end
	local out = {}
	local i = 1
	while i <= len do
		local b = string.byte(s, i)
		local clen = codepointLen(b)
		local valid = i + clen - 1 <= len
		if valid then
			for j = 1, clen - 1 do
				if not isContinuation(string.byte(s, i + j)) then
					valid = false
					break
				end
			end
		end
		if valid then
			out[#out + 1] = string.sub(s, i, i + clen - 1)
			i = i + clen
		else
			i = i + 1
		end
	end
	return table.concat(out)
end

return Input