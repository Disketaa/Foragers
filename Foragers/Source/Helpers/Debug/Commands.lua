--- Debug console command registry. Handlers take `(args, ctx)` where `ctx` is a
--- game-state accessor table injected by Main.lua, keeping this module decoupled
--- from the game. A handler returns `(message, success)`; success false renders
--- the message red. Main.lua routes results to `Debug.setChatOutput(message, success)`.
local Commands = {}

local Binds = require("Source.Helpers.Debug.Binds")
local GameState = require("Source.Helpers.Systems.GameState")
local I18n = require("Source.Helpers.Core.I18n")
local Options = require("Source.Helpers.Systems.Options")

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
	-- Register every command as a sub-command of `bind`/`unbind` so their
	-- command argument tab-completes; kept in sync automatically as commands
	-- are added (no manual list to maintain).
	Commands.addSubcommand("bind", name)
	Commands.addSubcommand("unbind", name)
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
		-- Completing a sub-command of `cmd`. Match case-insensitively so e.g.
		-- "medi" completes to "MediumCrystal"; the returned candidate keeps its
		-- original casing.
		local restLower = rest:lower()
		for _, sub in ipairs(subcommands[cmd] or {}) do
			if sub:lower():sub(1, #rest) == restLower then
				list[#list + 1] = sub
			end
		end
		return cmd .. " ", list
	end
	-- Completing the command name. Match case-insensitively; candidates keep casing.
	local cmdLower = cmd:lower()
	for _, name in ipairs(Commands.list()) do
		if name:lower():sub(1, #cmd) == cmdLower then
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

--- Split a command line into tokens, honoring "double-quoted" spans so a
--- command containing spaces (e.g. `world clear`) stays one token. Lets bind
--- separate the trailing key from a multi-word command whether or not the
--- command is quoted: `bind world clear a` and `bind "world clear" a` both
--- yield { "world clear", "a" }.
---@param s string
---@return table tokens
function Commands.tokenizeArgs(s)
	local tokens = {}
	local i = 1
	local n = #s
	while i <= n do
		while i <= n and s:sub(i, i):match("%s") do i = i + 1 end
		if i > n then break end
		if s:sub(i, i) == '"' then
			i = i + 1
			local start = i
			while i <= n and s:sub(i, i) ~= '"' do i = i + 1 end
			tokens[#tokens + 1] = s:sub(start, i - 1)
			i = i + 1
		else
			local start = i
			while i <= n and not s:sub(i, i):match("%s") do i = i + 1 end
			tokens[#tokens + 1] = s:sub(start, i - 1)
		end
	end
	return tokens
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

local function refreshWeaponUI(wlvl)
	local Tiers = require("Source.Helpers.Systems.Tiers")
	local wt = GameState.weaponLevelText
	local we = GameState.weaponEmblem
	local wtw = GameState.weaponTween
	local wpalette = GameState.weaponTier
	if wt then
		wt:setText(tostring(wlvl))
		wt:setColor({ Tiers.tierColor(wlvl) })
	end
	if we then
		local emblemTier = Tiers.tierForLevel(wlvl)
		we:setFrame(emblemTier)
	end
	if wtw then
		wtw:triggerTag("chosen")
	end
	if wpalette then
		wpalette:setLevel(wlvl)
	end
	local heldWeapon = GameState.weaponSprite
	if heldWeapon then
		local heldTier = heldWeapon:findComponent("tier")
		if heldTier then
			heldTier:setLevel(wlvl)
		end
	end
end

--- Dynamically discover weapon names from Content/Assets/Sprites/Tools/*.lua
--- that have a `weapon` field set.
local _weaponNames = nil
local function getWeaponNames()
	if _weaponNames then
		return _weaponNames
	end
	_weaponNames = {}
	local toolsPath = "Content/Assets/Sprites/Tools"
	local items = love and love.filesystem and love.filesystem.getDirectoryItems(toolsPath)
	if not items then
		return _weaponNames
	end
	for _, item in ipairs(items) do
		if item:match("%.lua$") then
			local modulePath = "Content/Assets/Sprites/Tools/" .. item:gsub("%.lua$", "")
			local ok, data = pcall(require, modulePath)
			if ok and data and data.weapon then
				_weaponNames[data.weapon] = true
			end
		end
	end
	return _weaponNames
end

-- Register weapon names as subcommands for tab-completion
for name in pairs(getWeaponNames()) do
	Commands.addSubcommand("lvl", name)
end

Commands.register("lvl", function(args, ctx)
	-- Handle weapon level: lvl <weapon> N
	local firstArg = args:match("^(%S+)")
	local weaponGroups = getWeaponNames()
	if firstArg and weaponGroups[firstArg] then
		local weaponName = firstArg
		local rest = args:match("^%S+%s+(.*)$") or ""
		if rest == "" then
			local currentLevel = GameState.cardGroupCounts[weaponName] or 0
			return weaponName .. " level: " .. currentLevel, true
		end
		local amount, op = Commands.parseAmount(rest)
		if not amount then
			return 'Usage: lvl pickaxe | lvl pickaxe +N | lvl pickaxe N', false
		end
		local currentLevel = GameState.cardGroupCounts[weaponName] or 0
		local newLevel
		if op == "add" then
			newLevel = currentLevel + amount
		elseif op == "sub" then
			newLevel = math.max(0, currentLevel - amount)
		else
			newLevel = amount
		end
		GameState.cardGroupCounts[weaponName] = newLevel
		refreshWeaponUI(newLevel)
		local delta = newLevel - currentLevel
		if delta > 0 then
			return weaponName .. " level: " .. currentLevel .. " → " .. newLevel, true
		elseif delta < 0 then
			return weaponName .. " level: " .. currentLevel .. " → " .. newLevel, true
		end
		return weaponName .. " level unchanged: " .. newLevel, true
	end

	-- Player level (original behavior)
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
		return 'Usage: lvl | lvl +N | lvl -N | lvl N | lvl pickaxe N', false
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
end, "player lvl or lvl <weapon> N.")

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
	s:restoreSatiety(s:getMaxSatiety())
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

Commands.register("seed", function(_, ctx)
	local seed = ctx.seed and ctx.seed()
	if not seed then
		return "No seed", false
	end
	return "Seed: " .. seed, true
end, "print the current world seed.")

Commands.register("time", function(args, ctx)
	local dc = ctx.dayCycle
	if not dc then
		return "No day/night system", false
	end
	if args == "" then
		return string.format("Time: %.2f", dc.time), true
	end
	local h = tonumber(args)
	if not h then
		return "Usage: time | time <0-24>", false
	end
	dc.setTime(h % 24)
	return "Time set to " .. string.format("%.2f", dc.time), true
end, "show or set the day/night time (0-24).")

Commands.register("bind", function(args, ctx)
	local tokens = Commands.tokenizeArgs(args)
	if #tokens < 2 then
		-- No command+key given: list current binds as styled lines.
		local all = Binds.all()
		if #all == 0 then
			return "No bindings. Usage: bind <command> <key>.", true
		end
		local lines = {}
		for _, b in ipairs(all) do
			lines[#lines + 1] = {
				{ b.key .. ": ", "name" },
				{ b.command, "label" },
			}
		end
		return lines, true, 10
	end
	local key = tokens[#tokens]
	local command = table.concat(tokens, " ", 1, #tokens - 1)
	if key == "" or command == "" then
		return "Usage: bind <command> <key>.", false
	end
	if key:find("%s") then
		return "Key cannot contain spaces.", false
	end
	-- Warn on a command with no registered handler so a typo fails now, not
	-- silently at keypress time.
	if not handlers[tokens[1]] then
		return "Unknown command: '" .. tokens[1] .. "'.", false
	end
	-- Reject core keys (restart/fullscreen/debug/chat toggles) so a bind can
	-- never shadow the controls needed to open the console and unbind it.
	if ctx and ctx.reservedKey and ctx.reservedKey(key) then
		return "Key '" .. key .. "' is reserved (core binding); cannot bind.", false
	end
	Binds.set(key, command)
	return "Bound '" .. command .. "' → " .. key, true
end, "bind a command to a key (bind <cmd> <key>).")

Commands.register("unbind", function(args)
	local tokens = Commands.tokenizeArgs(args)
	local key = tokens[1]
	if not key or key == "" then
		return "Usage: unbind <key> | unbind *", false
	end
	if key == "*" then
		Binds.clear()
		return "Cleared all bindings.", true
	end
	if not Binds.get(key) then
		return "No binding for " .. key, false
	end
	Binds.remove(key)
	return "Unbound " .. key, true
end, "remove a key binding (unbind <key>; unbind * clears all).")

-- Keep PAGE_SIZE + 2 (blank + footer line) <= Debug.lua's maxLines cap (10),
-- else the renderer trims the first commands and pagination never triggers.
local PAGE_SIZE = 8

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

-- Discover language names from Content/Data/I18n/*.lua so `language ` tab-completes
-- them the same way `lvl ` tab-completes weapon names.
local _languageNames = nil
local function getLanguageNames()
	if _languageNames then
		return _languageNames
	end
	_languageNames = {}
	local i18nPath = "Content/Data/I18n"
	local items = love and love.filesystem and love.filesystem.getDirectoryItems(i18nPath)
	if items then
		for _, item in ipairs(items) do
			if item:match("%.lua$") then
				local name = item:gsub("%.lua$", "")
				_languageNames[name] = true
			end
		end
	end
	return _languageNames
end

for name in pairs(getLanguageNames()) do
	Commands.addSubcommand("language", name)
end

Commands.register("language", function(args, _)
	local lang = Commands.trim(args)
	if lang == "" then
		local current = I18n.getLanguage()
		local names = {}
		for name in pairs(getLanguageNames()) do
			names[#names + 1] = name
		end
		table.sort(names)
		return "Current: " .. current .. " | Available: " .. table.concat(names, ", "), true
	end

	-- Case-insensitive match against discovered language file names.
	local matched = nil
	for name in pairs(getLanguageNames()) do
		if name:lower() == lang:lower() then
			matched = name
			break
		end
	end

	if not matched then
		local names = {}
		for name in pairs(getLanguageNames()) do
			names[#names + 1] = name
		end
		table.sort(names)
		return "Unknown language: '" .. lang .. "'. Available: " .. table.concat(names, ", "), false
	end

	I18n.setLanguage(matched)
	Options.language = matched
	Options.save()
	return "Language set to " .. matched, true
end, "change game language without restart (language <name>).")

return Commands