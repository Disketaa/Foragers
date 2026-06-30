local Config = require("Content.Data.Config") or {}

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

local SpriteLoader = require("Source.SpriteLoader")
local Canvas = require("Source.Canvas")

local objects = {}
local canvas = Canvas.new(480, 270)

local function getSpawnPosition(data)
	if data.tag == "player" then
		return canvas.width / 2, canvas.height / 2
	end
	return 0, 0
end

local function reloadConfig()
	package.loaded["Content.Data.Config"] = nil
	local newConfig = require("Content.Data.Config")
	if newConfig then
		Config = newConfig
		local bg = Config.backgroundColor or { 0.5, 0.8, 1.0 }
		love.graphics.setBackgroundColor(unpack(bg))
	end
end

function love.load()
	print("Love2D project started")
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.window.setMode(canvas.width, canvas.height, { resizable = true })
	local bg = Config.backgroundColor or { 0.5, 0.8, 1.0 }
	love.graphics.setBackgroundColor(unpack(bg))
	objects = SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition) or {}
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
	end)
end

function love.keypressed(key)
	if key == "f1" then
		reloadConfig()
		print("Config reloaded")
	elseif key == "f2" then
		objects = SpriteLoader.reload(objects, "Content/Assets/Sprites/Character", getSpawnPosition) or {}
		print("Sprites reloaded")
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
				if comp.type == "Controllable" then
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
