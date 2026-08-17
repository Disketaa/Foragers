---@class Canvas
---@field baseWidth number
---@field baseHeight number
---@field width number
---@field height number
---@field scale number
---@field offsetX number
---@field offsetY number
---@field canvas love.Canvas
---@field mode string
---@field new fun(width: number, height: number, mode?: string): Canvas
---@field newCanvas fun(w: number, h: number): love.Canvas
---@field createCanvasManager fun(): fun(w: number, h: number): love.Canvas
---@field drawTo fun(canvas: love.Canvas, drawFunc: function, clearColor?: table, afterRestore?: function)
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
	if self.mode ~= "inner" and self.mode ~= "outer" then
		error("Canvas: unknown mode '" .. tostring(self.mode) .. "'")
	end
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
		local newWidth = math.ceil(windowWidth / self.scale) + 2 * self.scale
		local newHeight = math.ceil(windowHeight / self.scale) + 2 * self.scale
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
---@param screenShader love.Shader|nil Optional shader applied when drawing canvas to screen (post-process)
---@param zoom number|nil Output zoom (1 = none). Scales the whole canvas blit about the
--- pivot point — magnifies the rendered picture without changing what was drawn.
---@param pivotX number|nil Screen-space X to zoom about (default: window center)
---@param pivotY number|nil Screen-space Y to zoom about (default: window center)
--- Canvas is padded by scale pixels on each side to prevent sub-pixel edge gaps with nearest filtering.
function Canvas:draw(drawFunc, clearColor, viewX, viewY, subX, subY, screenShader, zoom, pivotX, pivotY)
	-- Floor view offset for pixel-perfect canvas rendering (prevents sub-pixel seams)
	viewX = math.floor(viewX or 0)
	viewY = math.floor(viewY or 0)
	subX = subX or 0
	subY = subY or 0
	zoom = zoom or 1
	pivotX = pivotX or love.graphics.getWidth() * 0.5
	pivotY = pivotY or love.graphics.getHeight() * 0.5

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

	local finalX = self.offsetX + viewX + subX * self.scale - self.scale
	local finalY = self.offsetY + viewY + subY * self.scale - self.scale

	love.graphics.push()
	if zoom ~= 1 then
		love.graphics.translate(pivotX, pivotY)
		love.graphics.scale(zoom, zoom)
		love.graphics.translate(-pivotX, -pivotY)
	end
	if screenShader then
		love.graphics.setShader(screenShader)
	end
	love.graphics.draw(self.canvas, finalX, finalY, 0, self.scale, self.scale)
	if screenShader then
		love.graphics.setShader()
	end
	love.graphics.pop()
end

--- Create a reusable canvas with nearest-neighbor filtering.
---@param w number
---@param h number
---@return love.Canvas
function Canvas.newCanvas(w, h)
	local c = love.graphics.newCanvas(w, h)
	c:setFilter("nearest", "nearest")
	return c
end

--- Returns a closure that manages a single cached canvas.
--- Each call with the same dimensions returns the cached canvas;
--- different dimensions release the old canvas and create a new one.
---@return function ensureCanvas(w, h)
function Canvas.createCanvasManager()
	local canvas = nil
	local cw, ch = 0, 0
	return function(w, h)
		if canvas and cw == w and ch == h then
			return canvas
		end
		if canvas then
			canvas:release()
		end
		canvas = Canvas.newCanvas(w, h)
		cw, ch = w, h
		return canvas
	end
end

--- Render onto a temporary canvas with standard setup/teardown.
--- push("all") -> setCanvas -> origin -> clear -> draw -> setCanvas(prev) -> origin -> [afterRestore] -> pop()
--- afterRestore runs inside push/pop so origin is temporary (undoes on pop).
--- Shadow uses afterRestore to composite the canvas onto the world canvas at camera-space origin.
---@param canvas love.Canvas
---@param drawFunc function
---@param clearColor table|nil {r,g,b,a} or nil for transparent
---@param afterRestore function|nil Runs after origin on restored canvas, before pop
function Canvas.drawTo(canvas, drawFunc, clearColor, afterRestore)
	local prev = love.graphics.getCanvas()
	love.graphics.push("all")
	love.graphics.setCanvas(canvas)
	love.graphics.origin()
	if clearColor then
		love.graphics.clear(clearColor[1], clearColor[2], clearColor[3], clearColor[4] or 0)
	else
		love.graphics.clear()
	end
	drawFunc()
	love.graphics.setCanvas(prev)
	love.graphics.origin()
	if afterRestore then
		afterRestore()
	end
	love.graphics.pop()
end

return Canvas
