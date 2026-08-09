--- Debug console command registry. Handlers take `(args, ctx)` where `ctx` is a
--- game-state accessor table injected by Main.lua, keeping this module decoupled
--- from the game. A handler returns `(message, success)`; success false renders
--- the message red. Main.lua routes results to `Debug.setChatOutput(message, success)`.
local Commands = {}

local handlers = {}

--- Register a command handler.
---@param name string Invoked name (e.g. "xp"), no leading slash.
---@param fn function|nil Handler: (args: string, ctx: table) -> (message: string, success: boolean)
function Commands.register(name, fn)
	handlers[name] = fn
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
---@return string message
---@return boolean success
function Commands.execute(text, ctx)
	local name, args = text:match("^%s*(%S+)%s*(.*)$")
	local fn = handlers[name]
	if not fn then
		return 'Unknown command: "' .. text .. '"', false
	end
	local ok, message = pcall(fn, args or "", ctx)
	if not ok then
		return "Command error: " .. tostring(message), false
	end
	return message, true
end

-- Built-in commands; each uses `ctx` accessors so this file never touches game
-- modules directly.
local function ctxOf(ctx)
	if type(ctx.stats) == "function" then
		return ctx.stats()
	end
	return nil
end

local function needStats(ctx)
	local s = ctxOf(ctx)
	if not s then
		return nil, false, "No player"
	end
	return s, true
end

Commands.register("xp", function(args, ctx)
	local s, ok = needStats(ctx)
	if not ok then
		return s, false
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
end)

Commands.register("lvl", function(args, ctx)
	local s, ok = needStats(ctx)
	if not ok then
		return s, false
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
end)

Commands.register("eat", function(_, ctx)
	local s, ok = needStats(ctx)
	if not ok then
		return s, false
	end
	s:restoreSatiety(s.maxSatiety)
	return "Satiety restored", true
end)

Commands.register("world", function(args, ctx)
	if args ~= "clear" then
		return 'Usage: world clear', false
	end
	if ctx.clearProps then
		local n = ctx.clearProps()
		return "Cleared " .. n .. " props", true
	end
	return "No props", true
end)

Commands.register("restart", function(_, ctx)
	if ctx.restart then
		ctx.restart()
	end
	return "Restarting", true
end)

Commands.register("death", function(_, ctx)
	if ctx.triggerDeath then
		ctx.triggerDeath()
	end
	return "Death", true
end)

return Commands
