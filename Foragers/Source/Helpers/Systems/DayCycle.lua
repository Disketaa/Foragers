--- Day/night cycle system. Owns the world clock (0-24h) and derives sun state
--- (shadow offset + length) from it. A singleton, not a sprite component: the
--- cycle is world-global. Advances only while the game is actively simulating
--- (GameState.state == "game"), freezing on death/gameover like the rest of the
--- world. Emits TIME_CHANGED on each in-game minute so other systems (future
--- lighting/sky) can react without polling.
local EventEmitter = require("Source.Helpers.Core.EventEmitter")
local Events = require("Source.Helpers.Core.Events")
local GameState = require("Source.Helpers.Systems.GameState")
local Data = require("Content.Data.World").dayCycle

local DayCycle = {
	time = 12,
	emitter = EventEmitter.new(),
	-- Smoothed render target, eased toward getSunData(time) every frame so the
	-- shadow doesn't teleport on scrub/`time` jumps. Reused table (no per-frame alloc).
	display = { offsetX = 0, offsetY = 0, sunLength = 0 },
}

local lastMinute = -1

--- Frame-rate-independent exponential smoothing toward `target`.
local function approach(current, target, dt, tau)
	if tau <= 0 then
		return target
	end
	return current + (target - current) * (1 - math.exp(-dt / tau))
end

--- Derive sun state for a given hour (0-24). Outside [sunrise, sunset] the sun is
--- below the horizon: no elevation, zero shadow offset/length (shadow collapses
--- under the sprite). During the day the shadow is longest at the horizon and
--- shortest at noon, and sweeps from west (sunrise) to east (sunset).
---@param time number|nil Hour in [0,24); defaults to the current time.
---@return table { time, elevation, sunLength, offsetX, offsetY }
function DayCycle.getSunData(time)
	time = time or DayCycle.time
	local sr, ss = Data.sunriseHour, Data.sunsetHour
	local elevation = 0
	local sunLength = 0
	local offsetX = 0
	local offsetY = 0
	if time > sr and time < ss then
		local dayProgress = (time - sr) / (ss - sr) -- 0 at sunrise, 1 at sunset
		elevation = math.sin(dayProgress * math.pi) -- 0 at horizon, 1 at noon
		sunLength = Data.maxShadowLen * (1 - elevation)
		local angle = math.pi * (1 - dayProgress) -- pi at sunrise -> 0 at sunset
		offsetX = sunLength * math.cos(angle)
		offsetY = -sunLength * math.sin(angle) * (Data.shadowNorthBias or 0.5)
	end
	return {
		time = time,
		elevation = elevation,
		sunLength = sunLength,
		offsetX = offsetX,
		offsetY = offsetY,
	}
end

--- Ease displayed offset/length toward the instantaneous target. Cartesian
--- (offsetX/offsetY), NOT polar (angle/length): smoothing the angle directly
--- would sweep the shadow across the wrong arc at the night boundary where length
--- snaps to 0; easing the components independently avoids that.
--- Runs every frame regardless of the sim gate, so scrubbing while paused still
--- eases instead of snapping.
function DayCycle._approachDisplay(dt)
	local target = DayCycle.getSunData(DayCycle.time)
	local tau = Data.smoothingTau or 0.3
	local d = DayCycle.display
	d.offsetX = approach(d.offsetX, target.offsetX, dt, tau)
	d.offsetY = approach(d.offsetY, target.offsetY, dt, tau)
	d.sunLength = approach(d.sunLength, target.sunLength, dt, tau)
end

--- Smoothed sun data for rendering. Shadow reads THIS, not getSunData().
function DayCycle.getDisplaySunData()
	return DayCycle.display
end

--- Advance the clock. Gated to the live game state so the cycle pauses on
--- death/gameover. Emits TIME_CHANGED only when the in-game minute changes to
--- avoid 60/sec event spam for a value that needs ~1440 updates/day resolution.
---@param dt number Real seconds since last frame.
function DayCycle.update(dt)
	if GameState.state == "game" then
		DayCycle.time = DayCycle.time + dt * 24 / Data.dayLengthSec
		if DayCycle.time >= 24 then
			DayCycle.time = DayCycle.time - 24
		end
		local minute = math.floor(DayCycle.time * 60)
		if minute ~= lastMinute then
			lastMinute = minute
			DayCycle.emitter:emit(Events.TIME_CHANGED, DayCycle.getSunData())
		end
	end
	DayCycle._approachDisplay(dt)
end

--- Set the clock directly (used by the `time` debug command / wheel scrub).
--- Snaps the raw clock + force-emits TIME_CHANGED for future listeners (sky/
--- lighting); the shadow no longer reads raw time, so it eases in over
--- smoothingTau instead of teleporting.
---@param hours number Hour in [0,24).
function DayCycle.setTime(hours)
	DayCycle.time = hours % 24
	lastMinute = math.floor(DayCycle.time * 60)
	DayCycle.emitter:emit(Events.TIME_CHANGED, DayCycle.getSunData())
end

return DayCycle
