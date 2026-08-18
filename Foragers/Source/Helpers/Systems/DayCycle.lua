--- Day/night cycle system. Owns the world clock (0-24h) and derives sun state
--- (shadow offset + elevation) from it. A singleton, not a sprite component:
--- the cycle is world-global. Advances only while the game is actively
--- simulating (GameState.state == "game"), freezing on death/gameover like the
--- rest of the world. Emits TIME_CHANGED on each in-game minute so other
--- systems (future lighting/sky) can react without polling.
local EventEmitter = require("Source.Helpers.Core.EventEmitter")
local Events = require("Source.Helpers.Core.Events")
local GameState = require("Source.Helpers.Systems.GameState")
local Data = require("Content.Data.World").dayCycle

local DayCycle = {
	time = 12,
	emitter = EventEmitter.new(),
}

local lastMinute = -1

--- Derive sun state for a given hour (0-24). Outside [sunrise, sunset] the sun is
--- below the horizon: no elevation, zero shadow offset (shadow collapses under
--- the sprite). During the day the shadow is longest at the horizon and shortest
--- at noon, and sweeps from west (sunrise) to east (sunset).
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

--- Advance the clock. Gated to the live game state so the cycle pauses on
--- death/gameover. Emits TIME_CHANGED only when the in-game minute changes to
--- avoid 60/sec event spam for a value that needs ~1440 updates/day resolution.
---@param dt number Real seconds since last frame.
function DayCycle.update(dt)
	if GameState.state ~= "game" then
		return
	end
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

--- Set the clock directly (used by the `time` debug command). Forces an
--- immediate re-emit so any listener snaps to the new time at once instead of
--- waiting for the next minute-cross.
---@param hours number Hour in [0,24).
function DayCycle.setTime(hours)
	DayCycle.time = hours % 24
	lastMinute = math.floor(DayCycle.time * 60)
	DayCycle.emitter:emit(Events.TIME_CHANGED, DayCycle.getSunData())
end

return DayCycle
