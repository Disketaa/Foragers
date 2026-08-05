--- Performance snapshot. While the profiler is enabled, records each dip of FPS
--- below the target, capturing the profiler's top scopes at the dip's lowest
--- point as a trace. Each record also carries ambient diagnostics: the real
--- frame time split into measured (profiler) vs unmeasured (GPU/GC/driver), the
--- GC heap, draw-call count, and window/vsync state. When `rollupSeconds` is set,
--- a sparse one-line steady-state summary is appended on that cadence so ambient
--- info is available even without a drop. Writes Logs/Snapshot.txt, overwritten
--- per run. When the profiler is off, writes a one-line notice instead.
local debugData = require("Content.Data.Debug")

local Snapshot = {}

local FILE = "Logs/Snapshot.txt"

local initialized = false
local enabled = false
local lastFps = nil
local dip = nil
local lastRollup = 0
local lastDrawcalls = 0
-- Phase timing: wall-clock cost of love.update / love.draw, measured between
-- explicit marks. Includes any GC pause inside that phase, so a large value
-- localizes the allocator to update vs draw.
local updateStart = 0
local drawStart = 0
local updateMs = 0
local drawMs = 0

--- Config, modding-safe: falls back to defaults when the `hud.snapshot` group
--- (or any field) is absent.
local function conf()
	local s = debugData.hud and debugData.hud.snapshot
	local fg = debugData.hud and debugData.hud.fpsGraph and debugData.hud.fpsGraph.fpsTarget
	return {
		topScopes = s and s.topScopes or 10,
		rollupFps = s and s.rollupFps or 15,
		fpsTarget = (s and s.fpsTarget) or fg or 60,
	}
end

local function fmtMs(ms)
	if ms < 1 then
		return string.format("%.1fµs", ms * 1000)
	end
	return string.format("%.2fms", ms)
end

local function fmtMb(kb)
	if kb < 1024 then
		return string.format("%.0fKB", kb)
	end
	return string.format("%.2fMB", kb / 1024)
end

--- Ambient diagnostics for the current frame. Cheap: one getStats + one GC
--- count + one window query, all O(1). Returns a formatted one-line string.
---@param fps number Sampled frames per second.
---@param measuredMs number Profiler-measured frame cost.
local function ambient(fps, measuredMs)
	local frameMs = fps > 0 and (1000 / fps) or 0
	local unmeasured = frameMs - measuredMs
	if unmeasured < 0 then
		unmeasured = 0
	end
	local pct = frameMs > 0 and (unmeasured / frameMs * 100) or 0
	local gcKB = collectgarbage("count")
	local w, h = love.window.getMode()
	local idle = frameMs - updateMs - drawMs
	if idle < 0 then
		idle = 0
	end
	local line = string.format(
		"  frame %s | update %s | draw %s | idle %s | measured %s | unmeasured %s (%.0f%%)"
			.. "  GC %s  drawcalls %d  window %dx%d",
		fmtMs(frameMs),
		fmtMs(updateMs),
		fmtMs(drawMs),
		fmtMs(idle),
		fmtMs(measuredMs),
		fmtMs(unmeasured),
		pct,
		fmtMb(gcKB),
		lastDrawcalls,
		w,
		h
	)
	return line
end

--- Lazily overwrite the file once per run: a header when active, a one-line
--- notice otherwise. `enabled` is fixed at the first sample, so a mid-run
--- profiler toggle does not change what gets recorded.
local function init(on)
	if initialized then
		return
	end
	initialized = true
	enabled = on
	love.filesystem.createDirectory("Logs")
	local lines
	if on then
		lines = {
			"-- Snapshot --",
			"-- Started: " .. os.date("%Y-%m-%d %H:%M:%S"),
		}
	else
		lines = { "Snapshot disabled: profiler not enabled." }
	end
	love.filesystem.write(FILE, table.concat(lines, "\n") .. "\n")
end

--- Capture render stats during the draw phase. LÖVE resets these at frame
--- start, so they must be sampled after drawing, not from update(). Called from
--- Debug.draw each frame; cheap, stores one number.
function Snapshot.captureDraw()
	lastDrawcalls = love.graphics.getStats().drawcalls or 0
end

function Snapshot.markUpdateStart()
	updateStart = love.timer.getTime()
end

function Snapshot.markDrawStart()
	drawStart = love.timer.getTime()
end

--- Record the end of love.update (called from Debug.update, the last call in
--- the phase). Stores wall-clock update cost including any GC pause.
function Snapshot.setUpdateEnd()
	updateMs = love.timer.getTime() - updateStart
end

--- Record the end of love.draw (called from Debug.draw, the last call in the
--- phase). Stores wall-clock draw cost including any GC pause.
function Snapshot.setDrawEnd()
	drawMs = love.timer.getTime() - drawStart
end

--- Feed one FPS sample. Runs the drop detector and the optional steady-state
--- rollup; no-op when disabled.
---@param profilerOn boolean Whether the profiler is collecting this frame.
---@param fps number Sampled frames per second.
---@param entries table[] Profiler snapshot sorted by descending cost.
---@param totalMs number Measured total frame cost for the snapshot.
function Snapshot.update(profilerOn, fps, entries, totalMs)
	if not (love and love.filesystem) then
		return
	end
	init(profilerOn)
	if not enabled then
		return
	end
	local c = conf()
	local target = c.fpsTarget

	-- Sparse steady-state rollup: one ambient line per cadence, so ambient
	-- info is recorded even when FPS never dips. Gated by rollupFps (0 = off).
	if c.rollupFps > 0 then
		local now = love.timer.getTime()
		if now - lastRollup >= 1 / c.rollupFps then
			lastRollup = now
			local line = "["
				.. os.date("%H:%M:%S")
				.. "] FPS "
				.. string.format("%.0f", fps)
				.. " (avg "
				.. string.format("%.0f", love.timer.getFPS())
				.. ")"
				.. ambient(fps, totalMs)
			love.filesystem.append(FILE, line .. "\n")
		end
	end

	if fps < target then
		if not dip then
			dip = { from = lastFps }
		end
		if not dip.min or fps < dip.min then
			dip.min = fps
		end
		-- Refresh the trace every in-dip sample, not only when the minimum
		-- moves, so a dip that starts with an empty profiler snapshot (e.g.
		-- the startup frame) still records real scopes from later samples.
		dip.total = totalMs
		dip.ambient = ambient(fps, totalMs)
		dip.scopes = {}
		for _, e in ipairs(entries) do
			if #dip.scopes >= c.topScopes then
				break
			end
			table.insert(dip.scopes, e)
		end
	elseif dip then
		local head = "["
			.. os.date("%H:%M:%S")
			.. "] FPS "
			.. string.format("%.0f", dip.min)
			.. "  total "
			.. fmtMs(dip.total or 0)
		if dip.from then
			head = head .. "  (from " .. string.format("%.0f", dip.from) .. ")"
		end
		local lines = { head }
		if dip.ambient then
			lines[#lines + 1] = dip.ambient
		end
		for _, e in ipairs(dip.scopes) do
			lines[#lines + 1] = "  " .. e.name .. "  " .. fmtMs(e.ms)
		end
		love.filesystem.append(FILE, table.concat(lines, "\n") .. "\n")
		dip = nil
	end
	lastFps = fps
end

return Snapshot
