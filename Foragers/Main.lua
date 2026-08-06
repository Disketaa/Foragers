local World = require("Content.Data.World")
local Options = require("Source.Helpers.Options")
local Log = require("Source.Helpers.Log")

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Merge = require("Source.Helpers.Merge")
local Path = require("Source.Helpers.Path")
local WorldGen = require("Source.World.WorldGen")
local WorldBuilder = require("Source.World.WorldBuilder")
local Canvas = require("Source.Helpers.Canvas")
local ShaderLoader = require("Source.Helpers.ShaderLoader")
local ModLoader = require("Source.Helpers.ModLoader")
local DrawOrder = require("Source.Helpers.DrawOrder")
local AttackSystem = require("Source.Helpers.AttackSystem")
local Destructible = require("Source.Sprite.Components.Destructible")
local Collision = require("Source.Sprite.Components.Collision")
local ParticleEmitter = require("Source.Sprite.Components.ParticleEmitter")
local Drop = require("Source.Sprite.Components.Drop")
local TweenComponent = require("Source.Sprite.Components.Tween").Component
local Shadow = require("Source.Sprite.Components.Shadow")
local Mask = require("Source.Helpers.Mask")
local Events = require("Source.Helpers.Events")
local PropSpawner = require("Source.World.PropSpawner")
local TextEmitter = require("Source.UI.Components.TextEmitter")
local UIComponent = require("Source.UI.Components.UI")
local TimeScale = require("Source.Helpers.TimeScale")
local Reset = require("Source.Helpers.Reset")
local Debug = require("Source.Helpers.Debug")
local Snapshot = require("Source.Helpers.Snapshot")
local Gizmo = require("Source.Helpers.Gizmo")
local Pivot = require("Source.Helpers.Pivot")
local Zoom = require("Source.Helpers.Zoom")

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
local canvas = Canvas.new(480, 270, "outer")
local bgCanvas = Canvas.new(480, 270, "outer")
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
local shakeOffsetX = 0
local shakeOffsetY = 0
local uiSprites = {}
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
	ui.sprite.x = px + Pivot.px(ui.sprite.pivotX, w, 0)
	ui.sprite.y = py + Pivot.px(ui.sprite.pivotY, h, 0)
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
	love.window.setMode(canvas.width, canvas.height, {
		resizable = true,
		fullscreen = Options.fullscreen,
		vsync = Options.vsync,
	})
	local bg = World.backgroundColor or { 0.5, 0.8, 1.0 }
	love.graphics.setBackgroundColor(unpack(bg))

	ModLoader.loadAllMods("Mods")

	initGame()
end

-- Time a one-shot load step and log to Logs/Latest.txt (via print).
local function timeIt(label, fn)
	local t0 = love.timer.getTime()
	local result = fn()
	print(string.format("[Load] %-30s %8.1fms", label, (love.timer.getTime() - t0) * 1000))
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

	local worldData = timeIt("WorldGen.generate", function()
		return WorldGen.generate()
	end)

	local charEntries = timeIt("SpriteLoader Character", function()
		return SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition) or {}
	end)

	playerSprite = nil
	for _, entry in ipairs(charEntries) do
		if entry.data and entry.data.object == "player" then
			playerSprite = entry.instance
			break
		end
	end

	local result = timeIt("WorldBuilder.build", function()
		return WorldBuilder.build(worldData, function(data)
			return data.x, data.y
		end, playerSprite)
	end)
	terrainBatch = nil
	terrainPlan = result.terrainPlan or {}
	terrainIndex = 1
	propSpawnPlan = result.propPlan or {}
	propSpawnIndex = 1
	local toolEntries = timeIt("SpriteLoader Tools", function()
		return SpriteLoader.loadAll("Content/Assets/Sprites/Tools", function()
			return 0, 0
		end) or {}
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
			local follow = entry.instance:findComponent("follow", function(c)
				return c.setFollowTarget
			end)
			if follow then
				follow:setFollowTarget(playerSprite)
			end
			table.insert(dynamicObjects, entry)
			table.insert(objects, entry)
		end
		local scrollComp = playerSprite:findComponent("scroll_to", function(c)
			return c.setFollowTarget
		end)
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

	-- Wire counter components to player sprite (event-driven, no polling)
	if playerSprite then
		for _, ui in ipairs(uiSprites) do
			local counter = ui.sprite:findComponent("counter", function(c)
				return c.setPlayerSprite
			end)
			if counter then
				counter:setPlayerSprite(playerSprite)
			end
		end

		playerSprite:on(Events.VALUE_CHANGED, function(data)
			if data.field ~= "satiety" then
				return
			end
			local stats = playerSprite:findComponent("player_stats")
			local low = (stats and stats.lowSatietyPercent or 33) / 100
			local f = data.value / math.max(1, data.maxValue)
			TimeScale.scale = f >= low and 1.0 or 0.15 + 0.85 * (f / low)
			local s = f >= low and 1 or f / low
			ShaderLoader.sendUniform("u_saturation", math.max(0.33, math.min(1, s)))
			local zMax = stats and stats.lowSatietyZoom or 2
			Zoom.target = f >= low and 1 or (zMax - (zMax - 1) * (f / low))
		end, 5)
	end

	print(string.format("[Load] total initGame: %.1fms", (love.timer.getTime() - tLoad) * 1000))
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
local function screenToWorld(screenX, screenY)
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

	-- Main world canvas
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
	end, nil, shakeOffsetX, shakeOffsetY, camSubX, camSubY, ShaderLoader.getPostProcess(), zoom, zpx, zpy)

	-- Boundary overlay: each sprite's pivot-aware frame box — solid fill under
	-- its outline. Rects + fills are tagged by group so Gizmo can style each.
	if Debug.enabled("gizmo") and Debug.enabled("gizmo.boundaries") then
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
	if Debug.enabled("gizmo") and Debug.enabled("gizmo.pivots") then
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
	if Debug.enabled("gizmo") and Debug.enabled("gizmo.tileMesh") then
		for _, r in ipairs(Collision.getTerrainColliders()) do
			Gizmo.fillRect("tileMesh", r.x, r.y, r.w, r.h)
			Gizmo.rect("tileMesh", r.x, r.y, r.w, r.h)
		end
	end

	-- Gizmo overlay: native-resolution debug shapes, not scaled by the world canvas.
	if Debug.enabled("gizmo") then
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
	for _, ui in ipairs(uiSprites) do
		ui.sprite:draw()
	end
	love.graphics.pop()

	-- Debug HUD: top-left at native resolution, screen-fixed.
	Debug.draw(#objects, canvas.scale)

	-- Cursor drawn last so it sits above the debug HUD, screen-fixed.
	love.graphics.push()
	love.graphics.origin()
	love.graphics.translate(canvas.offsetX, canvas.offsetY)
	love.graphics.scale(canvas.scale, canvas.scale)
	if cursorSprite and cursorSprite.instance then
		local mx, my = love.mouse.getPosition()
		local cx = (mx - canvas.offsetX) / canvas.scale
		local cy = (my - canvas.offsetY) / canvas.scale
		cursorSprite.instance.x = cx
		cursorSprite.instance.y = cy
		cursorSprite.instance:draw()
	end
	love.graphics.pop()
end

local function removeSpriteFromLists(sprite)
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
end

local function bindingPressed(binding, key)
	local kb = binding and binding.keyboard
	if kb then
		for _, k in ipairs(kb) do
			if k == key then
				return true
			end
		end
	end
	return false
end

function love.keypressed(key)
	if bindingPressed(Options.keybinds.restart, key) then
		resetGame()
	elseif bindingPressed(Options.keybinds.toggleFullscreen, key) then
		local fullscreen, fstype = love.window.getFullscreen()
		Options.fullscreen = not fullscreen
		love.window.setFullscreen(Options.fullscreen, fstype)
		Options.save()
	elseif bindingPressed(Options.keybinds.toggleDebug, key) then
		Debug.toggle("hud")
	elseif bindingPressed(Options.keybinds.toggleGizmo, key) then
		Debug.toggle("gizmo")
	elseif bindingPressed(Options.keybinds.toggleProfiler, key) then
		Debug.toggle("hud.profiler")
	end
end

function love.update(dt)
	if _needsRestart then
		_needsRestart = false
		Reset.all()
		uiSprites = {}
		TimeScale.scale = 1.0
		Zoom.reset()
		initGame()
		return
	end

	local scaledDt = dt * TimeScale.scale
	-- Manual GC step: spread collection across frames so a full trace never
	-- lands in one stall.
	collectgarbage("step", GC_STEP)
	Snapshot.markUpdateStart()
	local dead = Destructible.getDead()
	for _, sprite in ipairs(dead) do
		ParticleEmitter.detachAll(sprite)
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
		Collision.removeSpriteColliders(sprite)
		removeSpriteFromLists(sprite)
	end
	Destructible.clearDead()

	for _, sprite in ipairs(Drop.getPending()) do
		if playerSprite then
			local follow = sprite:findComponent("follow", function(c)
				return c.setFollowTarget
			end)
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
		local follow = sprite:findComponent("follow", function(c)
			return c.followTarget
		end)
		if follow then
			local pickup = sprite:findComponent("pickup", function(c)
				return c.satiety
			end)
			local text = pickup and ("+" .. tostring(pickup.satiety)) or ""
			follow.followTarget:emit(Events.PICKUP, text)
		end
		Collision.removeSpriteColliders(sprite)
		removeSpriteFromLists(sprite)
	end
	TweenComponent.clearPendingDestroy()

	ShaderLoader.update(scaledDt)
	Zoom.update(scaledDt)
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

	-- Update camera from scroll_to component
	if scrollToComp then
		scrollToComp:update(scaledDt)
	end
	updateCamera()

	AttackSystem.update(scaledDt, dynamicObjects)
	ParticleEmitter.updateBursts(scaledDt)
	ParticleEmitter.updateDetached(scaledDt)
	TextEmitter.updateAll(scaledDt)
	Debug.update(scaledDt)

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
	else
		shakeOffsetX = 0
		shakeOffsetY = 0
	end

	-- Stream the initial terrain plan in over frames (nearest-first, so ground
	-- appears around the player immediately), then the prop plan. Each bounded by
	-- a wall-clock budget so a large world never stalls a single frame's load.
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
