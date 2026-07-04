local Canvas = {}
Canvas.__index = Canvas

---@param width number Base canvas width
---@param height number Base canvas height
---@return Canvas
function Canvas.new(width, height)
	local self = setmetatable({}, Canvas)
	self.width = width
	self.height = height
	self.scale = 1
	self.offsetX = 0
	self.offsetY = 0
	self.canvas = nil
	self:_recreateCanvas()
	return self
end

function Canvas:_recreateCanvas()
	if self.canvas then
		self.canvas:release()
	end
	self.canvas = love.graphics.newCanvas(self.width, self.height)
	self.canvas:setFilter("nearest", "nearest")
end

---@param windowWidth number|nil
---@param windowHeight number|nil
function Canvas:_initOffset(windowWidth, windowHeight)
	local w = windowWidth or self.width
	local h = windowHeight or self.height
	self.offsetX = math.floor((w - self.width * self.scale) / 2)
	self.offsetY = math.floor((h - self.height * self.scale) / 2)
end

---Recalculate scale and offset when window is resized
---@param windowWidth number
---@param windowHeight number
function Canvas:resize(windowWidth, windowHeight)
	self.scale = math.max(1, math.floor(math.min(windowWidth / self.width, windowHeight / self.height)))
	self.offsetX = math.floor((windowWidth - self.width * self.scale) / 2)
	self.offsetY = math.floor((windowHeight - self.height * self.scale) / 2)
end

---@param drawFunc function
---@param clearColor table|nil Optional {r,g,b,a} to clear canvas with instead of transparent
function Canvas:draw(drawFunc, clearColor)
	love.graphics.setCanvas(self.canvas)
	if clearColor then
		love.graphics.clear(clearColor[1], clearColor[2], clearColor[3], clearColor[4] or 1)
	else
		love.graphics.clear()
	end
	if drawFunc then
		drawFunc()
	end
	love.graphics.setCanvas()
	love.graphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.scale, self.scale)
end

---Get current canvas for direct access
---@return love.Canvas
function Canvas:getCanvas()
	return self.canvas
end

return Canvas
