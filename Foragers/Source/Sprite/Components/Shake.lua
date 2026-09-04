local Events = require("Source.Helpers.Core.Events")

local ShakeComponent = {}
ShakeComponent.__index = ShakeComponent

function ShakeComponent.new(data)
	return setmetatable({
		magnitude = data.magnitude or 2,
		duration = data.duration or 0.2,
		decay = data.decay ~= false,
		triggerOn = data.triggerOn or { Events.PROP_BROKEN },
		timer = 0,
		active = false,
		offsetX = 0,
		offsetY = 0,
		type = "shake",
	}, ShakeComponent)
end

function ShakeComponent:attach()
	for _, event in ipairs(self.triggerOn) do
		self.parent:on(event, function()
			self:trigger()
		end, 5)
	end
end

--- Start (or restart) the shake from zero. Public so anything can trigger it,
--- e.g. the death overlay's shake runs off an explicit spawn, not an event.
function ShakeComponent:trigger()
	self.timer = 0
	self.active = true
end

function ShakeComponent:update(dt)
	if not self.active then
		return
	end

	self.timer = self.timer + dt
	if self.timer >= self.duration then
		self.active = false
		self.offsetX = 0
		self.offsetY = 0
		return
	end

	local progress = self.timer / self.duration
	local currentMag = self.magnitude
	if self.decay then
		currentMag = self.magnitude * (1 - progress)
	end

	self.offsetX = math.floor((love.math.random() * 2 - 1) * currentMag + 0.5)
	self.offsetY = math.floor((love.math.random() * 2 - 1) * currentMag + 0.5)
end

return ShakeComponent