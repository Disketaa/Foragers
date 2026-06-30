local Config = require("Content.Data.Config")
local Sprite = require("Source.Sprite")
local CharacterData = require("Content.Data.Character")

local player
local moveSpeed = 64

local function reloadConfig()
	package.loaded["Content.Data.Config"] = nil
	Config = require("Content.Data.Config")
	love.window.setMode(Config.window.width, Config.window.height, { resizable = Config.window.resizable })
	love.graphics.setBackgroundColor(unpack(Config.backgroundColor))
end

function love.load()
	print("Love2D project started")
	love.window.setMode(Config.window.width, Config.window.height, { resizable = Config.window.resizable })
	love.graphics.setBackgroundColor(unpack(Config.backgroundColor))
	player = {
		x = Config.window.width / 2,
		y = Config.window.height / 2,
		flipX = false,
	}
	player.sprite = Sprite.new(CharacterData)
	print("Sprite: " .. CharacterData.spriteSheet)
end

function love.keypressed(key)
	if key == "f1" then
		reloadConfig()
		print("Config reloaded")
	end
	if key == "f2" then
		package.loaded["Content.Data.Character"] = nil
		local newCharData = require("Content.Data.Character")
		player.sprite = Sprite.new(newCharData)
		player.sprite.flipX = player.flipX
		print("Character data reloaded")
	end
end

function love.update(dt)
	player.sprite:update(dt)
	local moving = false
	if love.keyboard.isDown("w") then player.y = player.y - moveSpeed * dt; moving = true end
	if love.keyboard.isDown("s") then player.y = player.y + moveSpeed * dt; moving = true end
	if love.keyboard.isDown("a") then player.x = player.x - moveSpeed * dt; player.flipX = true; moving = true end
	if love.keyboard.isDown("d") then player.x = player.x + moveSpeed * dt; player.flipX = false; moving = true end
	if moving then
		player.sprite:setAnimation("run")
	else
		player.sprite:setAnimation("idle")
	end
	player.sprite.flipX = player.flipX
end

function love.draw()
	player.sprite:draw(player.x, player.y)
end
