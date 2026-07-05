---@class Follow
---@field parent Sprite|nil
---@field image love.Image|nil
---@field followTarget Sprite|nil
---@field offsetX number
---@field offsetY number
---@field type "follow"
local Follow = {}
Follow.__index = Follow

---@param data table
---@return Follow
function Follow.new(data)
	return setmetatable({
		image = data.image and love.graphics.newImage(data.image) or nil,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		type = "follow",
	}, Follow)
end

---@param target Sprite
function Follow:setFollowTarget(target)
	self.followTarget = target
end

---@param dt number
function Follow:update(dt)
	if not self.followTarget or not self.parent then
		return
	end

	local dir = self.followTarget.flipX and -1 or 1
	self.parent.x = self.followTarget.x + dir * self.offsetX
	self.parent.y = self.followTarget.y + self.offsetY

	if self.parent.tweens and self.parent.tweens.y then
		self.parent.y = self.parent.y + self.parent.tweens.y:getValue()
	end
end

---@param x number
---@param y number
function Follow:draw(x, y)
	if not self.image then
		return
	end
	local ox = self.parent.frameWidth * (self.parent.pivotX or 0.5)
	local oy = self.parent.frameHeight * (self.parent.pivotY or 1)
	love.graphics.draw(self.image, math.floor(x + 0.5), math.floor(y + 0.5), 0, 1, 1, ox, oy)
end

return Follow
