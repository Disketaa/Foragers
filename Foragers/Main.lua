local World = require("Content.Data.World")
local Options = require("Source.Helpers.Systems.Options")
local Log = require("Source.Helpers.Core.Log")

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Merge = require("Source.Helpers.Core.Merge")
local Path = require("Source.Helpers.Core.Path")
local WorldGen = require("Source.World.WorldGen")
local WorldBuilder = require("Source.World.WorldBuilder")
local Canvas = require("Source.Helpers.Graphics.Canvas")
local ShaderLoader = require("Source.Helpers.Graphics.ShaderLoader")
local ModLoader = require("Source.Helpers.Systems.ModLoader")
local DrawOrder = require("Source.Helpers.Graphics.DrawOrder")
local AttackSystem = require("Source.Helpers.Systems.AttackSystem")
local Destructible = require("Source.Sprite.Components.Destructible")
local Collision = require("Source.Sprite.Components.Collision")
local ParticleEmitter = require("Source.Sprite.Components.ParticleEmitter")
local Drop = require("Source.Sprite.Components.Drop")
local Tween = require("Source.Sprite.Components.Tween")
local TweenComponent = Tween.Component
local Easing = Tween.Easing
local Shadow = require("Source.Sprite.Components.Shadow")
local Sound = require("Source.Sprite.Components.Sound")
local Mask = require("Source.Helpers.Graphics.Mask")
local Events = require("Source.Helpers.Core.Events")
local PropSpawner = require("Source.World.PropSpawner")
local PropPicker = require("Source.World.PropPicker")
local TextEmitter = require("Source.UI.Components.TextEmitter")
local UIComponent = require("Source.UI.Components.UI")
local TimeScale = require("Source.Helpers.Systems.TimeScale")
local Reset = require("Source.Helpers.Systems.Reset")
local Debug = require("Source.Helpers.Debug.Debug")
local Snapshot = require("Source.Helpers.Debug.Snapshot")
local Gizmo = require("Source.Helpers.Debug.Gizmo")
local Pivot = require("Source.Helpers.Core.Pivot")
local Zoom = require("Source.Helpers.Graphics.Zoom")
local Math = require("Source.Helpers.Core.Math")
local Input = require("Source.Helpers.Systems.Input")
local Commands = require("Source.Helpers.Debug.Commands")

local objects = {}
local staticObjects = {}
local dynamicObjects = {}
-- Per-frame on-screen subset of dynamicObjects, computed once and shared by the
-- silhouette, shadow and main passes. Single AABB test per sprite, no sort
-- change. Props fully outside the view are skipped in all passes.
local visible = {}
local CULL_MARGIN = 32
local collisionScan = {}
local function isNonSolidCollision(c)
	return c.mode ~= "solid"
end
local canvas = Canvas.new(320, 180, "outer")
local bgCanvas = Canvas.new(320, 180, "outer")
local cursorSprite = nil
local cameraX = 0
local cameraY = 0
local camPixelX = 0
local camPixelY = 0
local camSubX = 0
local camSubY = 0
local scrollToComp = nil
local weaponSprite = nil
local playerSprite = nil
-- Plain scene state (AGENTS §XII): "game" runs the world; "dying" freezes the
-- world but keeps drawing it while the player plays the death anim; "gameover"
-- is the hold once the death anim ends. Menus will add more values later.
local state = "game"
-- Auto-restart after DEATH_DURATION on the death screen.
local AUTO_RESTART = true
local deathTimer = 0
local DEATH_DURATION = 4.5
-- Hold-to-restart (normal play): pressing the restart key scales the Loading
-- sprite in, and holding it for HOLD_DURATION restarts.
local holdActive = false
local holdTimer = 0
local HOLD_DURATION = Options.restartHoldDuration
local restartTimer = 0
local LOADING_OUT_DURATION = 0.2
-- Cached reference for the satiety handler (reads low-satiety fields); death is
-- tracked by `state`, not this flag.
local playerStats = nil
-- clearAttacker() is deferred out of the DEATH handler: that handler fires
-- mid-loop (a weapon hit on the player can emit PROP_HIT→DEATH inside
-- AttackSystem.update), and nil-ing `attacker` there makes the same frame's
-- `if simulating` AttackSystem.update crash. Cleared after the camera/attack
-- block, like the old deferred destruction.
local pendingClearAttacker = false
local shakeOffsetX = 0
local shakeOffsetY = 0
-- Canvas px, matches CircleMask's canvas-space math. Eased between satiety
-- changes; snapped at the off/on boundary so entry/exit never sweeps through
-- small (mostly-black) radii.
local circleMaskRadius = 0
local circleMaskTarget = 0
local CIRCLE_MASK_SMOOTHNESS = 1
-- Restores normal zoom smoothness after a temporary ease (start reveal / death).
local zoomRestoreTimer = 0
local START_ZOOM = 1.25
local INTRO_DURATION = 1
-- Zoom's normal easing rate; restored after a temporary ease overrides it.
local ZOOM_SMOOTHNESS = Zoom.smoothness

-- Hold the death screen (snapped zoom / low-sat look) for DEATH_REVEAL_DELAY
-- before the reveal eases zoom / saturation / contrast back to normal.
local DEATH_REVEAL_DELAY = 1.25
-- Forward declaration: defined as an assignment below so the debug `spawn` command's
-- mouseWorld accessor (built earlier) can close over the same binding.
local screenToWorld
local DEATH_REVEAL_DURATION = 2
local DEATH_REVEAL_CURVE = "OutCubic"
-- Grain fades from its current opacity to invisible over this window at death,
-- easing as the timescale recovers to full speed. No hard cutoff — it exits
-- gently alongside the slow-mo returning to normal.
local NOISE_FADE_DURATION = 7
local NOISE_FADE_CURVE = "InOutCubic"
-- After the reveal, wait DEATH_DARKEN_DELAY then fade the canvas to black via
-- the Darken post-process shader over DEATH_DARKEN_DURATION.
local DEATH_DARKEN_DELAY = 5
local DEATH_DARKEN_DURATION = 1
local DEATH_DARKEN_CURVE = "InOutCubic"
-- Opening fade: the canvas starts fully dark and reveals in from black.
local INTRO_DARKEN_DURATION = 1
local INTRO_DARKEN_CURVE = "OutCubic"
local startDarkenTimer = 1
local startDarkenActive = false
local revealTimer = 0
local revealActive = false
local revealFrom = {}
-- Current post-process uniform values, tracked so the death reveal can ease them
-- back to normal from wherever they are.
local satUniform = 1
local posterizeUniform = 0
local noiseUniform = 0

--- Ease zoom to `target` over `duration` seconds with a temporarily faster
--- smoothness, restoring the normal rate when the timer expires. Shared by the
--- start reveal and the death unzoom. Smoothness = duration/3 because expSmooth
--- settles in ~3x its rate, so the ease completes within `duration`.
local function easeZoom(target, duration)
	Zoom.target = target
	Zoom.smoothness = math.max(0.01, duration / 3)
	zoomRestoreTimer = duration
end
local uiSprites = {}
-- The Loading sprite (Content/Assets/Sprites/UI/Loading.lua): shown centered on
-- the death screen, scaled in/out by the hold-to-restart interaction. Its frame
-- tracks the hold progress (progress-to-frame, 1..numFrames).
local loadingSprite = nil
local loadingSheet = nil
local terrainBatch = nil
local tileSize = World.tileSize
local worldPixelWidth = World.width * tileSize
local worldPixelHeight = World.height * tileSize
local lastFrameTime = 0
-- GC pacing: LuaJIT has no "incremental" mode, so spread collection via a per-
-- frame manual step; GC_STEP is the KB budget per frame. Tune up until spikes vanish.
local GC_STEP = 2
-- Initial terrain + props stream in over frames (not one blocking load), within
-- a ~2ms wall-clock budget per frame so large worlds never stall the frame loop.
local PROP_SPAWN_TIME_BUDGET = 0.002
local terrainPlan = {}
local terrainIndex = 1
local propSpawnPlan = {}
local propSpawnIndex = 1

local function updateCamera()
	if scrollToComp then
		local targetX, targetY = scrollToComp:getCameraOffset()
		-- Center camera on target
		cameraX = (canvas.width / 2) - targetX
		cameraY = (canvas.height / 2) - targetY
	else
		-- fallback: center on world
		cameraX = math.floor((canvas.width - worldPixelWidth) / 2)
		cameraY = math.floor((canvas.height - worldPixelHeight) / 2)
	end

	-- Split into integer pixel offset + fractional sub-pixel remainder
	camPixelX = math.floor(cameraX)
	camPixelY = math.floor(cameraY)
	camSubX = cameraX - camPixelX
	camSubY = cameraY - camPixelY
end

local function getSpawnPosition(data)
	if data.object == "player" then
		local tileX = math.floor(World.width / 2)
		local tileY = math.floor(World.height / 2)
		return tileX * tileSize + tileSize / 2, tileY * tileSize + tileSize / 2
	end
	return 0, 0
end

local function positionUI(ui)
	local w = ui.sprite.frameWidth or ui.sprite.image:getWidth()
	local h = ui.sprite.frameHeight or ui.sprite.image:getHeight()
	local px, py = UIComponent.calculate(ui.ui, canvas.width, canvas.height, w, h)
	local tweens = ui.sprite.tweens
	local tweenX = tweens and tweens.x and tweens.x:getValue() or 0
	local tweenY = tweens and tweens.y and tweens.y:getValue() or 0
	ui.sprite.x = px + Pivot.px(ui.sprite.pivotX, w, 0) + tweenX
	ui.sprite.y = py + Pivot.px(ui.sprite.pivotY, h, 0) + tweenY
end

--- One-time engine setup. Runs once at startup. Must NOT touch the window
--- or re-create graphics assets on later restarts (love.window.setMode
--- recreates the native window), so only the persistent world/sprite state
--- lives in initGame(), which resetGame() re-runs.
local initGame
function love.load()
	Log.init()
	print("Foragers launches")
	-- GC pacing: trigger sooner (default pause 200) and work harder per KB
	-- (default stepmul 200) so collection is spread instead of one big stall.
	collectgarbage("setpause", 100)
	collectgarbage("setstepmul", 300)
	love.graphics.setDefaultFilter("nearest", "nearest")
	-- `not not x` widens literal `true` to the `boolean` supertype; required
	-- because love2d's inline-typed flags table rejects narrower boolean
	-- literals under strict subtype checking.
	love.window.setMode(canvas.width, canvas.height, {
		resizable = not not true,
		fullscreen = not not Options.fullscreen,
		vsync = not not Options.vsync,
	})
	local bg = World.backgroundColor or { 0.5, 0.8, 1 }
	love.graphics.setBackgroundColor(unpack(bg))

	ModLoader.loadAllMods("Mods")

	initGame()
end

-- Time a one-shot load step and log to Logs/Latest.txt (via print).
local function timeIt(label, fn)
	local t0 = love.timer.getTime()
	local result = fn()
	print(string.format("🚩 %-30s %8.1fms", label, (love.timer.getTime() - t0) * 1000))
	return result
end

--- Drop a sprite from the world: active lists + collision registry. The object
--- stays referenced by callers (camera/counters/attacker read it), so removal is
--- not destruction — it just stops updates/draws/collision.
local function destroySprite(sprite)
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
local function clearProps()
	local targets = {}
	for _, entry in ipairs(dynamicObjects) do
		local s = entry.instance
		if s and s ~= playerSprite and s ~= weaponSprite then
			targets[#targets + 1] = s
		end
	end
	for _, s in ipairs(targets) do
		destroySprite(s)
	end
	return #targets
end

--- Spawn a drop sprite at a world position (debug `spawn` command). Resolves the
--- drop name to its data file under Content/Assets/Sprites/Drops/, instantiates it,
--- and registers it in the live object lists so it updates/draws/collides. Returns
--- `true` on success, or `nil, reason` if the drop name is unknown.
local function spawnDrop(name, x, y)
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
	-- Drops follow the player via the `follow` component, whose target is set
	-- elsewhere for normal drops (Drop.getPending). Set it here so spawned drops
	-- scatter then home in and become edible.
	if playerSprite then
		local follow = sprite:findComponent("follow", function(c) return c.setFollowTarget end)
		if follow then
			follow:setFollowTarget(playerSprite)
		end
	end
	table.insert(objects, { instance = sprite, data = {} })
	table.insert(dynamicObjects, { instance = sprite, data = {} })
	return true
end

--- Rebuild all game state from scratch (world, sprites, UI, player).
--- Called at startup and on every restart. No window/graphics recreation.
function initGame()
	local tLoad = love.timer.getTime()
	-- Shaders are assets but live in module arrays (ShaderLoader.shaders),
	-- which Reset.all() empties on restart. Reload here so composed shaders
	-- like Caustic survive a reset. Recompiling shaders does not recreate
	-- the window.
	timeIt("ShaderLoader.loadAll", function()
		ShaderLoader.loadAll("Content/Assets/Shaders")
	end)
	ShaderLoader.reset()
	ShaderLoader.setPostProcessEnabled(true)
	-- Start zoomed in for a brief reveal; eases to 1x.
	Zoom.current = START_ZOOM
	easeZoom(1, INTRO_DURATION)
	circleMaskRadius = 0
	circleMaskTarget = 0
	satUniform = 1
	posterizeUniform = 0
	noiseUniform = 0
	ShaderLoader.sendUniform("u_noise", 0)
	revealActive = false
	revealTimer = 0
	ShaderLoader.sendUniform("u_darken", 1)
	startDarkenActive = true
	startDarkenTimer = 0
	state = "game"
	deathTimer = 0
	pendingClearAttacker = false
	holdActive = false
	holdTimer = 0
	restartTimer = 0

	local worldData = timeIt("WorldGen.generate", function() return WorldGen.generate() end)

	local charEntries = timeIt("SpriteLoader Character", function() return SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition) or {} end)

	playerSprite = nil
	for _, entry in ipairs(charEntries) do
		if entry.data and entry.data.object == "player" then
			playerSprite = entry.instance
			break
		end
	end
	playerStats = playerSprite and playerSprite:findComponent("player_stats") or nil

	local result = timeIt("WorldBuilder.build", function()
		return WorldBuilder.build(worldData, function(data) return data.x, data.y end, playerSprite)
	end)
	terrainBatch = nil
	terrainPlan = result.terrainPlan or {}
	terrainIndex = 1
	propSpawnPlan = result.propPlan or {}
	propSpawnIndex = 1
	local toolEntries = timeIt("SpriteLoader Tools", function()
		return SpriteLoader.loadAll("Content/Assets/Sprites/Tools", function() return 0, 0 end) or {}
	end)

	dynamicObjects = {}
	for _, entry in ipairs(charEntries) do
		table.insert(dynamicObjects, entry)
	end

	staticObjects = {}

	objects = {}
	for _, entry in ipairs(staticObjects) do
		table.insert(objects, entry)
	end
	for _, entry in ipairs(dynamicObjects) do
		table.insert(objects, entry)
	end

	if playerSprite then
		for _, entry in ipairs(toolEntries) do
			local follow = entry.instance:findComponent("follow", function(c) return c.setFollowTarget end)
			if follow then
				follow:setFollowTarget(playerSprite)
			end
			table.insert(dynamicObjects, entry)
			table.insert(objects, entry)
		end
		local scrollComp = playerSprite:findComponent("scroll_to", function(c) return c.setFollowTarget end)
		if scrollComp then
			scrollToComp = scrollComp
			scrollComp:setFollowTarget(playerSprite)
			scrollComp._currentX = playerSprite.x + (scrollComp.offsetX or 0)
			scrollComp._currentY = playerSprite.y + (scrollComp.offsetY or 0)
		end
		AttackSystem.registerAttacker(playerSprite, toolEntries[1] and toolEntries[1].instance)
		weaponSprite = toolEntries[1] and toolEntries[1].instance
	end

	PropSpawner.init(worldData, World, {
		playerSprite = playerSprite,
	})

	updateCamera()

	-- Cursor loaded separately: has no "ui" component, follows mouse instead of anchor.
	local cursorData = require("Content.Assets.Sprites.UI.Cursor")
	local cursorObj = SpriteLoader.instantiate(cursorData, 0, 0, "Content/Assets/Sprites/UI/Cursor.png")
	if cursorObj then
		cursorSprite = { instance = cursorObj, data = cursorData }
		love.mouse.setVisible(false)
	end

	-- All sprites in Content/Assets/Sprites/UI/ with a "ui" component → screen-fixed layer.
	local uiEntries = SpriteLoader.loadAll("Content/Assets/Sprites/UI") or {}
	for _, entry in ipairs(uiEntries) do
		local uiComp = entry.instance:findComponent("ui")
		if uiComp then
			table.insert(uiSprites, { sprite = entry.instance, ui = uiComp })
		end
	end
	for _, ui in ipairs(uiSprites) do
		positionUI(ui)
	end

	-- Hide the Loading sprite until death (its frame 0 isn't empty), then reveal
	-- it on the death screen scaled to 0 and grown by the hold interaction.
	loadingSprite = nil
	loadingSheet = nil
	for _, ui in ipairs(uiSprites) do
		if ui.sprite.object == "loading" then
			loadingSprite = ui.sprite
			loadingSheet = ui.sprite:findComponent("spritesheet")
			loadingSprite.alpha = 0
		end
	end

	-- Wire counter components to player sprite (event-driven, no polling)
	if playerSprite then
		for _, ui in ipairs(uiSprites) do
			local counter = ui.sprite:findComponent("counter", function(c) return c.setPlayerSprite end)
			if counter then
				counter:setPlayerSprite(playerSprite)
			end
		end

		playerSprite:on(Events.VALUE_CHANGED, function(data)
			if data.field ~= "satiety" then
				return
			end
			local stats = playerStats
			local low = (stats and stats.lowSatietyPercent or 33) / 100
			local f = data.value / math.max(1, data.maxValue)
			TimeScale.set(f >= low and 1 or 0.15 + 0.85 * (f / low))
			local s = f >= low and 1 or f / low
			satUniform = math.max(0.2, math.min(1, s))
			ShaderLoader.sendUniform("u_saturation", satUniform)
			-- Posterization (color reduction) ramps in below the low threshold:
			-- 0 at the threshold, 1 (full posterize) as satiety hits zero.
			local p = f >= low and 0 or (1 - f / low)
			posterizeUniform = p
			ShaderLoader.sendUniform("u_posterize", posterizeUniform)
			local n = f >= low and 0 or (1 - f / low)
			noiseUniform = n
			ShaderLoader.sendUniform("u_noise", noiseUniform)
			local zMax = stats and stats.lowSatietyZoom or 2
			Zoom.target = f >= low and 1 or (zMax - (zMax - 1) * (f / low))
			local maxR = math.sqrt(canvas.width * canvas.width + canvas.height * canvas.height) / 2 + 16
			local minR = (stats and stats.lowSatietyMaskRadius) or 24
			local k = f / low
			local target = f >= low and 0 or (minR + (maxR - minR) * (k * k))
			if target == 0 or circleMaskRadius == 0 then
				circleMaskRadius = target
			end
			circleMaskTarget = target
		end, 5)

		playerSprite:on(Events.DEATH, function()
			print("[DEATH] state=" .. state .. " -> dying, anim -> death")
			-- Post-process stays ON: the CircleMask holds its satiety-0 radius on
			-- the death screen, so do not flip setPostProcessEnabled here.
			state = "dying"
			deathTimer = 0
			-- Ease back to full speed (target, not set) so the low-satiety
			-- slow-mo doesn't snap to normal the instant the death anim plays.
			TimeScale.target = 1
			-- Snap (not ease) to the low-satiety zoom-in so the collapse starts
			-- zoomed on the player.
			local stats = playerStats
			local deathZoom = (stats and stats.lowSatietyZoom) or 2
			Zoom.current = deathZoom
			Zoom.target = deathZoom
			-- Stop the opening fade so it doesn't fight the death reveal over
			-- u_darken.
			startDarkenActive = false
			revealActive = true
			revealTimer = 0
			revealFrom = {
				zoom = Zoom.current,
				saturation = satUniform,
				posterize = posterizeUniform,
				noise = noiseUniform,
				circle = circleMaskRadius,
			}
			-- Force the anim via the event, not _state: Control is the sole writer
			-- and never runs again once the world freezes, so the anim sticks.
			playerSprite:emit(Events.STATE_CHANGED, "death")
			pendingClearAttacker = true
		end, 5)

		-- The death anim is non-looping; the frame reaching its last index means
		-- the collapse is done. The circle stays at its satiety-0 value — no
		-- blackout.
		playerSprite:on(Events.ANIM_FRAME, function(frameIndex)
			if state ~= "dying" then
				return
			end
			local ss = playerSprite:findComponent("spritesheet")
			local anim = ss and ss.animations and ss.animations.death
			if anim and frameIndex >= anim.frames then
				state = "gameover"
			end
		end, 5)
	end

	print(string.format("🚩 total initGame: %.1fms", (love.timer.getTime() - tLoad) * 1000))
end

function love.resize(w, h)
	canvas:resize(w, h)
	bgCanvas:resize(w, h)
	updateCamera()
	for _, ui in ipairs(uiSprites) do
		positionUI(ui)
	end
end

local _needsRestart = false

--- Reload the whole game state in-process (R / game over).
--- Re-runs initGame() so the world, sprites, UI and player are rebuilt
--- from scratch. Reset.all() clears every module-owned pool (particles,
--- floating text, dead/pending/detached sets, attacker refs, time scale) so
--- no stale references to old sprites remain. love.load() itself is NOT
--- re-run: it calls love.window.setMode(), which recreates the native window.
local function resetGame()
	_needsRestart = true
end

local function triggerLoading(tag)
	if loadingSprite then
		local tw = loadingSprite:findComponent("tween")
		if tw then
			tw:triggerTag(tag)
		end
	end
end

local function startLoadingHold()
	if holdActive then
		return
	end
	holdActive = true
	holdTimer = 0
	if loadingSprite then
		loadingSprite.alpha = 1
	end
	triggerLoading("loading_in")
end

local function cancelLoadingHold()
	if holdActive then
		holdActive = false
		triggerLoading("loading_out")
	end
end

-- Hold-to-restart is normal-play only (death auto-restarts), and works from any
-- bound input (keyboard / mouse / gamepad). Ignored while a restart is already
-- winding down (restartTimer > 0) so a re-press can't jump the scale-out tween.
local function handleRestartPress()
	if state ~= "game" or restartTimer > 0 then
		return
	end
	startLoadingHold()
end

local function handleRestartRelease()
	cancelLoadingHold()
end

-- Debug-command context: accessors the Commands module resolves without touching
-- Main.lua internals. `stats` is a function so it reads the current playerStats
-- (reassigned each initGame); the others are direct closures.
local function commandsCtx()
	return {
		stats = function() return playerStats end,
		seed = function() return WorldGen.getSeed() end,
		restart = function()
			resetGame()
		end,
		clearProps = clearProps,
		spawnDrop = spawnDrop,
		mouseWorld = function()
			local mx,
		my = love.mouse.getPosition()
			return screenToWorld(mx, my)
		end,
	}
end

-- Tab-completion cycle state. Stores the last completed input so a repeated Tab
-- advances to the next candidate; a fresh edit resets the cycle. `completionActive`
-- distinguishes "mid-cycle" (cycle the stored list) from a new completion (re-run
-- Commands.complete on the current text, which narrows it).
local completionBase = nil
local completionCandidates = {}
local completionIndex = 0
local completionActive = false

local function resetChatCompletion()
	completionBase = nil
	completionCandidates = {}
	completionIndex = 0
	completionActive = false
end

-- Tab-complete the current chat input. First press fills the first candidate;
-- subsequent presses cycle through the remaining ones. A fresh edit (different
-- base/candidates) restarts from the first candidate. No-op with no matches.
-- `backwards` (shift+tab) cycles in reverse.
local function handleChatTab(backwards)
	if not completionActive then
		local base, candidates = Commands.complete(Debug.chatText())
		if #candidates == 0 then
			return
		end
		completionBase = base
		completionCandidates = candidates
		completionActive = true
		completionIndex = backwards and #candidates or 1
	else
		local n = #completionCandidates
		if n == 0 then
			return
		end
		if backwards then
			completionIndex = completionIndex - 1
			if completionIndex < 1 then
				completionIndex = n
			end
		else
			completionIndex = completionIndex % n + 1
		end
	end
	Debug.setChatText(completionBase .. completionCandidates[completionIndex])
end

-- Unzoomed canvas blit origin (finalX/finalY in Canvas:draw). Shared by the zoom
-- coordinate transforms so mouse, gizmos and the pivot all agree with the render.
local function canvasBlitOrigin()
	local s = canvas.scale
	return canvas.offsetX - s + shakeOffsetX + camSubX * s, canvas.offsetY - s + shakeOffsetY + camSubY * s
end

-- Zoom pivot: the player's on-screen position (unzoomed), so output zoom magnifies
-- around the player rather than the fixed window center. Falls back to window center
-- when there is no player.
local function computeZoomPivot()
	if playerSprite then
		local s = canvas.scale
		local bx, by = canvasBlitOrigin()
		return bx + (playerSprite.x + camPixelX) * s, by + (playerSprite.y + camPixelY) * s
	end
	return love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5
end

-- Inverse of the render chain. Output zoom scales the canvas blit about the pivot:
-- screen = pivot + (finalX + (p + camPixel)*scale - pivot) * zoom.
screenToWorld = function(screenX, screenY)
	local z = Zoom.current
	local px, py = computeZoomPivot()
	local bx, by = canvasBlitOrigin()
	local pcx = ((screenX - px) / z + px - bx) / canvas.scale
	local pcy = ((screenY - py) / z + py - by) / canvas.scale
	return pcx - camPixelX, pcy - camPixelY
end

-- Forward of the render chain: screen = pivot + (finalX + (wx + camPixel)*scale - pivot)*zoom.
-- Mirrors Canvas:draw's placement so gizmo rects land on the exact pixels the
-- world canvas occupies, at native resolution.
local function worldToScreen(wx, wy)
	local s = canvas.scale
	local z = Zoom.current
	local px, py = computeZoomPivot()
	local bx, by = canvasBlitOrigin()
	local cx = bx + (wx + camPixelX) * s
	local cy = by + (wy + camPixelY) * s
	return (cx - px) * z + px, (cy - py) * z + py
end

--- Fill `visible` with the entries whose frame box intersects the camera view,
--- expanded by CULL_MARGIN to avoid boundary flicker. Same box math as the
--- gizmo boundaries overlay. Runs once per frame; all draw passes reuse it.
local function cullVisible()
	-- View rect in world space (world→screen adds camPixelX/Y, canvas clips to view).
	-- Zoom happens at the canvas blit, so the world view never changes — no cull change needed.
	local vx = -camPixelX - CULL_MARGIN
	local vy = -camPixelY - CULL_MARGIN
	local vw = canvas.width + CULL_MARGIN * 2
	local vh = canvas.height + CULL_MARGIN * 2
	local n = 0
	for i = 1, #dynamicObjects do
		local s = dynamicObjects[i].instance
		if s then
			local w = s.frameWidth or (s.image and s.image:getWidth() or 0) or 0
			local h = s.frameHeight or (s.image and s.image:getHeight() or 0) or 0
			if w > 0 and h > 0 then
				local bx = s.x - Pivot.px(s.pivotX, w, 0)
				local by = s.y - Pivot.px(s.pivotY, h, 0)
				if bx + w >= vx and bx <= vx + vw and by + h >= vy and by <= vy + vh then
					n = n + 1
					visible[n] = dynamicObjects[i]
				end
			else
				-- No frame box known: keep it (player, cursor-like, etc.).
				n = n + 1
				visible[n] = dynamicObjects[i]
			end
		end
	end
	for i = n + 1, #visible do
		visible[i] = nil
	end
end

function love.draw()
	Snapshot.markDrawStart()
	ShaderLoader.setCamera(camPixelX, camPixelY)
	local zoom = Zoom.current
	local zpx, zpy = computeZoomPivot()
	local isDead = state == "gameover"

	-- CircleMask maps window px back to canvas px; needs the blit transform
	-- (scale x zoom about the pivot), which changes every frame.
	local bx, by = canvasBlitOrigin()
	ShaderLoader.setScreenTransform(canvas.scale * zoom, zpx + (bx - zpx) * zoom, zpy + (by - zpy) * zoom)

	-- The world render must not inherit the color the HUD/Debug left on the
	-- previous frame (setColor persists). Reset to neutral before the canvases.
	love.graphics.setColor(1, 1, 1, 1)

	-- Background canvas: same movement as world (sticky to camera, no parallax)
	-- Shader compensates for missing translate via camera_x/y uniform
	bgCanvas:draw(
		function()
			ShaderLoader.drawBackground(bgCanvas.width, bgCanvas.height)
		end,
		World.backgroundColor,
		shakeOffsetX,
		shakeOffsetY,
		camSubX,
		camSubY,
		ShaderLoader.getPostProcess(),
		zoom,
		zpx,
		zpy
	)

	-- Main world canvas. The frozen world keeps drawing through the whole death
	-- sequence — while dying the player's collapse is visible, and at gameover
	-- the closing CircleMask blackens it. No separate black-cleared death layer.
	canvas:draw(function()
		love.graphics.push()
		love.graphics.translate(camPixelX, camPixelY)

		-- Static terrain (pre-ordered by generation — no sorting needed).
		-- Drawn as one SpriteBatch call; the per-tile sprites stay in
		-- staticObjects only for collision and gizmo overlays.
		if terrainBatch then
			love.graphics.draw(terrainBatch)
		end

		cullVisible()

		Mask.renderSilhouette(visible, canvas.width, canvas.height, camPixelX, camPixelY)

		-- Shadow layer: all shadows drawn opaque onto one layer, composited once
		-- at low alpha (union, not additive). Drawn AFTER terrain so shadows sit
		-- on top of tiles, but BEFORE dynamic sprites.
		Shadow.renderLayer(visible, canvas.width, canvas.height, camPixelX, camPixelY)

		ParticleEmitter.drawBurstsBehind()
		ParticleEmitter.drawDetachedBehind()

		local sorted = DrawOrder.collect(visible)
		DrawOrder.sort(sorted)

		local silCanvas = Mask.getCanvas()
		if silCanvas then
			for _, sprite in ipairs(sorted) do
				if sprite.shader and sprite.shader:hasUniform("u_silhouetteTexture") then
					sprite.shader:send("u_silhouetteTexture", silCanvas)
				end
			end
		end

		for _, sprite in ipairs(sorted) do
			sprite:draw()
		end

		ParticleEmitter.drawBursts()
		ParticleEmitter.drawDetached()

		TextEmitter.drawAll()

		love.graphics.pop() -- world layer end
	end, nil, shakeOffsetX, shakeOffsetY, camSubX, camSubY,
	ShaderLoader.getPostProcess(), zoom, zpx, zpy)

	-- Boundary overlay: each sprite's pivot-aware frame box — solid fill under
	-- its outline. Rects + fills are tagged by group so Gizmo can style each.
	if Debug.showing("gizmo") and Debug.enabled("gizmo.boundaries") then
		for _, entry in ipairs(objects) do
			local s = entry.instance
			if s then
				local w = s.frameWidth or (s.image and s.image:getWidth() or 0)
				local h = s.frameHeight or (s.image and s.image:getHeight() or 0)
				if w > 0 and h > 0 and not Debug.excluded("gizmo.boundaries", s.object) then
					local ox = Pivot.px(s.pivotX, w, 0)
					local oy = Pivot.px(s.pivotY, h, 0)
					Gizmo.fillRect("boundaries", s.x - ox, s.y - oy, w, h)
					Gizmo.rect("boundaries", s.x - ox, s.y - oy, w, h)
				end
			end
		end
	end

	-- Pivot overlay: solid square centered on each sprite's pivot (sprite.x/y).
	if Debug.showing("gizmo") and Debug.enabled("gizmo.pivots") then
		local psize = Debug.settings("gizmo.pivots").size or 5
		for _, entry in ipairs(objects) do
			local s = entry.instance
			if s and not Debug.excluded("gizmo.pivots", s.object) then
				Gizmo.point("pivots", s.x, s.y, psize)
			end
		end
	end

	-- Tile mesh overlay: merged terrain colliders (row-run AABBs from
	-- WorldBuilder) so you can verify the collision mesh covers exactly the
	-- active tiles with no gaps or over-reach.
	if Debug.showing("gizmo") and Debug.enabled("gizmo.tileMesh") then
		for _, r in ipairs(Collision.getTerrainColliders()) do
			Gizmo.fillRect("tileMesh", r.x, r.y, r.w, r.h)
			Gizmo.rect("tileMesh", r.x, r.y, r.w, r.h)
		end
	end

	-- Gizmo overlay: native-resolution debug shapes, not scaled by the world canvas.
	if Debug.showing("gizmo") then
		local groups = {}
		for _, name in ipairs({ "collisions", "boundaries", "pivots", "tileMesh" }) do
			if Debug.enabled("gizmo." .. name) then
				groups[name] = Debug.settings("gizmo." .. name)
			end
		end
		Gizmo.draw(worldToScreen, groups)
	end
	Gizmo.clear()

	-- UI + cursor drawn outside canvas: screen-fixed, no camera shake/sub-pixel jitter
	love.graphics.push()
	love.graphics.origin()
	love.graphics.translate(canvas.offsetX, canvas.offsetY)
	love.graphics.scale(canvas.scale, canvas.scale)
	-- UI stays visible through the whole death cycle: the reveal eases zoom /
	-- saturation / contrast back to normal while the HUD remains on screen. The
	-- Loading sprite is a uiSprite with alpha 0 by default, so it only appears
	-- via the hold-to-restart interaction.
	table.sort(uiSprites, function(a, b) return (a.sprite.layer or 0) < (b.sprite.layer or 0) end)
	for _, ui in ipairs(uiSprites) do
		positionUI(ui)
		ui.sprite:draw()
	end
	love.graphics.pop()

	-- Debug HUD: top-left at native resolution, screen-fixed.
	if not isDead then
		Debug.draw(#objects, canvas.scale)
	end

	-- Cursor drawn last so it sits above the debug HUD, screen-fixed.
	love.graphics.push()
	love.graphics.origin()
	love.graphics.translate(canvas.offsetX, canvas.offsetY)
	love.graphics.scale(canvas.scale, canvas.scale)
	if not isDead and cursorSprite and cursorSprite.instance then
		local mx, my = love.mouse.getPosition()
		local cx = (mx - canvas.offsetX) / canvas.scale
		local cy = (my - canvas.offsetY) / canvas.scale
		cursorSprite.instance.x = cx
		cursorSprite.instance.y = cy
		cursorSprite.instance:draw()
	end
	love.graphics.pop()
end

--- Match a binding against an input of the given type (keyboard/mouse/gamepad
--- buttons). Restart accepts all three; the other keybinds are keyboard-only.
local function bindingMatches(binding, inputType, value)
	if not binding then
		return false
	end
	local list
	if inputType == "keyboard" then
		list = binding.keyboard
	elseif inputType == "mouse" then
		list = binding.mouse
	elseif inputType == "gamepad" then
		list = binding.gamepad and binding.gamepad.buttons
	end
	if list then
		for _, v in ipairs(list) do
			if v == value then
				return true
			end
		end
	end
	return false
end

-- Chat key auto-repeat while chat is open: LÖVE only repeats keypressed when
-- setKeyRepeat is on, which would also repeat the HUD/restart toggles, so the
-- repeat is driven manually here instead. Mirrors the Windows model — one action
-- on press, then a fixed delay before repeats at a steady rate. One tracker
-- covers backspace, the up/down history arrows, and Tab; the repeat action is
-- stored with the held key.
local chatRepeatKey = nil
local chatRepeatTimer = 0
local chatRepeatRepeating = false
local chatRepeatAction = nil

-- Run a chat key action once and arm the auto-repeat state. Shared by backspace,
-- the up/down history arrows, and Tab so holding any of them repeats.
local function startChatRepeat(key, action)
	action()
	chatRepeatKey = key
	chatRepeatTimer = 0
	chatRepeatRepeating = false
	chatRepeatAction = action
end

function love.keypressed(key, _, _)
	if Debug.chatActive() then
		if key == "escape" then
			Debug.setChatActive(false)
			return
		elseif key == "return" or key == "kpenter" then
			local text = Debug.chatText()
			if text ~= "" then
			local message, success, hold = Commands.execute(text, commandsCtx())
			Debug.setChatOutput(message, success, hold)
			local marker = success and "✅" or "⚠️"
			local output = Debug.chatOutput()
			if output:find("\n") then
				-- Multi-line output: one marker per rendered line, like the screen.
				for line in output:gmatch("[^\n]+") do
					print(marker .. " " .. text .. " — " .. line)
				end
			else
				print(marker .. " " .. text .. " — " .. output)
			end
			Debug.pushChatHistory(text)
			Debug.setChatText("")
			Sound.play(Debug.chatEnterSound())
			end
			Debug.setChatActive(false)
			return
		elseif key == "backspace" then
			resetChatCompletion()
			startChatRepeat("backspace", function()
				Debug.setChatText(Input.removeLast(Debug.chatText()))
			end)
			return
		elseif key == "up" then
			resetChatCompletion()
			startChatRepeat("up", function()
				Debug.chatHistoryUp()
			end)
			return
		elseif key == "down" then
			resetChatCompletion()
			startChatRepeat("down", function()
				Debug.chatHistoryDown()
			end)
			return
		elseif key == "tab" then
			startChatRepeat("tab", function()
				local backwards = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
				handleChatTab(backwards)
			end)
			return
		end
		-- Chat consumes every key while open; never fall through to gameplay
		-- bindings (e.g. R-restart) so typing can't trigger the world.
		return
	end

	if bindingMatches(Options.keybinds.restart, "keyboard", key) then
		handleRestartPress()
	elseif bindingMatches(Options.keybinds.toggleFullscreen, "keyboard", key) then
		local fullscreen, fstype = love.window.getFullscreen()
		Options.fullscreen = not fullscreen
		love.window.setFullscreen(Options.fullscreen, fstype)
		Options.save()
	elseif bindingMatches(Options.keybinds.toggleDebug, "keyboard", key) then
		Debug.toggle("hud")
		if not Debug.enabled("hud") then
			Debug.setChatActive(false)
		end
	elseif bindingMatches(Options.keybinds.toggleGizmo, "keyboard", key) then
		Debug.toggle("gizmo")
	elseif bindingMatches(Options.keybinds.toggleProfiler, "keyboard", key) then
		Debug.toggle("hud.profiler")
	elseif bindingMatches(Options.keybinds.toggleChat, "keyboard", key) then
		if Debug.enabled("hud") then
			Debug.toggle("hud.chat")
		end
	end
end

function love.textinput(text)
	if Debug.chatActive() then
		Debug.setChatText(Debug.chatText() .. text)
		resetChatCompletion()
	end
end

function love.keyreleased(key)
	if key == chatRepeatKey then
		chatRepeatKey = nil
		chatRepeatRepeating = false
		chatRepeatAction = nil
	end
	if not Debug.chatActive() and bindingMatches(Options.keybinds.restart, "keyboard", key) then
		handleRestartRelease()
	end
end

function love.mousepressed(_, _, button)
	if not Debug.chatActive() and bindingMatches(Options.keybinds.restart, "mouse", button) then
		handleRestartPress()
	end
end

function love.mousereleased(_, _, button)
	if not Debug.chatActive() and bindingMatches(Options.keybinds.restart, "mouse", button) then
		handleRestartRelease()
	end
end

function love.gamepadpressed(_, button)
	if not Debug.chatActive() and bindingMatches(Options.keybinds.restart, "gamepad", button) then
		handleRestartPress()
	end
end

function love.gamepadreleased(_, button)
	if not Debug.chatActive() and bindingMatches(Options.keybinds.restart, "gamepad", button) then
		handleRestartRelease()
	end
end

-- Hold-to-restart + death screen timeout. Kept out of love.update — that
-- function already exceeds LuaJIT's 60-upvalue budget with the world
-- simulation, so this logic lives in its own function with its own upvalue set.
local function updateHold(dt)
	if state == "gameover" then
		deathTimer = deathTimer + dt
		if AUTO_RESTART and deathTimer >= DEATH_DURATION then
			resetGame()
		end
	end
	if holdActive then
		holdTimer = holdTimer + dt
		local progress = math.min(1, holdTimer / HOLD_DURATION)
		if loadingSheet then
			local numFrames = loadingSheet.columns or 1
			loadingSheet:setFrame(math.min(numFrames - 1, math.floor(progress * numFrames)))
		end
		if holdTimer >= HOLD_DURATION then
			holdActive = false
			triggerLoading("loading_out")
			restartTimer = LOADING_OUT_DURATION
		end
	end
	if restartTimer > 0 then
		restartTimer = restartTimer - dt
		if restartTimer <= 0 then
			restartTimer = 0
			resetGame()
		end
	end
end

-- Kept out of love.update (LuaJIT 60-upvalue budget). Sets current and target
-- together so Zoom.update and the circle ease see current==target.
local function updateReveal(dt)
	if not revealActive then
		return
	end
	revealTimer = revealTimer + dt
	-- Fade grain from its max to invisible over NOISE_FADE_DURATION, easing from
	-- the moment death starts — not tied to the reveal delay.
	local nt = math.min(revealTimer / NOISE_FADE_DURATION, 1)
	local ne = (Easing[NOISE_FADE_CURVE] or Easing.OutCubic)(nt)
	noiseUniform = revealFrom.noise * (1 - ne)
	ShaderLoader.sendUniform("u_noise", noiseUniform)
	-- Ease only after DEATH_REVEAL_DELAY elapses, so the death look holds before
	-- zoom / saturation / contrast return to normal.
	local t = math.max(0, math.min((revealTimer - DEATH_REVEAL_DELAY) / DEATH_REVEAL_DURATION, 1))
	local e = (Easing[DEATH_REVEAL_CURVE] or Easing.Linear)(t)
	Zoom.current = revealFrom.zoom + (1 - revealFrom.zoom) * e
	Zoom.target = Zoom.current
	satUniform = revealFrom.saturation + (1 - revealFrom.saturation) * e
	posterizeUniform = revealFrom.posterize * (1 - e)
	ShaderLoader.sendUniform("u_saturation", satUniform)
	ShaderLoader.sendUniform("u_posterize", posterizeUniform)
	local maxR = math.sqrt(canvas.width * canvas.width + canvas.height * canvas.height) / 2 + 16
	circleMaskRadius = revealFrom.circle + (maxR - revealFrom.circle) * e
	circleMaskTarget = circleMaskRadius

	if revealTimer >= DEATH_DARKEN_DELAY then
		local dtc = math.min((revealTimer - DEATH_DARKEN_DELAY) / DEATH_DARKEN_DURATION, 1)
		local de = (Easing[DEATH_DARKEN_CURVE] or Easing.Linear)(dtc)
		ShaderLoader.sendUniform("u_darken", de)
	end

	if t >= 1 and revealTimer >= DEATH_DARKEN_DELAY + DEATH_DARKEN_DURATION then
		revealActive = false
	end
end

-- Kept out of love.update (LuaJIT 60-upvalue budget).
local function updateStartDarken(dt)
	if not startDarkenActive then
		return
	end
	startDarkenTimer = startDarkenTimer + dt
	local t = math.min(startDarkenTimer / INTRO_DARKEN_DURATION, 1)
	local e = (Easing[INTRO_DARKEN_CURVE] or Easing.Linear)(t)
	ShaderLoader.sendUniform("u_darken", 1 - e)
	if t >= 1 then
		startDarkenActive = false
	end
end

function love.update(dt)
	if _needsRestart then
		_needsRestart = false
		Reset.all()
		uiSprites = {}
		TimeScale.set(1)
		Zoom.reset()
		initGame()
		return
	end

	TimeScale.update(dt)
	local scaledDt = dt * TimeScale.scale
	updateReveal(dt)
	updateStartDarken(dt)
	-- Manual GC step: spread collection across frames so a full trace never
	-- lands in one stall.
	collectgarbage("step", GC_STEP)
	Snapshot.markUpdateStart()
	local simulating = state == "game"
	if simulating then
	local dead = Destructible.getDead()
	for _, sprite in ipairs(dead) do
		ParticleEmitter.detachAll(sprite)
		if sprite.object == "vegetable" then
			PropPicker.onVegDestroyed()
		end
		if sprite._replaceWith then
			local luaPath = Path.lua(sprite._replaceWith)
			local ok, morphData = pcall(require, luaPath)
			if ok and morphData then
				if morphData.extends then
					morphData = Merge.resolveExtends(morphData)
				end
				local pngPath = Path.png(sprite._replaceWith)
				local newSprite = SpriteLoader.instantiate(morphData, sprite.x, sprite.y, pngPath)
				newSprite.flipX = sprite.flipX

				local ss = newSprite:findComponent("spritesheet")
				if ss then
					local numFrames = ss.columns or 1
					ss:setFrame(love.math.random(0, numFrames - 1))
				end
				local col = newSprite:findComponent("collision")
				if col then
					if col.mode == "slowdown" then
						col:registerAsSlowdown()
					else
						col:registerAsSolid()
					end
				end

				table.insert(objects, { instance = newSprite, data = morphData })
				table.insert(dynamicObjects, { instance = newSprite, data = morphData })
			end
		end
		destroySprite(sprite)
	end
	Destructible.clearDead()

	for _, sprite in ipairs(Drop.getPending()) do
		if playerSprite then
			local follow = sprite:findComponent("follow", function(c) return c.setFollowTarget end)
			if follow then
				follow:setFollowTarget(playerSprite)
			end
		end
		table.insert(objects, { instance = sprite, data = {} })
		table.insert(dynamicObjects, { instance = sprite, data = {} })
	end

	local destroyedTweens = TweenComponent.getPendingDestroy()
	for _, sprite in ipairs(destroyedTweens) do
		ParticleEmitter.detachAll(sprite)
		local follow = sprite:findComponent("follow", function(c) return c.followTarget end)
		if follow then
			local pickup = sprite:findComponent("pickup", function(c) return c.satiety end)
			local text = pickup and tostring(pickup.satiety) or ""
			follow.followTarget:emit(Events.PICKUP, text)
		end
		destroySprite(sprite)
	end
	TweenComponent.clearPendingDestroy()
	end -- world destruction/simulation

	ShaderLoader.update(scaledDt)
	Zoom.update(scaledDt)

	if zoomRestoreTimer > 0 then
		zoomRestoreTimer = zoomRestoreTimer - dt
		if zoomRestoreTimer <= 0 then
			zoomRestoreTimer = 0
			Zoom.smoothness = ZOOM_SMOOTHNESS
		end
	end
	if circleMaskRadius ~= circleMaskTarget then
		local ease = Math.expSmooth(scaledDt, CIRCLE_MASK_SMOOTHNESS)
		circleMaskRadius = circleMaskRadius + (circleMaskTarget - circleMaskRadius) * ease
		if math.abs(circleMaskRadius - circleMaskTarget) < 0.01 then
			circleMaskRadius = circleMaskTarget
		end
	end
	ShaderLoader.sendUniform("u_circleRadius", circleMaskRadius)
	if simulating then
	local mouseX, mouseY = love.mouse.getPosition()
	local worldX, worldY = screenToWorld(mouseX, mouseY)
	local moveMouse = (Options.keybinds.moveMouse and Options.keybinds.moveMouse.mouse) or { 1 }
	local isMouseDown = love.mouse.isDown(unpack(moveMouse))

	-- Save pre-move positions for collision resolution + process control + update.
	-- Only dynamic sprites need per-frame update; static terrain is baked (solid
	-- collision, no animation), so skipping it drops thousands of wasted xpcalls.
	for _, entry in ipairs(dynamicObjects) do
		if entry.instance and entry.instance.update then
			local comps = entry.instance:getComponentsInto("collision", isNonSolidCollision, collisionScan)
			for _, comp in ipairs(comps) do
				comp._prevX = entry.instance.x
				comp._prevY = entry.instance.y
			end
			local control = entry.instance:findComponent("control")
			if control then
				if control.mouseControl and isMouseDown then
					control:setMousePosition(worldX, worldY)
				else
					control.mouseX, control.mouseY = nil, nil
				end
			end
			entry.instance:update(scaledDt)
		end
	end
	end -- world update

	-- The world update loop is frozen while dying, but the collapse anim and
	-- shake must play out. Advance those manually — Control must not run, or it
	-- would rewrite _state and move the player.
	if state == "dying" and playerSprite then
		local ss = playerSprite:findComponent("spritesheet")
		if ss and ss.update then
			ss:update(dt)
		end
		local shk = playerSprite:findComponent("shake")
		if shk and shk.update then
			shk:update(dt)
		end
	end

	-- Update camera from scroll_to component
	if simulating then
	if scrollToComp then
		scrollToComp:update(scaledDt)
	end
	updateCamera()

	AttackSystem.update(scaledDt, dynamicObjects)
	end -- world camera/attack

	-- Drop the attacker reference once AttackSystem.update has finished (it must
	-- not run mid-loop — see pendingClearAttacker).
	if pendingClearAttacker then
		pendingClearAttacker = false
		AttackSystem.clearAttacker()
	end

	ParticleEmitter.updateBursts(scaledDt)
	if simulating then
		ParticleEmitter.updateDetached(scaledDt)
	end
	TextEmitter.updateAll(scaledDt)
	Debug.update(scaledDt)

	if chatRepeatKey and Debug.chatActive() then
		chatRepeatTimer = chatRepeatTimer + dt
		local delay = Debug.chatRepeatDelay()
		local interval = Debug.chatRepeatInterval()
		if not chatRepeatRepeating then
			if chatRepeatTimer >= delay then
				if chatRepeatAction then chatRepeatAction() end
				chatRepeatTimer = 0
				chatRepeatRepeating = true
			end
		else
			if chatRepeatTimer >= interval then
				if chatRepeatAction then chatRepeatAction() end
				chatRepeatTimer = 0
			end
		end
	else
		chatRepeatKey = nil
		chatRepeatTimer = 0
		chatRepeatRepeating = false
		chatRepeatAction = nil
	end

	-- Update UI sprites (for counter animations, etc.)
	for _, ui in ipairs(uiSprites) do
		if ui.sprite and ui.sprite.update then
			ui.sprite:update(scaledDt)
		end
	end

	local shakeComp = weaponSprite and weaponSprite:findComponent("shake") or nil
	if shakeComp and shakeComp.active then
		shakeOffsetX = shakeComp.offsetX
		shakeOffsetY = shakeComp.offsetY
	elseif playerSprite then
		local pshake = playerSprite:findComponent("shake")
		if pshake and pshake.active then
			shakeOffsetX = pshake.offsetX
			shakeOffsetY = pshake.offsetY
		else
			shakeOffsetX = 0
			shakeOffsetY = 0
		end
	else
		shakeOffsetX = 0
		shakeOffsetY = 0
	end

	-- Stream the initial terrain plan in over frames (nearest-first, so ground
	-- appears around the player immediately), then the prop plan. Each bounded by
	-- a wall-clock budget so a large world never stalls a single frame's load.
	-- Stopped on death: spawned props are invisible under the black screen and
	-- would still emit their spawn sounds.
	if simulating then
	local streamBudget = love.timer.getTime() + PROP_SPAWN_TIME_BUDGET
	while terrainIndex <= #terrainPlan and love.timer.getTime() < streamBudget do
		local spec = terrainPlan[terrainIndex]
		terrainIndex = terrainIndex + 1
		local sprite = WorldBuilder.instantiateTerrainTile(spec)
		if sprite then
			local entry = { path = spec.path, data = spec.data, instance = sprite }
			table.insert(staticObjects, entry)
			table.insert(objects, entry)
		end
	end
	terrainBatch = WorldBuilder.getTerrainBatch()

	if propSpawnIndex <= #propSpawnPlan then
		local budgetEnd = love.timer.getTime() + PROP_SPAWN_TIME_BUDGET
		while propSpawnIndex <= #propSpawnPlan and love.timer.getTime() < budgetEnd do
			local sprite = WorldBuilder.instantiateProp(propSpawnPlan[propSpawnIndex])
			propSpawnIndex = propSpawnIndex + 1
			if sprite then
				table.insert(objects, { instance = sprite, data = {} })
				table.insert(dynamicObjects, { instance = sprite, data = {} })
			end
		end
	end

	-- Runtime spawning starts only once the initial plan is fully streamed, so it
	-- can't reserve a plan tile that isn't solid yet (overlap on large worlds).
	if propSpawnIndex > #propSpawnPlan then
		local spawned = PropSpawner.update(scaledDt)
		if spawned then
			table.insert(objects, { instance = spawned, data = {} })
			table.insert(dynamicObjects, { instance = spawned, data = {} })
		end
	end
	end -- world streaming

	-- Hold-to-restart + death flash decay (extracted to keep love.update under
	-- LuaJIT's 60-upvalue limit).
	updateHold(dt)

	-- Manual FPS cap (love.timer.setFPS unavailable here): sleep the remainder
	-- of the target frame budget so CPU isn't pegged at uncapped rates.
	local maxFps = Options.maxFps
	if maxFps and maxFps > 0 then
		local budget = 1 / maxFps
		local elapsed = love.timer.getTime() - lastFrameTime
		if elapsed < budget then
			love.timer.sleep(budget - elapsed)
		end
		lastFrameTime = love.timer.getTime()
	end
end
