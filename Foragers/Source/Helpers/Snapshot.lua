--- FPS-drop snapshot. While the profiler is enabled, records each dip of FPS
--- below `hud.fpsGraph.fpsTarget`, capturing the profiler's top scopes at the
--- dip's lowest point as a trace. Writes Logs/Snapshot.txt, overwritten per run.
--- When the profiler is off, writes a one-line notice instead.
local debugData = require("Content.Data.Debug")

local Snapshot = {}

local FILE = "Logs/Snapshot.txt"
local TOP_SCOPES = 10

local initialized = false
local enabled = false
local lastFps = nil
local dip = nil

local function fmtMs(ms)
	if ms < 1 then
		return string.format("%.1fµs", ms * 1000)
	end
	return string.format("%.2fms", ms)
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
			"-- FPS drop snapshot --",
			"-- Started: " .. os.date("%Y-%m-%d %H:%M:%S"),
		}
	else
		lines = { "Snapshot disabled: profiler not enabled." }
	end
	love.filesystem.write(FILE, table.concat(lines, "\n") .. "\n")
end

--- Feed one FPS sample. Runs the drop detector; no-op when disabled.
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
	local target = debugData.hud and debugData.hud.fpsGraph and debugData.hud.fpsGraph.fpsTarget or 60
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
		dip.scopes = {}
		for _, e in ipairs(entries) do
			if #dip.scopes >= TOP_SCOPES then
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
		for _, e in ipairs(dip.scopes) do
			lines[#lines + 1] = "  " .. e.name .. "  " .. fmtMs(e.ms)
		end
		love.filesystem.append(FILE, table.concat(lines, "\n") .. "\n")
		dip = nil
	end
	lastFps = fps
end

return Snapshot
