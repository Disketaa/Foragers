--- Pre-render player sprite as white silhouette onto a canvas.
--- Trees with "Silhouette" shader module sample this canvas and show white
--- where the player silhouette overlaps their alpha.
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

---@param playerSprite Sprite|nil The player sprite to capture (nil = clear only)
---@param viewW number World canvas width in px
---@param viewH number World canvas height in px
---@param camX number Integer camera pixel offset X
---@param camY number Integer camera pixel offset Y
function Mask.renderSilhouette(playerSprite, viewW, viewH, camX, camY)
	ensureCanvas(viewW, viewH)

	local prevCanvas = love.graphics.getCanvas()

	love.graphics.push("all")
	love.graphics.setCanvas(silCanvas)
	love.graphics.origin()
	love.graphics.clear(0, 0, 0, 0)

	if playerSprite then
		local spritesheet
		for _, comp in ipairs(playerSprite.components) do
			if comp.type == "spritesheet" and not comp._broken then
				spritesheet = comp
				break
			end
		end

		if spritesheet then
			love.graphics.setColor(1, 1, 1, 1)
			local px = math.floor(playerSprite.x + 0.5) + camX
			local py = math.floor(playerSprite.y + 0.5) + camY
			spritesheet:drawCurrentFrame(px, py)
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
