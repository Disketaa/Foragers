local EventEmitter = require("Source.Helpers.EventEmitter")
local data = require("Content.Data.Debug")

local Debug = {}
local emitter = EventEmitter.new()

-- FPS history ring buffer for the HUD graph
local HISTORY_MAX = 60
local history = {}
local historyCount = 0
local historyIndex = 0
local frameCount = 0
local lastSample = 0
local font = nil
local fontKey = nil

local function masterOn()
	return data.debug == true
end

---@param group string Settings group name (e.g. "collisions")
---@return boolean
function Debug.enabled(group)
	---@type boolean
	local enabled = masterOn() and (data[group] or {}).enabled == true
	return enabled
end

--- Group "X" carries an `exclude` list of entity ids to skip.
---@param group string
---@param value string|nil Entity identifier (sprite.object)
---@return boolean
function Debug.excluded(group, value)
	if value == nil then
		return false
	end
	local list = (data[group] or {}).exclude
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
	local t = data[group] or {}
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

--- Sample FPS for the HUD. Gated by the `hud` group.
---@param dt number
function Debug.update(dt)
	if not Debug.enabled("hud") then
		return
	end
	frameCount = frameCount + 1
	local now = love.timer.getTime()
	if now - lastSample >= 0.5 then
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

--- Render one text segment in a single color.
---@param text string
---@param x number
---@param y number
---@param color table RGBA
local function renderText(text, x, y, color)
	love.graphics.setColor(color[1], color[2], color[3], color[4])
	love.graphics.print(text, x, y)
end

--- Draw the top-left HUD readout (FPS, FPS graph, object count) at native
--- resolution. Gated by the `hud` group. `scale` is the window upscale factor
--- (canvas.scale) so the text and graph stay proportional on any window size.
---@param objectCount number
---@param scale number
function Debug.draw(objectCount, scale)
	if not Debug.enabled("hud") then
		return
	end

	scale = scale or 1
	local s = Debug.settings("hud")
	local size = math.max(4, math.floor((s.size or 8) * scale))
	if fontKey ~= size then
		fontKey = size
		font = love.graphics.newFont(size)
	end
	love.graphics.setFont(font)

	local pad = (s.padding or 4) * scale
	local labelColor = s.labelColor or { 0.6, 0.6, 0.6, 1 }
	local valueColor = s.color or { 1, 1, 1, 1 }
	local lineHeight = size + 2
	local gh = size * 2

	-- Pre-compute layout so the background rect covers everything.
	local maxW = 0
	local lines = 0
	local fpsLine = false
	local fpsTextW = 0
	local graphX = 0

	if s.fps then
		fpsLine = true
		fpsTextW = font:getWidth("FPS: ") + font:getWidth(tostring(math.floor(history[historyIndex] or 0)))
		local w = fpsTextW + 3 + font:getWidth(" | ") + 6
		if s.fpsGraph and historyCount > 1 then
			local spacing = 2 * scale
			graphX = fpsTextW + 3 + font:getWidth(" | ") + 6
			w = w + (historyCount - 1) * spacing
		end
		maxW = math.max(maxW, w)
		lines = lines + 1
	end

	local objectsLine = false
	if s.objectCount then
		objectsLine = true
		maxW = math.max(maxW, font:getWidth("Objects: ") + font:getWidth(tostring(objectCount)))
		lines = lines + 1
	end

	-- Background: covers content plus `pad` margin on all sides.
	if s.backgroundColor then
		local bg = s.backgroundColor
		love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
		love.graphics.rectangle("fill", 0, 0, pad * 2 + maxW, pad * 2 + math.max(lines * lineHeight, gh + 2))
	end

	local y = pad
	if fpsLine then
		local label = "FPS: "
		local val = tostring(math.floor(history[historyIndex] or 0))
		renderText(label, pad, y, labelColor)
		renderText(val, pad + font:getWidth(label), y, valueColor)

		if s.fpsGraph and historyCount > 1 then
			renderText(" | ", pad + fpsTextW + 3, y, labelColor)

			local target = s.fpsTarget or 60
			local ok = s.graphColor or { 0, 1, 0, 1 }
			local bad = s.graphDropColor or { 1, 0, 0, 1 }
			local gy = y + (lineHeight - gh) / 2
			local spacing = 2 * scale
			local gx = pad + graphX
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
			love.graphics.setLineWidth(math.max(1, scale))
			for k = 1, historyCount - 1 do
				local v1, v2 = sampleAt(k - 1), sampleAt(k)
				local c = (v2 or 0) >= target and ok or bad
				love.graphics.setColor(c[1], c[2], c[3], c[4])
				local h1 = math.min(gh, (v1 / target) * gh)
				local h2 = math.min(gh, (v2 / target) * gh)
				love.graphics.line(gx + (k - 1) * spacing, gy + gh - h1, gx + k * spacing, gy + gh - h2)
			end
		end
		y = y + lineHeight
	end

	if objectsLine then
		local label = "Objects: "
		renderText(label, pad, y, labelColor)
		renderText(tostring(objectCount), pad + font:getWidth(label), y, valueColor)
	end
end

return Debug
