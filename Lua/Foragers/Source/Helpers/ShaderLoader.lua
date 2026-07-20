local Path = require("Source.Helpers.Path")
local Log = require("Source.Helpers.Log")

local ShaderLoader = {
	shaders = {},
	modules = {},
	time = 0,
	cameraX = 0,
	cameraY = 0,
}

function ShaderLoader.loadAll(basePath)
	ShaderLoader.shaders = {}
	ShaderLoader.modules = {}

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
				if success and type(data) == "table" and data.name then
					if data.module then
						-- building block, not a standalone shader
						ShaderLoader.modules[data.name] = data
					elseif data.modules then
						-- pre-declared program: compose listed modules
						local entry = ShaderLoader._compileProgram(data.modules, data)
						if entry then
							table.insert(ShaderLoader.shaders, entry)
						end
					elseif data.code then
						-- legacy standalone shader
						local ok, shader = pcall(love.graphics.newShader, data.code)
						if ok then
							table.insert(ShaderLoader.shaders, {
								name = data.name,
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
	end

	scan(basePath)
end

-- Build a composed shader from a list of module names. Cached by joined name.
function ShaderLoader.compose(names)
	local key = "prog_" .. table.concat(names, "_")
	for _, s in ipairs(ShaderLoader.shaders) do
		if s.name == key then
			return s
		end
	end

	local ok, entry = pcall(function()
		return ShaderLoader._compileProgram(names, {})
	end)
	if ok and entry then
		table.insert(ShaderLoader.shaders, entry)
		return entry
	end
	if not ok then
		Log.error(string.format("ShaderLoader compose(%s) FAILED: %s", table.concat(names, ","), tostring(entry)))
	end
	return nil
end

function ShaderLoader._compileProgram(names, meta)
	local bodies = {}
	local uniforms = {}
	local uvChain = {}
	local colorChain = {}
	for _, name in ipairs(names) do
		local mod = ShaderLoader.modules[name]
		if not mod then
			return nil
		end
		table.insert(bodies, mod.code)
		for u, v in pairs(mod.uniforms or {}) do
			uniforms[u] = v
		end
		if mod.type == "uv" then
			table.insert(uvChain, name)
		else
			table.insert(colorChain, name)
		end
	end
	for u, v in pairs(meta.uniforms or {}) do
		uniforms[u] = v
	end

	-- LÖVE does NOT auto-declare uniforms; each must be an `extern` in the source.
	local decls = {}
	for u, v in pairs(uniforms) do
		local typ = "float"
		if type(v) == "table" then
			typ = "vec" .. #v
		end
		table.insert(decls, string.format("extern %s %s;", typ, u))
	end

	-- Pipeline: uv modifiers -> single Texel -> color modifiers
	local uvCalls = {}
	for _, name in ipairs(uvChain) do
		table.insert(uvCalls, string.format("	uv = %s_uv(uv, screen_coords);", name))
	end
	local colorCalls = {}
	for _, name in ipairs(colorChain) do
		table.insert(colorCalls, string.format("	color = %s_color(color);", name))
	end

	local effectHeader = "\nvec4 effect(vec4 color, Image texture, vec2 tex_coords, vec2 screen_coords) {\n"
	local code = table.concat(decls, "\n")
		.. "\n"
		.. table.concat(bodies, "\n")
		.. effectHeader
		.. "	vec2 uv = tex_coords;\n"
		.. table.concat(uvCalls, "\n")
		.. "\n"
		.. "	vec4 sampled = Texel(texture, uv);\n"
		-- effect() already declares `color` as a parameter; redeclaring `vec4 color`
		-- here is a GLSL redefinition error, so assign into the existing parameter.
		.. "	color = sampled;\n"
		.. table.concat(colorCalls, "\n")
		.. "\n"
		.. "	return color;\n}\n"

	local shader = love.graphics.newShader(code)
	return {
		name = meta.name or ("prog_" .. table.concat(names, "_")),
		applies_to = meta.applies_to or "sprite",
		priority = meta.priority or "foreground",
		uniforms = uniforms,
		shader = shader,
		luaPath = meta.luaPath,
	}
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
