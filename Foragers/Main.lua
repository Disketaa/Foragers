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
local Shadow = require("Source.Sprite.Components.Shadow")
local Sound = require("Source.Sprite.Components.Sound")
local Mask = require("Source.Helpers.Graphics.Mask")
local Emissive = require("Source.Sprite.Components.Emissive")
local Cursor = require("Source.Sprite.Components.Cursor")
local Events = require("Source.Helpers.Core.Events")
local PropSpawner = require("Source.World.PropSpawner")
local PropPicker = require("Source.World.PropPicker")
local TextEmitter = require("Source.UI.Components.TextEmitter")
local Layout = require("Source.UI.Layout")
local TimeScale = require("Source.Helpers.Systems.TimeScale")
local Reset = require("Source.Helpers.Systems.Reset")
local DiscordRPC = require("Source.Helpers.Systems.DiscordRPC")
local Debug = require("Source.Helpers.Debug.Debug")
local Snapshot = require("Source.Helpers.Debug.Snapshot")
local Gizmo = require("Source.Helpers.Debug.Gizmo")
local Pivot = require("Source.Helpers.Core.Pivot")
local Zoom = require("Source.Helpers.Graphics.Zoom")
local Math = require("Source.Helpers.Core.Math")
local Input = require("Source.Helpers.Systems.Input")
local Bindings = require("Source.Helpers.Systems.Bindings")
local Commands = require("Source.Helpers.Debug.Commands")
local Chat = require("Source.Helpers.Debug.Chat")
local PostProcess = require("Source.Helpers.Graphics.PostProcess")
local Lifecycle = require("Source.Helpers.Systems.Lifecycle")
local Camera = require("Source.Helpers.Graphics.Camera")
local GameState = require("Source.Helpers.Systems.GameState")
local DayCycle = require("Source.Helpers.Systems.DayCycle")
local AmbientSpawner = require("Source.Helpers.Systems.AmbientSpawner")

local objects = {}
local staticObjects = {}
local dynamicObjects = {}
-- Per-frame on-screen subset of dynamicObjects, computed once and shared by the
-- silhouette, shadow and main passes. Single AABB test per sprite, no sort
-- change. Props fully outside the view are skipped in all passes.
local visible = {}
local collisionScan = {}
local function isNonSolidCollision(c)
	return c.mode ~= "solid"
end
local canvas = Canvas.new(320, 180, "outer")
local bgCanvas = Canvas.new(320, 180, "outer")
local cursorSprite = nil
GameState.cameraX = 0
GameState.cameraY = 0
GameState.camPixelX = 0
GameState.camPixelY = 0
GameState.camSubX = 0
GameState.camSubY = 0
GameState.scrollToComp = nil
local weaponSprite = nil
-- Plain scene state (AGENTS §XII): "game" runs the world; "dying" freezes the
-- world but keeps drawing it while the player plays the death anim; "gameover"
-- is the hold once the death anim ends. Menus will add more values later.
GameState.state = "game"
-- Auto-restart after DEATH_DURATION on the death screen.
GameState.deathTimer = 0
-- Hold-to-restart (normal play): pressing the restart key scales the Loading
-- sprite in, and holding it for HOLD_DURATION restarts.
GameState.holdActive = false
GameState.holdTimer = 0
GameState.restartTimer = 0
-- Cached reference for the satiety handler (reads low-satiety fields); death is
-- tracked by `state`, not this flag.
local playerStats = nil
-- clearAttacker() is deferred out of the DEATH handler: that handler fires
-- mid-loop (a weapon hit on the player can emit PROP_HIT→DEATH inside
-- AttackSystem.update), and nil-ing `attacker` there makes the same frame's
-- `if simulating` AttackSystem.update crash. Cleared after the camera/attack
-- block, like the old deferred destruction.
local pendingClearAttacker = false
GameState.shakeOffsetX = 0
GameState.shakeOffsetY = 0
-- Canvas px, matches CircleMask's canvas-space math. Eased between satiety
-- changes; snapped at the off/on boundary so entry/exit never sweeps through
-- small (mostly-black) radii.
GameState.circleMaskRadius = 0
GameState.circleMaskTarget = 0
local CIRCLE_MASK_SMOOTHNESS = 1
-- Restores normal zoom smoothness after a temporary ease (start reveal / death).
GameState.zoomRestoreTimer = 0
local START_ZOOM = 1.25
local INTRO_DURATION = 1
-- Zoom's normal easing rate; restored after a temporary ease overrides it.
local ZOOM_SMOOTHNESS = Zoom.smoothness

-- Hold the death screen (snapped zoom / low-sat look) for DEATH_REVEAL_DELAY
-- before the reveal eases zoom / saturation / contrast back to normal.
-- Grain fades from its current opacity to invisible over this window at death,
-- easing as the timescale recovers to full speed. No hard cutoff — it exits
-- gently alongside the slow-mo returning to normal.
-- After the reveal, wait DEATH_DARKEN_DELAY then fade the canvas to black via
-- the Darken post-process shader over DEATH_DARKEN_DURATION.
-- Opening fade: the canvas starts fully dark and reveals in from black.
GameState.startDarkenTimer = 1
GameState.startDarkenActive = false
GameState.revealTimer = 0
GameState.revealActive = false
GameState.revealFrom = {}
-- Current post-process uniform values, tracked so the death reveal can ease them
-- back to normal from wherever they are.
GameState.satUniform = 1
GameState.posterizeUniform = 0
GameState.noiseUniform = 0

--- Ease zoom to `target` over `duration` seconds with a temporarily faster
--- smoothness, restoring the normal rate when the timer expires. Shared by the
--- start reveal and the death unzoom. Smoothness = duration/3 because expSmooth
--- settles in ~3x its rate, so the ease completes within `duration`.
local uiSprites = {}
-- The Loading sprite (Content/Assets/Sprites/UI/Loading.lua): shown centered on
-- the death screen, scaled in/out by the hold-to-restart interaction. Its frame
-- tracks the hold progress (progress-to-frame, 1..numFrames).
local tileSize = World.tileSize
GameState.worldPixelWidth = World.width * tileSize
GameState.worldPixelHeight = World.height * tileSize
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


local function getSpawnPosition(data)
	if data.object == "player" then
		local tileX = math.floor(World.width / 2)
		local tileY = math.floor(World.height / 2)
		return tileX * tileSize + tileSize / 2, tileY * tileSize + tileSize / 2
	end
	return 0, 0
end

--- One-time engine setup. Runs once at startup. Must NOT touch the window
--- or re-create graphics assets on later restarts (love.window.setMode
--- recreates the native window), so only the persistent world/sprite state
--- lives in initGame(), which Lifecycle.resetGame() re-runs.
local initGame
function love.load()
	Log.init()
	-- Wire the generic ValueParser to the localization handler without coupling
	-- the parser to I18n/TextParser (handler injected at boot, before any
	-- ValueParser.table call during sprite loading).
	require("Source.Helpers.Core.ValueParser").registerKeyHandler(
		"text", require("Source.Helpers.Core.TextParser").resolve)
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

	DiscordRPC.init()

	initGame()
end

-- Time a one-shot load step and log to Logs/Latest.txt (via print).
local function timeIt(label, fn)
	local t0 = love.timer.getTime()
	local result = fn()
	Log.write("Loading", "%-30s %8.1fms", label, (love.timer.getTime() - t0) * 1000)
	return result
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
	PostProcess.easeZoom(1, INTRO_DURATION)
	GameState.circleMaskRadius = 0
	GameState.circleMaskTarget = 0
	GameState.satUniform = 1
	GameState.posterizeUniform = 0
	GameState.noiseUniform = 0
	GameState.darkenUniform = 0
	ShaderLoader.sendUniform("u_noise", 0)
	GameState.revealActive = false
	GameState.revealTimer = 0
	ShaderLoader.sendUniform("u_darken", 1)
	GameState.startDarkenActive = true
	GameState.startDarkenTimer = 0
	GameState.state = "game"
	DiscordRPC.setScene("game")
	GameState.deathTimer = 0
	pendingClearAttacker = false
	GameState.holdActive = false
	GameState.holdTimer = 0
	GameState.restartTimer = 0

	local worldData = timeIt("WorldGen.generate", function() return WorldGen.generate() end)

	local charEntries = timeIt("SpriteLoader Character", function() return SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition) or {} end)

	GameState.playerSprite = nil
	for _, entry in ipairs(charEntries) do
		if entry.data and entry.data.object == "player" then
			GameState.playerSprite = entry.instance
			break
		end
	end
	playerStats = GameState.playerSprite and GameState.playerSprite:findComponent("player_stats") or nil

	local result = timeIt("WorldBuilder.build", function()
		return WorldBuilder.build(worldData, function(data) return data.x, data.y end, GameState.playerSprite)
	end)
	GameState.terrainBatch = nil
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

	if GameState.playerSprite then
		for _, entry in ipairs(toolEntries) do
			local follow = entry.instance:findComponent("follow", function(c) return c.setFollowTarget end)
			if follow then
				follow:setFollowTarget(GameState.playerSprite)
			end
			table.insert(dynamicObjects, entry)
			table.insert(objects, entry)
		end
		local scrollComp = GameState.playerSprite:findComponent("scroll_to", function(c) return c.setFollowTarget end)
		if scrollComp then
			GameState.scrollToComp = scrollComp
			scrollComp:setFollowTarget(GameState.playerSprite)
			scrollComp._currentX = GameState.playerSprite.x + (scrollComp.offsetX or 0)
			scrollComp._currentY = GameState.playerSprite.y + (scrollComp.offsetY or 0)
		end
		AttackSystem.registerAttacker(GameState.playerSprite, toolEntries[1] and toolEntries[1].instance)
		weaponSprite = toolEntries[1] and toolEntries[1].instance
	end

	PropSpawner.init(worldData, World, {
		playerSprite = GameState.playerSprite,
	})

	AmbientSpawner.init(World.ambient, worldData, World)

	Camera.update(canvas)

	-- Cursor loaded separately: has no "ui" component, follows mouse instead of anchor.
	local cursorData = require("Content.Assets.Sprites.UI.Cursors.Arrow")
	local cursorObj = SpriteLoader.instantiate(cursorData, 0, 0, "Content/Assets/Sprites/UI/Cursors/Arrow.png")
	if cursorObj then
		-- data.components is now non-empty, so the loader skips the StaticSprite gate; force it so the PNG still renders.
		cursorObj.type = "StaticSprite"
		local cursorComp = cursorObj:findComponent("cursor")
		if cursorComp then
			cursorComp.canvas = canvas
			Cursor.active = cursorComp
		end
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
		Layout.positionUI(ui, canvas)
	end

	-- Hide the Loading sprite until death (its frame 0 isn't empty), then reveal
	-- it on the death screen scaled to 0 and grown by the hold interaction.
	GameState.loadingSprite = nil
	GameState.loadingSheet = nil
	for _, ui in ipairs(uiSprites) do
		if ui.sprite.object == "loading" then
			GameState.loadingSprite = ui.sprite
			GameState.loadingSheet = ui.sprite:findComponent("spritesheet")
			GameState.loadingSprite.alpha = 0
		end
	end

	-- Wire counter components to player sprite (event-driven, no polling)
	if GameState.playerSprite then
		for _, ui in ipairs(uiSprites) do
			local counter = ui.sprite:findComponent("counter", function(c) return c.setPlayerSprite end)
			if counter then
				counter:setPlayerSprite(GameState.playerSprite)
			end
		end

		GameState.playerSprite:on(Events.VALUE_CHANGED, function(data)
			if data.field ~= "satiety" then
				return
			end
			local stats = playerStats
			local low = (stats and stats.lowSatietyPercent or 33) / 100
			local f = data.value / math.max(1, data.maxValue)
			TimeScale.set(f >= low and 1 or 0.15 + 0.85 * (f / low))
			local s = f >= low and 1 or f / low
			GameState.satUniform = math.max(0.2, math.min(1, s))
			ShaderLoader.sendUniform("u_saturation", GameState.satUniform)
			-- Posterization (color reduction) ramps in below the low threshold:
			-- 0 at the threshold, 1 (full posterize) as satiety hits zero.
			local p = f >= low and 0 or (1 - f / low)
			GameState.posterizeUniform = p
			ShaderLoader.sendUniform("u_posterize", GameState.posterizeUniform)
			local n = f >= low and 0 or (1 - f / low)
			GameState.noiseUniform = n
			ShaderLoader.sendUniform("u_noise", GameState.noiseUniform)
			local zMax = stats and stats.lowSatietyZoom or 2
			Zoom.target = f >= low and 1 or (zMax - (zMax - 1) * (f / low))
			local maxR = math.sqrt(canvas.width * canvas.width + canvas.height * canvas.height) / 2 + 16
			local minR = (stats and stats.lowSatietyMaskRadius) or 24
			local k = f / low
			local target = f >= low and 0 or (minR + (maxR - minR) * (k * k))
			if target == 0 or GameState.circleMaskRadius == 0 then
				GameState.circleMaskRadius = target
			end
			GameState.circleMaskTarget = target
		end, 5)

		GameState.playerSprite:on(Events.DEATH, function()
			Log.write("Death", "state=%s -> dying, anim -> death", GameState.state)
			-- Post-process stays ON: the CircleMask holds its satiety-0 radius on
			-- the death screen, so do not flip setPostProcessEnabled here.
			GameState.state = "dying"
			DiscordRPC.setScene("dying")
			GameState.deathTimer = 0
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
			GameState.startDarkenActive = false
			GameState.revealActive = true
			GameState.revealTimer = 0
			GameState.revealFrom = {
				zoom = Zoom.current,
				saturation = GameState.satUniform,
				posterize = GameState.posterizeUniform,
				noise = GameState.noiseUniform,
				circle = GameState.circleMaskRadius,
			}
			-- Force the anim via the event, not _state: Control is the sole writer
			-- and never runs again once the world freezes, so the anim sticks.
			GameState.playerSprite:emit(Events.STATE_CHANGED, "death")
			pendingClearAttacker = true
		end, 5)

		-- The death anim is non-looping; the frame reaching its last index means
		-- the collapse is done. The circle stays at its satiety-0 value — no
		-- blackout.
		GameState.playerSprite:on(Events.ANIM_FRAME, function(frameIndex)
			if GameState.state ~= "dying" then
				return
			end
			local ss = GameState.playerSprite:findComponent("spritesheet")
			local anim = ss and ss.animations and ss.animations.death
			if anim and frameIndex >= anim.frames then
				GameState.state = "gameover"
				DiscordRPC.setScene("gameover")
			end
		end, 5)
	end

	Log.write("Loading", "%-30s %8.1fms", "total initGame", (love.timer.getTime() - tLoad) * 1000)
end

function love.resize(w, h)
	canvas:resize(w, h)
	bgCanvas:resize(w, h)
	Camera.update(canvas)
	for _, ui in ipairs(uiSprites) do
		Layout.positionUI(ui, canvas)
	end
end

GameState._needsRestart = false

-- Debug-command context: accessors the Commands module resolves without touching
-- Main.lua internals. `stats` is a function so it reads the current playerStats
-- (reassigned each initGame); the others are direct closures.
local function commandsCtx()
	return {
		stats = function() return playerStats end,
		seed = function() return WorldGen.getSeed() end,
		dayCycle = DayCycle,
		restart = function()
			Lifecycle.resetGame()
		end,
		clearProps = function() return Lifecycle.clearProps(dynamicObjects, objects, weaponSprite) end,
		spawnDrop = function(name, x, y) return Lifecycle.spawnDrop(name, x, y, objects, dynamicObjects) end,
		mouseWorld = function()
			local mx,
		my = love.mouse.getPosition()
			return Camera.screenToWorld(canvas, mx, my)
		end,
	}
end

function love.draw()
	Snapshot.markDrawStart()
	ShaderLoader.setCamera(GameState.camPixelX, GameState.camPixelY)
	local zoom = Zoom.current
	local zpx, zpy = Camera.computeZoomPivot(canvas)
	local isDead = GameState.state == "gameover"

	-- CircleMask maps window px back to canvas px; needs the blit transform
	-- (scale x zoom about the pivot), which changes every frame.
	local bx, by = Camera.canvasBlitOrigin(canvas)
	ShaderLoader.setScreenTransform(canvas.scale * zoom, zpx + (bx - zpx) * zoom, zpy + (by - zpy) * zoom, canvas.width, canvas.height)

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
		GameState.shakeOffsetX,
		GameState.shakeOffsetY,
		GameState.camSubX,
		GameState.camSubY,
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
		love.graphics.translate(GameState.camPixelX, GameState.camPixelY)

		-- Static terrain (pre-ordered by generation — no sorting needed).
		-- Drawn as one SpriteBatch call; the per-tile sprites stay in
		-- staticObjects only for collision and gizmo overlays.
		if GameState.terrainBatch then
			love.graphics.draw(GameState.terrainBatch)
		end

		Camera.cullVisible(canvas, dynamicObjects, visible)

		Mask.renderSilhouette(visible, canvas.width, canvas.height, GameState.camPixelX, GameState.camPixelY)

		-- Shadow layer: all shadows drawn opaque onto one layer, composited once
		-- at low alpha (union, not additive). Drawn AFTER terrain so shadows sit
		-- on top of tiles, but BEFORE dynamic sprites.
		Shadow.renderLayer(visible, canvas.width, canvas.height, GameState.camPixelX, GameState.camPixelY)

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
	end, nil, GameState.shakeOffsetX, GameState.shakeOffsetY, GameState.camSubX, GameState.camSubY,
	ShaderLoader.getPostProcess(), zoom, zpx, zpy)

	-- Draw only when grade chain differs from identity: postProcess active AND
	-- (darken active OR outside neutral day range 8-16.5).
	if ShaderLoader.postProcessEnabled and (GameState.darkenUniform > 0 or DayCycle.time < 8 or DayCycle.time > 16.5) then
		Emissive.drawToScreen(visible, canvas, GameState.camPixelX, GameState.camPixelY,
			GameState.camSubX, GameState.camSubY, GameState.shakeOffsetX, GameState.shakeOffsetY, zoom, zpx, zpy)
	end

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
		Gizmo.draw(function(wx, wy) return Camera.worldToScreen(canvas, wx, wy) end, groups)
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
		Layout.positionUI(ui, canvas)
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
		-- Cursor update sets position (mouse->canvas) + idle/hide; dt from wall-clock since draw runs once per frame.
		local now = love.timer.getTime()
		local fdt = now - (cursorSprite._lastDraw or now)
		cursorSprite._lastDraw = now
		cursorSprite.instance:update(fdt)
		cursorSprite.instance:draw()
	end
	love.graphics.pop()
end

--- Match a binding against an input of the given type (keyboard/mouse/gamepad
--- buttons). Restart accepts all three; the other keybinds are keyboard-only.
function love.keypressed(key, _, _)
	if Debug.chatActive() then
		if key == "escape" then
			Chat.resetChatCompletion()
			Debug.setChatActive(false)
			return
		elseif key == "return" or key == "kpenter" then
			local text = Debug.chatText()
			if text ~= "" then
			local message, success, hold = Commands.execute(text, commandsCtx())
			Debug.setChatOutput(message, success, hold)
		local output = Debug.chatOutput()
		local function logChat(detail)
			Log.write("Chat", "%s — %s", text, detail)
		end
			if output:find("\n") then
				-- Multi-line output: one marker per rendered line, like the screen.
				for line in output:gmatch("[^\n]+") do
					logChat(line)
				end
			else
				logChat(output)
			end
			Debug.pushChatHistory(text)
			Debug.setChatText("")
			Sound.play(Debug.chatEnterSound())
			end
		Debug.setChatActive(false)
		Chat.resetChatCompletion()
		return
	elseif key == "backspace" then
			Chat.resetChatCompletion()
			Chat.startChatRepeat("backspace", function()
				Debug.setChatText(Input.removeLast(Debug.chatText()))
			end)
			return
		elseif key == "up" then
			Chat.resetChatCompletion()
			Chat.startChatRepeat("up", function()
				Debug.chatHistoryUp()
			end)
			return
		elseif key == "down" then
			Chat.resetChatCompletion()
			Chat.startChatRepeat("down", function()
				Debug.chatHistoryDown()
			end)
			return
		elseif key == "tab" then
			Chat.startChatRepeat("tab", function()
				local backwards = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
				Chat.handleChatTab(backwards)
			end)
			return
		end
		-- Chat consumes every key while open; never fall through to gameplay
		-- bindings (e.g. R-restart) so typing can't trigger the world.
		return
	end

	if Bindings.matches(Options.keybinds.restart, "keyboard", key) then
		Lifecycle.handleRestartPress()
	elseif Bindings.matches(Options.keybinds.toggleFullscreen, "keyboard", key) then
		local fullscreen, fstype = love.window.getFullscreen()
		Options.fullscreen = not fullscreen
		love.window.setFullscreen(Options.fullscreen, fstype)
		Options.save()
	elseif Bindings.matches(Options.keybinds.toggleDebug, "keyboard", key) then
		Debug.toggle("hud")
		if not Debug.enabled("hud") then
			Debug.setChatActive(false)
		end
	elseif Bindings.matches(Options.keybinds.toggleGizmo, "keyboard", key) then
		Debug.toggle("gizmo")
	elseif Bindings.matches(Options.keybinds.toggleProfiler, "keyboard", key) then
		Debug.toggle("hud.profiler")
	elseif Bindings.matches(Options.keybinds.toggleChat, "keyboard", key) then
		if Debug.enabled("hud") then
			local wasActive = Debug.chatActive()
			Debug.toggle("hud.chat")
			-- Reset only on open: close already resets via escape / send handlers.
			if not wasActive and Debug.chatActive() then
				Chat.resetChatCompletion()
			end
		end
	end
end

function love.textinput(text)
	if Debug.chatActive() then
		Debug.setChatText(Debug.chatText() .. text)
		Chat.resetChatCompletion()
	end
end

function love.keyreleased(key)
	Chat.cancelRepeat(key)
	if not Debug.chatActive() and Bindings.matches(Options.keybinds.restart, "keyboard", key) then
		Lifecycle.handleRestartRelease()
	end
end

function love.mousepressed(_, _, button)
	if not Debug.chatActive() and Bindings.matches(Options.keybinds.restart, "mouse", button) then
		Lifecycle.handleRestartPress()
	end
end

function love.mousereleased(_, _, button)
	if not Debug.chatActive() and Bindings.matches(Options.keybinds.restart, "mouse", button) then
		Lifecycle.handleRestartRelease()
	end
end

function love.gamepadpressed(_, button)
	if not Debug.chatActive() and Bindings.matches(Options.keybinds.restart, "gamepad", button) then
		Lifecycle.handleRestartPress()
	end
end

function love.gamepadreleased(_, button)
	if not Debug.chatActive() and Bindings.matches(Options.keybinds.restart, "gamepad", button) then
		Lifecycle.handleRestartRelease()
	end
end

function love.wheelmoved(_, dy)
	if Debug.chatActive() then
		return
	end
	-- TEMP debug: wheel scrubs the day/night clock. Float step per notch for
	-- smooth fine control (whole-hour jumps were too coarse). Remove with the
	-- Day&Night debug controls.
	DayCycle.setTime(DayCycle.time + dy * 0.25)
end

function love.quit()
	DiscordRPC.shutdown()
end

function love.update(dt)
	if GameState._needsRestart then
		GameState._needsRestart = false
		Reset.all()
		uiSprites = {}
		GameState.playerSprite = nil
		GameState.loadingSprite = nil
		GameState.loadingSheet = nil
		GameState.terrainBatch = nil
		TimeScale.set(1)
		Zoom.reset()
		initGame()
		return
	end

	TimeScale.update(dt)
	DiscordRPC.update(dt)
	local scaledDt = dt * TimeScale.scale
	PostProcess.updateReveal(dt, canvas)
	PostProcess.updateStartDarken(dt)
	-- Manual GC step: spread collection across frames so a full trace never
	-- lands in one stall.
	collectgarbage("step", GC_STEP)
	Snapshot.markUpdateStart()
	local simulating = GameState.state == "game"
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
				elseif col.mode == "solid" then
					col:registerAsSolid()
				elseif col.mode == "detect" or col.mode == "solid_and_detect" then
					Log.write("Collision", "morph sprite uses dynamic-only collision mode '%s'; not baking a static collider", tostring(col.mode))
				else
					Log.error("Collision", "morph sprite has unknown collision mode '%s'; not baking a static collider", tostring(col.mode))
				end
				end

				table.insert(objects, { instance = newSprite, data = morphData })
				table.insert(dynamicObjects, { instance = newSprite, data = morphData })
			end
		end
		Lifecycle.destroySprite(sprite, objects, dynamicObjects)
	end
	Destructible.clearDead()

	for _, sprite in ipairs(Drop.getPending()) do
		if GameState.playerSprite then
			local follow = sprite:findComponent("follow", function(c) return c.setFollowTarget end)
			if follow then
				follow:setFollowTarget(GameState.playerSprite)
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
		Lifecycle.destroySprite(sprite, objects, dynamicObjects)
	end
	TweenComponent.clearPendingDestroy()
	end -- world destruction/simulation

	ShaderLoader.update(scaledDt)
	DayCycle.update(dt)
	PostProcess.updateDayCycle(DayCycle.time)
	Zoom.update(scaledDt)

	if GameState.zoomRestoreTimer > 0 then
		GameState.zoomRestoreTimer = GameState.zoomRestoreTimer - dt
		if GameState.zoomRestoreTimer <= 0 then
			GameState.zoomRestoreTimer = 0
			Zoom.smoothness = ZOOM_SMOOTHNESS
		end
	end
	if GameState.circleMaskRadius ~= GameState.circleMaskTarget then
		local ease = Math.expSmooth(scaledDt, CIRCLE_MASK_SMOOTHNESS)
		GameState.circleMaskRadius = GameState.circleMaskRadius + (GameState.circleMaskTarget - GameState.circleMaskRadius) * ease
		if math.abs(GameState.circleMaskRadius - GameState.circleMaskTarget) < 0.01 then
			GameState.circleMaskRadius = GameState.circleMaskTarget
		end
	end
	ShaderLoader.sendUniform("u_circleRadius", GameState.circleMaskRadius)
	if simulating then
	local mouseX, mouseY = love.mouse.getPosition()
	local worldX, worldY = Camera.screenToWorld(canvas, mouseX, mouseY)
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
	if GameState.state == "dying" and GameState.playerSprite then
		local ss = GameState.playerSprite:findComponent("spritesheet")
		if ss and ss.update then
			ss:update(dt)
		end
		local shk = GameState.playerSprite:findComponent("shake")
		if shk and shk.update then
			shk:update(dt)
		end
	end

	-- Update camera from scroll_to component
	if simulating then
	if GameState.scrollToComp then
		GameState.scrollToComp:update(scaledDt)
	end
	Camera.update(canvas)

		AmbientSpawner.update(scaledDt, objects, dynamicObjects, GameState.camPixelX, GameState.camPixelY, canvas.width, canvas.height)

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

	Chat.updateRepeat(dt)

	-- Update UI sprites (for counter animations, etc.)
	for _, ui in ipairs(uiSprites) do
		if ui.sprite and ui.sprite.update then
			ui.sprite:update(scaledDt)
		end
	end

	local shakeComp = weaponSprite and weaponSprite:findComponent("shake") or nil
	if shakeComp and shakeComp.active then
		GameState.shakeOffsetX = shakeComp.offsetX
		GameState.shakeOffsetY = shakeComp.offsetY
	elseif GameState.playerSprite then
		local pshake = GameState.playerSprite:findComponent("shake")
		if pshake and pshake.active then
			GameState.shakeOffsetX = pshake.offsetX
			GameState.shakeOffsetY = pshake.offsetY
		else
			GameState.shakeOffsetX = 0
			GameState.shakeOffsetY = 0
		end
	else
		GameState.shakeOffsetX = 0
		GameState.shakeOffsetY = 0
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
	GameState.terrainBatch = WorldBuilder.getTerrainBatch()

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
	Lifecycle.updateHold(dt)

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
