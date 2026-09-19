local Canvas = require("Source.Helpers.Graphics.Canvas")
local Mask = require("Source.Helpers.Graphics.Mask")

local Emissive = {}
Emissive.__index = Emissive

local emCanvas = nil
local ensureCanvas = Canvas.createCanvasManager()

function Emissive.new()
	return setmetatable({
		type = "emissive",
	}, Emissive)
end

function Emissive:attach()
	self.parent._hasEmissive = true
end

--- Draw emissive sprites at native 1x onto offscreen canvas, then blit canvas
--- to screen at integer scale s. Two-stage split avoids compounded fractional
--- scale (s * tweenScale) that breaks nearest-neighbor on direct-to-screen draw.
--- No shader UV sampling — canvas blit handles pixel alignment.
---@param entries table[] Entries with `.instance` (sprite)
---@param canvas table Canvas instance (for scale/offset)
---@param camPixelX number
---@param camPixelY number
---@param camSubX number
---@param camSubY number
---@param shakeX number
---@param shakeY number
---@param zoom number
---@param zpx number Zoom pivot X
---@param zpy number Zoom pivot Y
---@param targetCanvas love.Canvas|nil Optional target canvas; if nil, draws to screen
function Emissive.drawToScreen(entries, canvas, camPixelX, camPixelY, camSubX, camSubY, shakeX, shakeY, zoom, zpx, zpy, targetCanvas)
	emCanvas = ensureCanvas(canvas.width, canvas.height)

	Canvas.drawTo(emCanvas, function()
		love.graphics.push()
		love.graphics.translate(camPixelX, camPixelY)
		for _, entry in ipairs(entries) do
			local sprite = entry.instance or entry
			if sprite and sprite.components then
				local emComp = sprite:findComponent("emissive", function(c) return not c._broken end)
				if emComp then
					local alpha = sprite.alpha or 1
					love.graphics.setColor(1, 1, 1, alpha)

					Mask.drawSprite(sprite)
				end
			end
		end
		love.graphics.pop()
	end, { 0, 0, 0, 0 })

	love.graphics.push()
	if targetCanvas then
		love.graphics.draw(emCanvas, 0, 0)
	else
		if zoom ~= 1 then
			love.graphics.translate(zpx, zpy)
			love.graphics.scale(zoom, zoom)
			love.graphics.translate(-zpx, -zpy)
		end
		local s = canvas.scale
		local finalX = canvas.offsetX + math.floor(shakeX or 0) + camSubX * s - s
		local finalY = canvas.offsetY + math.floor(shakeY or 0) + camSubY * s - s
		love.graphics.draw(emCanvas, finalX, finalY, 0, s, s)
	end
	love.graphics.pop()
end

return Emissive