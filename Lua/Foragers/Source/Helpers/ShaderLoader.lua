local Path = require("Source.Helpers.Path")

local ShaderLoader = {
	shaders = {},
	time = 0,
	cameraX = 0,
	cameraY = 0,
}

function ShaderLoader.loadAll(basePath)
	ShaderLoader.shaders = {}

	local function scan(path)
		local items = love.filesystem.getDirectoryItems(path)

		for _, item in ipairs(items) do
			local fullPath = path .. "/" .. item
			local info = love.filesystem.getInfo(fullPath)
			if info and info.type == "directory" then
				scan(fullPath)
			elseif item:match("%.lua$") then
				local luaPath = Path.lua(fullPath)
				local success, data = pcall(require, luaPath)
				if success and type(data) == "table" and data.code then
					local ok, shader = pcall(love.graphics.newShader, data.code)
					if ok then
						table.insert(ShaderLoader.shaders, {
							name = data.name or Path.lua(item),
							applies_to = data.applies_to or "unknown",
							priority = data.priority or "background",
							uniforms = data.uniforms or {},
							shader = shader,
							luaPath = luaPath,
						})
					end
				end
			end
		end
	end

	scan(basePath)
end

function ShaderLoader.loadByName(name)
	for _, s in ipairs(ShaderLoader.shaders or {}) do
		if s.name == name then
			return s
		end
	end
	return nil
end

function ShaderLoader.update(dt)
	ShaderLoader.time = ShaderLoader.time + dt
end

function ShaderLoader.setCamera(x, y)
	ShaderLoader.cameraX = x
	ShaderLoader.cameraY = y
end

function ShaderLoader.drawBackground(canvasWidth, canvasHeight)
	for _, s in ipairs(ShaderLoader.shaders or {}) do
		if s.applies_to == "screen" and s.priority == "background" then
			s.shader:send("time", ShaderLoader.time)
			-- Send camera uniforms if shader declares them (pcall to avoid error on missing uniform)
			pcall(function()
				s.shader:send("camera_x", ShaderLoader.cameraX)
			end)
			pcall(function()
				s.shader:send("camera_y", ShaderLoader.cameraY)
			end)
			for name, value in pairs(s.uniforms) do
				s.shader:send(name, value)
			end
			love.graphics.setShader(s.shader)
			love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)
			love.graphics.setShader()
		end
	end
end

return ShaderLoader
