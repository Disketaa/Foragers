local Path = require("Source.Helpers.Core.Path")
local Log = require("Source.Helpers.Core.Log")

local ShaderLoader = {
	shaders = {},
	modules = {},
	time = 0,
	cameraX = 0,
	cameraY = 0,
	postProcessEnabled = true,
}
local screenOrigin = { 0, 0 }
local screenSize = { 0, 0 }

function ShaderLoader.loadAll(basePath)
	ShaderLoader.shaders = {}
	ShaderLoader.modules = {}
	local postprocess = {}
	Path.scanDirectory(basePath, function(fullPath)
		local luaPath = Path.lua(fullPath)
		local success, data = pcall(require, luaPath)
		if success and type(data) == "table" and data.name then
			if data.module then
				-- building block, not a standalone shader
				ShaderLoader.modules[data.name] = data
				if data.postprocess then
					table.insert(postprocess, { name = data.name, order = data.order or 0 })
				end
			elseif data.code then
				-- legacy standalone shader
				local ok, shader = pcall(love.graphics.newShader, data.code)
				if ok then
					-- Push data-file uniform defaults at creation so the GPU state
					-- matches the Lua default (LOVE initializes new uniforms to 0),
					-- independent of any later reset() timing.
					for u, v in pairs(data.uniforms or {}) do
						shader:send(u, v)
					end
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
	end)
	-- Stack every module flagged `postprocess` into ONE screen pass. Explicit
	-- `order` (tie-broken by name) keeps effect order controllable and stable.
	table.sort(postprocess, function(a, b)
		if a.order == b.order then
			return a.name < b.name
		end
		return a.order < b.order
	end)
	local names = {}
	for _, p in ipairs(postprocess) do
		table.insert(names, p.name)
	end
	if #names > 0 then
		local entry = ShaderLoader._compileProgram(names, {
			name = "ScreenPost",
			priority = "postprocess",
		})
		if entry then
			table.insert(ShaderLoader.shaders, entry)
		end
	end
end

-- Build a composed shader from a list of module names. Cached by joined name.
function ShaderLoader.compose(names)
	local key = "prog_" .. table.concat(names, "_")
	for _, s in ipairs(ShaderLoader.shaders) do
		if s.name == key then
			return s
		end
	end

	local ok, entry = pcall(function() return ShaderLoader._compileProgram(names, {}) end)
	if ok and entry then
		table.insert(ShaderLoader.shaders, entry)
		return entry
	end
	if not ok then
		Log.error("ShaderLoader", "compose(%s) FAILED: %s", table.concat(names, ","), tostring(entry))
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

	-- LOVE does NOT auto-declare uniforms; each must be an extern in the source.
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
		table.insert(colorCalls, string.format("	color = %s_color(color, screen_coords);", name))
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
		.. "	color = sampled;\n"
		.. table.concat(colorCalls, "\n")
		.. "\n"
		.. "	return color;\n}\n"

	local shader = love.graphics.newShader(code)
	-- Push composed defaults at creation so the GPU uniform state matches the
	-- Lua default (LOVE initializes new uniforms to 0), covering post-process
	-- programs universally without a separate reset() timing step.
	for u, v in pairs(uniforms) do
		shader:send(u, v)
	end
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

--- Restore every loaded shader to its data-file defaults. Reset.all() clears
--- array module fields only, so time (number) and externally-driven uniforms
--- (e.g. u_saturation) survive a restart — this restores both per entry.
--- Any shader declaring `uniforms` resets automatically.
function ShaderLoader.reset()
	ShaderLoader.time = 0
	for _, s in ipairs(ShaderLoader.shaders or {}) do
		for name, value in pairs(s.uniforms) do
			s.shader:send(name, value)
		end
	end
end

function ShaderLoader.update(dt)
	ShaderLoader.time = ShaderLoader.time + dt
	-- Broadcast the clock to any module that declares a u_noiseTime uniform
	-- (the Noise post-process grain). sendUniform targets only shaders that
	-- declare the uniform, so this stays decoupled from specific effects.
	ShaderLoader.sendUniform("u_noiseTime", ShaderLoader.time)
end

--- The screen post-process program. loadAll composes every module flagged
--- `postprocess` into exactly one entry with this priority, so the first
--- match IS the program — callers rely on the single-slot invariant. Returns nil
--- while disabled so callers can't accidentally keep applying it (e.g. on death).
function ShaderLoader.getPostProcess()
	if not ShaderLoader.postProcessEnabled then
		return nil
	end
	for _, s in ipairs(ShaderLoader.shaders or {}) do
		if s.priority == "postprocess" then
			return s.shader
		end
	end
	return nil
end

--- Master switch for the screen post-process (saturation, circle mask). Turned
--- off on death so the death screen is plain; callers pass getPostProcess()
--- unconditionally and it just returns nil.
function ShaderLoader.setPostProcessEnabled(enabled)
	ShaderLoader.postProcessEnabled = enabled
end

--- Send a uniform to every shader that declares it, so dynamic values
--- (saturation from player state) need no shader name at the call site.
function ShaderLoader.sendUniform(name, value)
	for _, s in ipairs(ShaderLoader.shaders or {}) do
		if s.uniforms[name] ~= nil then
			s.shader:send(name, value)
		end
	end
end

function ShaderLoader.setCamera(x, y)
	ShaderLoader.cameraX = x
	ShaderLoader.cameraY = y
end

--- Share the canvas->screen blit transform (blit scale x output zoom, zoom-pivoted
--- origin) with every screen effect that declares u_canvasScale/u_canvasOrigin.
--- Main calls this once per frame; effects sampling in canvas pixels need it.
--- The origin table is reused, not allocated per frame.
function ShaderLoader.setScreenTransform(scale, originX, originY, canvasWidth, canvasHeight)
	screenOrigin[1] = originX
	screenOrigin[2] = originY
	screenSize[1] = canvasWidth or 1
	screenSize[2] = canvasHeight or 1
	ShaderLoader.sendUniform("u_canvasScale", scale)
	ShaderLoader.sendUniform("u_canvasOrigin", screenOrigin)
	ShaderLoader.sendUniform("u_canvasSize", screenSize)
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
