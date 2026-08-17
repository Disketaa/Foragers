--- Game lifecycle: restart (hold-to-restart + death auto-restart) and the
--- restart-state machine. Reads/writes restart fields in GameState; `state` is
--- passed in from Main (it owns the scene string). resetGame() only flags a
--- restart -- love.update performs the actual Reset.all + initGame rebuild.
local GameState = require("Source.Helpers.Systems.GameState")
local Options = require("Source.Helpers.Systems.Options")

local AUTO_RESTART = true
local DEATH_DURATION = 4.5
local HOLD_DURATION = Options.restartHoldDuration
local LOADING_OUT_DURATION = 0.2

local Lifecycle = {}

function Lifecycle.resetGame()
	GameState._needsRestart = true
end

local function triggerLoading(tag)
	if GameState.loadingSprite then
		local tw = GameState.loadingSprite:findComponent("tween")
		if tw then
			tw:triggerTag(tag)
		end
	end
end

local function startLoadingHold()
	if GameState.holdActive then
		return
	end
	GameState.holdActive = true
	GameState.holdTimer = 0
	if GameState.loadingSprite then
		GameState.loadingSprite.alpha = 1
	end
	triggerLoading("loading_in")
end

local function cancelLoadingHold()
	if GameState.holdActive then
		GameState.holdActive = false
		triggerLoading("loading_out")
	end
end

--- Hold-to-restart is normal-play only (death auto-restarts), and works from any
--- bound input. Ignored while a restart is already winding down (restartTimer > 0)
--- so a re-press can't jump the scale-out tween.
function Lifecycle.handleRestartPress()
	if GameState.state ~= "game" or GameState.restartTimer > 0 then
		return
	end
	startLoadingHold()
end

function Lifecycle.handleRestartRelease()
	cancelLoadingHold()
end

--- Hold-to-restart + death screen timeout.
function Lifecycle.updateHold(dt)
	if GameState.state == "gameover" then
		GameState.deathTimer = GameState.deathTimer + dt
		if AUTO_RESTART and GameState.deathTimer >= DEATH_DURATION then
			Lifecycle.resetGame()
		end
	end
	if GameState.holdActive then
		GameState.holdTimer = GameState.holdTimer + dt
		local progress = math.min(1, GameState.holdTimer / HOLD_DURATION)
		if GameState.loadingSheet then
			local numFrames = GameState.loadingSheet.columns or 1
			GameState.loadingSheet:setFrame(math.min(numFrames - 1, math.floor(progress * numFrames)))
		end
		if GameState.holdTimer >= HOLD_DURATION then
			GameState.holdActive = false
			triggerLoading("loading_out")
			GameState.restartTimer = LOADING_OUT_DURATION
		end
	end
	if GameState.restartTimer > 0 then
		GameState.restartTimer = GameState.restartTimer - dt
		if GameState.restartTimer <= 0 then
			GameState.restartTimer = 0
			Lifecycle.resetGame()
		end
	end
end

return Lifecycle
