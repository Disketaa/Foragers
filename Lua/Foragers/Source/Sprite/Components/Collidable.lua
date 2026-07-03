---@class Collidable
---@field parent Sprite|nil
---@field mode "collision"|"detect"|"both"
---@field collisionWidth number
---@field collisionHeight number
---@field offsetX number Offset from sprite pivot to collision rect top-left in pixels
---@field offsetY number
---@field object string|nil Object name for color generation
---@field visible boolean Draw wireframe when true
---@field type "collidable"
local Collidable = {}
Collidable.__index = Collidable

---@type table<{x:number, y:number, w:number, h:number}>
local terrianColliders = {}

local function stringToColor(str)
	if not str or #str == 0 then
		return 0.6, 0.6, 0.6, 0.5
	end
	local h = 0
	for i = 1, #str do
		h = h * 31 + string.byte(str, i)
	end
	local r = ((h % 37) / 37) * 0.8 + 0.2
	local g = ((math.floor(h / 37) % 43) / 43) * 0.8 + 0.2
	local b = ((math.floor(h / (37 * 43)) % 29) / 29) * 0.8 + 0.2
	return r, g, b, 0.5
end

function Collidable.resetTerrain()
	terrianColliders = {}
end

function Collidable.getTerrainColliders()
	return terrianColliders
end

function Collidable.new(data)
	data = data or {}
	local self = setmetatable({
		mode = data.mode or "collision",
		collisionWidth = data.collisionWidth or 8,
		collisionHeight = data.collisionHeight or 8,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		object = data.object,
		visible = data.visible or false,
		type = "collidable",
	}, Collidable)
	return self
end

function Collidable:getRect()
	return {
		x = self.parent.x + self.offsetX,
		y = self.parent.y + self.offsetY,
		w = self.collisionWidth,
		h = self.collisionHeight,
	}
end

local function checkAABB(a, b)
	return a.x < b.x + b.w
		and a.x + a.w > b.x
		and a.y < b.y + b.h
		and a.y + a.h > b.y
end

function Collidable:update(dt)
	if not self.parent then
		return
	end

	if self.mode == "collision" then
		return
	end

	local myRect = self:getRect()
	local grounded = false
	for _, r in ipairs(terrianColliders) do
		if checkAABB(myRect, r) then
			grounded = true
			break
		end
	end

	self.parent._grounded = grounded

	if self.mode == "both" and not grounded then
		self.parent._state = "swimming"
	end
end

function Collidable:registerAsTerrain()
	table.insert(terrianColliders, self:getRect())
end

function Collidable:draw()
	if not self.visible or not self.parent then
		return
	end
	local rect = self:getRect()
	local r, g, b, a = stringToColor(self.object)
	love.graphics.setColor(r, g, b, a)
	love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)
	love.graphics.setColor(1, 1, 1, 1)
end

return Collidable