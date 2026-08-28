local Events = require("Source.Helpers.Core.Events")
local Log = require("Source.Helpers.Core.Log")

---@class Sound
---@field parent Sprite|nil
---@field soundSets table<string, table>
---@field tags table<string, table>
---@field _currentState string|nil
---@field _stepCounter number
---@field type "sound"
local Sound = {}
Sound.__index = Sound

-- Cache loaded sources by path. Hundreds of props share the same sound files, so
-- without this every instantiate re-decodes the .ogg (~5ms/prop during the
-- initial spawn). Cloning from a shared base at play is cheap, so reuse is safe.
local audioCache = {}

--- Report a failed sound load (shared by Sound.new and Sound.play).
local function logLoadFail(what)
	Log.error("Sound", "Failed to load sound: %s", tostring(what))
end

---@param data table
---@return Sound
function Sound.new(data)
	local self = setmetatable({ type = "sound" }, Sound)
	self.soundSets = {}
	self.tags = data.tags or {}
	self._currentState = nil
	self._stepCounter = 0

	-- Per-tag overrides must honor explicit 0 (mute volume, zero pitch randomness),
	-- which `or` would treat as nil.
	local function resolve(config, field, default)
		local v = config[field]
		if v == nil then
			v = data[field]
		end
		if v == nil then
			v = default
		end
		return v
	end

	for stateName, config in pairs(self.tags) do
		local sounds = config.sounds or config
		local soundSet = {
			volume = resolve(config, "volume", 1),
			pitch = resolve(config, "pitch", 1),
			pitchRandomness = resolve(config, "pitchRandomness", 0),
			stepInterval = resolve(config, "stepInterval", 1),
			-- A tag only steps (replays on frames) if it declares stepInterval;
			-- event one-shots (death, hunger, ...) omit it.
			step = config.stepInterval ~= nil,
			baseSources = {},
		}
		for _, soundPath in ipairs(sounds) do
			local cached = audioCache[soundPath]
			local baseSource
			if cached ~= nil then
				baseSource = cached
			else
				local ok, src = pcall(love.audio.newSource, soundPath, "static")
				if ok then
					baseSource = src
					audioCache[soundPath] = src
				else
					audioCache[soundPath] = false
					logLoadFail(soundPath)
				end
			end
			if baseSource then
				table.insert(soundSet.baseSources, baseSource)
			end
		end
		self.soundSets[stateName] = soundSet
	end

	return self
end

function Sound:attach()
	-- Skip the first GROUNDED_CHANGED: it's the spawn's initial state, not a
	-- transition, so it shouldn't play water_in/water_out. Control still receives
	-- it to learn whether the player started grounded (swim vs land).
	local groundedSeen = false
	self.parent:on(Events.GROUNDED_CHANGED, function(isGrounded)
		if not groundedSeen then
			groundedSeen = true
			return
		end
		self:_play(isGrounded and "water_out" or "water_in")
	end, 15)

	self.parent:on(Events.STATE_CHANGED, function(state)
		self._currentState = state
		self._stepCounter = 0
		local set = self.soundSets[state]
		if set and set.step then
			self:_play(state)
		end
	end, 15)

	self.parent:on(Events.ANIM_FRAME, function()
		local set = self.soundSets[self._currentState]
		if not set or not set.step then
			return
		end
		self._stepCounter = self._stepCounter + 1
		if self._stepCounter % set.stepInterval == 0 then
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

	self.parent:on(Events.LOW_SATIETY, function()
		self:_play("hunger")
	end, 15)

	self.parent:on(Events.DEATH, function()
		self:_play("death")
	end, 15)

	self.parent:on(Events.CARD_SELECT_OPEN, function()
		self:_play("card_shuffle")
	end, 15)

	self.parent:on(Events.CARD_SELECTED, function()
		self:_play("card_select")
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

--- Play a one-shot sound by path (UI blips). Cache the source so the .ogg
--- decodes once, then clone cheaply at play — same pattern as the sprite component.
---@param path string|nil
---@param volume number|nil
---@param pitch number|nil
function Sound.play(path, volume, pitch)
	if not path or not (love and love.audio) then
		return
	end
	local base = audioCache[path]
	if base == nil then
		local ok, src = pcall(love.audio.newSource, path, "static")
		if ok then
			base = src
			audioCache[path] = src
		else
			audioCache[path] = false
			logLoadFail(path)
		end
	end
	if not base then
		return
	end
	local source = base:clone()
	source:setVolume(volume or 1)
	source:setPitch(pitch or 1)
	source:play()
end

return Sound
