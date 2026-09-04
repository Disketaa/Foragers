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

-- Module-level snapshot session state, held in one explicit table instead of
-- ten scattered upvalues (the ModuleSingleton smell). Collapsing them also
-- sidesteps the LuaJIT 60-upvalue trap noted in AGENTS.md.
local state = {
	initialized = false,
	enabled = false,
	lastFps = nil,
	dip = nil,
	lastRollup = 0,
	lastDrawcalls = 0,
	-- Phase timing: wall-clock cost of love.update / love.draw, measured between
	-- explicit marks. Includes any GC pause inside that phase, so a large value
	-- localizes the allocator to update vs draw.
	updateStart = 0,
	drawStart = 0,
	updateMs = 0,
	drawMs = 0,
}

--- Config, modding-safe: falls back to defaults when the `hud.snapshot` group
--- (or any field) is absent.
local function conf()
	local s = debugData.snapshot
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

local function fmtHead(fps)
	return "[" .. os.date("%H:%M:%S") .. "] FPS " .. string.format("%.0f", fps)
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
	local idle = frameMs - state.updateMs - state.drawMs
	if idle < 0 then
		idle = 0
	end
	local line = string.format(
		"  frame %s | update %s | draw %s | idle %s | measured %s | unmeasured %s (%.0f%%)"
			.. "  GC %s  drawcalls %d  window %dx%d",
		fmtMs(frameMs),
		fmtMs(state.updateMs),
		fmtMs(state.drawMs),
		fmtMs(idle),
		fmtMs(measuredMs),
		fmtMs(unmeasured),
		pct,
		fmtMb(gcKB),
		state.lastDrawcalls,
		w,
		h
	)
	return line
end

--- Lazily overwrite the file once per run: a header when active, a one-line
--- notice otherwise. `enabled` is fixed at the first sample, so a mid-run
--- profiler toggle does not change what gets recorded.
local function init(on)
	if state.initialized then
		return
	end
	state.initialized = true
	state.enabled = on
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
	state.lastDrawcalls = love.graphics.getStats().drawcalls or 0
end

function Snapshot.markUpdateStart()
	state.updateStart = love.timer.getTime()
end

function Snapshot.markDrawStart()
	state.drawStart = love.timer.getTime()
end

--- Record the end of love.update (called from Debug.update, the last call in
--- the phase). Stores wall-clock update cost including any GC pause.
function Snapshot.setUpdateEnd()
	state.updateMs = love.timer.getTime() - state.updateStart
end

--- Record the end of love.draw (called from Debug.draw, the last call in the
--- phase). Stores wall-clock draw cost including any GC pause.
function Snapshot.setDrawEnd()
	state.drawMs = love.timer.getTime() - state.drawStart
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
	if not state.enabled then
		return
	end
	local c = conf()
	local target = c.fpsTarget

	-- Sparse steady-state rollup: one ambient line per cadence, so ambient
	-- info is recorded even when FPS never dips. Gated by rollupFps (0 = off).
	if c.rollupFps > 0 then
		local now = love.timer.getTime()
		if now - state.lastRollup >= 1 / c.rollupFps then
			state.lastRollup = now
			local line = fmtHead(fps)
				.. " (avg "
				.. string.format("%.0f", love.timer.getFPS())
				.. ")"
				.. ambient(fps, totalMs)
			love.filesystem.append(FILE, line .. "\n")
		end
	end

	if fps < target then
		if not state.dip then
			state.dip = { from = state.lastFps }
		end
		if not state.dip.min or fps < state.dip.min then
			state.dip.min = fps
			-- Capture ambient once at the dip's lowest point, not every sample.
			state.dip.ambient = ambient(fps, totalMs)
		end
		-- Refresh the trace every in-dip sample, not only when the minimum
		-- moves, so a dip that starts with an empty profiler snapshot (e.g.
		-- the startup frame) still records real scopes from later samples.
		state.dip.total = totalMs
		state.dip.scopes = {}
		for _, e in ipairs(entries) do
			if #state.dip.scopes >= c.topScopes then
				break
			end
			table.insert(state.dip.scopes, e)
		end
	elseif state.dip then
		local head = fmtHead(state.dip.min) .. "  total " .. fmtMs(state.dip.total or 0)
		if state.dip.from then
			head = head .. "  (from " .. string.format("%.0f", state.dip.from) .. ")"
		end
		local lines = { head }
		if state.dip.ambient then
			lines[#lines + 1] = state.dip.ambient
		end
		for _, e in ipairs(state.dip.scopes) do
			lines[#lines + 1] = "  " .. e.name .. "  " .. fmtMs(e.ms)
		end
		love.filesystem.append(FILE, table.concat(lines, "\n") .. "\n")
		state.dip = nil
	end
	state.lastFps = fps
end

return Snapshot