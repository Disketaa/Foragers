--- Game lifecycle: restart (hold-to-restart + death auto-restart) and the
--- restart-state machine. Reads/writes restart fields in GameState; `state` is
--- passed in from Main (it owns the scene string). resetGame() only flags a
--- restart -- love.update performs the actual Reset.all + initGame rebuild.
local GameState = require("Source.Helpers.Systems.GameState")
local Options = require("Source.Helpers.Systems.Options")
local Collision = require("Source.Sprite.Components.Collision")
local Path = require("Source.Helpers.Core.Path")
local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Merge = require("Source.Helpers.Core.Merge")

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

--- Drop a sprite from the world: active lists + collision registry. The object
--- stays referenced by callers (camera/counters/attacker read it), so removal is
--- not destruction — it just stops updates/draws/collision.
function Lifecycle.destroySprite(sprite, objects, dynamicObjects)
	if not sprite then
		return
	end
	for i = #objects, 1, -1 do
		if objects[i].instance == sprite then
			table.remove(objects, i)
			break
		end
	end
	for i = #dynamicObjects, 1, -1 do
		if dynamicObjects[i].instance == sprite then
			table.remove(dynamicObjects, i)
			break
		end
	end
	Collision.removeSpriteColliders(sprite)
end

--- Destroy every spawned prop (dynamic non-player, non-tool sprite) so the
--- world clears of runtime props while the player/tools/terrain survive. Returns
--- the number removed. Used by the `world clear` debug command.
function Lifecycle.clearProps(dynamicObjects, objects, weaponSprite)
	local targets = {}
	for _, entry in ipairs(dynamicObjects) do
		local s = entry.instance
		if s and s ~= GameState.playerSprite and s ~= weaponSprite then
			targets[#targets + 1] = s
		end
	end
	for _, s in ipairs(targets) do
		Lifecycle.destroySprite(s, objects, dynamicObjects)
	end
	return #targets
end

--- Spawn a drop sprite at a world position (debug `spawn` command). Resolves the
--- drop name to its data file, instantiates it, and registers it in the live
--- object lists. Returns `true` on success, or `nil, reason` if the drop is unknown.
function Lifecycle.spawnDrop(name, x, y, objects, dynamicObjects)
	local spritePath = "Content/Assets/Sprites/Drops/" .. name
	local luaPath = Path.lua(spritePath)
	local ok, data = pcall(require, luaPath)
	if not ok or not data then
		return nil, "unknown drop"
	end
	if data.extends then
		data = Merge.resolveExtends(data)
	end
	local pngPath = spritePath .. ".png"
	local sprite = SpriteLoader.instantiate(data, x, y, pngPath)
	if not sprite then
		return nil, "instantiate failed"
	end
	if GameState.playerSprite then
		local follow = sprite:findComponent("follow", function(c) return c.setFollowTarget end)
		if follow then
			follow:setFollowTarget(GameState.playerSprite)
		end
	end
	table.insert(objects, { instance = sprite, data = {} })
	table.insert(dynamicObjects, { instance = sprite, data = {} })
	return true
end

return Lifecycle
