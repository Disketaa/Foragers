local Canvas = require("Source.Helpers.Graphics.Canvas")
local DayCycle = require("Source.Helpers.Systems.DayCycle")
local Data = require("Content.Data.World").dayCycle

---@class Shadow
---@field parent Sprite|nil
---@field offsetMultiplier number Reserved; previously scaled the sun-driven shadow offset. The sun no longer translates the shadow, so this is currently unused.
---@field offsetX number Static px added to the shadow position on top of the sun-driven offset (per-object horizontal nudge)
---@field offsetY number Static px added to the shadow position on top of the sun-driven offset (per-object vertical nudge)
---@field width number Shadow width in px
---@field height number Shadow height in px
---@field type "shadow"
local Shadow = {}
Shadow.__index = Shadow

-- All shadows drawn 100% opaque to one canvas, then composited once at
-- layerAlpha: overlaps union (no additive darkening), blend touched once/frame.
local layerAlpha = 0.3
local layerColor = { 0, 0, 0.2 }

local shadowCanvas = nil
local ensureCanvas = Canvas.createCanvasManager()

-- 1px-corner-rounded shadow from 3 rectangle() calls.
---@param x number Integer world X (top-left)
---@param y number Integer world Y (top-left)
---@param w number Width in px
---@param h number Height in px
local function drawShape(x, y, w, h)
	if w <= 0 or h <= 0 then
		return
	end
	if w <= 2 or h <= 2 then
		love.graphics.rectangle("fill", x, y, w, h)
		return
	end
	love.graphics.rectangle("fill", x + 1, y, w - 2, 1)
	love.graphics.rectangle("fill", x, y + 1, w, h - 2)
	love.graphics.rectangle("fill", x + 1, y + h - 1, w - 2, 1)
end

Shadow.drawShape = drawShape

-- Batch shadow rects into one draw call. Count is bounded by on-screen props
-- (culled), so 20000 slots are ample for any world size.
local whiteImage = nil
local shadowBatch = nil
local function ensureBatch()
	if shadowBatch then
		return shadowBatch
	end
	local id = love.image.newImageData(1, 1)
	id:setPixel(0, 0, 255, 255, 255, 255)
	whiteImage = love.graphics.newImage(id)
	shadowBatch = love.graphics.newSpriteBatch(whiteImage, 20000, "dynamic")
	return shadowBatch
end

local shadowScan = {}
local function hasShadow(c)
	return not c._broken
end

---@param sprites table[] Entries with `.instance` (sprite) — same list Main sorts
---@param viewW number World canvas width (px)
---@param viewH number World canvas height (px)
---@param camX number Camera pixel offset X (float for smooth scrolling)
---@param camY number Camera pixel offset Y (float for smooth scrolling)
function Shadow.renderLayer(sprites, viewW, viewH, camX, camY)
	-- Raw target alpha, not eased display.alpha: exponential smoothing never
	-- reaches exactly 0, so gate would never fire at night.
	if DayCycle.getSunData(DayCycle.time).alpha <= 0 then
		return
	end
	local display = DayCycle.getDisplaySunData()
	shadowCanvas = ensureCanvas(viewW, viewH)
	local timeShiftPerPx = Data.shadow.timeShiftPerPx or 0
	local worldCenterX = Data.shadow.worldCenterX or 0

	Canvas.drawTo(
		shadowCanvas,
		function()
			shadowBatch = ensureBatch()
			shadowBatch:clear()
			for _, entry in ipairs(sprites) do
				local sprite = entry.instance or entry
				if sprite and sprite.components then
					local comps = sprite:getComponentsInto("shadow", hasShadow, shadowScan)
					for _, comp in ipairs(comps) do
						-- Phase-shift the golden hour per prop so stretch/offset/alpha
						-- sweep across the island by X instead of all props peaking at once.
						local sx = math.floor(sprite.x + 0.5)
						local effTime = (display.time + (sx - worldCenterX) * timeShiftPerPx) % 24
						local sun = DayCycle.getSunData(effTime)

						-- Derive extraPx from |offsetX| so width and the pivot flip stay
						-- consistent: both hit 0 at offsetX=0 (phase-shifted horizon).
						local lengthRatio = Data.shadow.maxLen > 0 and math.min(1, math.abs(sun.offsetX) / Data.shadow.maxLen) or 0
						local extraPx = math.floor((Data.shadow.stretchPx or 0) * lengthRatio + 0.5)

						local ccx = sx + (comp.offsetX or 0) + camX
						local ccy = math.floor(sprite.y + 0.5) + (comp.offsetY or 0) + camY
						local halfW = math.floor(comp.width / 2 + 0.5)
						local w = comp.width + extraPx
						local h = comp.height
						-- Pivot on the RAW eased offsetX sign (not a rounded value) so the
						-- flip happens exactly at offsetX=0 where extraPx=0, with no 2px
						-- sunset snap.
						local x = sun.offsetX < 0 and (ccx + halfW - w) or (ccx - halfW)
						local y = ccy - math.floor(h / 2)
						if w > 0 and h > 0 then
							shadowBatch:setColor(layerColor[1], layerColor[2], layerColor[3], sun.alpha or 0)
							if w <= 2 or h <= 2 then
								shadowBatch:add(x, y, 0, w, h)
							else
								shadowBatch:add(x + 1, y, 0, w - 2, 1)
								shadowBatch:add(x, y + 1, 0, w, h - 2)
								shadowBatch:add(x + 1, y + h - 1, 0, w - 2, 1)
							end
						end
					end
				end
			end
			love.graphics.draw(shadowBatch)
		end,
		nil,
		function()
			love.graphics.setColor(1, 1, 1, layerAlpha)
			love.graphics.draw(shadowCanvas, 0, 0)
		end
	)
end

---@param data table
---@return Shadow
	function Shadow.new(data)
		return setmetatable({
			offsetMultiplier = data.offsetMultiplier or 1,
			offsetX = data.offsetX or 0,
			offsetY = data.offsetY or 0,
			width = math.floor(data.width or 16),
			height = math.floor(data.height or 8),
			type = "shadow",
		}, Shadow)
	end

return Shadow
