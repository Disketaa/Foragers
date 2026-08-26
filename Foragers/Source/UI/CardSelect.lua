--- Card selection reuses the Darken post-process shader (PostProcess.startCardDarken)
--- for the dim — eased in by start() and out by finish(), same easing concept as the intro fade.
local Bounds = require("Source.Helpers.Core.Bounds")
local Layout = require("Source.UI.Layout")
local Cursor = require("Source.Sprite.Components.Cursor")
local GameState = require("Source.Helpers.Systems.GameState")
local PostProcess = require("Source.Helpers.Graphics.PostProcess")

local CardSelect = {}

local GAP = -4
local cardSlots = { -1, 0, 1 }

local _cards = {}

--- Callers must gate state themselves (start() does); this only lays out + shows.
function CardSelect.enter(uiSprites, canvas)
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

--- Start the card-select state from gameplay (level up). Pauses the world by
--- switching GameState.state to "cardselect" (Main's `simulating` gate), dims
--- the background, and shows the cards. No-op if already showing or not in game.
---@return boolean shown
function CardSelect.start(uiSprites, canvas)
	if GameState.state ~= "game" or GameState.showingCards then
		return false
	end
	GameState.state = "cardselect"
	CardSelect.enter(uiSprites, canvas)
	GameState.showingCards = true
	PostProcess.startCardDarken(PostProcess.CARD_DARKEN_TARGET)
	return true
end

function CardSelect.finish()
	PostProcess.startCardDarken(0)
	CardSelect.exit()
	GameState.showingCards = false
	GameState.state = "game"
end

function CardSelect.exit()
	for _, entry in ipairs(_cards) do
		entry.sprite.alpha = 0
	end
	_cards = {}
end

--- Apply a card's modifier to the player. Modifier is read from the card's data
--- table: either a function `modifier(stats)` or a table
--- `{ stat = "damage", amount = 2 }`. Handles both number and {base,gain} stats.
function CardSelect.applyModifier(sprite)
	local mod = sprite.data and sprite.data.modifier
	if not mod then
		return
	end
	local stats = GameState.playerSprite and GameState.playerSprite:findComponent("player_stats")
	if not stats then
		return
	end
	if type(mod) == "function" then
		mod(stats)
		return
	end
	local cur = stats[mod.stat]
	if type(cur) == "table" then
		cur.base = (cur.base or 0) + (mod.amount or 0)
	else
		stats[mod.stat] = (stats[mod.stat] or 0) + (mod.amount or 0)
	end
end

function CardSelect.handleClick()
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
			CardSelect.applyModifier(entry.sprite)
			return entry.sprite
		end
	end
	return nil
end

return CardSelect
