local Canvas = require("Source.Helpers.Graphics.Canvas")
local DayCycle = require("Source.Helpers.Systems.DayCycle")
local Data = require("Content.Data.World").dayCycle

---@class Shadow
---@field parent Sprite|nil
---@field offsetMultiplier number Scale applied to the global sun-driven shadow offset (taller sprites can use >1)
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
	shadowCanvas = ensureCanvas(viewW, viewH)

	Canvas.drawTo(
		shadowCanvas,
		function()
			love.graphics.setColor(layerColor[1], layerColor[2], layerColor[3], 1)
			shadowBatch = ensureBatch()
			shadowBatch:clear()
			-- Sun-driven shadow offset/length is global (same for every sprite this
			-- frame); compute it once and scale per sprite via offsetMultiplier.
			-- Read the eased display state, not raw time, so scrubbing eases.
			local sun = DayCycle.getDisplaySunData()
			local lengthRatio = Data.maxShadowLen > 0 and (sun.sunLength / Data.maxShadowLen) or 0
			local widthMult = 1 + ((Data.widthStretchMax or 1) - 1) * lengthRatio
			for _, entry in ipairs(sprites) do
				local sprite = entry.instance or entry
				if sprite and sprite.components then
					local comps = sprite:getComponentsInto("shadow", hasShadow, shadowScan)
					for _, comp in ipairs(comps) do
						local mult = comp.offsetMultiplier or 1
						-- +0.5 round-half-up (matches sprite.x below); plain floor()
						-- biases toward -inf and flickers 1px near a zero-crossing (noon).
						local ox = math.floor(sun.offsetX * mult + 0.5)
						local oy = math.floor(sun.offsetY * mult + 0.5)
						local cx = math.floor(sprite.x + 0.5) + ox + camX
						local cy = math.floor(sprite.y + 0.5) + oy + camY
						local w = math.floor(comp.width * widthMult + 0.5)
						local h = comp.height
						-- Anchor the near edge (toward the sprite pivot) and grow only the
						-- far edge, so the shadow stretches AWAY from the sprite instead of
						-- bulging both ways. ox>=0 leans right (left edge holds, right grows);
						-- ox<0 leans left (right edge holds, left grows).
						local baseLeft = cx - math.floor(comp.width / 2 + 0.5)
						local extra = w - comp.width
						local x = ox >= 0 and baseLeft or (baseLeft - extra)
						local y = cy - math.floor(h / 2)
						if w > 0 and h > 0 then
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
		width = math.floor(data.width or 16),
		height = math.floor(data.height or 8),
		type = "shadow",
	}, Shadow)
end

return Shadow
