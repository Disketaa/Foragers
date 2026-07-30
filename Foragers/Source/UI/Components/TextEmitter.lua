local Path = require("Source.Helpers.Path")
local ValueParser = require("Source.Helpers.ValueParser")
local Easing = require("Source.Sprite.Components.Tween").Easing
local SpriteFont = require("Source.Sprite.Components.SpriteFont")

local activeTexts = {}
local fontCache = {}

local function loadFont(fontPath)
	if fontCache[fontPath] ~= nil then
		return fontCache[fontPath]
	end

	local SpriteLoader = require("Source.Sprite.SpriteLoader")
	local fsPath = Path.moduleToPath(fontPath)
	local pngPath = fsPath .. ".png"

	local ok, fontData = pcall(require, fontPath)
	if not ok or not fontData then
		print("[TextEmitter] FONT REQUIRE FAILED: " .. tostring(fontPath) .. " err=" .. tostring(fontData))
		fontCache[fontPath] = false
		return nil
	end

	local sprite = SpriteLoader.instantiate(fontData, 0, 0, pngPath)
	if not sprite then
		print("[TextEmitter] FONT INSTANTIATE FAILED: " .. tostring(fontPath))
		fontCache[fontPath] = false
		return nil
	end

	local spriteFont = nil
	local spritesheet = nil
	for _, comp in ipairs(sprite.components) do
		if comp.type == "spritefont" then
			spriteFont = comp
		elseif comp.type == "spritesheet" then
			spritesheet = comp
		end
	end

	if not spriteFont or not spritesheet then
		fontCache[fontPath] = false
		return nil
	end

	local ref = {
		image = spritesheet.image,
		quads = spritesheet.quads,
		charIndex = spriteFont._charIndex,
		charWidth = spriteFont._charWidth,
		charSpacing = spriteFont.charSpacing,
		frameW = spritesheet.frameWidth,
		frameH = spritesheet.frameHeight,
		pivotX = spritesheet.pivotX or 0.5,
		pivotY = spritesheet.pivotY or 0.5,
	}
	fontCache[fontPath] = ref
	return ref
end

local TextEmitter = {}
TextEmitter.__index = TextEmitter

function TextEmitter.new(data)
	return setmetatable({
		font = data.font or "Content.Assets.Sprites.UI.Fonts.Tinylorder",
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
	}, TextEmitter)
end

function TextEmitter:attach()
	local ref = loadFont(self.font)
	if not ref then
		return
	end

	self.parent:on(self.event, function(eventText)
		local displayText = self.text or tostring(eventText or "")
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
			fontRef = ref,
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
			else -- instant
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
		local ref = t.fontRef
		if ref then
			local alpha = math.max(0, math.min(1, t.alpha))
			SpriteFont.drawText(ref, t.text, t.x, t.y, {
				color = t.color,
				alpha = alpha,
				scale = t.scale,
			})
		end
	end

	love.graphics.setShader(prevShader)
end

return TextEmitter
