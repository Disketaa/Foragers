local World = require("Content.Data.World")
local Options = require("Content.Data.Options")

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
local Gizmo = require("Source.Helpers.Gizmo")
local Pivot = require("Source.Helpers.Pivot")

local objects = {}
local staticObjects = {}
local dynamicObjects = {}
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
local saturationShader = nil
local terrainBatch = nil
local tileSize = World.tileSize
local worldPixelWidth = World.width * tileSize
local worldPixelHeight = World.height * tileSize

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
	print("Love2D project started")
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.window.setMode(canvas.width, canvas.height, {
		resizable = true,
		fullscreen = Options.fullscreen,
	})
	local bg = World.backgroundColor or { 0.5, 0.8, 1.0 }
	love.graphics.setBackgroundColor(unpack(bg))

	saturationShader = love.graphics.newShader(require("Content.Assets.Shaders.Saturation"))
	saturationShader:send("u_saturation", 1)

	ModLoader.loadAllMods("Mods")

	initGame()
end

--- Rebuild all game state from scratch (world, sprites, UI, player).
--- Called at startup and on every restart. No window/graphics recreation.
function initGame()
	-- Shaders are assets but live in module arrays (ShaderLoader.shaders),
	-- which Reset.all() empties on restart. Reload here so composed shaders
	-- like Caustic survive a reset. Recompiling shaders does not recreate
	-- the window.
	ShaderLoader.loadAll("Content/Assets/Shaders")

	local worldData = WorldGen.generate()

	local charEntries = SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition) or {}

	playerSprite = nil
	for _, entry in ipairs(charEntries) do
		if entry.data and entry.data.object == "player" then
			playerSprite = entry.instance
			break
		end
	end

	local result = WorldBuilder.build(worldData, function(data)
		return data.x, data.y
	end, playerSprite)
	local tileEntries = result.terrain
	local propEntries = result.props or {}
	terrainBatch = result.terrainBatch
	local toolEntries = SpriteLoader.loadAll("Content/Assets/Sprites/Tools", function()
		return 0, 0
	end) or {}

	dynamicObjects = {}
	for _, entry in ipairs(charEntries) do
		table.insert(dynamicObjects, entry)
	end
	for _, entry in ipairs(propEntries) do
		table.insert(dynamicObjects, entry)
	end

	staticObjects = {}
	for _, entry in ipairs(tileEntries) do
		table.insert(staticObjects, entry)
	end

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
			local f = data.value / math.max(1, data.maxValue)
			TimeScale.scale = f >= 0.33 and 1.0 or 0.15 + 0.85 * (f / 0.33)
			local s = f >= 0.33 and 1 or f / 0.33
			saturationShader:send("u_saturation", math.max(0, math.min(1, s)))
		end, 5)
	end
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

local function screenToWorld(screenX, screenY)
	local cx = (screenX - canvas.offsetX) / canvas.scale
	local cy = (screenY - canvas.offsetY) / canvas.scale
	return cx - cameraX, cy - cameraY
end

-- Mirrors Canvas:draw's final world-to-screen placement so gizmo rects land on
-- the exact pixels the world canvas occupies, but at native resolution.
-- canvas:draw receives shakeOffsetX/Y as its view offset; camPixelX/Y is the
-- translate applied once inside the world draw.
local function worldToScreen(wx, wy)
	local s = canvas.scale
	local bx = canvas.offsetX - s + shakeOffsetX + camSubX * s
	local by = canvas.offsetY - s + shakeOffsetY + camSubY * s
	return (wx + camPixelX) * s + bx, (wy + camPixelY) * s + by
end

function love.draw()
	ShaderLoader.setCamera(camPixelX, camPixelY)

	-- The world render must not inherit the color the HUD/Debug left on the
	-- previous frame (setColor persists). Reset to neutral before the canvases.
	love.graphics.setColor(1, 1, 1, 1)

	-- Background canvas: same movement as world (sticky to camera, no parallax)
	-- Shader compensates for missing translate via camera_x/y uniform
	bgCanvas:draw(function()
		ShaderLoader.drawBackground(bgCanvas.width, bgCanvas.height)
	end, World.backgroundColor, shakeOffsetX, shakeOffsetY, camSubX, camSubY, saturationShader)

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

		Mask.renderSilhouette(dynamicObjects, canvas.width, canvas.height, camPixelX, camPixelY)

		-- Shadow layer: all shadows drawn opaque onto one layer, composited once
		-- at low alpha (union, not additive). Drawn AFTER terrain so shadows sit
		-- on top of tiles, but BEFORE dynamic sprites.
		Shadow.renderLayer(dynamicObjects, canvas.width, canvas.height, camPixelX, camPixelY)

		ParticleEmitter.drawBurstsBehind()
		ParticleEmitter.drawDetachedBehind()

		local sorted = DrawOrder.collect(dynamicObjects)
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
	end, nil, shakeOffsetX, shakeOffsetY, camSubX, camSubY, saturationShader)

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
		love.window.setFullscreen(not fullscreen, fstype)
	elseif bindingPressed(Options.keybinds.toggleDebug, key) then
		Debug.set("debug", not Debug.isEnabled())
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
		initGame()
		return
	end

	local scaledDt = dt * TimeScale.scale
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
			local text = pickup and ("+" .. tostring(pickup.satiety)) or ""
			follow.followTarget:emit(Events.PICKUP, text)
		end
		Collision.removeSpriteColliders(sprite)
		removeSpriteFromLists(sprite)
	end
	TweenComponent.clearPendingDestroy()

	ShaderLoader.update(scaledDt)
	local mouseX, mouseY = love.mouse.getPosition()
	local worldX, worldY = screenToWorld(mouseX, mouseY)
	local moveMouse = (Options.keybinds.moveMouse and Options.keybinds.moveMouse.mouse) or { 1 }
	local isMouseDown = love.mouse.isDown(unpack(moveMouse))

	-- Save pre-move positions for collision resolution + process control + update.
	-- Only dynamic sprites need per-frame update; static terrain is baked (solid
	-- collision, no animation), so skipping it drops thousands of wasted xpcalls.
	for _, entry in ipairs(dynamicObjects) do
		if entry.instance and entry.instance.update then
			for _, comp in ipairs(entry.instance:getComponents("collision", function(c) return c.mode ~= "solid" end)) do
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

	local spawned = PropSpawner.update(scaledDt)
	if spawned then
		table.insert(objects, { instance = spawned, data = {} })
		table.insert(dynamicObjects, { instance = spawned, data = {} })
	end
end
