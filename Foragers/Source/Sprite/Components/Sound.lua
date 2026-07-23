local Events = require("Source.Helpers.Events")
local Log = require("Source.Helpers.Log")

---@class Sound
---@field parent Sprite|nil
---@field soundSets table<string, table>
---@field tags table<string, table>
---@field _currentState string|nil
---@field _stepCounter number
---@field type "sound"
local Sound = {}
Sound.__index = Sound

---@param data table
---@return Sound
function Sound.new(data)
	local self = setmetatable({}, Sound)
	self.soundSets = {}
	self.tags = data.tags or {}
	self._currentState = nil
	self._stepCounter = 0
	self.type = "sound"

	for stateName, config in pairs(self.tags) do
		local sounds = config.sounds or config
		local soundSet = {
			volume = config.volume or data.volume or 1,
			pitch = config.pitch or data.pitch or 1,
			pitchRandomness = config.pitchRandomness or data.pitchRandomness or 0,
			stepInterval = config.stepInterval or data.stepInterval or 1,
			baseSources = {},
		}
		for _, soundPath in ipairs(sounds) do
			local ok, baseSource = pcall(love.audio.newSource, soundPath, "static")
			if not ok then
				Log.error("Failed to load sound: " .. tostring(soundPath))
			else
				table.insert(soundSet.baseSources, baseSource)
			end
		end
		self.soundSets[stateName] = soundSet
	end

	return self
end

function Sound:attach()
	self.parent:on(Events.GROUNDED_CHANGED, function(isGrounded)
		self:_play(isGrounded and "water_out" or "water_in")
	end, 15)

	self.parent:on(Events.STATE_CHANGED, function(state)
		self._currentState = state
		self._stepCounter = 0
		self:_play(state)
	end, 15)

	self.parent:on(Events.ANIM_FRAME, function()
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

	self.parent:on(Events.SLOWDOWN_ENTER, function()
		self:_play("prop_touch")
	end, 15)

	self.parent:on(Events.PROP_HIT, function()
		self:_play("prop_hit")
	end, 15)

	self.parent:on(Events.TWEEN_COMPLETED, function()
		self:_play("arrived")
	end, 15)

	self.parent:on(Events.PROP_BROKEN, function()
		self:_play("prop_broken")
	end, 15)

	self.parent:on(Events.PROP_SPAWNED, function()
		self:_play("prop_spawned")
	end, 15)

	self.parent:on(Events.COUNTER_WRAP, function()
		self:_play("level_up")
	end, 15)
end

function Sound:_play(state)
	local set = self.soundSets[state]
	if not set or #set.baseSources == 0 then
		return
	end
	local base = set.baseSources[love.math.random(1, #set.baseSources)]
	local source = base:clone()
	source:setVolume(set.volume)
	local effectivePitch = set.pitch + (love.math.random() * 2 - 1) * set.pitchRandomness
	source:setPitch(math.max(0.1, effectivePitch))
	source:play()
end

return Sound
