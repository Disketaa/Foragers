local EventEmitter = require("Source.Helpers.EventEmitter")
local data = require("Content.Data.Debug")

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
	---@type boolean
	local t = lookup(group)
	return masterOn() and type(t) == "table" and t.enabled == true
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
	---@type table
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

--- Draw the top-left HUD readout (FPS, FPS graph, object count) at native
--- resolution. Gated by the `hud` group. `scale` is the window upscale factor
--- (canvas.scale) so the text and graph stay proportional on any window size.
---@param objectCount number
---@param scale number
function Debug.draw(objectCount, scale)
	scale = scale or 1
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
