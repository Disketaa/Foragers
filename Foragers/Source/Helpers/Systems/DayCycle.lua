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
	-- shadow doesn't teleport on scrub/time jumps. `time` is the eased clock Shadow
	-- phase-shifts per prop (see Shadow.renderLayer). Reused table (no per-frame alloc).
	display = { offsetX = 0, offsetY = 0, sunLength = 0, isDay = false, alpha = 0, time = 12 },
}

local lastMinute = -1

--- Frame-rate-independent exponential smoothing toward `target`.
local function approach(current, target, dt, tau)
	if tau <= 0 then
		return target
	end
	return current + (target - current) * (1 - math.exp(-dt / tau))
end

--- Derive sun state for a given hour (0-24). Simplified shadow model: the
--- stretch/offset is concentrated at the horizon (sunrise/sunset) and collapses
--- to 0 across the rest of the day and all night, so midday and night shadows are
--- normal (no offset, no extra stretch). At sunrise the shadow stretches to the
--- RIGHT; at sunset it stretches to the LEFT. The stretch window is CENTERED on
--- each horizon and eases to 0 on both sides, so the peak sits exactly at
--- sunrise/sunset with no hard cut at the day/night boundary (which snapped).
--- `shadow.stretchWindow` (fraction of the day) controls the window half-width.
---@param time number|nil Hour in [0,24); defaults to the current time.
---@return table { time, elevation, sunLength, offsetX, offsetY }
function DayCycle.getSunData(time)
	time = time or DayCycle.time
	local sr, ss = Data.sunriseHour, Data.sunsetHour
	local dayLen = ss - sr
	local elevation = 0
	local sunLength = 0
	local offsetX = 0
	local offsetY = 0
	local isDay = false
	if time > sr and time < ss then
		isDay = true
		local dayProgress = (time - sr) / dayLen -- 0 at sunrise, 1 at sunset
		elevation = math.sin(dayProgress * math.pi) -- 0 at horizon, 1 at noon
	end
	-- Stretch window centered on each horizon, easing to 0 on both sides. Peak is
	-- exactly at the horizon; this avoids the old sunset snap where the ramp hit
	-- max at the boundary then cut to 0 (night). Sunrise leans RIGHT (dir=1),
	-- sunset leans LEFT (dir=-1); Shadow applies it as a pivot-based stretch.
	local winH = (Data.shadow.stretchWindow or 0.15) * dayLen
	-- >1 concentrates the stretch at the horizon (peak-short): tails flatten, change
	-- is steepest right at sunrise/sunset instead of spreading linearly across the
	-- whole golden hour. (Smoothstep/InOut would do the opposite — flat at the peak.)
	local power = Data.shadow.stretchPower or 2
	local stretch, dir = 0, 0
	local dSr = time - sr
	if dSr > -winH and dSr < winH then
		-- Sunrise: hold MAX stretch across the horizon half (where opacity fades in)
		-- so the shadow appears already lengthened, then ramp to default on the day
		-- half as the sun rises. Prevents the shadow growing during fade-in.
		dir = 1
		stretch = dSr < 0 and 1 or (1 - dSr / winH) ^ power
	else
		local dSs = time - ss
		if dSs > -winH and dSs < winH then
			-- Sunset: ramp up on the day half (shadow lengthens as the sun lowers),
			-- hold MAX across the horizon half (where opacity fades out) so it
			-- dissolves at full length instead of easing back to default.
			dir = -1
			stretch = dSs > 0 and 1 or (1 + dSs / winH) ^ power
		end
	end
	if stretch > 0 then
		sunLength = Data.shadow.maxLen * stretch
		offsetX = dir * sunLength
	end
	-- Shadow opacity: full across the day, fades out across the golden hour after
	-- sunset and back in before sunrise, so the post-sunset stretch ease-back is
	-- hidden (no visible snap) and night carries no shadow. Reuses winH for fade width.
	local alpha = 0
	if time >= sr and time <= ss then
		alpha = 1
	else
		local dSrFade = time - sr
		local dSs = time - ss
		if dSrFade >= -winH and dSrFade < 0 then
			alpha = 1 - math.abs(dSrFade) / winH -- 0 at sr-winH -> 1 at sr
		elseif dSs > 0 and dSs <= winH then
			alpha = 1 - math.abs(dSs) / winH -- 1 at ss -> 0 at ss+winH
		end
	end
	return {
		time = time,
		elevation = elevation,
		sunLength = sunLength,
		offsetX = offsetX,
		offsetY = offsetY,
		isDay = isDay,
		alpha = alpha,
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
	local tau = Data.smoothness or 0.3
	local d = DayCycle.display
	-- Ease the clock (24h wrap) so Shadow's per-prop phase shift (d.time + xOffset)
	-- eases instead of snapping on scrub/time jumps.
	local diff = (DayCycle.time - (d.time or DayCycle.time) + 12) % 24 - 12
	d.time = ((d.time or DayCycle.time) + diff * (1 - math.exp(-dt / tau))) % 24
	d.offsetX = approach(d.offsetX, target.offsetX, dt, tau)
	d.offsetY = approach(d.offsetY, target.offsetY, dt, tau)
	d.sunLength = approach(d.sunLength, target.sunLength, dt, tau)
	d.alpha = approach(d.alpha or 0, target.alpha, dt, tau)
	d.isDay = target.isDay
end

--- Smoothed render state. Shadow reads `display.time` from THIS (the eased clock)
--- and phase-shifts it per prop via `getSunData(effTime)`; it does NOT read the
--- global eased offsetX/alpha (those are now computed per prop from effTime).
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
--- smoothness instead of teleporting.
---@param hours number Hour in [0,24).
function DayCycle.setTime(hours)
	DayCycle.time = hours % 24
	lastMinute = math.floor(DayCycle.time * 60)
	DayCycle.emitter:emit(Events.TIME_CHANGED, DayCycle.getSunData())
end

--- Restore the world clock and eased render state to the neutral day start.
--- Hooked by Reset.all() on restart so the DayNightGrade shader (driven from
--- here every frame) and the shadow both reset instead of freezing.
function DayCycle.reset()
	DayCycle.time = 12
	lastMinute = -1
	DayCycle.display.time = 12
	DayCycle.display.offsetX = 0
	DayCycle.display.offsetY = 0
	DayCycle.display.sunLength = 0
	DayCycle.display.isDay = true
	DayCycle.display.alpha = 1
end

return DayCycle