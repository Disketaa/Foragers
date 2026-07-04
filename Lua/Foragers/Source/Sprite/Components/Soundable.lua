---@class Soundable
---@field parent Sprite|nil
---@field soundSets table<string, table>
---@field tags table<string, table>
---@field _currentState string|nil
---@field _stepCounter number
---@field type "soundable"
local Soundable = {}
Soundable.__index = Soundable

---@param data table
---@return Soundable
function Soundable.new(data)
	local self = setmetatable({}, Soundable)
	self.soundSets = {}
	self.tags = data.tags or {}
	self._currentState = nil
	self._stepCounter = 0
	self.type = "soundable"

	for stateName, config in pairs(self.tags) do
		local sounds = config.sounds or config
		local soundSet = {
			volume = config.volume or data.volume or 1.0,
			pitch = config.pitch or data.pitch or 1.0,
			pitchRandomness = config.pitchRandomness or data.pitchRandomness or 0,
			stepInterval = config.stepInterval or data.stepInterval or 1,
			sourcePoolSize = #(config.sounds or config),
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

function Soundable:attach()
	self.parent:on("grounded_changed", function(isGrounded)
		self:_play(isGrounded and "water_out" or "water_in")
	end, 15)

	self.parent:on("state_changed", function(state)
		self._currentState = state
		self._stepCounter = 0
		self:_play(state)
	end, 15)

	self.parent:on("anim_frame", function()
		local set = self.soundSets[self._currentState]
		local interval = set and set.stepInterval or 1
		if interval > 1 then
			self._stepCounter = self._stepCounter + 1
			if self._stepCounter % interval == 0 then
				self:_play(self._currentState)
			end
		else
			self:_play(self._currentState)
		end
	end, 15)
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
function Soundable:update(dt) end

return Soundable
