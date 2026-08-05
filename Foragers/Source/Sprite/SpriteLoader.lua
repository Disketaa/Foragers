local Sprite = require("Source.Sprite.Sprite")
local ComponentRegistry = require("Source.Helpers.ComponentRegistry")
local Merge = require("Source.Helpers.Merge")
local Path = require("Source.Helpers.Path")
local ValueParser = require("Source.Helpers.ValueParser")

local SpriteLoader = {}

--- Turn a data table into a live Sprite. Handles field copy, component creation,
--- and PNG loading. Used by loadAll(), WorldBuilder.instantiateProp() and Drop.
---@param data table
---@param x number
---@param y number
---@param pngPath string|nil
---@return table
function SpriteLoader.instantiate(data, x, y, pngPath)
	ValueParser.table(data)
	local sprite = Sprite.new(x, y)
	sprite.frameWidth = data.frameWidth
	sprite.frameHeight = data.frameHeight
	sprite.pivotX = data.pivotX
	sprite.pivotY = data.pivotY
	sprite.sortOffsetY = data.sortOffsetY or 0
	sprite.layer = data.layer or 0
	sprite.object = data.object

	-- Copy angle, re-rolling per instance if raw string exists
	if data.__raw and data.__raw.angle then
		sprite.angle = ValueParser.value(data.__raw.angle)
	else
		sprite.angle = data.angle
	end

	for _, compData in ipairs(data.components or {}) do
		if type(compData) == "table" then
			compData.frameWidth = sprite.frameWidth
			compData.frameHeight = sprite.frameHeight
			compData.pivotX = sprite.pivotX
			compData.pivotY = sprite.pivotY
			if compData.component == "spritesheet" and pngPath then
				compData.spriteSheet = pngPath
			end
			local component = ComponentRegistry.create(compData.component, compData)
			if component then
				if compData.__raw then
					component.__raw = compData.__raw
				end
				sprite:addComponent(component)
			end
		end
	end

	if pngPath then
		local pngInfo = love.filesystem.getInfo(pngPath)
		if pngInfo then
			local ok, image = pcall(function()
				return love.graphics.newImage(pngPath)
			end)
			if ok then
				sprite.image = image
				if not next(data.components or {}) then
					sprite.type = "StaticSprite"
				end
			end
		end
	end

	return sprite
end

---@param assetsPath string
---@param spawnCallback function|nil
---@return table[]
function SpriteLoader.loadAll(assetsPath, spawnCallback)
	local objects = {}

	Path.scanDirectory(assetsPath, function(fullPath, item)
		if not item:match("^_") then
			local luaPath = Path.lua(fullPath)
			local success, data = pcall(require, luaPath)
			if success and type(data) == "table" then
				if data.extends then
					data = Merge.resolveExtends(data)
				end

				local pngPath = Path.png(fullPath)
				local sprite = SpriteLoader.instantiate(data, 0, 0, pngPath)

				if spawnCallback then
					local x, y = spawnCallback(data)
					if x then
						sprite.x = x
					end
					if y then
						sprite.y = y
					end
				end

				table.insert(objects, { path = fullPath, data = data, instance = sprite })
			end
		end
	end)

	return objects
end

return SpriteLoader
