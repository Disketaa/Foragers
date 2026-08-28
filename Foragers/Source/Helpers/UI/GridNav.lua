local Options = require("Source.Helpers.Systems.Options")
local Input = require("Source.Helpers.Systems.Input")
local InputCheck = require("Source.Helpers.Core.InputCheck")

local DELAY = 0.35
local RATE = 0.12
local KEYBOARD_IDLE_TIMEOUT = 0.5

local GridNav = {}
GridNav.__index = GridNav
GridNav.active = nil

function GridNav.detectGrid(entries)
	local rows = {}
	for _, e in ipairs(entries) do
		local y = e.ui.offsetY or 0
		local row
		for _, r in ipairs(rows) do
			if math.abs(r.y - y) < (e.sprite.frameHeight or 64) * 0.5 then
				row = r
				break
			end
		end
		if not row then
			row = { y = y, items = {} }
			table.insert(rows, row)
		end
		table.insert(row.items, e)
	end
	table.sort(rows, function(a, b) return a.y < b.y end)
	for _, r in ipairs(rows) do
		table.sort(r.items, function(a, b) return (a.ui.offsetX or 0) < (b.ui.offsetX or 0) end)
	end
	return rows
end

function GridNav.new(entries, opts)
	opts = opts or {}
	local self = setmetatable({
		rows = GridNav.detectGrid(entries),
		r = 1,
		c = 1,
		onConfirm = opts.onConfirm,
		_held = false,
		_next = 0,
		_confirmHeld = false,
		_keyboardActive = false,
		_keyboardIdleTimer = 0,
		_lastDx = 0,
		_lastDy = 0,
	}, GridNav)
	if self.rows[1] then
		self.c = math.max(1, math.ceil(#self.rows[1].items / 2))
	end
	self:_setSelected(self:current(), true)
	return self
end

function GridNav:current()
	local row = self.rows[self.r]
	if not row then return nil end
	return row.items[self.c]
end

function GridNav:focusSprite(sprite)
	for ri, row in ipairs(self.rows) do
		for ci, entry in ipairs(row.items) do
			if entry.sprite == sprite then
				local prev = self:current()
				if prev and prev.sprite ~= sprite then
					self:_setSelected(prev, false)
				end
				self.r, self.c = ri, ci
				self:_setSelected(entry, true)
				return true
			end
		end
	end
	return false
end

function GridNav:move(dx, dy)
	if #self.rows == 0 then return end
	if dy ~= 0 then
		self.r = math.max(1, math.min(#self.rows, self.r + dy))
		local row = self.rows[self.r]
		if row then
			self.c = math.max(1, math.min(#row.items, self.c))
		end
	end
	if dx ~= 0 then
		local row = self.rows[self.r]
		if row and #row.items > 0 then
			self.c = ((self.c - 1 + dx) % #row.items) + 1
		end
	end
end

function GridNav:_setSelected(entry, selected)
	if not entry then return end
	local tw = entry.sprite:findComponent("tween")
	if tw then tw:triggerTag(selected and "select" or "unselect") end
	local hov = entry.sprite:findComponent("hover")
	if hov then hov._hovered = selected end
end

function GridNav:_applyMove(dx, dy)
	local prev = self:current()
	self:move(dx, dy)
	local now = self:current()
	if now == prev then return end
	self:_setSelected(prev, false)
	self:_setSelected(now, true)
end

function GridNav:pollConfirm()
	local down = InputCheck.isDirectionActive(Options.keybinds.confirm)
	if down and not self._confirmHeld then
		self._confirmHeld = true
		local now = self:current()
		if now and self.onConfirm then
			self.onConfirm(now.sprite)
		end
	elseif not down then
		self._confirmHeld = false
	end
end

function GridNav:update(dt)
	if Input.isCaptured() then return end
	local dx, dy = 0, 0
	if InputCheck.isDirectionActive(Options.keybinds.left) then dx = -1
	elseif InputCheck.isDirectionActive(Options.keybinds.right) then dx = 1 end
	if InputCheck.isDirectionActive(Options.keybinds.up) then dy = -1
	elseif InputCheck.isDirectionActive(Options.keybinds.down) then dy = 1 end

	if dx == 0 and dy == 0 then
		self._held = false
		self._lastDx = 0
		self._lastDy = 0
		if self._keyboardActive then
			self._keyboardIdleTimer = self._keyboardIdleTimer + dt
			if self._keyboardIdleTimer >= KEYBOARD_IDLE_TIMEOUT then
				self._keyboardActive = false
			end
		end
	else
		self._keyboardActive = true
		self._keyboardIdleTimer = 0
		if dx ~= self._lastDx or dy ~= self._lastDy then
			self._held = false
		end
		self._lastDx = dx
		self._lastDy = dy
		local t = love.timer.getTime()
		if not self._held then
			self._held = true
			self._next = t + DELAY
			self:_applyMove(dx, dy)
		elseif t >= self._next then
			self._next = t + RATE
			self:_applyMove(dx, dy)
		end
	end
	self:pollConfirm()
end

return GridNav