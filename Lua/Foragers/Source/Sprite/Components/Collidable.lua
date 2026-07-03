---@class Collidable
---@field parent Sprite|nil
---@field mode "solid"|"detect"|"solid_and_detect"
---@field collisionWidth number
---@field collisionHeight number
---@field offsetX number Offset from sprite pivot to collision rect top-left in pixels
---@field offsetY number
---@field visible boolean Draw wireframe when true
---@field type "collidable"
local Collidable = {}
Collidable.__index = Collidable

-- Baked static terrain colliders, populated once at world generation
---@type table<{x:number, y:number, w:number, h:number}>
local terrainColliders = {}

function Collidable.resetTerrain()
	terrainColliders = {}
end

function Collidable.getTerrainColliders()
	return terrainColliders
end

---@param data table
---@return Collidable
function Collidable.new(data)
	data = data or {}
	local self = setmetatable({
		mode = data.mode or "solid",
		collisionWidth = data.collisionWidth or 8,
		collisionHeight = data.collisionHeight or 8,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		visible = data.visible or false,
		type = "collidable",
	}, Collidable)
	return self
end

function Collidable:getRect()
	return {
		x = self.parent.x - self.collisionWidth / 2 + self.offsetX,
		y = self.parent.y - self.collisionHeight / 2 + self.offsetY,
		w = self.collisionWidth,
		h = self.collisionHeight,
	}
end

local function checkAABB(a, b)
	return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y
end

---@param dt number
function Collidable:update(dt)
	if not self.parent then
		return
	end

	if self.mode == "solid" then
		return
	end

	local myRect = self:getRect()
	local grounded = false
	for _, r in ipairs(terrainColliders) do
		if checkAABB(myRect, r) then
			grounded = true
			break
		end
	end

	self.parent._grounded = grounded

	if self.mode == "solid_and_detect" and not grounded then
		self.parent._state = "swimming"
	end
end

-- For static tiles only; baked once at world generation
function Collidable:registerAsTerrain()
	table.insert(terrainColliders, self:getRect())
end

function Collidable:draw()
	if not self.visible or not self.parent then
		return
	end
	local rect = self:getRect()
	love.graphics.setColor(1, 0, 0, 0.5)
	love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)
	love.graphics.setColor(1, 1, 1, 1)
end

return Collidable
