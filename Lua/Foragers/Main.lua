-- Game entry point. Initializes systems and handles LÖVE callbacks.
local Config = require("Content.Data.Config")
local SpriteLoader = require("Source.SpriteLoader")

local objects = {}

-- Returns spawn position based on data.tag.
-- "player" spawns at screen center, others at (0, 0).
-- Used as callback in SpriteLoader.loadAll.
local function getSpawnPosition(data)
	if data.tag == "player" then
		return Config.window.width / 2, Config.window.height / 2
	end
	return 0, 0
end

-- Reloads Config.lua and applies window settings.
-- If config fails to load, keeps previous values.
local function reloadConfig()
	package.loaded["Content.Data.Config"] = nil
	local newConfig = require("Content.Data.Config")
	if not newConfig then return end
	Config = newConfig
	local w = Config.window or {}
	local bg = Config.backgroundColor or { 0.5, 0.8, 1.0 }
	love.window.setMode(w.width or 640, w.height or 360, { resizable = w.resizable })
	love.graphics.setBackgroundColor(unpack(bg))
end

-- Reloads Config.lua and applies window settings.
function love.load()
	print("Love2D project started")
	love.window.setMode(Config.window.width, Config.window.height, { resizable = Config.window.resizable })
	love.graphics.setBackgroundColor(unpack(Config.backgroundColor))

	objects = SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition)
end

-- Hot-reloads Config.lua on F1.
-- Hot-reloads sprites on F2.
function love.keypressed(key)
	if key == "f1" then
		reloadConfig()
		print("Config reloaded")
	end
	if key == "f2" then
		objects = SpriteLoader.reload(objects, "Content/Assets/Sprites/Character", getSpawnPosition)
		print("Sprites reloaded")
	end
end

-- Updates all game objects.
function love.update(dt)
	for _, entry in ipairs(objects) do
		entry.instance:update(dt)
	end
end

-- Draws all game objects.
function love.draw()
	for _, entry in ipairs(objects) do
		entry.instance:draw()
	end
end
