--- Pre-render sprites marked with `silhouette` component as white silhouettes.
--- Trees with "Silhouette" shader module sample this canvas and show black
--- dither where a silhouette overlaps their alpha.
local Canvas = require("Source.Helpers.Canvas")
local Mask = {}

local silCanvas = nil
local canvasW, canvasH = 0, 0

local function ensureCanvas(w, h)
	if silCanvas and canvasW == w and canvasH == h then
		return
	end
	if silCanvas then
		silCanvas:release()
	end
	silCanvas = Canvas.newCanvas(w, h)
	canvasW, canvasH = w, h
end

---@param entries table[] Entries with `.instance` (sprite) — same list as sorted draw
---@param viewW number World canvas width in px
---@param viewH number World canvas height in px
---@param camX number Integer camera pixel offset X
---@param camY number Integer camera pixel offset Y
function Mask.renderSilhouette(entries, viewW, viewH, camX, camY)
	ensureCanvas(viewW, viewH)

	Canvas.drawTo(silCanvas, function()
		love.graphics.setColor(1, 1, 1, 1)

		for _, entry in ipairs(entries) do
			local sprite = entry.instance or entry
			if sprite and sprite.components then
				local hasSilhouette = sprite:findComponent("silhouette", function(c) return c.mode ~= "mask" and not c._broken end)
				if hasSilhouette then
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
						local ox = (sprite.frameWidth or sprite.image:getWidth()) * (sprite.pivotX or 0)
						local oy = (sprite.frameHeight or sprite.image:getHeight()) * (sprite.pivotY or 0)
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
