--- Pre-render sprites marked with `silhouette` component as white silhouettes.
--- Trees with "Silhouette" shader module sample this canvas and show white
--- where a silhouette overlaps their alpha.
---@module Mask
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
	silCanvas = love.graphics.newCanvas(w, h)
	silCanvas:setFilter("nearest", "nearest")
	canvasW, canvasH = w, h
end

---@param entries table[] Entries with `.instance` (sprite) — same list as sorted draw
---@param viewW number World canvas width in px
---@param viewH number World canvas height in px
---@param camX number Integer camera pixel offset X
---@param camY number Integer camera pixel offset Y
function Mask.renderSilhouette(entries, viewW, viewH, camX, camY)
	ensureCanvas(viewW, viewH)

	local prevCanvas = love.graphics.getCanvas()

	love.graphics.push("all")
	love.graphics.setCanvas(silCanvas)
	love.graphics.origin()
	love.graphics.clear(0, 0, 0, 0)

	love.graphics.setColor(1, 1, 1, 1)

	for _, entry in ipairs(entries) do
		local sprite = entry.instance or entry
		if sprite and sprite.components then
			local hasSilhouette = false
			for _, comp in ipairs(sprite.components) do
				if comp.type == "silhouette" and comp.mode ~= "mask" and not comp._broken then
					hasSilhouette = true
					break
				end
			end
			if hasSilhouette then
				local spritesheet
				for _, comp in ipairs(sprite.components) do
					if comp.type == "spritesheet" and not comp._broken then
						spritesheet = comp
						break
					end
				end
		if spritesheet then
			local px = math.floor(sprite.x + 0.5) + camX
			local py = math.floor(sprite.y + 0.5) + camY
			spritesheet:drawCurrentFrame(px, py)
		elseif sprite.image then
			-- No spritesheet: single-frame sprite (Pickaxe, etc.)
			-- Match Sprite:draw() StaticSprite path
			local sx, sy = 1, 1
			if sprite.flipX then
				sx = -sx
			end
			local ox = (sprite.frameWidth or sprite.image:getWidth()) * (sprite.pivotX or 0)
			local oy = (sprite.frameHeight or sprite.image:getHeight()) * (sprite.pivotY or 0)
			local px = math.floor(sprite.x + 0.5) + camX
			local py = math.floor(sprite.y + 0.5) + camY
			love.graphics.draw(sprite.image, px, py, 0, sx, sy, ox, oy)
		end
			end
		end
	end

	love.graphics.setCanvas(prevCanvas)
	love.graphics.origin()
	love.graphics.pop()
end

---@return love.Canvas|nil
function Mask.getCanvas()
	return silCanvas
end

return Mask
