--- Chat command history persisted to `ChatHistory.txt` (one entry per line,
--- newest last) with cursor-based up/down navigation for re-typing commands.
--- Decoupled from Debug: callers pass the current input text and max cap rather
--- than the module reading chat state, so any text-input surface can reuse it.
local ChatHistory = {}

local HISTORY_FILE = "ChatHistory.txt"

-- `pos` is 0 while free typing; up/down walk `entries` and return `draft` (the
-- text captured before the first up-press) when moving past the newest entry.
local entries = {}
local pos = 0
local draft = ""

---@param max number Trim on load so an old file never exceeds the current cap.
function ChatHistory.load(max)
	entries = {}
	if not (love and love.filesystem and love.filesystem.getInfo(HISTORY_FILE)) then
		return
	end
	for line in love.filesystem.lines(HISTORY_FILE) do
		entries[#entries + 1] = line
	end
	while #entries > max do
		table.remove(entries, 1)
	end
	pos = 0
	draft = ""
end

local function save()
	if not (love and love.filesystem) then
		return
	end
	love.filesystem.write(HISTORY_FILE, table.concat(entries, "\n") .. "\n")
end

---@param text string
---@param max number
function ChatHistory.push(text, max)
	if text == nil or text == "" then
		return
	end
	if #entries > 0 and entries[#entries] == text then
		pos = 0
		draft = ""
		return
	end
	entries[#entries + 1] = text
	while #entries > max do
		table.remove(entries, 1)
	end
	save()
	pos = 0
	draft = ""
end

---@param current string The typed input; captured as the draft on first up-press.
---@return string|nil
function ChatHistory.up(current)
	if #entries == 0 then
		return nil
	end
	if pos == 0 then
		draft = current or ""
		pos = #entries
	else
		pos = math.max(1, pos - 1)
	end
	return entries[pos]
end

---@return string|nil
function ChatHistory.down()
	if pos == 0 then
		return nil
	end
	pos = pos + 1
	if pos > #entries then
		pos = 0
		return draft
	end
	return entries[pos]
end

function ChatHistory.reset()
	pos = 0
	draft = ""
end

---@return table The in-memory entries (newest last). Read-only by convention.
function ChatHistory.entries()
	return entries
end

return ChatHistory