local Config = require("Content.Data.Config")
local SpriteLoader = require("Source.SpriteLoader")

local objects

local function reloadConfig()
	package.loaded["Content.Data.Config"] = nil
	Config = require("Content.Data.Config")
	love.window.setMode(Config.window.width, Config.window.height, { resizable = Config.window.resizable })
	love.graphics.setBackgroundColor(unpack(Config.backgroundColor))
end

local function getSpawnPosition(data)
	if data.tag == "player" then
		return Config.window.width / 2, Config.window.height / 2
	end
	return 0, 0
end

function love.load()
	print("Love2D project started")
	love.window.setMode(Config.window.width, Config.window.height, { resizable = Config.window.resizable })
	love.graphics.setBackgroundColor(unpack(Config.backgroundColor))

	objects = SpriteLoader.loadAll("Content/Assets/Sprites/Character", getSpawnPosition)
end

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

function love.update(dt)
	for _, entry in ipairs(objects) do
		entry.instance:update(dt)
	end
end

function love.draw()
	for _, entry in ipairs(objects) do
		entry.instance:draw()
	end
end
