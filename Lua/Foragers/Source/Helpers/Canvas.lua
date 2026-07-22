local Canvas = {}
Canvas.__index = Canvas

---@param width number Base canvas width
---@param height number Base canvas height
---@param mode string "inner" to keep fixed resolution and center with borders, "outer" to fill window
---@return Canvas
function Canvas.new(width, height, mode)
	local self = setmetatable({}, Canvas)
	self.baseWidth = width
	self.baseHeight = height
	self.width = width
	self.height = height
	self.scale = 1
	self.offsetX = 0
	self.offsetY = 0
	self.canvas = nil
	self.mode = mode or "outer"
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

---Recalculate scale, offset, and recreate canvas when window is resized
---@param windowWidth number
---@param windowHeight number
function Canvas:resize(windowWidth, windowHeight)
	self.scale = math.max(1, math.floor(math.min(windowWidth / self.baseWidth, windowHeight / self.baseHeight)))

	if self.mode == "inner" then
		self.offsetX = math.floor((windowWidth - self.baseWidth * self.scale) / 2)
		self.offsetY = math.floor((windowHeight - self.baseHeight * self.scale) / 2)
		if self.width ~= self.baseWidth or self.height ~= self.baseHeight then
			self.width = self.baseWidth
			self.height = self.baseHeight
			self:_recreateCanvas()
		end
	else
		local newWidth = math.ceil(windowWidth / self.scale)
		local newHeight = math.ceil(windowHeight / self.scale)
		if self.width ~= newWidth or self.height ~= newHeight then
			self.width = newWidth
			self.height = newHeight
			self:_recreateCanvas()
		end
		self.offsetX = 0
		self.offsetY = 0
	end
end

---@param drawFunc function
---@param clearColor table|nil Optional {r,g,b,a} to clear canvas with instead of transparent
---@param viewX number|nil Camera offset X (shifts canvas draw position)
---@param viewY number|nil Camera offset Y (shifts canvas draw position)
---@param subX number|nil Sub-pixel offset X (0..1, for smooth canvas movement)
---@param subY number|nil Sub-pixel offset Y (0..1, for smooth canvas movement)
function Canvas:draw(drawFunc, clearColor, viewX, viewY, subX, subY)
	-- Floor view offset for pixel-perfect canvas rendering (prevents sub-pixel seams)
	viewX = math.floor(viewX or 0)
	viewY = math.floor(viewY or 0)
	subX = subX or 0
	subY = subY or 0

	if self.mode == "inner" then
		local r, g, b =
			clearColor and clearColor[1] or 0, clearColor and clearColor[2] or 0, clearColor and clearColor[3] or 0
		love.graphics.clear(r, g, b, 1)
	end

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

	-- viewX/Y is floored (discrete); subX/subY is the fractional remainder scaled to screen pixels for smooth scroll
	local finalX = self.offsetX + viewX + subX * self.scale
	local finalY = self.offsetY + viewY + subY * self.scale

	love.graphics.draw(self.canvas, finalX, finalY, 0, self.scale, self.scale)
end

return Canvas