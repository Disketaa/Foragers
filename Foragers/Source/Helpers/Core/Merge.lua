local Log = require("Source.Helpers.Core.Log")

local Merge = {}

function Merge._isArray(t)
	return #t > 0
end

function Merge._deepCopy(v)
	if type(v) ~= "table" then
		return v
	end
	local copy = {}
	for k, val in pairs(v) do
		copy[k] = Merge._deepCopy(val)
	end
	return copy
end

--- Deep merge two tables. Arrays (sequence tables) replace entirely.
--- Other tables deep-merge by key. Scalars override.
---@param base table
---@param override table
---@return table
function Merge.merge(base, override)
	local result = {}
	for k, v in pairs(base) do
		result[k] = Merge._deepCopy(v)
	end
	for k, v in pairs(override) do
		if
			type(v) == "table"
			and type(result[k]) == "table"
			and not Merge._isArray(v)
			and not Merge._isArray(result[k])
		then
			result[k] = Merge.merge(result[k], v)
		else
			result[k] = Merge._deepCopy(v)
		end
	end
	return result
end

local function _compKey(comp)
	return comp.component
end

-- Shader component merges its `shaders` array by concatenation (parent first,
-- child appended) so children inherit base shaders plus their own. Each entry
-- may be a string name or a table spec { name=..., u_*=... }. Dedup by name.
local function _mergeShaderShaders(base, override)
	local baseList = base.shaders or (base.shaderName and { base.shaderName } or {})
	local overList = override.shaders or (override.shaderName and { override.shaderName } or {})
	local seen = {}
	local result = {}
	local function add(entry)
		local spec
		if type(entry) == "string" then
			spec = { name = entry }
		elseif entry.name then
			spec = entry
		else
			local name, params = next(entry)
			spec = { name = name }
			if type(params) == "table" then
				for k, v in pairs(params) do
					spec[k] = v
				end
			end
		end
		if not seen[spec.name] then
			seen[spec.name] = true
			table.insert(result, spec)
		end
	end
	for _, entry in ipairs(baseList) do
		add(entry)
	end
	for _, entry in ipairs(overList) do
		add(entry)
	end
	return result
end

--- Merge data.components with inheritance: match by component key.
--- Arrays (component lists) are matched and deep-merged by key.
--- Base order is preserved; new override entries are appended at the end.
---@param baseComponents table[]
---@param overrideComponents table[]
---@return table[]
function Merge.componentMerge(baseComponents, overrideComponents)
	local byKey = {}
	for _, comp in ipairs(baseComponents) do
		byKey[_compKey(comp)] = Merge._deepCopy(comp)
	end
	for _, comp in ipairs(overrideComponents) do
		local key = _compKey(comp)
		if byKey[key] then
			local merged = Merge.merge(byKey[key], comp)
			if comp.component == "shader" then
				merged.shaders = _mergeShaderShaders(byKey[key], comp)
				merged.shaderName = nil
			end
			byKey[key] = merged
		else
			byKey[key] = Merge._deepCopy(comp)
		end
	end
	local result = {}
	for _, comp in ipairs(baseComponents) do
		local key = _compKey(comp)
		if byKey[key] then
			table.insert(result, byKey[key])
			byKey[key] = nil
		end
	end
	for _, comp in pairs(byKey) do
		table.insert(result, comp)
	end
	return result
end

--- Resolve extends chain on a data table. Handles circular extends guard.
---@param data table
---@return table
function Merge.resolveExtends(data)
	local visited = {}
	while data.extends do
		if visited[data.extends] then
			Log.error("Circular extends detected: " .. data.extends)
			break
		end
		visited[data.extends] = true
		local ok, base = pcall(require, data.extends)
		if not ok or type(base) ~= "table" then
			Log.error("Failed to load base module: " .. tostring(data.extends))
			break
		end
		local mergedComponents = Merge.componentMerge(base.components or {}, data.components or {})
		data = Merge.merge(base, data)
		data.components = mergedComponents
		data.extends = base.extends
	end
	return data
end

return Merge
