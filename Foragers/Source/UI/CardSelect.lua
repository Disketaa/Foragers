--- Card selection reuses the Darken post-process shader for the dim.
--- Component draws ignore alpha, so scale 0 is the real hide mechanism.
local Bounds = require("Source.Helpers.Core.Bounds")
local Cursor = require("Source.Sprite.Components.Cursor")
local Events = require("Source.Helpers.Core.Events")
local GameState = require("Source.Helpers.Systems.GameState")
local I18n = require("Source.Helpers.Core.I18n")
local PostProcess = require("Source.Helpers.Graphics.PostProcess")
local GridNav = require("Source.Helpers.UI.GridNav")
local Rarities = require("Source.Helpers.Systems.Rarities")
local SpriteLoader = require("Source.Sprite.SpriteLoader")
local TextParser = require("Source.Helpers.Core.TextParser")
local Zoom = require("Source.Helpers.Graphics.Zoom")
local UIComponent = require("Source.UI.Components.UI")
local SpotlightData = require("Content.Assets.Sprites.UI.Cards.Graphics.Spotlight")
local Tiers = require("Source.Helpers.Systems.Tiers")
local Path = require("Source.Helpers.Core.Path")

local CardSelect = {}

local REST_GAP = -4
local ZOOM_ADD = 0.15
local MAX_VISIBLE_CARDS = 3

local _cards = {}
local _hiding = false
_G._cardSelectHiding = false
local _chosen = nil
local _uiSprites = {}
local _spotlight = nil
local _baseZoom = 1
local _cardDefs = {}

local function freshData(data)
	local copy = {}
	for k, v in pairs(data) do
	    if k == "components" and type(v) == "table" then
	        copy.components = {}
	        for _, comp in ipairs(v) do
	            if type(comp) == "table" then
	                local compCopy = {}
	                for ck, cv in pairs(comp) do
	                    compCopy[ck] = cv
	                end
	                table.insert(copy.components, compCopy)
	            end
	        end
	    else
	        copy[k] = v
	    end
	end
	return copy
end

--- Pickable while group count < maxLevel (unbounded when maxLevel absent).
--- Drives both filtering in enter() and the "no upgrades left" check in shouldShow.
local function cardAvailable(def)
	local data = def.data
	local grp = data.group
	if not grp then
	    return true
	end
	local max = data.maxLevel
	if not max then
	    return true
	end
	return (GameState.cardGroupCounts[grp] or 0) < max
end

local function finalOffset(i, n, cardW)
	local slot = i - (n + 1) / 2
	return slot * (cardW + REST_GAP)
end

local function pickWeightedCards(cards, max)
	if #cards <= max then
	    return cards
	end
	local pool = {}
	for _, def in ipairs(cards) do
	    local data = def.data
	    local rarity = data.rarity or "common"
	    table.insert(pool, { def = def, weight = Rarities.weight(rarity) })
	end

	local picked = {}
	for _ = 1, max do
	    if #pool == 0 then
	        break
	    end

	    local totalWeight = 0
	    for _, item in ipairs(pool) do
	        totalWeight = totalWeight + item.weight
	    end

	    if totalWeight <= 0 then
	        local idx = love.math.random(1, #pool)
	        table.insert(picked, pool[idx].def)
	        table.remove(pool, idx)
	    else
	        local roll = love.math.random(1, totalWeight)
	        local cumulative = 0
	        for j, item in ipairs(pool) do
	            cumulative = cumulative + item.weight
	            if roll <= cumulative then
	                table.insert(picked, item.def)
	                table.remove(pool, j)
	                break
	            end
	        end
	    end
	end
	return picked
end

local function applyRarity(entry, rarity)
	entry.sprite.data.rarity = rarity
	-- Re-bake image canvases that use rarity palette so they pick up the new
	-- parent.data.rarity on next draw.
	for _, comp in ipairs(entry.sprite.components) do
	    if comp.type == "image" and comp.palette and comp.palette.scheme == "rarity" then
	        comp._canvas = nil
	    end
	end
	local pal = entry.sprite:findComponent("palette")
	if pal and pal.scheme == "rarity" then
	    pal:setRarity(rarity)
	end
end

local function tweensRunning(sprite)
	for _, tween in pairs(sprite.tweens) do
		if not tween.loop and not tween:isFinished() then
			return true
		end
	end
	return false
end

local function updateSpotlight()
	if not _spotlight or not GridNav.active then
		return
	end
	local cur = GridNav.active:current()
	if cur then
		_spotlight.ui.offsetX = cur.ui.offsetX
		_spotlight.ui.offsetY = cur.ui.offsetY
	end
end

local function setupCardGroup(s)
    local grp = s.data and s.data.group
    if not grp then
        return
    end
    local level = (GameState.cardGroupCounts[grp] or 0) + 1
    local lvl = s:findComponent("text", function(c) return c.id == "level" end)
    if lvl then
        lvl:setText(tostring(level))
    end
    local emblem = s:findComponent("image", function(c) return c.id == "emblem" end)
    local tier = Tiers.tierForLevel(level)
    if emblem then
        emblem:setFrame(tier)
    end
    if lvl then
        lvl:setColor({ Tiers.tierColor(level) })
    end
    local cardTier = s:findComponent("tier")
    if cardTier and grp == "pickaxe" then
        cardTier:setLevel(level)
    end
end

local function setupCardModifier(s)
    local mod = s.data and s.data.modifier
    if not (mod and type(mod) == "table" and mod.stat) then
        return
    end
    local stats = GameState.playerSprite and GameState.playerSprite:findComponent("player_stats")
    local desc = s:findComponent("text", function(c) return c.id == "description" end)
    if not (stats and desc and desc._rawText and desc._rawText.key) then
        return
    end
    local rarity = s.data and s.data.rarity or "common"
    local scale = Rarities.scale(rarity)
    local amount = (mod.baseAmount or 0) * scale
    local old, new = stats:previewStat({ stat = mod.stat, amount = amount })
    local raw = I18n.withDelta(desc._rawText.key, old, new, desc._rawText.params)
    desc._rawText = raw
    desc:setText(TextParser.resolve(raw))
end

local function setupCard(entry, i, n)
    entry.ui.horizontalAlign = "center"
    entry.ui.verticalAlign = "center"
    entry.sprite.alpha = 1
    entry.sprite.scaleX = 1
    entry.sprite.scaleY = 1
    local s = entry.sprite
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
    setupCardGroup(s)
    setupCardModifier(s)
    local cardW = s.frameWidth or 64
    entry.ui.offsetX = finalOffset(i, n, cardW)
end

--- Callers must gate state themselves (start() does); this only lays out + shows.
function CardSelect.enter(uiSprites)
	_cards = {}
	_hiding = false
	_chosen = nil
	_uiSprites = uiSprites

	-- Load card defs once and cache them.
	if #_cardDefs == 0 then
	    _cardDefs = SpriteLoader.loadDefs("Content/Assets/Sprites/UI/Cards") or {}
	end

	local available = {}
	for _, def in ipairs(_cardDefs) do
	    local data = def.data
	    if data.object == "card" and cardAvailable(def) then
	        table.insert(available, def)
	    end
	end

	local picked = pickWeightedCards(available, MAX_VISIBLE_CARDS)
	for _, def in ipairs(picked) do
	    local rarity = Rarities.pick()
	    local data = freshData(def.data)
	    local sprite = SpriteLoader.instantiate(data, 0, 0, Path.png(def.path))
	    local uiComp = sprite:findComponent("ui")
	    local entry = { sprite = sprite, ui = uiComp }
	    if not uiComp then
	        table.remove(_cards, #_cards)
	        table.remove(_uiSprites, #_uiSprites)
	    else
	        applyRarity(entry, rarity)
	        table.insert(_cards, entry)
	        table.insert(_uiSprites, entry)
	    end
	end

	local n = #_cards
	for i, entry in ipairs(_cards) do
	    setupCard(entry, i, n)
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
	_baseZoom = Zoom.target
	if #_cards == 0 then
	    CardSelect.exit()
	    return false
	end
	GameState.state = "cardselect"
	GameState.showingCards = true
	PostProcess.startSelectionDarken(PostProcess.SELECTION_DARKEN_TARGET)
	GridNav.active = GridNav.new(_cards, {
	    onConfirm = function(sprite) CardSelect.applyModifier(sprite); Zoom.current = _baseZoom + ZOOM_ADD; Zoom.target = _baseZoom; CardSelect.hide(sprite) end,
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
function CardSelect.shouldShow(_)
	if #_cardDefs == 0 then
	    _cardDefs = SpriteLoader.loadDefs("Content/Assets/Sprites/UI/Cards") or {}
	end
	for _, def in ipairs(_cardDefs) do
	    local data = def.data
	    if data.object == "card" and cardAvailable(def) then
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
	_G._cardSelectHiding = true
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
	            entry.sprite:emit(Events.CARD_CHOOSE)
	        else
	            tw:triggerTag("hide")
	            entry.sprite:emit(Events.CARD_HIDE)
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
	updateSpotlight()
	if GridNav.active and not _hiding then
	    GridNav.active:update(dt)
	end
	if not _hiding then
	    return
	end

	for _, entry in ipairs(_cards) do
	    if entry.sprite ~= _chosen and tweensRunning(entry.sprite) then
	        return
	    end
	end
	-- Also wait for chosen card's tweens (burn takes 2s, longer than hide).
	if _chosen and tweensRunning(_chosen) then
	    return
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
	    entry.sprite.scaleX = 0
	    entry.sprite.scaleY = 0
	    entry.sprite.layer = 0
	end
	-- Remove instantiated cards from _uiSprites and drop refs.
	local isCard = {}
	for _, card in ipairs(_cards) do
	    isCard[card] = true
	end
	for i = #_uiSprites, 1, -1 do
	    if isCard[_uiSprites[i]] then
	        table.remove(_uiSprites, i)
	    end
	end
	_cards = {}
	_hiding = false
	_G._cardSelectHiding = false
end

local function refreshWeaponUI(grp)
    local wt = GameState.weaponLevelText
    local we = GameState.weaponEmblem
    local wtw = GameState.weaponTween
    local wpalette = GameState.weaponTier
    if not (wt or we or wtw or wpalette) then
        return
    end
    local wgrp = "pickaxe"
    local wlvl = (GameState.cardGroupCounts[wgrp] or 0)
    if wt then
        wt:setText(tostring(wlvl))
        wt:setColor({ Tiers.tierColor(wlvl) })
    end
    if we then
        local emblemTier = Tiers.tierForLevel(wlvl)
        we:setFrame(emblemTier)
    end
    if wtw and grp == wgrp then
        wtw:triggerTag("chosen")
    end
    if wpalette and grp == wgrp then
        wpalette:setLevel(wlvl)
    end
    local heldWeapon = GameState.weaponSprite
    if heldWeapon and grp == wgrp then
        local heldTier = heldWeapon:findComponent("tier")
        if heldTier then
            heldTier:setLevel(wlvl)
        end
    end
end

function CardSelect.applyModifier(sprite)
	local mod = sprite.data and sprite.data.modifier
	if not mod then
	    return
	end
	local grp = sprite.data and sprite.data.group
	if grp then
	    GameState.cardGroupCounts[grp] = (GameState.cardGroupCounts[grp] or 0) + 1
	end
	refreshWeaponUI(grp)
	local stats = GameState.playerSprite and GameState.playerSprite:findComponent("player_stats")
	if not stats then
	    return
	end
	if type(mod) == "function" then
	    mod(stats)
	    return
	end
	local rarity = sprite.data and sprite.data.rarity or "common"
	local scale = Rarities.scale(rarity)
	local amount = (mod.baseAmount or 0) * scale
	local cur = stats[mod.stat]
	if type(cur) == "table" then
	    cur.base = (cur.base or 0) + amount
	else
	    stats[mod.stat] = (stats[mod.stat] or 0) + amount
	end
end

function CardSelect.handleClick()
	local cursor = Cursor.active
	if not cursor or not cursor.canvas or _hiding then
	    return nil
	end
	if cursor._state == "hidden" then
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
	        Zoom.current = _baseZoom + ZOOM_ADD
	        Zoom.target = _baseZoom
	        CardSelect.hide(entry.sprite)
	        return entry.sprite
	    end
	end
	return nil
end

return CardSelect