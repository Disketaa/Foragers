local Log = require("Source.Helpers.Core.Log")
local ValueParser = require("Source.Helpers.Core.ValueParser")
local Easing = require("Source.Sprite.Components.Tween").Easing
local Font = require("Source.Sprite.Components.Font")

local activeTexts = {}

---@class TextEmitter
---@field font string
---@field fontSize number
---@field text string|nil
---@field event string
---@field color table
---@field moveX number
---@field moveY number
---@field gravity number
---@field duration number
---@field offsetX number
---@field offsetY number
---@field destroy string
---@field destroyCurve string
---@field type string
---@field parent Sprite
local TextEmitter = {}
TextEmitter.__index = TextEmitter

---@param data table Component config: font, fontSize, text, event, color, motion (moveX/moveY/gravity/duration/offsetX/offsetY), destruction (destroy/destroyCurve).
--- Motion fields may be range ("-6..-8") or choice ("-10|10") strings. ValueParser.table resolves them and stores
--- originals in t.__raw so ValueParser.call re-rolls per emit; without it the raw strings leak into arithmetic in the handler.
---@return TextEmitter
function TextEmitter.new(data)
	local t = {
		font = data.font or "Content/Assets/Sprites/UI/Fonts/Tinylorder.ttf",
		fontSize = data.fontSize or Font.DEFAULT_SIZE,
		text = data.text,
		event = data.event or "prop_hit",

		color = data.color or { 1, 1, 1 },

		-- motion (moveY negative = upward, gravity pulls down)
		moveX = data.moveX or 0,
		moveY = data.moveY or -120,
		gravity = data.gravity or 400,

		duration = data.duration or 0.8,
		offsetX = data.offsetX or 0,
		offsetY = data.offsetY or -8,

		-- destruction: "fade" (alpha 1->0) | "scale" (scale 1->0) | "instant"
		destroy = data.destroy or "fade",
		destroyCurve = data.destroyCurve or "Linear",

		type = "text_emitter",
	}
	ValueParser.table(t)
	return setmetatable(t, TextEmitter)
end

function TextEmitter:attach()
	local fontObj = Font.load(self.font, self.fontSize)
	if not fontObj then
		return
	end
	self._fontObj = fontObj

	self.parent:on(self.event, function(eventText)
		local value = eventText
		if type(value) == "number" then
			value = math.floor(value)
		end
		local displayText = self.text or tostring(value or "")
		if displayText == "" then
			return
		end

		-- re-roll random params per emit so choice/range strings vary each hit
		local moveX = ValueParser.call(self, "moveX")
		local moveY = ValueParser.call(self, "moveY")
		local gravity = ValueParser.call(self, "gravity")
		local duration = ValueParser.call(self, "duration")
		local offsetX = ValueParser.call(self, "offsetX")
		local offsetY = ValueParser.call(self, "offsetY")

		local baseX = self.parent.x + offsetX
		local baseY = self.parent.y + offsetY

		local num = {
			text = displayText,
			baseX = baseX,
			baseY = baseY,
			x = baseX,
			y = baseY,
			scale = 1,
			alpha = 1,
			age = 0,
			duration = duration,
			moveX = moveX,
			moveY = moveY,
			gravity = gravity,
			destroy = self.destroy,
			destroyCurve = self.destroyCurve,
			color = self.color,
			fontRef = self._fontObj,
		}
		table.insert(activeTexts, num)
	end, 5)
end

function TextEmitter:update(dt) end
function TextEmitter:draw(x, y) end

--- Advance all active floating texts (called from Main)
function TextEmitter.updateAll(dt)
	for i = #activeTexts, 1, -1 do
		local t = activeTexts[i]
		t.age = t.age + dt
		if t.age >= t.duration then
			table.remove(activeTexts, i)
		else
			local p = t.age / t.duration
			t.x = t.baseX + t.moveX * t.age
			t.y = t.baseY + t.moveY * t.age + 0.5 * t.gravity * t.age * t.age

			-- animated property always goes 1 -> 0, shaped by the easing curve
			local eased = (Easing[t.destroyCurve] or Easing.Linear)(p)
			if t.destroy == "fade" then
				t.alpha = 1 - eased
				t.scale = 1
			elseif t.destroy == "scale" then
				t.scale = 1 - eased
				t.alpha = 1
			elseif t.destroy == "instant" then
				t.alpha = 1
				t.scale = 1
			else
				Log.error("TextEmitter", "unknown destroy mode '%s'; defaulting to instant", tostring(t.destroy))
				t.alpha = 1
				t.scale = 1
			end
		end
	end
end

--- Draw all active floating texts (called from Main)
function TextEmitter.drawAll()
	if #activeTexts == 0 then
		return
	end

	local prevShader = love.graphics.getShader()
	love.graphics.setShader()

	for _, t in ipairs(activeTexts) do
		local fontObj = t.fontRef
		if fontObj then
			local alpha = math.max(0, math.min(1, t.alpha))
			Font.drawText({ font = fontObj, charSpacing = 0 }, t.text, t.x, t.y, {
				color = t.color,
				alpha = alpha,
				scale = t.scale,
			})
		end
	end

	love.graphics.setShader(prevShader)
end

return TextEmitter
