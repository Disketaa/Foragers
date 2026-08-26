--- Card selection reuses the Darken post-process shader (PostProcess.startSelectionDarken)
--- for the dim — eased in by start() and out by hide(), same easing concept as the intro fade.
--- Show/hide pop is a scale tween on each card (Tween component, tags "show"/"hide"):
--- component draws ignore alpha, so scale 0 is the real hide mechanism.
local Bounds = require("Source.Helpers.Core.Bounds")
local Cursor = require("Source.Sprite.Components.Cursor")
local GameState = require("Source.Helpers.Systems.GameState")
local PostProcess = require("Source.Helpers.Graphics.PostProcess")
local TweenModule = require("Source.Sprite.Components.Tween")
local Tween = TweenModule.Tween
local Easing = TweenModule.Easing

local CardSelect = {}

-- Cards stack at one centre spot (offsetX 0) then separate to their aligned
-- slot. REST_GAP is the resting spacing between card centres (cardW+REST_GAP).
-- Show: stack(0) -> separated(final). Hide: separated(final) -> stack(0).
local REST_GAP = -4
local SHOW_OFFSET_DURATION = 0.3
local HIDE_OFFSET_DURATION = 0.4

local _cards = {}
local _hiding = false

--- Resting horizontal offset for card i of n (centred row).
local function finalOffset(i, n, cardW)
	local slot = i - (n + 1) / 2
	return slot * (cardW + REST_GAP)
end

--- Callers must gate state themselves (start() does); this only lays out + shows.
--- Cards are centered as a row regardless of count (2, 3, 6, 10, ...).
function CardSelect.enter(uiSprites, canvas)
	_cards = {}
	_hiding = false
	for _, entry in ipairs(uiSprites) do
		if entry.sprite.object == "card" then
			table.insert(_cards, entry)
		end
	end

	local n = #_cards
	for i, entry in ipairs(_cards) do
		entry.ui.horizontalAlign = "center"
		entry.ui.verticalAlign = "center"
		entry.sprite.alpha = 1
		local shader = entry.sprite:findComponent("shader")
		if shader then
			shader.skewCenterX = canvas.width * 0.5
			shader.skewCenterY = canvas.height * 0.5
		end
		-- Scale/angle handled by the tween component's "show" tag.
		local s = entry.sprite
		local tw = s:findComponent("tween")
		if tw then
			tw:triggerTag("show")
		end
		-- Stack at centre, then separate to the aligned slot.
		local cardW = s.frameWidth or 64
		entry.ui.offsetX = 0
		entry.offsetTween = Tween.new("offsetX", 0, finalOffset(i, n, cardW), SHOW_OFFSET_DURATION, Easing.OutCubic)
	end
end

--- Pauses the world by switching GameState.state to "cardselect"
--- (Main's `simulating` gate). No-op if already showing or not in game.
---@return boolean shown
function CardSelect.start(uiSprites, canvas)
	if GameState.state ~= "game" or GameState.showingCards then
		return false
	end
	GameState.state = "cardselect"
	CardSelect.enter(uiSprites, canvas)
	GameState.showingCards = true
	PostProcess.startSelectionDarken(PostProcess.SELECTION_DARKEN_TARGET)
	return true
end

--- Begin the hide animation. Keeps showingCards true so cards keep drawing and
--- updating until the scale tween reaches 0; update() finalizes once all done.
function CardSelect.hide()
	if _hiding then
		return
	end
	_hiding = true
	PostProcess.startSelectionDarken(0)
	for _, entry in ipairs(_cards) do
		-- Collapse to centre (offset tween) while the tween component's "hide"
		-- tag shrinks the scale. No vertical motion now.
		local tw = entry.sprite:findComponent("tween")
		if tw then
			tw:triggerTag("hide")
		end
		entry.offsetTween = Tween.new("offsetX", entry.ui.offsetX, 0, HIDE_OFFSET_DURATION, Easing.InOutBack)
	end
end

function CardSelect.isHiding()
	return _hiding
end

--- Called each frame while showingCards. Advances each card's separation
--- tween (stack<->spread). Finalizes once every card has collapsed to centre
--- AND its scale tween (driven by the tween component's "hide" tag) finished.
function CardSelect.update(dt)
	-- Advance each card's offset tween and apply the live horizontal offset.
	for _, entry in ipairs(_cards) do
		if entry.offsetTween then
			entry.offsetTween:update(dt)
			entry.ui.offsetX = entry.offsetTween:getValue()
		end
	end

	if not _hiding then
		return
	end

	-- Finalize once every card has collapsed to centre AND shrunk (scale tween
	-- from the tween component's "hide" tag).
	for _, entry in ipairs(_cards) do
		if entry.offsetTween and not entry.offsetTween:isFinished() then
			return
		end
		local sx = entry.sprite.tweens.scale_x
		if sx and not sx:isFinished() then
			return
		end
	end
	CardSelect.exit()
	GameState.showingCards = false
	GameState.state = "game"
end

function CardSelect.exit()
	for _, entry in ipairs(_cards) do
		entry.sprite.alpha = 0
		entry.offsetTween = nil
	end
	_cards = {}
	_hiding = false
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
