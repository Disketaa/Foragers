local Canvas = require("Source.Helpers.Graphics.Canvas")
local Pivot = require("Source.Helpers.Core.Pivot")

local Emissive = {}
Emissive.__index = Emissive

local emCanvas = nil
local ensureCanvas = Canvas.createCanvasManager()

function Emissive.new()
	return setmetatable({
		type = "emissive",
	}, Emissive)
end

function Emissive.renderLayer(entries, viewW, viewH, camX, camY)
	emCanvas = ensureCanvas(viewW, viewH)

	Canvas.drawTo(emCanvas, function()
		love.graphics.setColor(1, 1, 1, 1)
		for _, entry in ipairs(entries) do
			local sprite = entry.instance or entry
			if sprite and sprite.components then
				local emComp = sprite:findComponent("emissive", function(c) return not c._broken end)
				if emComp then
					local rot = 0
					local t = sprite.tweens
					if t then
						local angleTween = t.swing_angle or t.angle
						if angleTween then
							rot = math.rad(angleTween:getValue())
						end
					end
					if rot == 0 and sprite.angle then
						rot = math.rad(sprite.angle)
					end

					local spritesheet = sprite:findComponent("spritesheet", function(c) return not c._broken end)
					if spritesheet then
						local px = math.floor(sprite.x + 0.5) + camX
						local py = math.floor(sprite.y + 0.5) + camY
						spritesheet:drawCurrentFrame(px, py, rot)
					elseif sprite.image then
						local px = math.floor(sprite.x + 0.5) + camX
						local py = math.floor(sprite.y + 0.5) + camY
						local sx, sy = 1, 1
						if t then
							if t.scale_x then
								sx = t.scale_x:getValue()
							end
							if t.scale_y then
								sy = t.scale_y:getValue()
							end
						end
						if sprite.flipX then
							sx = -sx
						end
						local w = sprite.frameWidth or sprite.image:getWidth()
						local h = sprite.frameHeight or sprite.image:getHeight()
						local ox = Pivot.px(sprite.pivotX, w, 0)
						local oy = Pivot.px(sprite.pivotY, h, 0)
						love.graphics.draw(sprite.image, px, py, rot, sx, sy, ox, oy)
					end
				end
			end
		end
	end, { 0, 0, 0, 0 })
end

function Emissive.getCanvas()
	return emCanvas
end

return Emissive