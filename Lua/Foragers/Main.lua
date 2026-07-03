local Config = require("Content.Data.Config") or {}
local Options = require("Content.Data.Options") or {}

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Generator = require("Source.World.Generator")
local Canvas = require("Source.Canvas")

local objects = {}
local canvas = Canvas.new(480, 270)
local cursorSprite = nil

local function getSpawnPosition(data)
	if data.object == "player" then
		return canvas.width / 2, canvas.height / 2
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
	local bg = Config.backgroundColor or { 0.5, 0.8, 1.0 }
	love.graphics.setBackgroundColor(unpack(bg))

	objects = SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition) or {}

	-- Insert world tiles at the beginning of objects list (drawn behind characters)
	local worldData = Generator.generate()
	for _, entry in
		ipairs(Generator.buildWorldSprites(worldData, canvas.width, canvas.height, function(data)
			return data.x, data.y
		end))
	do
		table.insert(objects, 1, entry)
	end

	cursorSprite = SpriteLoader.loadAll("Content/Assets/Sprites/UI", function(data)
		return 0, 0
	end)[1]
	if cursorSprite and cursorSprite.instance then
		love.mouse.setVisible(false)
	end
end

function love.resize(w, h)
	canvas:resize(w, h)
end

function love.draw()
	canvas:draw(function()
		for _, entry in ipairs(objects) do
			if entry.instance and entry.instance.draw then
				entry.instance:draw()
			end
		end
		if cursorSprite and cursorSprite.instance then
			local mx, my = love.mouse.getPosition()
			local wx = (mx - canvas.offsetX) / canvas.scale
			local wy = (my - canvas.offsetY) / canvas.scale
			cursorSprite.instance.x = wx
			cursorSprite.instance.y = wy
			cursorSprite.instance:draw()
		end
	end)
end

function love.keypressed(key)
	if key == "f11" then
		local fullscreen, fstype = love.window.getFullscreen()
		love.window.setFullscreen(not fullscreen, fstype)
	end
end

local function screenToWorld(screenX, screenY)
	return (screenX - canvas.offsetX) / canvas.scale, (screenY - canvas.offsetY) / canvas.scale
end

function love.update(dt)
	local mouseX, mouseY = love.mouse.getPosition()
	local worldX, worldY = screenToWorld(mouseX, mouseY)
	local isMouseDown = love.mouse.isDown(1)

	for _, entry in ipairs(objects) do
		if entry.instance and entry.instance.update then
			for _, comp in ipairs(entry.instance.components or {}) do
				if comp.type == "controllable" then
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
