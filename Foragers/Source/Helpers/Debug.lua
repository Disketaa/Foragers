local EventEmitter = require("Source.Helpers.EventEmitter")
local data = require("Content.Data.Debug")

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

local function timed(fn, label)
	return function(...)
		if not collecting then
			return fn(...)
		end
		local t0 = clock()
		local results = { xpcall(fn, debug.traceback, ...) }
		Profiler.record(label, clock() - t0)
		if not results[1] then
			error(results[2], 2)
		end
		return unpack(results, 2)
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
local groupBy = profConf and profConf.groupBy or "type"

local function scopeKey(sprite, compType, phase)
	if groupBy == "object.type" then
		return (sprite.object or "?") .. "." .. (compType or "?") .. "." .. phase
	elseif groupBy == "object" then
		return (sprite.object or compType or "?") .. "." .. phase
	end
	return (compType or "?") .. "." .. phase
end

function Sprite:addComponent(component)
	if collecting and component and not component.__profiled then
		component.__profiled = true
		if type(component.update) == "function" then
			local label = scopeKey(self, component.type, "update")
			component.update = timed(component.update, label)
		end
		if type(component.draw) == "function" then
			local label = scopeKey(self, component.type, "draw")
			component.draw = timed(component.draw, label)
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

-- Don't wrap Debug itself (its update/draw drive the profiler).
instrumentedMods["Source.Helpers.Debug"] = true

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
	table.sort(snapshot, function(a, b)
		return a.ms > b.ms
	end)
	frameCost = {}
	frameCalls = {}
end

function Profiler.enabled()
	return collecting
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

-- Cache key "path@size": the same font file at different sizes is a distinct entry.
local fontCache = {}

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

local function masterOn()
	return data.debug == true
end

--- Walk a dotted path into the data (e.g. "hud.fpsGraph"); nil if absent.
---@param path string
---@return table|nil
local function lookup(path)
	local t = data
	for part in (path .. ""):gmatch("[^.]+") do
		t = t[part]
		if t == nil then
			return nil
		end
	end
	return t
end

---@param group string Settings group name (e.g. "collisions", "hud.fpsGraph")
---@return boolean
function Debug.enabled(group)
	local t = lookup(group)
	local enabled = masterOn() and type(t) == "table" and t.enabled == true
	return enabled == true
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

function Debug.isEnabled()
	return masterOn()
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
end

--- Sample FPS for the HUD. Gated by the `hud.fps`/`hud.fpsGraph` items.
--- `updateSpeed` (Hz) controls how often a sample is taken.
---@param dt number
function Debug.update(dt)
	-- Auto-profiler flushes its own buckets each frame, independent of the HUD.
	Profiler.update(dt)

	local s = Debug.settings("hud")
	if not masterOn() or not Debug.enabled("hud") or not (s.fps or Debug.enabled("hud.fpsGraph")) then
		return
	end
	frameCount = frameCount + 1
	local now = love.timer.getTime()
	local interval = 1 / (s.updateSpeed or 2)
	if now - lastSample >= interval then
		local fps = frameCount / (now - lastSample)
		frameCount = 0
		lastSample = now
		historyIndex = historyIndex % HISTORY_MAX + 1
		history[historyIndex] = fps
		if historyCount < HISTORY_MAX then
			historyCount = historyCount + 1
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
	if not Profiler.enabled() then
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
	local fconf = s.font or {}
	local labelFont = getFont(fconf.label, size)
	local valueFont = getFont(fconf.value, size)
	local fontHeight = math.max(labelFont:getHeight(), valueFont:getHeight())
	local rowH = fontHeight
	local offset = (p.padding ~= nil and p.padding or s.padding or 4) * scale
	local rowGap = (p.gap ~= nil and p.gap or s.gap ~= nil and s.gap or offset) * scale
	local colGap = math.max(2, size) * scale
	local labelColor = s.labelColor or { 0.6, 0.6, 0.6, 1 }
	local valueColor = s.color or { 1, 1, 1, 1 }
	local bg = p.backgroundColor or s.backgroundColor

	local rows = {}
	for i = 1, math.min(limit, #entries) do
		table.insert(rows, entries[i])
	end

	local nameMax = math.max(3, math.floor(p.nameMaxChars or 18))
	local digits = math.max(0, math.floor(p.digits or 4))
	for _, e in ipairs(rows) do
		if #e.name > nameMax then
			e.name = string.sub(e.name, 1, nameMax - 1) .. "..."
		end
		local dot = e.name:find("%.")
		if dot then
			e.module = string.sub(e.name, 1, dot - 1)
			e.method = string.sub(e.name, dot)
		else
			e.module = e.name
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
	for _, e in ipairs(rows) do
		nameCol = math.max(nameCol, labelFont:getWidth(e.name))
		pctCol = math.max(pctCol, valueFont:getWidth(fmtPct(e.ms) .. "%"))
	end
	nameCol = math.max(nameCol, labelFont:getWidth("Scope"))
	pctCol = math.max(pctCol, valueFont:getWidth("%"))
	local msCol = valueFont:getWidth(string.rep("9", timeChars))

	local rowW = nameCol + colGap + msCol + colGap + pctCol
	local topY = love.graphics.getHeight() - offset - (rowH + #rows * (rowH + rowGap))

	local x1 = offset
	local x2 = offset + nameCol + colGap
	local x3 = x2 + msCol + colGap

	local y = topY
	-- Each column is a list of { text, color, font } segments so a cell can be
	-- split (e.g. number in valueColor, unit in labelColor).
	local function drawRow(segs)
		if bg then
			love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
			love.graphics.rectangle("fill", offset, y, rowW, rowH)
		end
		local xs = { x1, x2, x3 }
		local cy = y + (rowH - fontHeight) / 2
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
				renderText(seg[1], x, cy, seg[2], seg[3])
				x = x + seg[3]:getWidth(seg[1])
			end
		end
		y = y + rowH + rowGap
	end

	local labelSeg = { "Scope", labelColor, labelFont }
	local header = {
		{ labelSeg },
		{ { string.format("%" .. timeChars .. "s", "Time"), labelColor, valueFont } },
		{ { "%", labelColor, valueFont } },
	}
	drawRow(header)
	for _, e in ipairs(rows) do
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

--- Draw the top-left HUD readout (FPS, FPS graph, object count) at native
--- resolution. Gated by the `hud` group. `scale` is the window upscale factor
--- (canvas.scale) so the text and graph stay proportional on any window size.
---@param objectCount number
---@param scale number
function Debug.draw(objectCount, scale)
	scale = scale or 1
	-- Auto-profiler draws its own table first, independent of the HUD.
	drawProfiler(scale)

	local s = Debug.settings("hud")
	local gs = Debug.settings("hud.fpsGraph")
	local hasFps = s.fps
	local hasGraph = Debug.enabled("hud.fpsGraph")
	local hasCount = s.objectCount
	if not masterOn() or not Debug.enabled("hud") or not (hasFps or hasGraph or hasCount) then
		return
	end

	local size = math.max(4, math.floor((s.size or 8) * scale))
	local fconf = s.font or {}
	local labelFont = getFont(fconf.label, size)
	local valueFont = getFont(fconf.value, size)

	-- `padding` is a single group offset: the whole readout shifts right/down
	-- by it. `gap` alone spaces the rows inside the block.
	local offset = (s.padding or 4) * scale
	local gap = (s.gap ~= nil and s.gap or offset) * scale
	local labelColor = s.labelColor or { 0.6, 0.6, 0.6, 1 }
	local valueColor = s.color or { 1, 1, 1, 1 }
	local fontHeight = math.max(labelFont:getHeight(), valueFont:getHeight())
	local rowH = fontHeight
	-- Graph height clamped to the row so a tall graph never overflows its box.
	local gh = math.min((gs.height or (size * 2)) * scale, rowH)
	local graphShown = hasGraph and historyCount > 1

	-- Pre-compute each row's content Y and width so every background box hugs
	-- its own line instead of one full-width rectangle. The whole block starts
	-- at `offset` (the group offset), rows separated by `gap`.
	local fpsY, fpsW = nil, nil
	local objY, objW = nil, nil
	local graphX = 0
	local y = offset
	if hasFps then
		fpsY = y
		local gapi = (gs.gap or 6) * scale
		local textW = labelFont:getWidth("FPS ") + valueFont:getWidth(tostring(math.floor(history[historyIndex] or 0)))
		fpsW = textW + gapi
		if graphShown then
			graphX = textW + gapi
			fpsW = fpsW + (gs.width or 60) * scale
		end
		y = y + rowH + gap
	end
	if hasCount then
		objY = y
		objW = labelFont:getWidth("Objects ") + valueFont:getWidth(tostring(objectCount))
	end

	if s.backgroundColor then
		local bg = s.backgroundColor
		love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
		if fpsY then
			love.graphics.rectangle("fill", offset, fpsY, fpsW, rowH)
		end
		if objY then
			love.graphics.rectangle("fill", offset, objY, objW, rowH)
		end
	end

	if fpsY then
		local fy = fpsY + (rowH - fontHeight) / 2
		local label = "FPS "
		local val = tostring(math.floor(history[historyIndex] or 0))
		renderText(label, offset, fy, labelColor, labelFont)
		renderText(val, offset + labelFont:getWidth(label), fy, valueColor, valueFont)

		if graphShown then
			local target = gs.fpsTarget or 60
			local ok = gs.goodColor or { 0, 1, 0, 1 }
			local bad = gs.badColor or { 1, 0, 0, 1 }
			local gy = fy + (fontHeight - gh) / 2
			local spacing = (gs.width or 60) * scale / (historyCount - 1)
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
			for k = 1, historyCount - 1 do
				local v1, v2 = sampleAt(k - 1), sampleAt(k)
				local c = (v2 or 0) >= target and ok or bad
				love.graphics.setColor(c[1], c[2], c[3], c[4])
				local h1 = math.min(gh, (v1 / target) * gh)
				local h2 = math.min(gh, (v2 / target) * gh)
				love.graphics.line(gx + (k - 1) * spacing, gy + gh - h1, gx + k * spacing, gy + gh - h2)
			end
		end
	end

	if objY then
		local oy = objY + (rowH - fontHeight) / 2
		local label = "Objects "
		renderText(label, offset, oy, labelColor, labelFont)
		renderText(tostring(objectCount), offset + labelFont:getWidth(label), oy, valueColor, valueFont)
	end
end

return Debug
