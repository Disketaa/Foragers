--- Persisted key→command bindings for the debug chat console. Stored as
--- `Binds.txt` (one `key command` line each) in the love save dir, matching
--- the project's ChatHistory.txt convention so binds survive restarts. Key is
--- the LÖVE `keypressed` key string (never contains spaces), so splitting each
--- line on the first space cleanly separates key from a command that may itself
--- contain spaces. Pure persistence — no game deps, so Commands.lua stays
--- decoupled from the game.
local Binds = {}

local FILE = "Binds.txt"

-- key (string) -> command (string). Built at load(); mutated by set/remove.
local binds = {}

---@return table Array of {key=string, command=string}, sorted by key.
function Binds.all()
	local out = {}
	for key, command in pairs(binds) do
		out[#out + 1] = { key = key, command = command }
	end
	table.sort(out, function(a, b) return a.key < b.key end)
	return out
end

---@param key string
---@return string|nil
function Binds.get(key)
	return binds[key]
end

---@param key string
---@param command string
function Binds.set(key, command)
	binds[key] = command
	Binds.save()
end

---@param key string
function Binds.remove(key)
	binds[key] = nil
	Binds.save()
end

function Binds.clear()
	binds = {}
	Binds.save()
end

function Binds.load()
	binds = {}
	if not (love and love.filesystem) then return end
	if not love.filesystem.getInfo(FILE) then return end
	for line in love.filesystem.lines(FILE) do
		local sp = line:find(" ", 1, true)
		if sp then
			local key = line:sub(1, sp - 1)
			local command = line:sub(sp + 1)
			if key ~= "" and command ~= "" then
				binds[key] = command
			end
		end
	end
end

function Binds.save()
	if not (love and love.filesystem) then return end
	local lines = {}
	for _, b in ipairs(Binds.all()) do
		lines[#lines + 1] = b.key .. " " .. b.command
	end
	love.filesystem.write(FILE, table.concat(lines, "\n") .. (#lines > 0 and "\n" or ""))
end

return Binds