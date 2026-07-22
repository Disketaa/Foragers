local SpriteLoader = require("Source.Sprite.SpriteLoader")
local Path = require("Source.Helpers.Path")

local Text = {}
Text.__index = Text

---@param opts table|string If string: text content
---@param x number|nil
---@param y number|nil
---@param fontPath string|nil Lua require path to font data
function Text.new(opts, x, y, fontPath)
	if type(opts) == "string" then
		opts = { text = opts, x = x, y = y, font = fontPath }
	end
	opts = opts or {}
	opts.text = opts.text or ""
	opts.x = opts.x or 0
	opts.y = opts.y or 0
	opts.font = opts.font or "Content.Assets.Sprites.UI.Fonts.Tinylorder"

	local self = setmetatable({
		_sprite = nil,
		_fontComp = nil,
		_fontPath = opts.font,
		_text = opts.text,
		_color = opts.color,
		x = opts.x,
		y = opts.y,
	}, Text)

	self:loadFont()
	return self
end

function Text:loadFont()
	local luaPath = Path.moduleToPath(self._fontPath)
	local pngPath = luaPath .. ".png"
	local ok, data = pcall(require, self._fontPath)
	if not ok or not data then
		return
	end

	local sprite = SpriteLoader.instantiate(data, self.x, self.y, pngPath)
	if not sprite then
		return
	end

	self._sprite = sprite

	for _, comp in ipairs(sprite.components) do
		if comp.type == "spritefont" then
			self._fontComp = comp
			break
		end
	end

	if self._fontComp then
		self._fontComp.text = self._text
		if self._color then
			self._fontComp.color = self._color
		end
	end
end

---@param text string
function Text:setText(text)
	self._text = text or ""
	if self._fontComp then
		self._fontComp.text = self._text
	end
end

---@param color table {r, g, b, a}
function Text:setColor(color)
	if self._fontComp then
		self._fontComp.color = color
	end
end

---@param x number
---@param y number
function Text:setPosition(x, y)
	self.x = x or self.x
	self.y = y or self.y
	if self._sprite then
		self._sprite.x = self.x
		self._sprite.y = self.y
	end
end

function Text:draw()
	if self._sprite and self._sprite.draw then
		self._sprite:draw()
	end
end

return Text