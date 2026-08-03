local EventEmitter = require("Source.Helpers.EventEmitter")
local data = require("Content.Data.Debug")

local Debug = {}
local emitter = EventEmitter.new()

local function masterOn()
	return data.debug == true
end

---@param group string Settings group name (e.g. "collisions")
---@return boolean
function Debug.enabled(group)
	return masterOn() and (data[group] or {}).enabled == true
end

--- Group "X" carries an `exclude` list of entity ids to skip.
---@param group string
---@param value string|nil Entity identifier (sprite.object)
---@return boolean
function Debug.excluded(group, value)
	if value == nil then
		return false
	end
	local list = (data[group] or {}).exclude
	if not list then
		return false
	end
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

---@param group string
---@return table Settings table for the group (thickness, color, ...).
function Debug.settings(group)
	return data[group] or {}
end

function Debug.isEnabled()
	return masterOn()
end

--- Subscribe to runtime flag changes. Callback receives (key, value).
---@param callback function
function Debug.onChange(callback)
	emitter:on("flags", callback)
end

--- Set a flag at runtime and notify subscribers.
---@param key string
---@param value boolean
function Debug.set(key, value)
	data[key] = value == true
	emitter:emit("flags", key, data[key])
end

return Debug
