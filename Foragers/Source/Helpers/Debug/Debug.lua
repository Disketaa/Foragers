local EventEmitter = require("Source.Helpers.Core.EventEmitter")
local data = require("Content.Data.Debug")
local Options = require("Source.Helpers.Systems.Options")
local Snapshot = require("Source.Helpers.Debug.Snapshot")
local Input = require("Source.Helpers.Systems.Input")
local ChatHistory = require("Source.Helpers.Debug.ChatHistory")

local Sprite = require("Source.Sprite.Sprite")

-- Auto-profiler. Patches Sprite.addComponent + global system updates on load so
-- every scope's per-frame CPU cost is measured without any other file importing
-- it. Config lives in `hud.profiler`.
local Profiler = {}

local profConf = data.hud and data.hud.profiler
local collecting = type(profConf) == "table" and profConf.enabled == true

local function clock()
	return love.timer.getTime()
end

local frameCost = {}
local frameCalls = {}
local snapshot = {}
local snapshotTotal = 0

function Profiler.record(label, ms)
	local c = frameCost[label]
	if c then
		frameCost[label] = c + ms
		frameCalls[label] = frameCalls[label] + 1
	else
		frameCost[label] = ms
		frameCalls[label] = 1
	end
end

-- Defined once at load (not a per-call closure) so the wrapper allocates nothing;
-- on failure `...` is the xpcall traceback, rethrown so Section IX's log keeps it.
local function reportTimed(label, t0, ok, ...)
	Profiler.record(label, clock() - t0)
	if not ok then
		error((...), 2)
	end
	return ...
end

local function timed(fn, label)
	return function(...)
		if not collecting then
			return fn(...)
		end
		local t0 = clock()
		return reportTimed(label, t0, xpcall(fn, debug.traceback, ...))
	end
end

local function instrumentMethod(module, method, label)
	local orig = module[method]
	if type(orig) ~= "function" then
		return
	end
	module[method] = timed(orig, label)
end

local origAddComponent = Sprite.addComponent

function Sprite:addComponent(component)
	if collecting and component and not component.__profiled then
		component.__profiled = true
		if type(component.update) == "function" then
			component.update = timed(component.update, (component.type or "?") .. ".update")
		end
		if type(component.draw) == "function" then
			component.draw = timed(component.draw, (component.type or "?") .. ".draw")
		end
	end
	return origAddComponent(self, component)
end

-- Universal auto-instrumentation. Any module exposing a per-frame method name
-- (update*, drawAll, ...) gets wrapped — both modules already loaded and any
-- required later — so a new system file needs no registration here.
local FRAME_METHODS = {
	"update",
	"updateAll",
	"updateBursts",
	"updateDetached",
	"updateAttached",
	"drawAll",
	"drawBursts",
	"drawDetached",
	"drawBurstsBehind",
	"drawDetachedBehind",
	"renderLayer",
	"renderSilhouette",
}
local instrumentedMods = {}

local function shortName(modname)
	return modname:match("([^%.]+)$") or modname
end

local function instrumentModule(modname, module)
	if type(module) ~= "table" or instrumentedMods[modname] then
		return
	end
	instrumentedMods[modname] = true
	local base = shortName(modname)
	for _, m in ipairs(FRAME_METHODS) do
		instrumentMethod(module, m, base .. "." .. m)
	end
end

-- Debug isn't in package.loaded during the sweep (its own file is mid-load), and
-- timing Debug.update/draw would otherwise recurse through Profiler.update. It's
-- wrapped explicitly after definition below instead.

for modname, module in pairs(package.loaded) do
	instrumentModule(modname, module)
end

local origRequire = require
_G.require = function(modname)
	local module = origRequire(modname)
	instrumentModule(modname, module)
	return module
end

local lastFlush = 0

function Profiler.update(dt)
	if not collecting then
		return
	end
	local interval = 1 / (profConf.updateSpeed or 10)
	lastFlush = lastFlush + dt
	if lastFlush < interval then
		return
	end
	lastFlush = 0
	snapshot = {}
	snapshotTotal = 0
	for label, ms in pairs(frameCost) do
		local entry = { name = label, ms = ms, count = frameCalls[label] }
		table.insert(snapshot, entry)
		snapshotTotal = snapshotTotal + ms
	end
	table.sort(snapshot, function(a, b) return a.ms > b.ms end)
	frameCost = {}
	frameCalls = {}
end

function Profiler.enabled()
	return collecting
end

--- Runtime switch for the auto-profiler. Toggling this enables/disables
--- collection without re-wrapping methods: the `timed` wrappers check
--- `collecting` every call and pass through when off, so existing hooks stay.
---@param enabled boolean
function Profiler.setEnabled(enabled)
	collecting = enabled == true
end

function Profiler.entries()
	return snapshot
end

function Profiler.totalMs()
	return snapshotTotal
end

local Debug = {}
local emitter = EventEmitter.new()

local HISTORY_MAX = 60
local history = {}
local historyCount = 0
local historyIndex = 0
local frameCount = 0
local lastSample = 0

-- Chat state. `data.hud.chat.enabled` is the single source of truth for whether
-- the input is open; `chatActive` would duplicate it and drift (Escape/HUD-hide
-- must close it without flipping the persisted toggle).
local chatText = ""
local chatOutputLines = {}
local chatOutputSuccess = false
local chatOutputTimer = 0
local chatBlink = 0

-- Cache key "path@size": the same font file at different sizes is a distinct entry.
local fontCache = {}

---@alias Font love.Font
--- Load a font (optional path via love.filesystem), cached by path+size. On
--- failure (missing/corrupt file) fall back to LÖVE's default font so the HUD
--- never crashes.
---@param path string|nil
---@param size number
---@return Font
local function getFont(path, size)
	local key = (path or "") .. "@" .. size
	local f = fontCache[key]
	if f then
		return f
	end
	local ok = false
	if path then
		ok, f = pcall(love.graphics.newFont, path, size)
	end
	if not ok then
		f = love.graphics.newFont(size)
	end
	fontCache[key] = f
	return f
end

--- Resolve the `hud` group's fonts at a given scale. Shared by the top-left
--- HUD and the bottom-left profiler so both render with the same metrics.
---@param s table `hud` settings
---@param scale number
---@return Font labelFont, Font valueFont, number fontHeight
local function hudFonts(s, scale)
	local size = math.max(4, math.floor((s.size or 8) * scale))
	local fconf = s.font or {}
	local labelFont = getFont(fconf.label, size)
	local valueFont = getFont(fconf.value, size)
	return labelFont, valueFont, math.max(labelFont:getHeight(), valueFont:getHeight())
end

--- Resolve the row offset and gap, preferring the sub-group (`g`) over the base
--- `hud` group. All three draw panels (chat, profiler, HUD) share this fallback.
---@param g table Sub-group settings (e.g. `hud.chat`).
---@param s table Base `hud` settings.
---@param scale number
---@return number offset, number gap
local function spacing(g, s, scale)
	local offset = (g.padding ~= nil and g.padding or s.padding or 4) * scale
	local gap = (g.gap ~= nil and g.gap or s.gap ~= nil and s.gap or offset) * scale
	return offset, gap
end

-- Resolve cached by path: every accessor (settings, enabled, chat*) calls this
-- each frame, and re-walking the dotted path via gmatch every time is wasteful
-- in the draw hot path. Cache the resolved table so the walk happens once.
local resolved = {}

--- Resolve a dotted path into the data (e.g. "hud.fpsGraph"); nil if absent.
--- Typed `any` so accessors that read a known field (e.g. a number or string)
--- can declare their own return type instead of inheriting `table|nil`.
---@param path string
---@return any
local function lookup(path)
	local cached = resolved[path]
	if cached ~= nil then
		return cached
	end
	local t = data --[[@as any]]
	for part in (path .. ""):gmatch("[^.]+") do
		t = t[part]
		if t == nil then
			break
		end
	end
	resolved[path] = t
	return t
end

---@param group string Settings group name (e.g. "collisions", "hud.fpsGraph")
---@return boolean
function Debug.enabled(group)
	local t = lookup(group)
	if type(t) == "boolean" then
		return t
	end
	-- `not not` widens the short-circuit `false` literal to `boolean` (luals
	-- strict subtype check rejects the narrower literal against `@return boolean`).
	return not not (type(t) == "table" and t.enabled == true)
end

--- Group "X" carries an `exclude` list of entity ids to skip. Path is dotted
--- (e.g. "gizmo.collisions") so nested groups resolve like `Debug.enabled`.
---@param group string
---@param value string|nil Entity identifier (sprite.object)
---@return boolean
function Debug.excluded(group, value)
	if value == nil then
		return false
	end
	local t = lookup(group)
	local list = type(t) == "table" and t.exclude
	if not list then
		return false
	end
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

---@param group string
---@return table Settings table for the group (thickness, color, ...).
function Debug.settings(group)
	local t = lookup(group)
	if type(t) ~= "table" then
		t = {}
	end
	return t
end

--- Whether a group's overlay should render. Gates on the `hud` master switch so
--- F1 hides gizmo/profiler/chat by view, not by mutating their flags — leaving
--- each panel's persisted toggle as the true user preference.
---@param group string
---@return boolean
function Debug.showing(group)
	return not not (Debug.enabled("hud") and Debug.enabled(group))
end

---@return boolean Whether the top-level `debug` master switch is on.
function Debug.isEnabled()
	return data.debug == true
end

--- Chat state accessors
function Debug.chatActive()
	return Debug.enabled("hud.chat")
end

function Debug.setChatActive(active)
	local newVal = active == true
	local t = lookup("hud.chat")
	if type(t) == "table" then
		t.enabled = newVal
	end
	Input.setCaptured(newVal)
	if not newVal then
		chatText = ""
		Debug.resetChatHistory()
	else
		chatOutputLines = {}
	end
end

function Debug.chatText()
	return chatText
end

--- Normalize an output message into lines of styled segments. A string splits
--- on newlines into single `"value"` segments; a table is used as-is (each entry
--- is a line: an array of `{ text, style }`, style `"value"` or `"label"`).
---@param text string|table
---@return table lines
local function normalizeOutput(text)
	if type(text) == "table" then
		return text
	end
	local lines = {}
	for line in (text or ""):gmatch("[^\n]+") do
		lines[#lines + 1] = { { line, "value" } }
	end
	return lines
end

function Debug.setChatOutput(text, success, timeoutMult)
	chatOutputLines = normalizeOutput(text)
	chatOutputSuccess = success == true
	if #chatOutputLines > 0 then
		local base = lookup("hud.chat.outputTimeout") or 3
		chatOutputTimer = base * (timeoutMult or 1)
	end
end

---@return string Full output joined by newlines (single-line callers still work).
function Debug.chatOutput()
	local out = {}
	for _, line in ipairs(chatOutputLines) do
		local text = ""
		for _, seg in ipairs(line) do
			text = text .. seg[1]
		end
		out[#out + 1] = text
	end
	return table.concat(out, "\n")
end

function Debug.setChatText(text)
	chatText = Input.sanitize(text or "")
end

---@return number
function Debug.chatRepeatDelay()
	return (lookup("hud.chat.repeatDelay")) --[[@as number]]
end

---@return number
function Debug.chatRepeatInterval()
	return (lookup("hud.chat.repeatInterval")) --[[@as number]]
end

---@return string|nil Path of the one-shot sound played when a command is submitted.
function Debug.chatEnterSound()
	return (lookup("hud.chat.enterSound")) --[[@as string|nil]]
end

-- Command history ------------------------------------------------------------

---@return number Max persisted history entries (data `hud.chat.historyMax`).
function Debug.chatHistoryMax()
	return (lookup("hud.chat.historyMax")) --[[@as number]] or 10
end

---@param text string
function Debug.pushChatHistory(text)
	ChatHistory.push(text, Debug.chatHistoryMax())
end

function Debug.chatHistoryUp()
	local text = ChatHistory.up(chatText)
	if text ~= nil then
		Debug.setChatText(text)
	end
end

function Debug.chatHistoryDown()
	local text = ChatHistory.down()
	if text ~= nil then
		Debug.setChatText(text)
	end
end

function Debug.resetChatHistory()
	ChatHistory.reset()
end

--- Subscribe to runtime flag changes. Callback receives (key, value).
---@param callback function
function Debug.onChange(callback)
	emitter:on("flags", callback)
end

--- Set a flag at runtime and notify subscribers.
---@param key string
---@param value boolean
function Debug.set(key, value)
	data[key] = value == true
	emitter:emit("flags", key, data[key])
	Options.save()
end

--- Set a nested group's `enabled` flag and apply its runtime side effects
--- (profiler collect switch, input capture). Shared by toggle/applyFlags so the
--- side-effect mapping lives in one place. Returns false if the path is absent
--- or not a group table.
---@param path string Dotted group path, e.g. "hud.profiler".
---@param value boolean
---@return boolean
local function setGroupEnabled(path, value)
	local on = value == true
	local t = lookup(path)
	if type(t) ~= "table" then
		return false
	end
	t.enabled = on
	if path == "hud.profiler" then
		Profiler.setEnabled(on)
	end
	if path == "hud.chat" then
		Input.setCaptured(on)
		-- Reopening the chat erases any lingering output (its timer may still be
		-- counting down from a previous command).
		if on then
			chatOutputLines = {}
		end
	end
	return true
end

--- Flip a nested group's `enabled` flag at runtime and notify subscribers.
--- Unlike `Debug.set` (top-level keys only), this walks a dotted path so the
--- `gizmo`, `hud` and `hud.profiler` groups toggle independently. Subscribers
--- re-read the flag on the `flags` emit. The profiler special-cases its
--- internal `collecting` switch, which the data flag alone cannot reach.
---@param path string Dotted group path, e.g. "gizmo" or "hud.profiler".
---@return boolean New enabled state.
function Debug.toggle(path)
	local t = lookup(path)
	if type(t) ~= "table" then
		return false
	end
	local newVal = not (t.enabled == true)
	setGroupEnabled(path, newVal)
	emitter:emit("flags", path, newVal)
	Options.save()
	return newVal
end

--- Runtime-toggleable flag paths (the ones Debug.set/Debug.toggle mutate and
--- that Options persists). Top-level `debug` is the master switch; the rest are
--- nested group `enabled` flags.
local TOGGLE_PATHS = { "debug", "gizmo", "hud", "hud.profiler" }

---@return table path → boolean current value for each runtime-toggleable flag.
function Debug.serializeFlags()
	local out = {}
	for _, path in ipairs(TOGGLE_PATHS) do
		out[path] = Debug.enabled(path)
	end
	return out
end

--- Apply persisted flag values (from Options.txt) onto the data table.
---@param flags table path → boolean.
function Debug.applyFlags(flags)
	for path, val in pairs(flags or {}) do
		if path == "debug" then
			data.debug = val == true
		else
			setGroupEnabled(path, val)
		end
	end
end

--- Sample FPS for the HUD. Gated by the `hud.fps`/`hud.fpsGraph` items.
--- `updateSpeed` (Hz) controls how often a sample is taken.
---@param dt number
function Debug.update(dt)
	-- Auto-profiler flushes its own buckets each frame, independent of the HUD.
	if Profiler.enabled() then
		Profiler.update(dt)
	end
	-- Debug.update is the last call in love.update, so this marks its end.
	Snapshot.setUpdateEnd()

	local s = Debug.settings("hud")
	local wantFps = Debug.enabled("hud") and (s.fps or Debug.enabled("hud.fpsGraph"))
	local now = love.timer.getTime()
	local interval = 1 / (s.updateSpeed or 2)
	frameCount = frameCount + 1
	if now - lastSample >= interval then
		local fps = frameCount / (now - lastSample)
		frameCount = 0
		lastSample = now
		if wantFps then
			historyIndex = historyIndex % HISTORY_MAX + 1
			history[historyIndex] = fps
			if historyCount < HISTORY_MAX then
				historyCount = historyCount + 1
			end
		end
		-- Sample the snapshot even when the HUD readout is off, so drops are
		-- captured as long as the profiler is collecting.
		Snapshot.update(Profiler.enabled(), fps, Profiler.entries(), Profiler.totalMs())
	end

	-- Auto-hide chat output after its timeout.
	if chatOutputTimer > 0 then
		chatOutputTimer = chatOutputTimer - dt
		if chatOutputTimer <= 0 then
			chatOutputLines = {}
			chatOutputTimer = 0
		end
	end
end

--- Render one text segment in a single color/font.
---@param text string
---@param x number
---@param y number
---@param color table RGBA
---@param f Font
local function renderText(text, x, y, color, f)
	love.graphics.setColor(color[1], color[2], color[3], color[4])
	love.graphics.setFont(f)
	love.graphics.print(text, x, y)
end

--- Bottom-left table of per-scope frame cost (name, ms, % of measured total).
--- Reuses the `hud` styling (size, fonts, colors, padding) and the same row-box
--- rendering as the top-left HUD. `profiler` group adds only `enabled`/`limit`.
---@param scale number
local function drawProfiler(scale)
	if not Profiler.enabled() or not Debug.enabled("hud") then
		return
	end
	local entries = Profiler.entries()
	local total = Profiler.totalMs()
	if #entries == 0 or total <= 0 then
		return
	end

	local s = Debug.settings("hud")
	local p = Debug.settings("hud.profiler")
	local limit = math.max(1, math.floor(p.limit or 14))

	local size = math.max(4, math.floor((s.size or 8) * scale))
	local labelFont, valueFont, fontHeight = hudFonts(s, scale)
	local offset, rowGap = spacing(p, s, scale)
	local colGap = math.max(2, size) * scale
	local labelColor = s.labelColor or { 0.6, 0.6, 0.6, 1 }
	local valueColor = s.color or { 1, 1, 1, 1 }
	local bg = p.backgroundColor or s.backgroundColor

	local count = math.min(limit, #entries)

	local nameMax = math.max(3, math.floor(p.nameMaxChars or 18))
	local digits = math.max(0, math.floor(p.digits or 4))
	for i = 1, count do
		local e = entries[i]
		-- Truncate into a local display name; never mutate the shared entry
		-- name so the snapshot trace reads the full scope names.
		local disp = e.name
		if #disp > nameMax then
			disp = string.sub(disp, 1, nameMax - 1) .. "..."
		end
		local dot = disp:find("%.")
		if dot then
			e.module = string.sub(disp, 1, dot - 1)
			e.method = string.sub(disp, dot)
		else
			e.module = disp
			e.method = nil
		end
	end

	-- Time column keeps a fixed char width so a value crossing a digit boundary
	-- (9→10µs) never resizes it and shifts the `%` column. `%` is the last column
	-- so it can size to its content without causing any shift.
	local valueMaxChars = p.valueMaxChars and math.max(4, math.floor(p.valueMaxChars)) or 0
	local timeChars = math.max(4, digits + 6)
	if valueMaxChars > 0 then
		timeChars = math.min(timeChars, valueMaxChars)
	end

	local function fmtMs(ms)
		local fmt = "%." .. digits .. "f"
		local val, unit
		if ms < 1 then
			val, unit = ms * 1000, "µs"
		else
			val, unit = ms, "ms"
		end
		local num = string.format("%" .. (timeChars - 2) .. "s", string.format(fmt, val))
		return num, unit
	end
	local function fmtPct(ms)
		return string.format("%.1f", (ms / total) * 100)
	end

	local nameCol = 0
	local pctCol = 0
	for i = 1, count do
		local e = entries[i]
		nameCol = math.max(nameCol, labelFont:getWidth(e.module .. (e.method or "")))
		pctCol = math.max(pctCol, valueFont:getWidth(fmtPct(e.ms) .. "%"))
	end
	nameCol = math.max(nameCol, labelFont:getWidth("Scope"))
	pctCol = math.max(pctCol, valueFont:getWidth("%"))
	local msCol = valueFont:getWidth(string.rep("9", timeChars))

	local rowW = nameCol + colGap + msCol + colGap + pctCol
	local totalHeight = fontHeight + count * (fontHeight + rowGap)
	local topY = (love.graphics.getHeight() - totalHeight) / 2

	local x1 = offset
	local x2 = offset + nameCol + colGap
	local x3 = x2 + msCol + colGap

	local y = topY
	-- Each column is a list of { text, color, font } segments so a cell can be
	-- split (e.g. number in valueColor, unit in labelColor).
	local function drawRow(segs)
		if bg then
			love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
			love.graphics.rectangle("fill", offset, y, rowW, fontHeight)
		end
		local xs = { x1, x2, x3 }
		for i = 1, 3 do
			local segs3 = segs[i]
			local w = 0
			for _, seg in ipairs(segs3) do
				w = w + seg[3]:getWidth(seg[1])
			end
			local x = xs[i]
			if i == 3 then
				x = x3 + pctCol - w
			end
			for _, seg in ipairs(segs3) do
				renderText(seg[1], x, y, seg[2], seg[3])
				x = x + seg[3]:getWidth(seg[1])
			end
		end
		y = y + fontHeight + rowGap
	end

	local labelSeg = { "Scope", labelColor, labelFont }
	local header = {
		{ labelSeg },
		{ { string.format("%" .. timeChars .. "s", "Time"), labelColor, valueFont } },
		{ { "%", labelColor, valueFont } },
	}
	drawRow(header)
	for i = 1, count do
		local e = entries[i]
		local num, unit = fmtMs(e.ms)
		local nameSegs = { { e.module, valueColor, labelFont } }
		if e.method then
			table.insert(nameSegs, { e.method, labelColor, labelFont })
		end
		local cells = {
			nameSegs,
			{ { num, valueColor, valueFont }, { unit, labelColor, valueFont } },
			{ { fmtPct(e.ms), valueColor, valueFont }, { "%", labelColor, valueFont } },
		}
		drawRow(cells)
	end
end

---@param scale number
function Debug.drawChat(scale)
	scale = scale or 1
	local s = Debug.settings("hud")
	local cs = Debug.settings("hud.chat")
	local hudOn = Debug.enabled("hud")
	if not hudOn then
		return
	end

	local inputActive = Debug.enabled("hud.chat")
	local hasOutput = #chatOutputLines > 0
	if not inputActive and not hasOutput then
		return
	end

	local labelFont, _, fontHeight = hudFonts(s, scale)
	local offset, gap = spacing(cs, s, scale)
	local valueColor = s.color or { 1, 1, 1, 1 }
	local goodColor = s.goodColor or { 0, 1, 0, 1 }
	local badColor = s.badColor or { 1, 0, 0, 1 }
	local bg = cs.backgroundColor or s.backgroundColor
	local labelColor = s.labelColor or { 0.6, 0.6, 0.6, 1 }

	local prompt = ""
	local textW = 0
	if inputActive then
		-- The font may reject codepoints it can't decode (e.g. scripts outside its
		-- charset); guard measurement/draw so a bad char can't crash the frame.
		local ok, w = pcall(labelFont.getWidth, labelFont, prompt .. chatText)
		if ok then
			textW = w
		end
	end
	local cursorW = labelFont:getWidth("|")
	local rowH = fontHeight + gap
	local rowW = gap + textW + cursorW + gap

	-- Output renders as stacked rows growing upward from the input position,
	-- capped so a long help listing never fills the screen. Line 1 is the
	-- bottom row; each subsequent line sits one row above. Each line is a list
	-- of styled segments: "value" uses the success/error color, "label" the dim
	-- label color (e.g. a help command name vs its description).
	if hasOutput and not inputActive then
		local outColor = chatOutputSuccess and goodColor or badColor
		local maxLines = 10
		local lines = chatOutputLines
		if #lines > maxLines then
			local trimmed = {}
			for i = #lines - maxLines + 1, #lines do
				trimmed[#trimmed + 1] = lines[i]
			end
			lines = trimmed
		end
		local outW = 0
		for _, line in ipairs(lines) do
			local w = gap * 2
			for _, seg in ipairs(line) do
				w = w + labelFont:getWidth(seg[1])
			end
			if w > outW then
				outW = w
			end
		end
		local baseY = love.graphics.getHeight() - offset - rowH * #lines
		if bg then
			love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
			love.graphics.rectangle("fill", offset, baseY, outW, rowH * #lines)
		end
		love.graphics.setFont(labelFont)
		for i, line in ipairs(lines) do
			local ly = love.graphics.getHeight() - offset - rowH * (#lines - i + 1)
			local x = offset + gap
			for _, seg in ipairs(line) do
				local c = seg[2] == "name" and valueColor or (seg[2] == "label" and labelColor or outColor)
				love.graphics.setColor(c[1], c[2], c[3], c[4])
				love.graphics.print(seg[1], x, ly + gap / 2)
				x = x + labelFont:getWidth(seg[1])
			end
		end
	end

	if inputActive then
		local y = love.graphics.getHeight() - offset - rowH

		if bg then
			love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
			love.graphics.rectangle("fill", offset, y, rowW, rowH)
		end

		love.graphics.setColor(valueColor[1], valueColor[2], valueColor[3], valueColor[4])
		love.graphics.setFont(labelFont)
		pcall(love.graphics.print, prompt .. chatText, offset + gap, y + gap / 2)

		-- I-beam blinks at ~2Hz when the field is focused.
		chatBlink = (chatBlink + 1) % 60
		if chatBlink < 30 then
			love.graphics.setColor(labelColor[1], labelColor[2], labelColor[3], labelColor[4])
			local cursorX = offset + gap + textW
			love.graphics.line(cursorX, y + gap / 2, cursorX, y + rowH - gap / 2)
		end
	end

	love.graphics.setColor(1, 1, 1, 1)
end

--- Draw the top-left HUD readout (FPS, FPS graph, object count) at native
--- resolution. Gated by the `hud` group. `scale` is the window upscale factor
--- (canvas.scale) so the text and graph stay proportional on any window size.
---@param objectCount number
---@param scale number
function Debug.draw(objectCount, scale)
	scale = scale or 1
	-- Sample render stats here so the snapshot reports draw calls from the
	-- real draw pass (getStats resets each frame, so update() sees zeros).
	Snapshot.captureDraw()
	Snapshot.setDrawEnd()
	-- Auto-profiler draws its own table first, independent of the HUD.
	drawProfiler(scale)
	Debug.drawChat(scale)

	local s = Debug.settings("hud")
	local gs = Debug.settings("hud.fpsGraph")
	local hasFps = s.fps
	local hasGraph = Debug.enabled("hud.fpsGraph")
	local hasCount = s.objectCount
	local toggles = type(s.toggles) == "table" and s.toggles or {}
	local hasToggles = #toggles > 0
	if not Debug.enabled("hud") or not (hasFps or hasGraph or hasCount or hasToggles) then
		return
	end

	local size = math.max(4, math.floor((s.size or 8) * scale))
	local labelFont, valueFont, fontHeight = hudFonts(s, scale)

	-- `padding` is a single group offset: the whole readout shifts right/down
	-- by it. `gap` alone spaces the rows inside the block.
	local offset, gap = spacing(s, s, scale)
	local labelColor = s.labelColor or { 0.6, 0.6, 0.6, 1 }
	local valueColor = s.color or { 1, 1, 1, 1 }
	local goodColor = s.goodColor or { 0, 1, 0, 1 }
	local badColor = s.badColor or { 1, 0, 0, 1 }
	-- Graph height clamped to the row so a tall graph never overflows its box.
	local gh = math.min((gs.height or (size * 2)) * scale, fontHeight)
	local graphShown = hasGraph and historyCount > 1

	-- Layout every row (FPS, object count, separator, toggles) up front so the
	-- background boxes and text share one pass. Each row hugs its own content.
	local rows = {}
	local graphX = 0
	local y = offset
	if hasFps then
		local gapi = (gs.gap or 6) * scale
		-- Reserve a fixed value width (maxFps digits) so the graph doesn't shift
		-- when the live reading goes 2→3 digits. Value text right-aligns into it.
		local digits = #tostring(math.floor(Options.maxFps or 999))
		local labelW = labelFont:getWidth("FPS ")
		local fixedValW = valueFont:getWidth(string.rep("9", digits))
		local textW = labelW + fixedValW
		local w = textW + gapi
		if graphShown then
			graphX = textW + gapi
			w = w + (gs.width or 60) * scale
		end
		table.insert(rows, { y = y, w = w, kind = "fps", fixedValW = fixedValW, labelW = labelW })
		y = y + fontHeight + gap
	end
	if hasCount then
		local w = labelFont:getWidth("Objects ") + valueFont:getWidth(tostring(objectCount))
		table.insert(rows, { y = y, w = w, kind = "count" })
		y = y + fontHeight + gap
	end
	if hasToggles then
		-- One empty separator row between the readout and the toggle statuses.
		y = y + fontHeight + gap
		for _, t in ipairs(toggles) do
			local on = Debug.enabled(t.path)
			-- Key prefix read from Options.lua keybinds so the readout mirrors
			-- the bindings without duplicating the mapping.
			local keyText = ""
			if t.key then
				local kb = Options.keybinds[t.key]
				local k = kb and kb.keyboard and kb.keyboard[1]
				if k then
					keyText = string.upper(k)
				end
			end
			local dimText = (keyText ~= "" and " | " or "") .. (t.label or t.path) .. " "
			local status = on and "Enabled" or "Disabled"
			local statusColor = on and goodColor or badColor
			local w = labelFont:getWidth(keyText) + labelFont:getWidth(dimText) + valueFont:getWidth(status)
			local row = {
				y = y,
				w = w,
				kind = "toggle",
				keyText = keyText,
				dimText = dimText,
				status = status,
				statusColor = statusColor,
			}
			table.insert(rows, row)
			y = y + fontHeight + gap
		end
	end

	if s.backgroundColor then
		local bg = s.backgroundColor
		love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
		for _, r in ipairs(rows) do
			love.graphics.rectangle("fill", offset, r.y, r.w, fontHeight)
		end
	end

	for _, r in ipairs(rows) do
		if r.kind == "fps" then
			local label = "FPS "
			local val = tostring(math.floor(history[historyIndex] or 0))
			renderText(label, offset, r.y, labelColor, labelFont)
			renderText(val, offset + r.labelW + (r.fixedValW - valueFont:getWidth(val)), r.y, valueColor, valueFont)

			if graphShown then
			local target = Options.maxFps or 60
			-- Color against the real ceiling: user maxFps capped at what the display
			-- can actually sustain, so a 144hz panel at ~144 isn't painted red against
			-- an unreachable 180 target. Options.maxFps stays the static user setting
			-- (bar scale + label); only the threshold/cap-marker use the ceiling.
			-- getDisplayRefreshRate is absent on some LÖVE builds, so fall back to the
			-- highest measured FPS (the display cap appears as the peak sample when
			-- maxFps is above it).
			local refresh = 0
			local getRate = love.window["getDisplayRefreshRate"]
			if getRate then
				refresh = getRate() or 0
			end
			if refresh <= 0 then
				local peak = 0
				for i = 1, historyCount do
					local idx = (historyIndex - historyCount + i - 1) % HISTORY_MAX + 1
					if (history[idx] or 0) > peak then peak = history[idx] end
				end
				refresh = peak
			end
			local effectiveMax = (refresh > 0 and math.min(target, refresh) or target)
			-- `tolerance` is a fraction of the ceiling (0.5 = 50%): at 60fps a
			-- segment stays green down to 30fps before it goes red.
			local tolerance = gs.tolerance or 0
			local threshold = effectiveMax * (1 - tolerance)
				local gy = r.y + (fontHeight - gh) / 2
				local step = (gs.width or 60) * scale / (historyCount - 1)
				local gx = offset + graphX
				-- Walk the ring oldest→newest (history[historyIndex] is the newest).
				local first = (historyIndex - historyCount) % HISTORY_MAX + 1
				local function sampleAt(k)
					local idx = first + k
					if idx > HISTORY_MAX then
						idx = idx - HISTORY_MAX
					end
					return history[idx]
				end
				-- Per-segment color: green while stable, red at the samples that dropped.
			love.graphics.setLineWidth(math.max(1, (gs.thickness or 1) * scale))
			-- Dim marker at the display refresh cap when it's below the user's
			-- maxFps target, so the graph shows both the configured line and the
			-- real ceiling it can't exceed.
			if effectiveMax < target then
				local capY = gy + gh - (effectiveMax / target) * gh
				love.graphics.setColor(labelColor[1], labelColor[2], labelColor[3], 0.5)
				love.graphics.line(gx, capY, gx + (gs.width or 60) * scale, capY)
			end
			for k = 1, historyCount - 1 do
					local v1, v2 = sampleAt(k - 1), sampleAt(k)
					local c = (v2 or 0) >= threshold and goodColor or badColor
					love.graphics.setColor(c[1], c[2], c[3], c[4])
					local h1 = math.min(gh, (v1 / target) * gh)
					local h2 = math.min(gh, (v2 / target) * gh)
					love.graphics.line(gx + (k - 1) * step, gy + gh - h1, gx + k * step, gy + gh - h2)
				end
			end
		elseif r.kind == "count" then
			local label = "Objects "
			renderText(label, offset, r.y, labelColor, labelFont)
			renderText(tostring(objectCount), offset + labelFont:getWidth(label), r.y, valueColor, valueFont)
		elseif r.kind == "toggle" then
			local x = offset
			if r.keyText ~= "" then
				renderText(r.keyText, x, r.y, valueColor, labelFont)
				x = x + labelFont:getWidth(r.keyText)
			end
			renderText(r.dimText, x, r.y, labelColor, labelFont)
			x = x + labelFont:getWidth(r.dimText)
			renderText(r.status, x, r.y, r.statusColor, valueFont)
		end
	end

	-- Restore neutral color. setColor persists across frames, so leaving it
	-- green/red here tints next frame's world canvas (terrainBatch draws with
	-- whatever color is current).
	love.graphics.setColor(1, 1, 1, 1)
end

-- Time Debug's own per-frame work so its cost shows up in the profiler. Safe
-- here: Debug is fully defined and `timed` only records, never re-enters Debug.
if collecting then
	instrumentMethod(Debug, "update", "Debug.update")
	instrumentMethod(Debug, "draw", "Debug.draw")
end

-- Re-apply persisted toggles from Options.txt. Options loads before Debug, so
-- its collected overrides are ready by the time this module finishes loading.
Debug.applyFlags(Options._debug)

-- Load persisted command history from chat_history.txt.
ChatHistory.load(Debug.chatHistoryMax())

return Debug
