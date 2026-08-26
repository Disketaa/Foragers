--- Card-choosing state: shows 3 upgrade cards horizontally, player picks one.
--- Uses existing card sprites loaded by loadAll (identified by object="card").
--- On enter: finds 3 card sprites in uiSprites, positions with gap, shows them.
--- On exit: hides them. Click detection uses Bounds helper (same math as Hover).
local Bounds = require("Source.Helpers.Core.Bounds")
local Layout = require("Source.UI.Layout")
local Cursor = require("Source.Sprite.Components.Cursor")
local GameState = require("Source.Helpers.Systems.GameState")

local CardChoosing = {}

local GAP = -4
local cardSlots = { -1, 0, 1 }

local _cards = {}

--- Enter card-choosing overlay. Only valid while state=="game".
function CardChoosing.enter(uiSprites, canvas)
	if GameState.state ~= "game" then return end
	_cards = {}
	for _, entry in ipairs(uiSprites) do
		if entry.sprite.object == "card" then
			table.insert(_cards, entry)
		end
	end

	for i, entry in ipairs(_cards) do
		local slot = cardSlots[i] or 0
		local cardW = entry.sprite.frameWidth or 64
		entry.ui.offsetX = slot * (cardW + GAP)
		entry.ui.horizontalAlign = "center"
		entry.ui.verticalAlign = "center"
		entry.sprite.alpha = 1
		Layout.positionUI(entry, canvas)
		local shader = entry.sprite:findComponent("shader")
		if shader then
			shader.skewCenterX = canvas.width * 0.5
			shader.skewCenterY = canvas.height * 0.5
		end
	end
end

--- Guarded enter + set showingCards. Returns true if cards shown.
function CardChoosing.tryEnter(uiSprites, canvas)
	if GameState.state ~= "game" or GameState.showingCards then return false end
	CardChoosing.enter(uiSprites, canvas)
	GameState.showingCards = true
	return true
end

function CardChoosing.exit()
	for _, entry in ipairs(_cards) do
		entry.sprite.alpha = 0
	end
	_cards = {}
end

function CardChoosing.handleClick()
	local cursor = Cursor.active
	if not cursor or not cursor.canvas then
		return nil
	end

	local mx, my = love.mouse.getPosition()
	local cv = cursor.canvas
	local cx = (mx - cv.offsetX) / cv.scale
	local cy = (my - cv.offsetY) / cv.scale

	for _, entry in ipairs(_cards) do
		local left, top, w, h = Bounds.spriteBounds(entry.sprite)
		if cx >= left and cx <= left + w and cy >= top and cy <= top + h then
			-- TODO: apply card modifier to player/gamestate
			return entry.sprite
		end
	end
	return nil
end

return CardChoosing