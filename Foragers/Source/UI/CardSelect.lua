--- Card selection reuses the Darken post-process shader (PostProcess.startSelectionDarken)
--- for the dim — eased in by start() and out by hide(), same easing concept as the intro fade.
--- Show/hide pop is a scale tween on each card (Tween component, tags "show"/"hide"):
--- component draws ignore alpha, so scale 0 is the real hide mechanism.
local Bounds = require("Source.Helpers.Core.Bounds")
local Cursor = require("Source.Sprite.Components.Cursor")
local GameState = require("Source.Helpers.Systems.GameState")
local PostProcess = require("Source.Helpers.Graphics.PostProcess")

local CardSelect = {}

-- REST_GAP is the resting spacing between card centres (cardW+REST_GAP).
local REST_GAP = -4

local _cards = {}
local _hiding = false

--- A card is still pickable while its group's chosen count is below the card's
--- maxLevel (unbounded when maxLevel is absent). Drives both filtering and the
--- "no upgrades left" check in shouldShow.
local function cardAvailable(sprite)
	local grp = sprite.data and sprite.data.group
	if not grp then
		return true
	end
	local max = sprite.data.maxLevel
	if not max then
		return true
	end
	return (GameState.cardGroupCounts[grp] or 0) < max
end

--- Resting horizontal offset for card i of n (centred row).
local function finalOffset(i, n, cardW)
	local slot = i - (n + 1) / 2
	return slot * (cardW + REST_GAP)
end

--- Callers must gate state themselves (start() does); this only lays out + shows.
function CardSelect.enter(uiSprites, canvas)
	_cards = {}
	_hiding = false
	for _, entry in ipairs(uiSprites) do
		if entry.sprite.object == "card" and cardAvailable(entry.sprite) then
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
		-- Level text = chosen count of this card's group + 1 (first pack shows "1").
		local grp = s.data and s.data.group
		if grp then
			local level = (GameState.cardGroupCounts[grp] or 0) + 1
			local lvl = s:findComponent("text", function(c) return c.id == "level" end)
			if lvl then
				lvl:setText(tostring(level))
			end
			-- Emblem tier: 5 frames span levels 0-4, 5-9, 10-14, 15-19, 20.
			local emblem = s:findComponent("image", function(c) return c.id == "emblem" end)
			local maxTier = (emblem and emblem._ss and emblem._ss.columns) or 5
			local tier = math.min(maxTier, math.floor(level / 5) + 1)
			if emblem then
				emblem:setFrame(tier)
			end
			-- Match the level text color to the emblem tier's background.
			if lvl and lvl.tierColors then
				lvl:setColor(lvl.tierColors[tier] or lvl.tierColors[1])
			end
		end
		local cardW = s.frameWidth or 64
		entry.ui.offsetX = finalOffset(i, n, cardW)
	end
end

--- Pauses the world by switching GameState.state to "cardselect"
--- (Main's `simulating` gate). No-op if already showing or not in game.
---@return boolean shown
function CardSelect.start(uiSprites, canvas)
	if GameState.state ~= "game" or GameState.showingCards then
		return false
	end
	CardSelect.enter(uiSprites, canvas)
	-- All cards maxed: nothing to pick, so don't open the screen.
	if #_cards == 0 then
		CardSelect.exit()
		return false
	end
	GameState.state = "cardselect"
	GameState.showingCards = true
	PostProcess.startSelectionDarken(PostProcess.SELECTION_DARKEN_TARGET)
	return true
end

--- True if at least one card is still below its maxLevel. Caller consumes the
--- pending level-up whether or not this returns true, so a fully-maxed run
--- never retries the (now impossible) selection every frame.
function CardSelect.shouldShow(uiSprites)
	for _, entry in ipairs(uiSprites) do
		if entry.sprite.object == "card" and cardAvailable(entry.sprite) then
			return true
		end
	end
	return false
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
		local tw = entry.sprite:findComponent("tween")
		if tw then
			tw:triggerTag("hide")
		end
	end
end

function CardSelect.isHiding()
	return _hiding
end

--- Called each frame while showingCards. Finalizes once every card's scale tween
--- (driven by the tween component's "hide" tag) finished.
function CardSelect.update(dt)
	if not _hiding then
		return
	end

	for _, entry in ipairs(_cards) do
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
	-- Count the pick toward its group (even if stats component is missing).
	local grp = sprite.data and sprite.data.group
	if grp then
		GameState.cardGroupCounts[grp] = (GameState.cardGroupCounts[grp] or 0) + 1
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
