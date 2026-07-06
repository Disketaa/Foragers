local World = require("Content.Data.World") or {}
local Options = require("Content.Data.Options") or {}

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

local Sprite = require("Source.Sprite.Sprite")
local SpriteLoader = require("Source.Sprite.SpriteLoader")
local WorldGen = require("Source.World.WorldGen")
local WorldBuilder = require("Source.World.WorldBuilder")
local Canvas = require("Source.Helpers.Canvas")
local ShaderLoader = require("Source.Helpers.ShaderLoader")
local ModLoader = require("Source.Helpers.ModLoader")
local DrawOrder = require("Source.Helpers.DrawOrder")
local AttackSystem = require("Source.Helpers.AttackSystem")
local ComponentRegistry = require("Source.Helpers.ComponentRegistry")
local Destructible = require("Source.Sprite.Components.Destructible")
local Collision = require("Source.Sprite.Components.Collision")
local ParticleEmitter = require("Source.Sprite.Components.ParticleEmitter")
local ProximityFade = require("Source.Sprite.Components.ProximityFade")

local objects = {}
local staticObjects = {}
local dynamicObjects = {}
local canvas = Canvas.new(480, 270, "outer")
local cursorSprite = nil
local cameraX = 0
local cameraY = 0
local weaponSprite = nil
local shakeOffsetX = 0
local shakeOffsetY = 0
local tileSize = 8
local worldPixelWidth = World.width * tileSize
local worldPixelHeight = World.height * tileSize

local function updateCamera()
	-- integer translate only: fractional causes sub-pixel gaps with nearest filtering
	cameraX = math.floor((canvas.width - worldPixelWidth) / 2)
	cameraY = math.floor((canvas.height - worldPixelHeight) / 2)
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
	local tileEntries = WorldBuilder.buildWorldSprites(worldData, function(data)
		return data.x, data.y
	end)
	local propEntries = WorldBuilder.spawnProps(worldData) or {}
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

	-- Link tools to the player
	local playerSprite = nil
	for _, entry in ipairs(objects) do
		if entry.data and entry.data.object == "player" then
			playerSprite = entry.instance
			break
		end
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
		AttackSystem.registerAttacker(playerSprite, toolEntries[1] and toolEntries[1].instance)
		weaponSprite = toolEntries[1] and toolEntries[1].instance
	end

	updateCamera()

	ModLoader.loadAllMods("Mods")

	cursorSprite = SpriteLoader.loadAll("Content/Assets/Sprites/UI", function(data)
		return 0, 0
	end)[1]
	if cursorSprite and cursorSprite.instance then
		love.mouse.setVisible(false)
	end
end

function love.resize(w, h)
	canvas:resize(w, h)
	updateCamera()
end

local function screenToWorld(screenX, screenY)
	local cx = (screenX - canvas.offsetX) / canvas.scale
	local cy = (screenY - canvas.offsetY) / canvas.scale
	return cx - cameraX, cy - cameraY
end

function love.draw()
	canvas:draw(function()
		ShaderLoader.drawBackground(canvas.width, canvas.height)

		love.graphics.push()
		love.graphics.translate(cameraX, cameraY)

		-- Static terrain (pre-ordered by generation — no sorting needed)
		for _, entry in ipairs(staticObjects) do
			if entry.instance and entry.instance.draw then
				entry.instance:draw()
			end
		end

		-- Orphan particles behind dynamic sprites (terrain-aligned: dust, sparks near ground)
		ParticleEmitter.drawOrphans(true)

		-- Dynamic sprites: collect, sort by zKey, draw
		local sorted = DrawOrder.collect(dynamicObjects)
		DrawOrder.sort(sorted)
		for _, sprite in ipairs(sorted) do
			sprite:draw()
		end

		-- Orphan particles on top of everything
		ParticleEmitter.drawOrphans(false)

		if cursorSprite and cursorSprite.instance then
			local mx, my = love.mouse.getPosition()
			local wx, wy = screenToWorld(mx, my)
			cursorSprite.instance.x = wx
			cursorSprite.instance.y = wy
			cursorSprite.instance:draw()
		end

		love.graphics.pop()
	end, World.backgroundColor, shakeOffsetX, shakeOffsetY)
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
			local luaPath = sprite._replaceWith:gsub("[/\\]", "."):gsub("%.lua$", "")
			local ok, morphData = pcall(require, luaPath)
			if ok and morphData then
				local newSprite = Sprite.new(sprite.x, sprite.y)
				newSprite.flipX = sprite.flipX
				newSprite.frameWidth = morphData.frameWidth
				newSprite.frameHeight = morphData.frameHeight
				newSprite.pivotX = morphData.pivotX
				newSprite.pivotY = morphData.pivotY
				newSprite.sortOffsetY = morphData.sortOffsetY or 0
				newSprite.layer = morphData.layer or 0

				local hasSpritesheet = false
				for _, cd in ipairs(morphData.components or {}) do
					if cd.component == "spritesheet" then
						hasSpritesheet = true
						local comp = ComponentRegistry.create("spritesheet", cd)
						if comp then
							local numFrames = cd.columns or 1
							comp:setFrame(love.math.random(0, numFrames - 1))
							newSprite:addComponent(comp)
						end
					elseif cd.component == "collision" then
						local comp = ComponentRegistry.create("collision", cd)
						if comp then
							newSprite:addComponent(comp)
							if comp.mode == "slowdown" then
								comp:registerAsSlowdown()
							else
								comp:registerAsSolid()
							end
						end
					else
						local comp = ComponentRegistry.create(cd.component, cd)
						if comp then
							newSprite:addComponent(comp)
						end
					end
				end

				if not hasSpritesheet then
					local pngPath = sprite._replaceWith .. ".png"
					local pngInfo = love.filesystem.getInfo(pngPath)
					if pngInfo then
						newSprite.image = love.graphics.newImage(pngPath)
					end
					newSprite.type = "StaticSprite"
				end

				table.insert(objects, { instance = newSprite, data = morphData })
				table.insert(dynamicObjects, { instance = newSprite, data = morphData })
			end
		end
		Collision.removeSpriteColliders(sprite)
		removeSpriteFromLists(sprite)
	end
	Destructible.clearDead()

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

	AttackSystem.update(dt, dynamicObjects)
	ParticleEmitter.updateOrphans(dt)

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
end
