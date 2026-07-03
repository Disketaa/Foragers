local ShaderLoader = {
	shaders = {},
	time = 0,
}

function ShaderLoader.loadAll(basePath)
	ShaderLoader.shaders = {}

	local function scan(path)
		local items = love.filesystem.getDirectoryItems(path)
		if not items then return end

		for _, item in ipairs(items) do
			local fullPath = path .. "/" .. item
			local info = love.filesystem.getInfo(fullPath)
			if info and info.type == "directory" then
				scan(fullPath)
			elseif item:match("%.lua$") then
				local luaPath = fullPath:gsub("^/", ""):gsub("/", "."):gsub("%.lua$", "")
				local success, data = pcall(require, luaPath)
				if not success or type(data) ~= "table" or not data.code then
					package.loaded[luaPath] = nil
					return
				end

				local ok, shader = pcall(love.graphics.newShader, data.code)
				if not ok then
					package.loaded[luaPath] = nil
					return
				end

				table.insert(ShaderLoader.shaders, {
					name = data.name or item:gsub("%.lua$", ""),
					applies_to = data.applies_to or "unknown",
					priority = data.priority or "background",
					uniforms = data.uniforms or {},
					shader = shader,
					luaPath = luaPath,
				})
				package.loaded[luaPath] = nil
			end
		end
	end

	scan(basePath)
end

function ShaderLoader.getByAppliesTo(appliesTo)
	local result = {}
	for _, s in ipairs(ShaderLoader.shaders or {}) do
		if s.applies_to == appliesTo then
			table.insert(result, s)
		end
	end
	return result
end

function ShaderLoader.update(dt)
	ShaderLoader.time = ShaderLoader.time + dt
end

function ShaderLoader.drawBackground(canvasWidth, canvasHeight)
	for _, s in ipairs(ShaderLoader.shaders or {}) do
		if s.applies_to == "screen" and s.priority == "background" then
			s.shader:send("time", ShaderLoader.time)
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