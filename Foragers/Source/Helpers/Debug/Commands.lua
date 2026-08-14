--- Debug console command registry. Handlers take `(args, ctx)` where `ctx` is a
--- game-state accessor table injected by Main.lua, keeping this module decoupled
--- from the game. A handler returns `(message, success)`; success false renders
--- the message red. Main.lua routes results to `Debug.setChatOutput(message, success)`.
local Commands = {}

local handlers = {}
local descriptions = {}
local subcommands = {} -- name -> array of sub-command names (sorted)

--- Register a command handler.
---@param name string Invoked name (e.g. "xp"), no leading slash.
---@param fn function|nil Handler: (args: string, ctx: table) -> (message: string, success: boolean)
---@param help string|nil Short description shown by the `help` command.
function Commands.register(name, fn, help)
	handlers[name] = fn
	descriptions[name] = help
end

--- Register a sub-command for completion (e.g. `world` → `clear`). Doesn't add a
--- handler; the main command parses its own args at run time.
---@param name string Main command name.
---@param sub string Sub-command token.
function Commands.addSubcommand(name, sub)
	local list = subcommands[name] or {}
	list[#list + 1] = sub
	table.sort(list)
	subcommands[name] = list
end

---@return table Command names, alphabetically sorted.
function Commands.list()
	local names = {}
	for name in pairs(handlers) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

--- Trim leading/trailing whitespace so extra spaces in input don't break matching.
---@param s string
---@return string
function Commands.trim(s)
	return (s or ""):match("^%s*(.-)%s*$")
end

--- Return tab-completion candidates for the token being typed. Completes command
--- names before any space; after `cmd ` it completes that command's sub-commands.
---@param text string Current chat input.
---@return string base Immutable text kept before the inserted candidate.
---@return table candidates Matched tokens, alphabetically sorted.
function Commands.complete(text)
	local cmd, rest = text:match("^(%S*)%s*(.*)$")
	local trailingSpace = text:match("^.*%s$") ~= nil
	local list = {}
	if trailingSpace or rest ~= "" then
		-- Completing a sub-command of `cmd`.
		for _, sub in ipairs(subcommands[cmd] or {}) do
			if sub:sub(1, #rest) == rest then
				list[#list + 1] = sub
			end
		end
		return cmd .. " ", list
	end
	-- Completing the command name.
	for _, name in ipairs(Commands.list()) do
		if name:sub(1, #cmd) == cmd then
			list[#list + 1] = name
		end
	end
	return "", list
end

--- Parse a signed amount arg. Accepts "+50" / "-50" / "50". Returns the integer
--- value and the op ("add"/"sub"/"set"); nil if unparsable.
---@param arg string
---@return number|nil value, "add"|"sub"|"set"|nil op
function Commands.parseAmount(arg)
	local s = arg:match("^%s*(%S+)%s*$")
	if not s then
		return nil
	end
	local sign, digits = s:match("^([+-]?)(%d+)$")
	if not digits then
		return nil
	end
	local num = tonumber(digits)
	local op = "set"
	if sign == "+" then
		op = "add"
	elseif sign == "-" then
		op = "sub"
	end
	return num, op
end

--- Execute a chat line ("xp +50"). Returns `(message, success)`.
---@param text string Full input, e.g. "xp +50".
---@param ctx table Game-state accessors.
---@return string|table message (string, or table of styled segment-lines for help)
---@return boolean success
---@return number|nil hold Optional output hide-delay multiplier (help uses 10).
function Commands.execute(text, ctx)
	local name, args = text:match("^%s*(%S+)%s*(.*)$")
	local fn = handlers[name]
	if not fn then
		return 'Unknown command: "' .. text .. '"', false
	end
	-- Trim trailing whitespace so "world clear   " behaves like "world clear".
	local ok, message, success, hold = pcall(fn, Commands.trim(args or ""), ctx)
	if not ok then
		return "Command error: " .. tostring(message), false
	end
	return message, success == true, hold
end

-- Built-in commands; each uses `ctx` accessors so this file never touches game
-- modules directly.
local function ctxOf(ctx)
	if type(ctx.stats) == "function" then
		return ctx.stats()
	end
	return nil
end

---@param ctx table
---@return table|nil s PlayerStats, or nil with `err` set when absent.
---@return string|nil err
local function needStats(ctx)
	local s = ctxOf(ctx)
	if not s then
		return nil, "No player"
	end
	return s, nil
end

Commands.register("xp", function(args, ctx)
	local s, err = needStats(ctx)
	if not s then
		return err, false
	end
	local amount, op = Commands.parseAmount(args)
	if not amount then
		return 'Usage: xp +N | xp -N | xp N', false
	end
	if op == "add" then
		s:addExperience(amount)
		return "+" .. amount .. " XP", true
	elseif op == "sub" then
		s:subtractExperience(amount)
		return "-" .. amount .. " XP", true
	end
	s:setExperience(amount)
	return "XP set to " .. amount, true
end, "set, add, or remove XP.")

Commands.register("lvl", function(args, ctx)
	local s, err = needStats(ctx)
	if not s then
		return err, false
	end
	if args == "" then
		s:addLevels(1)
		return "+1 Level", true
	end
	local amount, op = Commands.parseAmount(args)
	if not amount then
		return 'Usage: lvl | lvl +N | lvl -N | lvl N', false
	end
	if op == "add" then
		s:addLevels(amount)
		return "+" .. amount .. " Levels", true
	elseif op == "sub" then
		s:subtractLevels(amount)
		return "-" .. amount .. " Levels", true
	end
	s:setLevel(amount)
	return "Level set to " .. amount, true
end, "set, add, or remove levels.")

Commands.register("satiety", function(args, ctx)
	local s, err = needStats(ctx)
	if not s then
		return err, false
	end
	local amount, op = Commands.parseAmount(args)
	if not amount then
		return 'Usage: satiety +N | satiety -N | satiety N', false
	end
	if op == "add" then
		s:restoreSatiety(amount)
		return "+" .. amount .. " Satiety", true
	elseif op == "sub" then
		s:consumeSatiety(amount)
		return "-" .. amount .. " Satiety", true
	end
	s:setSatiety(amount)
	return "Satiety set to " .. amount, true
end, "set, add, or remove satiety.")

Commands.register("eat", function(_, ctx)
	local s, err = needStats(ctx)
	if not s then
		return err, false
	end
	s:restoreSatiety(s.maxSatiety)
	return "Satiety restored", true
end, "restore satiety to full.")

Commands.addSubcommand("world", "clear")

Commands.register("world", function(args, ctx)
	if args ~= "clear" then
		return 'Usage: world clear.', false
	end
	if ctx.clearProps then
		local n = ctx.clearProps()
		return "Cleared " .. n .. " props", true
	end
	return "No props", true
end, "manipulate world.")

-- Drop sprite names (base file names under Content/Assets/Sprites/Drops/). Registered
-- as sub-commands so `spawn ` tab-completes them. Keep in sync with that folder.
local DROP_NAMES = {
	"Berries", "BrownMushroom", "Carrot", "MediumCrystal",
	"RedMushroom", "SmallCrystal", "Snail", "Turnip",
}
for _, name in ipairs(DROP_NAMES) do
	Commands.addSubcommand("spawn", name)
end

--- Spawn one or more drops at the mouse world position. Args is a space-separated
--- list of drop names (e.g. "Snail Turnip"). Each name resolves to a drop sprite
--- via `ctx.spawnDrop`; the spawn point comes from `ctx.mouseWorld`.
Commands.register("spawn", function(args, ctx)
	if args == "" then
		return 'Usage: spawn <drop> [<drop> ...] (at mouse).', false
	end
	if not ctx.spawnDrop then
		return "No spawn accessor", false
	end
	local wx, wy = ctx.mouseWorld()
	if not wx then
		return "No mouse position", false
	end
	local spawned = {}
	local failed = {}
	for name in args:gmatch("%S+") do
		local ok, err = ctx.spawnDrop(name, wx, wy)
		if ok then
			spawned[#spawned + 1] = name
		else
			failed[#failed + 1] = name .. (err and (" (" .. err .. ")") or "")
		end
	end
	local msg = "Spawned " .. #spawned .. " drop(s): " .. table.concat(spawned, ", ")
	if #failed > 0 then
		msg = msg .. " | unknown: " .. table.concat(failed, ", ")
	end
	return msg, true
end, "spawn drops at the mouse position.")

Commands.register("restart", function(_, ctx)
	if ctx.restart then
		ctx.restart()
	end
	return "Restarting", true
end, "restart the game.")

local PAGE_SIZE = 10

Commands.register("help", function(args)
	local names = Commands.list()
	local totalPages = math.max(1, math.ceil(#names / PAGE_SIZE))
	local page = math.max(1, math.min(totalPages, tonumber(args or 1) or 1))
	-- Each command line: green name + dim description. Footer is a dim label
	-- preceded by a blank line. Returns styled segment-lines and a 10x hide delay.
	local lines = {}
	for i = (page - 1) * PAGE_SIZE + 1, math.min(page * PAGE_SIZE, #names) do
		local name = names[i]
	lines[#lines + 1] = {
		{ name, "name" },
		{ ": " .. (descriptions[name] or ""), "label" },
	}
	end
	lines[#lines + 1] = {}
	lines[#lines + 1] = {
		{ "Page " .. page .. "/" .. totalPages, "value" },
		{ " (help 'N' for more)", "label." },
	}
	return lines, true, 10
end, "list commands (help 2 for next page).")

return Commands
