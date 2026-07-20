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
local ProximityFade = require("Source.Sprite.Components.ProximityFade")
local Drop = require("Source.Sprite.Components.Drop")
local TweenComponent = require("Source.Sprite.Components.Tween").Component
local Shadow = require("Source.Sprite.Components.Shadow")
local Events = require("Source.Helpers.Events")
local PropSpawner = require("Source.World.PropSpawner")

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

function love.load()
	print("Love2D project started")
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.window.setMode(canvas.width, canvas.height, {
		resizable = true,
		fullscreen = Options.fullscreen,
	})
	local bg = World.backgroundColor or { 0.5, 0.8, 1.0 }
	love.graphics.setBackgroundColor(unpack(bg))

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
		ProximityFade.setPlayer(playerSprite)
		for _, entry in ipairs(toolEntries) do
			for _, comp in ipairs(entry.instance.components or {}) do
				if comp.type == "follow" and comp.setFollowTarget then
					comp:setFollowTarget(playerSprite)
				end
			end
			table.insert(dynamicObjects, entry)
			table.insert(objects, entry)
		end
		-- Find scroll_to component for camera
		for _, comp in ipairs(playerSprite.components or {}) do
			if comp.type == "scroll_to" then
				scrollToComp = comp
				comp:setFollowTarget(playerSprite)
				-- Initialize camera to player position for smooth start
				comp._currentX = playerSprite.x + (comp.offsetX or 0)
				comp._currentY = playerSprite.y + (comp.offsetY or 0)
				break
			end
		end
		AttackSystem.registerAttacker(playerSprite, toolEntries[1] and toolEntries[1].instance)
		weaponSprite = toolEntries[1] and toolEntries[1].instance
	end

	PropSpawner.init(worldData, World, {
		playerSprite = playerSprite,
	})

	updateCamera()

	ModLoader.loadAllMods("Mods")

	cursorSprite = SpriteLoader.loadAll("Content/Assets/Sprites/UI", function(_)
		return 0, 0
	end)[1]
	if cursorSprite and cursorSprite.instance then
		love.mouse.setVisible(false)
	end
end

function love.resize(w, h)
	canvas:resize(w, h)
	bgCanvas:resize(w, h)
	updateCamera()
end

local function screenToWorld(screenX, screenY)
	local cx = (screenX - canvas.offsetX) / canvas.scale
	local cy = (screenY - canvas.offsetY) / canvas.scale
	return cx - cameraX, cy - cameraY
end

function love.draw()
	ShaderLoader.setCamera(camPixelX, camPixelY)

	-- Background canvas: same movement as world (sticky to camera, no parallax)
	-- Shader compensates for missing translate via camera_x/y uniform
	bgCanvas:draw(function()
		ShaderLoader.drawBackground(bgCanvas.width, bgCanvas.height)
	end, World.backgroundColor, shakeOffsetX, shakeOffsetY, camSubX, camSubY)

	-- Main world canvas
	canvas:draw(function()
		love.graphics.push()
		love.graphics.translate(camPixelX, camPixelY)

		-- Static terrain (pre-ordered by generation — no sorting needed)
		for _, entry in ipairs(staticObjects) do
			if entry.instance and entry.instance.draw then
				entry.instance:draw()
			end
		end

		-- Shadow layer: all shadows drawn opaque onto one layer, composited once
		-- at low alpha (union, not additive). Drawn AFTER terrain so shadows sit
		-- on top of tiles, but BEFORE dynamic sprites.
		Shadow.renderLayer(dynamicObjects, canvas.width, canvas.height, camPixelX, camPixelY)

		ParticleEmitter.drawBurstsBehind()

		local sorted = DrawOrder.collect(dynamicObjects)
		DrawOrder.sort(sorted)
		for _, sprite in ipairs(sorted) do
			sprite:draw()
		end

		ParticleEmitter.drawBursts()

		if cursorSprite and cursorSprite.instance then
			local mx, my = love.mouse.getPosition()
			local wx, wy = screenToWorld(mx, my)
			cursorSprite.instance.x = wx
			cursorSprite.instance.y = wy
			cursorSprite.instance:draw()
		end

		love.graphics.pop()
	end, nil, shakeOffsetX, shakeOffsetY, camSubX, camSubY)
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

function love.keypressed(key)
	if key == "f11" then
		local fullscreen, fstype = love.window.getFullscreen()
		love.window.setFullscreen(not fullscreen, fstype)
	end
end

function love.update(dt)
	local dead = Destructible.getDead()
	for _, sprite in ipairs(dead) do
		if sprite._replaceWith then
			local luaPath = Path.lua(sprite._replaceWith)
			local ok, morphData = pcall(require, luaPath)
			if ok and morphData then
				if morphData.extends then
					morphData = Merge.resolveExtends(morphData)
				end
				local pngPath = sprite._replaceWith .. ".png"
				local newSprite = SpriteLoader.instantiate(morphData, sprite.x, sprite.y, pngPath)
				newSprite.flipX = sprite.flipX

				for _, comp in ipairs(newSprite.components) do
					if comp.type == "spritesheet" then
						local numFrames = comp.columns or 1
						comp:setFrame(love.math.random(0, numFrames - 1))
					elseif comp.type == "collision" then
						if comp.mode == "slowdown" then
							comp:registerAsSlowdown()
						else
							comp:registerAsSolid()
						end
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
			for _, comp in ipairs(sprite.components or {}) do
				if comp.type == "follow" and comp.setFollowTarget then
					comp:setFollowTarget(playerSprite)
				end
			end
		end
		table.insert(objects, { instance = sprite, data = {} })
		table.insert(dynamicObjects, { instance = sprite, data = {} })
	end

	local destroyedTweens = TweenComponent.getPendingDestroy()
	for _, sprite in ipairs(destroyedTweens) do
		for _, comp in ipairs(sprite.components or {}) do
			if comp.type == "follow" and comp.followTarget then
				comp.followTarget:emit(Events.PICKUP, sprite)
			end
		end
		Collision.removeSpriteColliders(sprite)
		removeSpriteFromLists(sprite)
	end
	TweenComponent.clearPendingDestroy()

	ShaderLoader.update(dt)
	local mouseX, mouseY = love.mouse.getPosition()
	local worldX, worldY = screenToWorld(mouseX, mouseY)
	local isMouseDown = love.mouse.isDown(1)

	-- Save pre-move positions for collision resolution
	for _, entry in ipairs(objects) do
		if entry.instance then
			for _, comp in ipairs(entry.instance.components or {}) do
				if comp.type == "collision" and comp.mode ~= "solid" then
					comp._prevX = entry.instance.x
					comp._prevY = entry.instance.y
				end
			end
		end
	end

	for _, entry in ipairs(objects) do
		if entry.instance and entry.instance.update then
			for _, comp in ipairs(entry.instance.components or {}) do
				if comp.type == "control" then
					if comp.mouseControl and isMouseDown then
						comp:setMousePosition(worldX, worldY)
					else
						comp.mouseX, comp.mouseY = nil, nil
					end
				end
			end
			entry.instance:update(dt)
		end
	end

	-- Update camera from scroll_to component
	if scrollToComp then
		scrollToComp:update(dt)
	end
	updateCamera()

	AttackSystem.update(dt, dynamicObjects)
	ParticleEmitter.updateBursts(dt)

	local shakeComp = nil
	if weaponSprite then
		for _, comp in ipairs(weaponSprite.components or {}) do
			if comp.type == "shake" then
				shakeComp = comp
				break
			end
		end
	end
	if shakeComp and shakeComp.active then
		shakeOffsetX = shakeComp.offsetX
		shakeOffsetY = shakeComp.offsetY
	else
		shakeOffsetX = 0
		shakeOffsetY = 0
	end

	local spawned = PropSpawner.update(dt)
	if spawned then
		table.insert(objects, { instance = spawned, data = {} })
		table.insert(dynamicObjects, { instance = spawned, data = {} })
	end
end
