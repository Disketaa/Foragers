-- Base game object with position and component list.
local Object = {}
Object.__index = Object

-- Creates object at (x, y). Defaults to (0, 0).
-- Components added via addComponent.
function Object.new(x, y)
	return setmetatable({
		x = x or 0,
		y = y or 0,
		components = {},
	}, Object)
end

-- Adds component to object.
-- Component receives parent reference.
function Object:addComponent(component)
	table.insert(self.components, component)
	component.parent = self
end

-- Updates all components with dt.
-- Components with update() method are called automatically.
function Object:update(dt)
	for _, component in ipairs(self.components) do
		if component.update then
			component:update(dt)
		end
	end
end

-- Draws all components.
-- Object position passed to components for rendering.
function Object:draw()
	for _, component in ipairs(self.components) do
		if component.draw then
			component:draw(self.x, self.y)
		end
	end
end

return Object
