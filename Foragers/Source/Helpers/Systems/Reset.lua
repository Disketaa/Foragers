--- Universal state reset. Scans every loaded `Source.`/`Mods.` module and
--- clears all **array-valued** fields (sequential integer keys 1..n), and
--- invokes any module-exposed `reset()` for non-array state (e.g. DayCycle's
--- clock, which drives shader uniforms every frame and would otherwise freeze
--- across a restart). New components with array pools reset automatically;
--- modules owning other resettable state just add a `reset()` function.
--- DEV RULE: a module's `reset()` must not read other modules' state (iteration
--- order over package.loaded is non-deterministic), and any file-scope local
--- state must be reset explicitly inside `reset()` (Reset.all only sees module
--- table fields, not upvalues).
local Log = require("Source.Helpers.Core.Log")

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
			if type(mod.reset) == "function" then
				local ok, err = pcall(mod.reset)
				if not ok then
					Log.error("Reset", "mod.reset for %s failed: %s", key, tostring(err))
				end
			end
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
