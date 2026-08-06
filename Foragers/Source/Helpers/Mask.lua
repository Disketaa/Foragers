--- Pre-render sprites marked with `silhouette` component as white silhouettes.
--- Trees with "Silhouette" shader module sample this canvas and show black
--- dither where a silhouette overlaps their alpha.
local Canvas = require("Source.Helpers.Canvas")
local Pivot = require("Source.Helpers.Pivot")
local Mask = {}

local silCanvas = nil
local ensureCanvas = Canvas.createCanvasManager()

---@param entries table[] Entries with `.instance` (sprite) — same list as sorted draw
---@param viewW number World canvas width in px
---@param viewH number World canvas height in px
---@param camX number Camera pixel offset X (float for smooth scrolling)
---@param camY number Camera pixel offset Y (float for smooth scrolling)
function Mask.renderSilhouette(entries, viewW, viewH, camX, camY)
	silCanvas = ensureCanvas(viewW, viewH)

	Canvas.drawTo(silCanvas, function()
		for _, entry in ipairs(entries) do
			local sprite = entry.instance or entry
			if sprite and sprite.components then
				local silComp = sprite:findComponent("silhouette", function(c) return c.mode ~= "mask" and not c._broken end)
				if silComp then
					local color = silComp.color or { 0, 0, 0, 0.75 }
					love.graphics.setColor(color[1], color[2], color[3], color[4] or 0.75)
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

---@return love.Canvas|nil
function Mask.getCanvas()
	return silCanvas
end

return Mask
