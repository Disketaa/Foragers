local World = require("Content.Data.World") or {}
local Options = require("Content.Data.Options") or {}

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Generator = require("Source.World.Generator")
local Canvas = require("Source.Helpers.Canvas")
local ShaderLoader = require("Source.Helpers.ShaderLoader")
local ModLoader = require("Source.Helpers.ModLoader")

local objects = {}
local canvas = Canvas.new(480, 270, "outer")
local cursorSprite = nil
local cameraX = 0
local cameraY = 0
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
		return worldPixelWidth / 2, worldPixelHeight / 2
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

	objects = SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition) or {}

	-- Insert world tiles at the beginning of objects list (drawn behind characters)
	ShaderLoader.loadAll("Content/Assets/Shaders")

	local worldData = Generator.generate()
	local tileCount = 0
	for _, entry in
		ipairs(Generator.buildWorldSprites(worldData, function(data)
			return data.x, data.y
		end))
	do
		table.insert(objects, 1, entry)
		tileCount = tileCount + 1
	end
	-- Spawn props on tiles (between tiles and characters in draw order)
	local propEntries = Generator.spawnProps(worldData) or {}
	for _, entry in ipairs(propEntries) do
		table.insert(objects, tileCount + 1, entry)
		tileCount = tileCount + 1
	end

	-- Load and link tools to the player
	local toolEntries = SpriteLoader.loadAll("Content/Assets/Sprites/Tools", function()
		return 0, 0
	end) or {}
	local playerSprite = nil
	for _, entry in ipairs(objects) do
		if entry.data and entry.data.object == "player" then
			playerSprite = entry.instance
			break
		end
	end
	if playerSprite then
		for _, entry in ipairs(toolEntries) do
			for _, comp in ipairs(entry.instance.components or {}) do
				if comp.type == "follow" and comp.setFollowTarget then
					comp:setFollowTarget(playerSprite)
				end
			end
			table.insert(objects, entry)
		end
	end

	updateCamera()

	local mods = ModLoader.loadAllMods("Mods")
	ModLoader.reloadAll(mods)

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

function love.draw()
	canvas:draw(function()
		ShaderLoader.drawBackground(canvas.width, canvas.height)

		love.graphics.push()
		love.graphics.translate(cameraX, cameraY)

		for _, entry in ipairs(objects) do
			if entry.instance and entry.instance.draw then
				entry.instance:draw()
			end
		end

		if cursorSprite and cursorSprite.instance then
			local mx, my = love.mouse.getPosition()
			local cx = (mx - canvas.offsetX) / canvas.scale
			local cy = (my - canvas.offsetY) / canvas.scale
			cursorSprite.instance.x = cx - cameraX
			cursorSprite.instance.y = cy - cameraY
			cursorSprite.instance:draw()
		end

		love.graphics.pop()
	end, World.backgroundColor)
end

function love.keypressed(key)
	if key == "f11" then
		local fullscreen, fstype = love.window.getFullscreen()
		love.window.setFullscreen(not fullscreen, fstype)
	end
end

local function screenToWorld(screenX, screenY)
	local cx = (screenX - canvas.offsetX) / canvas.scale
	local cy = (screenY - canvas.offsetY) / canvas.scale
	return cx - cameraX, cy - cameraY
end

function love.update(dt)
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
end
