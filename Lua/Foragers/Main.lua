-- Game entry point. Initializes systems and handles LÖVE callbacks.
local Config = require("Content.Data.Config") or {}
local SpriteLoader = require("Source.SpriteLoader")

local objects = {}

-- Returns spawn position based on data.tag.
-- "player" spawns at screen center, others at (0, 0).
-- Uses Config captured by closure; hot-reload updates via reloadConfig.
local function getSpawnPosition(data)
	local w = Config.window or {}
	if data.tag == "Player" then
		return (w.width or 640) / 2, (w.height or 360) / 2
	end
	return 0, 0
end

-- Reloads Config.lua and applies window settings.
-- If config fails to load, keeps previous values.
local function reloadConfig()
	package.loaded["Content.Data.Config"] = nil
	local newConfig = require("Content.Data.Config")
	if not newConfig then
		return
	end
	Config = newConfig
	local w = Config.window or {}
	local bg = Config.backgroundColor or { 0.5, 0.8, 1.0 }
	love.window.setMode(w.width or 640, w.height or 360, { resizable = w.resizable })
	love.graphics.setBackgroundColor(unpack(bg))
end

-- Initializes window, loads sprites, sets background.
-- Uses Config captured at load time for hot-reload safety.
function love.load()
	print("Love2D project started")
	local w = Config.window or {}
	local bg = Config.backgroundColor or { 0.5, 0.8, 1.0 }
	love.window.setMode(w.width or 640, w.height or 360, { resizable = w.resizable })
	love.graphics.setBackgroundColor(unpack(bg))
	objects = SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition) or {}
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

-- Draws all game object instances.
function love.draw()
	for _, entry in ipairs(objects) do
		if entry.instance and entry.instance.draw then
			entry.instance:draw()
		end
	end
end
