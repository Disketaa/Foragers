local Sprite = require("Source.Sprite.Sprite")
local ComponentRegistry = require("Source.Helpers.ComponentRegistry")

local SpriteLoader = {}

---@param assetsPath string
---@param spawnCallback function|nil
---@return table[]
function SpriteLoader.loadAll(assetsPath, spawnCallback)
	local objects = {}

	local function scan(path)
		local items = love.filesystem.getDirectoryItems(path)
		if not items then
			return
		end

		for _, item in ipairs(items) do
			local fullPath = path .. "/" .. item
			local info = love.filesystem.getInfo(fullPath)

			if info and info.type == "directory" then
				scan(fullPath)
			elseif item:match("%.lua$") then
				local luaPath = fullPath:gsub("^/", ""):gsub("/", "."):gsub("%.lua$", "")
				local success, data = pcall(require, luaPath)
				if success and type(data) == "table" then
					local obj = Sprite.new(0, 0)
					obj.frameWidth = data.frameWidth
					obj.frameHeight = data.frameHeight
					obj.pivotX = data.pivotX
					obj.pivotY = data.pivotY
					obj.sortOffsetY = data.sortOffsetY or 0
					obj.layer = data.layer or 0

					for _, compData in ipairs(data.components or {}) do
						if type(compData) == "table" then
							compData.frameWidth = obj.frameWidth
							compData.frameHeight = obj.frameHeight
							compData.pivotX = obj.pivotX
							compData.pivotY = obj.pivotY
							local component = ComponentRegistry.create(compData.component, compData)
							if component then
								obj:addComponent(component)
							end
						end
					end

					local pngPath = fullPath:gsub("%.lua$", ".png")
					local pngInfo = love.filesystem.getInfo(pngPath)
					if pngInfo then
						local ok, image = pcall(function() return love.graphics.newImage(pngPath) end)
						if ok then
							obj.image = image
							if not next(data.components or {}) then
								obj.type = "StaticSprite"
							end
						end
					end

					if spawnCallback then
						local x, y = spawnCallback(data)
						if x then
							obj.x = x
						end
						if y then
							obj.y = y
						end
					end

					table.insert(objects, { path = fullPath, data = data, instance = obj })
					package.loaded[luaPath] = nil
				end
			end
		end
	end

	scan(assetsPath)
	return objects
end

return SpriteLoader
