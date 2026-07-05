local Spritesheet = {}
Spritesheet.__index = Spritesheet

function Spritesheet.new(data)
	local self = setmetatable({}, Spritesheet)
	local image = love.graphics.newImage(data.spriteSheet)
	if not image then
		return self
	end
	self.image = image
	self.frameWidth = data.frameWidth or 8
	self.frameHeight = data.frameHeight or 8
	self.type = "spritesheet"
	self.pivotX = data.pivotX or 0.5
	self.pivotY = data.pivotY or 0.5
	self.columns = data.columns or 4

	local rows = data.rows or 6
	local sheetWidth, sheetHeight = image:getWidth(), image:getHeight()
	local totalFrames = rows * self.columns
	self.quads = {}
	for i = 0, totalFrames - 1 do
		local col = i % self.columns
		local row = math.floor(i / self.columns)
		self.quads[i + 1] = love.graphics.newQuad(
			col * self.frameWidth,
			row * self.frameHeight,
			self.frameWidth,
			self.frameHeight,
			sheetWidth,
			sheetHeight
		)
	end

	self.currentQuad = nil
	return self
end

function Spritesheet:setFrame(index)
	if index >= 0 and index < #self.quads then
		self.currentQuad = self.quads[index + 1]
	end
end

function Spritesheet:draw(x, y)
	if not self.currentQuad then
		return
	end
	local ox = self.frameWidth * self.pivotX
	local oy = self.frameHeight * self.pivotY
	love.graphics.draw(self.image, self.currentQuad, math.floor(x + 0.5), math.floor(y + 0.5), 0, 1, 1, ox, oy)
end

return Spritesheet
