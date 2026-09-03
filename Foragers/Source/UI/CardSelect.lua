--- Card selection reuses the Darken post-process shader for the dim.
--- Component draws ignore alpha, so scale 0 is the real hide mechanism.
local Bounds = require("Source.Helpers.Core.Bounds")
local Cursor = require("Source.Sprite.Components.Cursor")
local Events = require("Source.Helpers.Core.Events")
local GameState = require("Source.Helpers.Systems.GameState")
local PostProcess = require("Source.Helpers.Graphics.PostProcess")
local GridNav = require("Source.Helpers.UI.GridNav")
local SpriteLoader = require("Source.Sprite.SpriteLoader")
local UIComponent = require("Source.UI.Components.UI")
local SpotlightData = require("Content.Assets.Sprites.UI.Cards.Graphics.Spotlight")

local CardSelect = {}

local REST_GAP = -4

local _cards = {}
local _hiding = false
local _chosen = nil
local _uiSprites = {}
local _spotlight = nil

--- Pickable while group count < maxLevel (unbounded when maxLevel absent).
--- Drives both filtering in enter() and the "no upgrades left" check in shouldShow.
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

local function finalOffset(i, n, cardW)
	local slot = i - (n + 1) / 2
	return slot * (cardW + REST_GAP)
end

--- Callers must gate state themselves (start() does); this only lays out + shows.
function CardSelect.enter(uiSprites)
	_cards = {}
	_hiding = false
	_chosen = nil
	_uiSprites = uiSprites
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
		local s = entry.sprite
		-- Force-reset burn and angle directly on the sprite, bypassing tween
		-- system. The LOVE shader object retains the old uniform otherwise.
		s.angle = 0
		if s.shader then
			s.shader:send("u_burn", 0)
		end
		local shader = s:findComponent("shader")
		if shader then
			shader._uniformValues.u_burn = 0
			s.shaderData.u_burn = 0
		end
		local tw = s:findComponent("tween")
		if tw then
			tw:triggerTag("show")
		end
		-- Level text = chosen count + 1 (first pack shows "1").
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
function CardSelect.start(uiSprites)
	if GameState.state ~= "game" or GameState.showingCards then
		return false
	end
	CardSelect.enter(uiSprites)
	-- All cards maxed: nothing to pick, so don't open the screen.
	if #_cards == 0 then
		CardSelect.exit()
		return false
	end
	GameState.state = "cardselect"
	GameState.showingCards = true
	PostProcess.startSelectionDarken(PostProcess.SELECTION_DARKEN_TARGET)
	GridNav.active = GridNav.new(_cards, {
		onConfirm = function(sprite) CardSelect.applyModifier(sprite); CardSelect.hide(sprite) end,
		onSelect = function(entry, selected)
			if selected then
				entry.sprite:emit(Events.CARD_SELECTED)
				-- Restart the glow pop so it re-pulses on every new selection.
				if _spotlight then
					local stw = _spotlight.sprite:findComponent("tween")
					if stw then
						stw:triggerTag("show")
					end
				end
			end
		end,
	})
	_cards[1].sprite:emit(Events.CARD_SELECT_OPEN)
	-- Spotlight glow lives on its own sprite (layer -1) so it isn't clipped to
	-- the card canvas like a card image component would be; it follows the
	-- selected card each frame in update().
	local spot = SpriteLoader.instantiate(SpotlightData, 0, 0, "Content/Assets/Sprites/UI/Cards/Graphics/Spotlight.png")
	spot.layer = -1
	local spotUI = UIComponent.new({ horizontalAlign = "center", verticalAlign = "center", offsetX = 0, offsetY = 0 })
	spot:addComponent(spotUI)
	_spotlight = { sprite = spot, ui = spotUI }
	table.insert(_uiSprites, _spotlight)
	local tw = spot:findComponent("tween")
	if tw then
		tw:triggerTag("show")
	end
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

---@param chosenSprite table|nil plays the "chosen" pop; others play "hide".
--- Nil means no pick yet (e.g. manual dismiss) and all cards shrink together.
function CardSelect.hide(chosenSprite)
	if _hiding then
		return
	end
	_hiding = true
	_cardSelectHiding = true
	_chosen = chosenSprite
	if chosenSprite then
		chosenSprite.layer = 2
	end
	PostProcess.startSelectionDarken(0, nil, nil, PostProcess.SELECTION_UNDARKEN_DELAY)
	for _, entry in ipairs(_cards) do
		local tw = entry.sprite:findComponent("tween")
		if tw then
			if entry.sprite == chosenSprite then
				tw:triggerTag("chosen")
			else
				tw:triggerTag("hide")
			end
		end
	end
	if _spotlight then
		local stw = _spotlight.sprite:findComponent("tween")
		if stw then
			stw:triggerTag("hide")
		end
	end
	-- Unpause the game immediately when a card is chosen. The chosen card's
	-- burn animation continues playing while the game runs underneath.
	-- showingCards stays true so Main doesn't open another card select and
	-- keeps updating/rendering the card sprites.
	if chosenSprite then
		GameState.state = "game"
	end
end

function CardSelect.isHiding()
	return _hiding
end

function CardSelect.update(dt)
	if _spotlight and GridNav.active then
		local cur = GridNav.active:current()
		if cur then
			_spotlight.ui.offsetX = cur.ui.offsetX
			_spotlight.ui.offsetY = cur.ui.offsetY
		end
	end
	if GridNav.active and not _hiding then
		GridNav.active:update(dt)
	end
	if not _hiding then
		return
	end

	for _, entry in ipairs(_cards) do
		if entry.sprite ~= _chosen then
			for _, tween in pairs(entry.sprite.tweens) do
				if not tween.loop and not tween:isFinished() then
					return
				end
			end
		end
	end
	-- Also wait for chosen card's tweens (burn takes 2s, longer than hide).
	if _chosen then
		for _, tween in pairs(_chosen.tweens) do
			if not tween.loop and not tween:isFinished() then
				return
			end
		end
	end
	CardSelect.exit()
	GameState.showingCards = false
	GameState.state = "game"
end

function CardSelect.exit()
	GridNav.active = nil
	if _spotlight and _uiSprites then
		for i, e in ipairs(_uiSprites) do
			if e == _spotlight then
				table.remove(_uiSprites, i)
				break
			end
		end
		_spotlight = nil
	end
	for _, entry in ipairs(_cards) do
		entry.sprite.tweens.skewAngle = nil
		entry.sprite.alpha = 0
		entry.sprite.layer = 0
	end
	_cards = {}
	_hiding = false
	_cardSelectHiding = false
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
	if not cursor or not cursor.canvas or _hiding then
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
			CardSelect.hide(entry.sprite)
			return entry.sprite
		end
	end
	return nil
end

return CardSelect
