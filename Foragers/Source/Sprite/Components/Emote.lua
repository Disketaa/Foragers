local Events = require("Source.Helpers.Events")
local Path = require("Source.Helpers.Path")
local ValueParser = require("Source.Helpers.ValueParser")
local Pivot = require("Source.Helpers.Pivot")
local SpriteSheet = require("Source.Sprite.Components.SpriteSheet")
local TweenModule = require("Source.Sprite.Components.Tween")

---@class Emote
---@field parent Sprite|nil
---@field object string Path to emote sprite data (spritesheet + PNG)
---@field event string Event string that triggers the emote
---@field offsetX number
---@field offsetY number
---@field duration number Seconds to show before the hide tween runs
---@field tweens table[] Spawn/pop-in tween set, runs on trigger (no tag, like drops on spawn)
---@field tags table<string, table[]> Tagged tween sets (e.g. `hide`)
---@field flipX boolean Mirrors parent flip for render (read in draw only)
---@field _liveTweens table<string, Tween> Live tween objects keyed by target (draw reads these)
---@field _sheet table|nil Internal spritesheet component
---@field _image love.Image|nil Static image (non-spritesheet emotes)
---@field _active boolean
---@field _hiding boolean
---@field _elapsed number
---@field _duration number
---@field _hideTweens table[]
---@field type "emote"
local Emote = {}
Emote.__index = Emote

---@param data table
---@return Emote
function Emote.new(data)
	local self = setmetatable({
		object = data.object,
		event = data.event or "low_satiety",
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or -8,
		duration = data.duration,
		tweens = {},
		tags = {},
		flipX = false,
		_liveTweens = {},
		_sheet = nil,
		_image = nil,
		_active = false,
		_hiding = false,
		_elapsed = 0,
		_duration = 0,
		_hideTweens = {},
		type = "emote",
	}, Emote)

	local ok, emoteData = pcall(require, Path.lua(self.object))
	if ok and emoteData then
		ValueParser.table(emoteData)

		-- Emote data is self-contained: its `tween` component carries the spawn
		-- pop-in (`tweens`, runs on trigger like drops on spawn) and the exit
		-- animation (`tags.hide`). Read both from it.
		for _, comp in ipairs(emoteData.components or {}) do
			if comp.component == "tween" then
				self.tweens = comp.tweens or {}
				self.tags = comp.tags or {}
				break
			end
		end

		-- Spritesheet path (single-frame or animated): embed the sheet and wire it
		-- to this component as its parent so draw() applies our scale/flip.
		for _, comp in ipairs(emoteData.components or {}) do
			if comp.component == "spritesheet" then
				local compData = {}
				for k, v in pairs(comp) do
					compData[k] = v
				end
				compData.frameWidth = emoteData.frameWidth
				compData.frameHeight = emoteData.frameHeight
				compData.pivotX = emoteData.pivotX
				compData.pivotY = emoteData.pivotY
				if not compData.spriteSheet then
					compData.spriteSheet = Path.png(self.object)
				end
				local ok2, sp = pcall(SpriteSheet.new, compData)
				if ok2 and sp and sp.quads then
					sp.parent = self
					self._sheet = sp
					local anim = sp.animations and sp.animations[sp.currentAnim]
					if anim then
						self._duration = anim.frames / anim.speed
					end
				end
				break
			end
		end

		-- No spritesheet in data: plain-image emotes (e.g. Cursor) draw the raw PNG.
		if not self._sheet then
			local pngInfo = love.filesystem.getInfo(Path.png(self.object))
			if pngInfo then
				local ok2, image = pcall(love.graphics.newImage, Path.png(self.object))
				if ok2 and image then
					self._image = image
					self.frameWidth = emoteData.frameWidth
					self.frameHeight = emoteData.frameHeight
					self.pivotX = emoteData.pivotX or "center"
					self.pivotY = emoteData.pivotY or "center"
					self._duration = emoteData.lifetime or 1
				end
			end
		end
	end

	-- `duration` is the emote component's param; falls back to the sheet
	-- animation length, then 1s.
	self._duration = self.duration or self._duration or 1

	return self
end

--- Turn a tween-def array into live Tween objects, stored in _liveTweens (keyed
--- by target so getDrawContext reads them) and returned as a list for finish checks.
---@param defs table[]
---@return table[]
local function buildTweens(self, defs)
	local list = {}
	self._liveTweens = {}
	for _, td in ipairs(defs or {}) do
		if td.target then
			local tween = TweenModule.Tween.new(
				td.target,
				ValueParser.call(td, "from"),
				ValueParser.call(td, "to"),
				ValueParser.call(td, "duration"),
				TweenModule.Easing[td.curve] or TweenModule.Easing.OutBack
			)
			tween:start()
			list[#list + 1] = tween
			self._liveTweens[td.target] = tween
		end
	end
	return list
end

function Emote:attach()
	local eventName = Events[self.event:upper()] or self.event
	self.parent:on(eventName, function()
		self:trigger()
	end, 5)
end

--- Start (or restart) the emote: play the spawn pop-in, then the hide tag after `duration`.
function Emote:trigger()
	if not self._sheet and not self._image then
		return
	end
	self._active = true
	self._hiding = false
	self._elapsed = 0
	self._hideTweens = buildTweens(self, self.tweens)
	if self._sheet then
		self._sheet.currentTime = 0
	end
end

--- Kick off the `hide` tween tag; if none defined, hide immediately.
function Emote:startHide()
	if not self.tags.hide or #self.tags.hide == 0 then
		self._active = false
		self._hiding = false
		return
	end
	self._hiding = true
	self._hideTweens = buildTweens(self, self.tags.hide)
end

function Emote:update(dt)
	if not self._active then
		return
	end
	if self._hiding then
		local allDone = true
		for _, tween in ipairs(self._hideTweens) do
			tween:update(dt)
			if not tween:isFinished() then
				allDone = false
			end
		end
		if allDone then
			self._active = false
			self._hiding = false
		end
	else
		self._elapsed = self._elapsed + dt
		if self._duration > 0 and self._elapsed >= self._duration then
			self:startHide()
		end
		for _, tween in pairs(self._liveTweens) do
			tween:update(dt)
		end
	end
	if self._sheet then
		self._sheet.currentTime = self._elapsed
	end
end

--- Mirror Sprite.getDrawContext so the embedded spritesheet applies our scale/flip.
function Emote:getDrawContext()
	local sx, sy = 1, 1
	local rot = 0
	local t = self._liveTweens.scale_x
	if t then
		sx = t:getValue()
	end
	t = self._liveTweens.scale_y
	if t then
		sy = t:getValue()
	end
	t = self._liveTweens.angle
	if t then
		rot = math.rad(t:getValue())
	end
	if self.flipX then
		sx = -sx
	end
	return sx, sy, rot, self.alpha or 1
end

function Emote:draw()
	if not self._active or not self.parent then
		return
	end
	self.flipX = self.parent.flipX
	local x = self.parent.x + self.offsetX
	local y = self.parent.y + self.offsetY
	if self._sheet then
		self._sheet:draw(x, y)
	elseif self._image then
		local sx, sy, rot, alpha = self:getDrawContext()
		local ox = Pivot.px(self.pivotX, self.frameWidth, "center")
		local oy = Pivot.px(self.pivotY, self.frameHeight, "center")
		if alpha < 1 then
			love.graphics.setColor(1, 1, 1, alpha)
		end
		love.graphics.draw(self._image, math.floor(x + 0.5), math.floor(y + 0.5), rot, sx, sy, ox, oy)
		if alpha < 1 then
			love.graphics.setColor(1, 1, 1, 1)
		end
	end
end

return Emote
