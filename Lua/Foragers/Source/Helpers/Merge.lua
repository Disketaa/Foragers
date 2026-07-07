local Log = require("Source.Helpers.Log")

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
	return comp.component .. ":" .. (comp.mergeKey or "")
end

--- Merge data.components with inheritance: match by component key.
--- Arrays (component lists) are matched and deep-merged by key.
--- Components in `overrideComponents` with `_remove = true` delete the base entry.
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
		if comp._remove then
			byKey[key] = nil
		elseif byKey[key] then
			byKey[key] = Merge.merge(byKey[key], comp)
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
