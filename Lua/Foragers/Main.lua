-- Game entry point. Initializes systems and handles LÖVE callbacks.
local Config = require("Content.Data.Config") or {}
local SpriteLoader = require("Source.SpriteLoader")

local objects = {}
local canvasWidth, canvasHeight = 640, 360
local scale, offsetX, offsetY = 1, 0, 0
local canvas

-- Returns spawn position based on data.tag.
-- "player" spawns at screen center, others at (0, 0).
local function getSpawnPosition(data)
	local w = Config.window or {}
	if data.tag == "player" then
		return (w.width or 640) / 2, (w.height or 360) / 2
	end
	return 0, 0
end

-- Recreate canvas with nearest filter for pixel-perfect scaling
local function recreateCanvas()
	if canvas then
		canvas:release()
	end
	canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
	canvas:setFilter("nearest", "nearest")
end

-- Reloads Config.lua and applies window settings.
local function reloadConfig()
	package.loaded["Content.Data.Config"] = nil
	local newConfig = require("Content.Data.Config")
	if newConfig then
		Config = newConfig
		local w = Config.window or {}
		canvasWidth = w.width or 640
		canvasHeight = w.height or 360
		local bg = Config.backgroundColor or { 0.5, 0.8, 1.0 }
		love.graphics.setBackgroundColor(unpack(bg))
		recreateCanvas()
	end
end

-- Initializes window, loads sprites, sets background.
function love.load()
	print("Love2D project started")
	recreateCanvas()
	love.window.setMode(canvasWidth, canvasHeight, { resizable = true })
	local bg = Config.backgroundColor or { 0.5, 0.8, 1.0 }
	love.graphics.setBackgroundColor(unpack(bg))
	objects = SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition) or {}
end

-- Integer scale outer: calculate scale and offset based on window size
-- See window/functions/setMode.md for flags
function love.resize(w, h)
	scale = math.floor(math.min(w / canvasWidth, h / canvasHeight))
	if scale < 1 then
		scale = 1
	end
	offsetX = math.floor((w - canvasWidth * scale) / 2)
	offsetY = math.floor((h - canvasHeight * scale) / 2)
end

-- Draws to canvas with nearest filtering for pixel-perfect upscale
function love.draw()
	-- Draw game to canvas
	love.graphics.setCanvas(canvas)
	love.graphics.clear()
	for _, entry in ipairs(objects) do
		if entry.instance and entry.instance.draw then
			entry.instance:draw()
		end
	end
	love.graphics.setCanvas()

	-- Draw scaled canvas to screen
	love.graphics.draw(canvas, offsetX, offsetY, 0, scale, scale)
end

-- Hot-reloads Config.lua on F1, sprites on F2.
function love.keypressed(key)
	if key == "f1" then
		reloadConfig()
		print("Config reloaded")
	elseif key == "f2" then
		objects = SpriteLoader.reload(objects, "Content/Assets/Sprites/Character", getSpawnPosition) or {}
		print("Sprites reloaded")
	end
end

-- Updates all game object instances.
function love.update(dt)
	for _, entry in ipairs(objects) do
		if entry.instance and entry.instance.update then
			entry.instance:update(dt)
		end
	end
end
