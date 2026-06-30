---@class Object
---@field x number World X position
---@field y number World Y position
---@field components table<object> Component instances, updated in order
local Object = {}
Object.__index = Object

-- Creates object at position. Defaults to (0, 0).
-- Components are added via addComponent() which sets parent reference.
---@param x number|nil
---@param y number|nil
---@return Object
function Object.new(x, y)
	return setmetatable({
		x = x or 0,
		y = y or 0,
		components = {},
	}, Object)
end

-- Adds component to object and sets parent reference.
-- Component receives self as parent for accessing position/state.
---@param component table Component with optional update/draw methods
function Object:addComponent(component)
	table.insert(self.components, component)
	component.parent = self
end

-- Updates all components with delta time.
-- Only components with update() method are called.
---@param dt number Delta time in seconds
function Object:update(dt)
	for _, component in ipairs(self.components) do
		if component.update then component:update(dt) end
	end
end

-- Draws all components at object position.
-- Component:draw(x, y) receives world coordinates.
function Object:draw()
	for _, component in ipairs(self.components) do
		if component.draw then component:draw(self.x, self.y) end
	end
end

return Object
