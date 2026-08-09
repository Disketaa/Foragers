---@class Shadow
---@field parent Sprite|nil
---@field offsetX number Offset (px) of the shadow CENTER from the sprite's pivot point (sprite.x, sprite.y)
---@field offsetY number Offset (px) of the shadow CENTER from the sprite's pivot point (sprite.x, sprite.y)
---@field width number Shadow width in px
---@field height number Shadow height in px
---@field type "shadow"
local Canvas = require("Source.Helpers.Canvas")
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
			for _, entry in ipairs(sprites) do
				local sprite = entry.instance or entry
				if sprite and sprite.components then
					local comps = sprite:getComponentsInto("shadow", hasShadow, shadowScan)
					for _, comp in ipairs(comps) do
						local cx = math.floor(sprite.x + 0.5) + comp.offsetX + camX
						local cy = math.floor(sprite.y + 0.5) + comp.offsetY + camY
						local x = cx - math.floor(comp.width / 2)
						local y = cy - math.floor(comp.height / 2)
						local w = comp.width
						local h = comp.height
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
		offsetX = math.floor(data.offsetX or 0),
		offsetY = math.floor(data.offsetY or 0),
		width = math.floor(data.width or 16),
		height = math.floor(data.height or 8),
		type = "shadow",
	}, Shadow)
end

return Shadow
