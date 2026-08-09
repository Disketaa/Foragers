--- Universal state reset. Scans every loaded `Source.` module and
--- clears all **array-valued** fields (sequential integer keys 1..n).
--- This covers all runtime pools (burst particles, active texts,
--- pending drops, etc.) without touching dict-based registries
--- (factories, caches) or metamethods (__index, __call, etc.).
--- New components with module-level array pools are reset
--- automatically — no per-component code needed.
local Reset = {}

---@param key string
local function isSourceModule(key)
	if type(key) ~= "string" then
		return false
	end
	return key:find("^Source%.") ~= nil or key:find("^Mods%.") ~= nil
end

---@param t table
---@return boolean
local function isArray(t)
	if type(t) ~= "table" then
		return false
	end
	local count = 0
	for k, _ in pairs(t) do
		count = count + 1
		if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
			return false
		end
	end
	return count > 0
end

--- Clear every array-valued field in each Source. module so that
--- runtime pools are emptied. Non-array tables (dicts, registries,
--- caches) and metamethod keys (starting with __) are untouched.
function Reset.all()
	for key, mod in pairs(package.loaded) do
		if isSourceModule(key) and type(mod) == "table" then
			for k, v in pairs(mod) do
				if type(k) ~= "string" or not k:find("^__") then
					if isArray(v) then
						mod[k] = {}
					end
				end
			end
		end
	end
end

return Reset
