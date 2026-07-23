local Events = require("Source.Helpers.Events")

---@class Collision
---@field parent Sprite|nil
---@field mode "solid"|"detect"|"solid_and_detect"|"slowdown"
---@field collisionWidth number
---@field collisionHeight number
---@field offsetX number Offset from sprite pivot to collision rect top-left in pixels
---@field offsetY number
---@field visible boolean Draw wireframe when true
---@field slowdown number|nil Speed multiplier when inside this zone (0-1)
---@field _prevGrounded boolean|nil Previous frame grounded state
---@field _prevSlowdown number|nil Previous frame slowdown multiplier
---@field type "collision"
local Collision = {}
Collision.__index = Collision

-- Baked static terrain colliders, populated once at world generation
---@type table<{x:number, y:number, w:number, h:number}>
local terrainColliders = {}
-- Baked static solid colliders (props, obstacles), populated once at world generation
---@type table<{x:number, y:number, w:number, h:number}>
local solidColliders = {}
-- Baked static slowdown colliders, populated once at world generation
---@type table<{x:number, y:number, w:number, h:number, slowdown:number, sprite:Sprite|nil}>
local slowdownColliders = {}
-- Reusable buffers for tracking slowdown sprite overlap sets (no per-frame alloc)
local _slowdownCurr = {}
local _slowdownPrev = {}

function Collision.resetTerrain()
	terrainColliders = {}
end

function Collision.getTerrainColliders()
	return terrainColliders
end

function Collision.resetSolids()
	solidColliders = {}
end

function Collision.getSolidColliders()
	return solidColliders
end

function Collision.resetSlowdown()
	slowdownColliders = {}
end

function Collision.getSlowdownColliders()
	return slowdownColliders
end

---@param data table
---@return Collision
function Collision.new(data)
	data = data or {}
	return setmetatable({
		mode = data.mode or "solid",
		collisionWidth = data.collisionWidth or 8,
		collisionHeight = data.collisionHeight or 8,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or 0,
		visible = data.visible or false,
		slowdown = data.slowdown,
		_prevGrounded = nil,
		_prevSlowdown = nil,
		drawOnTop = true,
		type = "collision",
	}, Collision)
end

function Collision:getRect()
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

local function collidesWithAny(rect, list)
	for _, r in ipairs(list) do
		if checkAABB(rect, r) then
			return true
		end
	end
	return false
end

---@param dt number
function Collision:update(dt)
	if not self.parent then
		return
	end

	if self.mode == "solid" or self.mode == "slowdown" then
		return
	end

	-- Collision resolution for moving entities: slide along walls
	if self._prevX ~= nil and self._prevY ~= nil then
		local desiredX, desiredY = self.parent.x, self.parent.y

		-- Start from pre-move position
		self.parent.x = self._prevX
		self.parent.y = self._prevY

		-- Try X movement only
		self.parent.x = desiredX
		if collidesWithAny(self:getRect(), solidColliders) then
			self.parent.x = self._prevX
		end

		-- Try Y movement only (from resolved X)
		self.parent.y = desiredY
		if collidesWithAny(self:getRect(), solidColliders) then
			self.parent.y = self._prevY
		end
	end

	local myRect = self:getRect()
	local grounded = false
	for _, r in ipairs(terrainColliders) do
		if checkAABB(myRect, r) then
			grounded = true
			break
		end
	end

	if grounded ~= self._prevGrounded then
		self._prevGrounded = grounded
		self.parent:emit(Events.GROUNDED_CHANGED, grounded)
	end

	for k in pairs(_slowdownCurr) do
		_slowdownCurr[k] = nil
	end

	local currentSlowdown = 1
	for _, r in ipairs(slowdownColliders) do
		if checkAABB(myRect, r) then
			if r.slowdown and r.slowdown < currentSlowdown then
				currentSlowdown = r.slowdown
			end
			if r.sprite then
				_slowdownCurr[r.sprite] = true
				if not _slowdownPrev[r.sprite] then
					r.sprite:emit(Events.SLOWDOWN_ENTER)
				end
			end
		end
	end
	if currentSlowdown ~= self._prevSlowdown then
		self._prevSlowdown = currentSlowdown
		self.parent:emit(Events.SLOWDOWN_CHANGED, currentSlowdown)
	end

	for sprite in pairs(_slowdownPrev) do
		if not _slowdownCurr[sprite] then
			sprite:emit(Events.SLOWDOWN_EXIT)
		end
	end
	_slowdownPrev, _slowdownCurr = _slowdownCurr, _slowdownPrev

	self._prevX = self.parent.x
	self._prevY = self.parent.y
end

-- For static tiles only; baked once at world generation
function Collision:registerAsTerrain()
	table.insert(terrainColliders, self:getRect())
end

-- For static obstacles (props); baked once at world generation
function Collision:registerAsSolid()
	local rect = self:getRect()
	rect.sprite = self.parent
	table.insert(solidColliders, rect)
end

-- For slowdown zones (bushes, etc.); baked once at world generation
function Collision:registerAsSlowdown()
	local rect = self:getRect()
	rect.slowdown = self.slowdown or 1
	rect.sprite = self.parent
	table.insert(slowdownColliders, rect)
end

function Collision.removeSpriteColliders(sprite)
	for i = #solidColliders, 1, -1 do
		if solidColliders[i].sprite == sprite then
			table.remove(solidColliders, i)
		end
	end
	for i = #slowdownColliders, 1, -1 do
		if slowdownColliders[i].sprite == sprite then
			table.remove(slowdownColliders, i)
		end
	end
end

function Collision:draw()
	if not self.visible or not self.parent then
		return
	end
	local rect = self:getRect()
	love.graphics.setColor(1, 0, 0, 0.5)
	love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h)
	love.graphics.setColor(1, 1, 1, 1)
end

return Collision
