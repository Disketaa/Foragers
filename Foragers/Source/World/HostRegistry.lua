-- Registry of host props (bush/tree/rock/stump) keyed by tile coords. Hosts
-- register on spawn so overlay-food picks (berries/apples/snails/mushrooms) can
-- find a place to attach. Keyed by coords so a destroyed host is removed cleanly.

local HostRegistry = {}

local _hosts = {} -- hostType -> { [coordKey] = sprite }
local _claimed = {} -- hostType -> { [coordKey] = true }

function HostRegistry.register(hostType, sprite)
	local byType = _hosts[hostType] or {}
	byType[HostRegistry.coordKey(sprite.x, sprite.y)] = sprite
	_hosts[hostType] = byType
end

function HostRegistry.unregister(hostType, sprite)
	local byType = _hosts[hostType]
	if byType then
		byType[HostRegistry.coordKey(sprite.x, sprite.y)] = nil
	end
	local claims = _claimed[hostType]
	if claims then
		claims[HostRegistry.coordKey(sprite.x, sprite.y)] = nil
	end
end

--- Fetch a specific host by coord. Used by the initial plan, which pairs each
--- berry to a particular bush at plan time.
---@param hostType string
---@param key string
---@return table|nil
function HostRegistry.get(hostType, key)
	local byType = _hosts[hostType]
	return byType and byType[key] or nil
end

--- Return a random unclaimed host of the given type and claim it (runtime path).
--- Returns nil when every host already carries fruit.
---@param hostType string
---@return table|nil sprite, string|nil key
function HostRegistry.find(hostType)
	local byType = _hosts[hostType]
	if not byType then
		return nil
	end
	local claims = _claimed[hostType] or {}
	local candidates = {}
	for key, sprite in pairs(byType) do
		if not claims[key] then
			candidates[#candidates + 1] = { key = key, sprite = sprite }
		end
	end
	if #candidates == 0 then
		return nil
	end
	local pick = candidates[love.math.random(1, #candidates)]
	_claimed[hostType] = claims
	claims[pick.key] = true
	return pick.sprite, pick.key
end

--- Free a host's claim when its fruit is destroyed, so the host can carry again.
---@param hostType string
---@param key string
function HostRegistry.release(hostType, key)
	local claims = _claimed[hostType]
	if claims then
		claims[key] = nil
	end
end

--- Tile-coord key for a host (shared with the plan so both agree on the key).
---@param x number
---@param y number
---@return string
function HostRegistry.coordKey(x, y)
	return math.floor(x) .. "," .. math.floor(y)
end

return HostRegistry