local Object = {}
Object.__index = Object

function Object.new(x, y)
	return setmetatable({
		x = x or 0,
		y = y or 0,
		components = {},
	}, Object)
end

function Object:addComponent(component)
	table.insert(self.components, component)
	component.parent = self
end

function Object:update(dt)
	for _, component in ipairs(self.components) do
		if component.update then
			component:update(dt)
		end
	end
end

function Object:draw()
	for _, component in ipairs(self.components) do
		if component.draw then
			component:draw(self.x, self.y)
		end
	end
end

return Object
