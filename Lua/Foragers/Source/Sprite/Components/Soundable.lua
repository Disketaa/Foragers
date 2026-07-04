---@class Soundable
---@field parent Sprite|nil
---@field soundSets table<string, table>
---@field tags table<string, table>
---@field _prevState string|nil
---@field _prevGrounded boolean|nil
---@field _lastFrame number|nil
---@field type "soundable"
local Soundable = {}
Soundable.__index = Soundable

local function findAnimatable(sprite)
	for _, comp in ipairs(sprite.components) do
		if comp.type == "animatable" then
			return comp
		end
	end
end

---@param data table
---@return Soundable
function Soundable.new(data)
	local self = setmetatable({}, Soundable)
	self.soundSets = {}
	self.tags = data.tags or {}
	self._prevState = nil
	self._prevGrounded = nil
	self._lastFrame = nil
	self.type = "soundable"

	for stateName, config in pairs(self.tags) do
		local sounds = config.sounds or config
		local soundSet = {
			volume = config.volume or data.volume or 1.0,
			pitch = config.pitch or data.pitch or 1.0,
			pitchRandomness = config.pitchRandomness or data.pitchRandomness or 0,
			stepInterval = config.stepInterval or data.stepInterval or 1,
			baseSources = {},
		}
		for _, soundPath in ipairs(sounds) do
			local baseSource = love.audio.newSource(soundPath, "static")
			table.insert(soundSet.baseSources, baseSource)
		end
		self.soundSets[stateName] = soundSet
	end

	return self
end

function Soundable:_play(state)
	local set = self.soundSets[state]
	if not set or #set.baseSources == 0 then
		return
	end
	local base = set.baseSources[love.math.random(1, #set.baseSources)]
	local source = base:clone()
	source:setVolume(set.volume)
	local effectivePitch = set.pitch + (math.random() * 2 - 1) * set.pitchRandomness
	source:setPitch(math.max(0.1, effectivePitch))
	source:play()
end

---@param dt number
function Soundable:update(dt)
	if not self.parent then
		return
	end

	local grounded = self.parent._grounded
	if self._prevGrounded ~= nil and grounded ~= self._prevGrounded then
		if grounded == false then
			self:_play("water_in")
		else
			self:_play("water_out")
		end
	end
	self._prevGrounded = grounded

	local state = self.parent._state
	if not state then
		self._lastFrame = nil
		return
	end

	if state ~= self._prevState then
		self._prevState = state
		self._lastFrame = nil
		self:_play(state)
		return
	end

	local anim = findAnimatable(self.parent)
	if not anim or not anim.currentAnim then
		return
	end

	local animData = anim.animations[anim.currentAnim]
	if not animData then
		return
	end

	local currentFrame = math.floor(anim.currentTime * animData.speed)
	local set = self.soundSets[state]
	local interval = set and set.stepInterval or 1

	if self._lastFrame ~= nil and currentFrame ~= self._lastFrame then
		if currentFrame % interval == 0 then
			self:_play(state)
		end
	end
	self._lastFrame = currentFrame
end

return Soundable