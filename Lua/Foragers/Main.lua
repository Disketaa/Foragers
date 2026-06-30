-- Game entry point. Initializes systems and handles LÖVE callbacks.
local Config = require("Content.Data.Config") or {}

-- Debugger integration - must be early
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

local SpriteLoader = require("Source.SpriteLoader")
local Canvas = require("Source.Canvas")

local objects = {}
local canvas = Canvas.new(480, 270)

-- Returns spawn position based on data.tag.
-- "player" spawns at screen center, others at (0, 0).
local function getSpawnPosition(data)
	if data.tag == "player" then
		return canvas.width / 2, canvas.height / 2
	end
	return 0, 0
end

-- Reloads Config.lua and applies background color.
local function reloadConfig()
	package.loaded["Content.Data.Config"] = nil
	local newConfig = require("Content.Data.Config")
	if newConfig then
		Config = newConfig
		local bg = Config.backgroundColor or { 0.5, 0.8, 1.0 }
		love.graphics.setBackgroundColor(unpack(bg))
	end
end

-- Initializes window, loads sprites, sets background.
function love.load()
	print("Love2D project started")
	-- Set nearest filter for all images to prevent blur on scale
	-- See graphics/functions/setDefaultFilter.md for filter modes
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.window.setMode(canvas.width, canvas.height, { resizable = true })
	local bg = Config.backgroundColor or { 0.5, 0.8, 1.0 }
	love.graphics.setBackgroundColor(unpack(bg))
	objects = SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition) or {}
end

-- Integer scale outer: calculate scale and offset based on window size
function love.resize(w, h)
	canvas:resize(w, h)
end

-- Draws to canvas with nearest filtering for pixel-perfect upscale
function love.draw()
	canvas:draw(function()
		for _, entry in ipairs(objects) do
			if entry.instance and entry.instance.draw then
				entry.instance:draw()
			end
		end
	end)
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
