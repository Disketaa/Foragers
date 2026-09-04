---@class EventEmitter
local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter.new()
	return setmetatable({ _listeners = {} }, EventEmitter)
end

function EventEmitter:on(event, callback, priority)
	priority = priority or 100
	if not self._listeners[event] then
		self._listeners[event] = {}
	end
	table.insert(self._listeners[event], { callback = callback, priority = priority })
	table.sort(self._listeners[event], function(a, b) return a.priority < b.priority end)
	return callback
end

function EventEmitter:emit(event, ...)
	local list = self._listeners[event]
	if not list then
		return
	end
	for _, entry in ipairs(list) do
		entry.callback(...)
	end
end

function EventEmitter:removeListener(event, callback)
	local list = self._listeners[event]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		if list[i].callback == callback then
			table.remove(list, i)
			return
		end
	end
end

function EventEmitter:clear()
	self._listeners = {}
end

return EventEmitter