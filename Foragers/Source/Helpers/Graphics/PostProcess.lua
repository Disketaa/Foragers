--- Screen post-process transitions: death reveal (eases zoom + saturation /
--- posterize / noise / circle-mask back to normal) and the opening fade. Reads
--- and writes the live uniform values in GameState so the death-sequence block in
--- Main can snapshot them at death and the per-frame update can ease them back.
local GameState = require("Source.Helpers.Systems.GameState")
local Zoom = require("Source.Helpers.Graphics.Zoom")
local ShaderLoader = require("Source.Helpers.Graphics.ShaderLoader")
local Tween = require("Source.Sprite.Components.Tween")
local Easing = Tween.Easing

local DEATH_REVEAL_DELAY = 1.25
local DEATH_REVEAL_DURATION = 2
local DEATH_REVEAL_CURVE = "OutCubic"
local NOISE_FADE_DURATION = 7
local NOISE_FADE_CURVE = "InOutCubic"
local DEATH_DARKEN_DELAY = 5
local DEATH_DARKEN_DURATION = 1
local DEATH_DARKEN_CURVE = "InOutCubic"
local INTRO_DARKEN_DURATION = 1
local INTRO_DARKEN_CURVE = "OutCubic"

local PostProcess = {}

--- Ease zoom to `target` over `duration` seconds with a temporarily faster
--- smoothness, restoring the normal rate when the timer expires. Shared by the
--- start reveal and the death unzoom. Smoothness = duration/3 because expSmooth
--- settles in ~3x its rate, so the ease completes within `duration`.
function PostProcess.easeZoom(target, duration)
	Zoom.target = target
	Zoom.smoothness = math.max(0.01, duration / 3)
	GameState.zoomRestoreTimer = duration
end

--- Eases post-process uniforms and zoom back to normal after death, reading the
--- snapshot taken at death (GameState.revealFrom) and the live values in GameState.
function PostProcess.updateReveal(dt, canvas)
	if not GameState.revealActive then
		return
	end
	GameState.revealTimer = GameState.revealTimer + dt
	-- Fade grain from its max to invisible over NOISE_FADE_DURATION, easing from
	-- the moment death starts -- not tied to the reveal delay.
	local nt = math.min(GameState.revealTimer / NOISE_FADE_DURATION, 1)
	local ne = (Easing[NOISE_FADE_CURVE] or Easing.OutCubic)(nt)
	GameState.noiseUniform = GameState.revealFrom.noise * (1 - ne)
	ShaderLoader.sendUniform("u_noise", GameState.noiseUniform)
	-- Ease only after DEATH_REVEAL_DELAY elapses, so the death look holds before
	-- zoom / saturation / contrast return to normal.
	local t = math.max(0, math.min((GameState.revealTimer - DEATH_REVEAL_DELAY) / DEATH_REVEAL_DURATION, 1))
	local e = (Easing[DEATH_REVEAL_CURVE] or Easing.Linear)(t)
	Zoom.current = GameState.revealFrom.zoom + (1 - GameState.revealFrom.zoom) * e
	Zoom.target = Zoom.current
	GameState.satUniform = GameState.revealFrom.saturation + (1 - GameState.revealFrom.saturation) * e
	GameState.posterizeUniform = GameState.revealFrom.posterize * (1 - e)
	ShaderLoader.sendUniform("u_saturation", GameState.satUniform)
	ShaderLoader.sendUniform("u_posterize", GameState.posterizeUniform)
	local maxR = math.sqrt(canvas.width * canvas.width + canvas.height * canvas.height) / 2 + 16
	GameState.circleMaskRadius = GameState.revealFrom.circle + (maxR - GameState.revealFrom.circle) * e
	GameState.circleMaskTarget = GameState.circleMaskRadius

	if GameState.revealTimer >= DEATH_DARKEN_DELAY then
		local dtc = math.min((GameState.revealTimer - DEATH_DARKEN_DELAY) / DEATH_DARKEN_DURATION, 1)
		local de = (Easing[DEATH_DARKEN_CURVE] or Easing.Linear)(dtc)
		ShaderLoader.sendUniform("u_darken", de)
	end

	if t >= 1 and GameState.revealTimer >= DEATH_DARKEN_DELAY + DEATH_DARKEN_DURATION then
		GameState.revealActive = false
	end
end

function PostProcess.updateStartDarken(dt)
	if not GameState.startDarkenActive then
		return
	end
	GameState.startDarkenTimer = GameState.startDarkenTimer + dt
	local t = math.min(GameState.startDarkenTimer / INTRO_DARKEN_DURATION, 1)
	local e = (Easing[INTRO_DARKEN_CURVE] or Easing.Linear)(t)
	ShaderLoader.sendUniform("u_darken", 1 - e)
	if t >= 1 then
		GameState.startDarkenActive = false
	end
end

--- Push the current day/night hour into the DayCycle post-process shader. Safe to
--- call every frame unconditionally: sendUniform no-ops for shaders that don't
--- declare u_dayTime (precedent: u_noiseTime in ShaderLoader.update).
function PostProcess.updateDayCycle(time)
	ShaderLoader.sendUniform("u_dayTime", time)
end

return PostProcess
