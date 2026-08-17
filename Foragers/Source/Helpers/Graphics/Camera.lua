--- Reads camera state from the shared GameState table and takes the world
--- `canvas` (a Canvas instance) as an argument. Requires GameState directly so
--- the math-chain functions (screenToWorld -> computeZoomPivot -> canvasBlitOrigin)
--- stay arg-free except for `canvas`.
local GameState = require("Source.Helpers.Systems.GameState")
local Zoom = require("Source.Helpers.Graphics.Zoom")
local Pivot = require("Source.Helpers.Core.Pivot")

local CULL_MARGIN = 32

local Camera = {}

function Camera.update(canvas)
	if GameState.scrollToComp then
		local targetX, targetY = GameState.scrollToComp:getCameraOffset()
		-- Center camera on target
		GameState.cameraX = (canvas.width / 2) - targetX
		GameState.cameraY = (canvas.height / 2) - targetY
	else
		-- fallback: center on world
		GameState.cameraX = math.floor((canvas.width - GameState.worldPixelWidth) / 2)
		GameState.cameraY = math.floor((canvas.height - GameState.worldPixelHeight) / 2)
	end

	-- Split into integer pixel offset + fractional sub-pixel remainder
	GameState.camPixelX = math.floor(GameState.cameraX)
	GameState.camPixelY = math.floor(GameState.cameraY)
	GameState.camSubX = GameState.cameraX - GameState.camPixelX
	GameState.camSubY = GameState.cameraY - GameState.camPixelY
end

--- Unzoomed canvas blit origin (finalX/finalY in Canvas:draw). Shared by the zoom
--- coordinate transforms so mouse, gizmos and the pivot all agree with the render.
function Camera.canvasBlitOrigin(canvas)
	local s = canvas.scale
	return canvas.offsetX - s + GameState.shakeOffsetX + GameState.camSubX * s, canvas.offsetY - s + GameState.shakeOffsetY + GameState.camSubY * s
end

--- Zoom pivot: the player's on-screen position (unzoomed), so output zoom magnifies
--- around the player rather than the fixed window center. Falls back to window center
--- when there is no player.
function Camera.computeZoomPivot(canvas)
	if GameState.playerSprite then
		local s = canvas.scale
		local bx, by = Camera.canvasBlitOrigin(canvas)
		return bx + (GameState.playerSprite.x + GameState.camPixelX) * s, by + (GameState.playerSprite.y + GameState.camPixelY) * s
	end
	return love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5
end

--- Inverse of the render chain. Output zoom scales the canvas blit about the pivot:
--- screen = pivot + (finalX + (p + camPixel)*scale - pivot) * zoom.
function Camera.screenToWorld(canvas, screenX, screenY)
	local z = Zoom.current
	local px, py = Camera.computeZoomPivot(canvas)
	local bx, by = Camera.canvasBlitOrigin(canvas)
	local pcx = ((screenX - px) / z + px - bx) / canvas.scale
	local pcy = ((screenY - py) / z + py - by) / canvas.scale
	return pcx - GameState.camPixelX, pcy - GameState.camPixelY
end

--- Forward of the render chain: screen = pivot + (finalX + (wx + camPixel)*scale - pivot)*zoom.
--- Mirrors Canvas:draw's placement so gizmo rects land on the exact pixels the
--- world canvas occupies, at native resolution.
function Camera.worldToScreen(canvas, wx, wy)
	local s = canvas.scale
	local z = Zoom.current
	local px, py = Camera.computeZoomPivot(canvas)
	local bx, by = Camera.canvasBlitOrigin(canvas)
	local cx = bx + (wx + GameState.camPixelX) * s
	local cy = by + (wy + GameState.camPixelY) * s
	return (cx - px) * z + px, (cy - py) * z + py
end

--- CULL_MARGIN expands the view box so sprites don't flicker at the boundary;
--- the same box math as the gizmo boundaries overlay. All draw passes reuse this
--- list, computed once per frame.
function Camera.cullVisible(canvas, dynamicObjects, visible)
	-- View rect in world space (world->screen adds camPixelX/Y, canvas clips to view).
	-- Zoom happens at the canvas blit, so the world view never changes -- no cull change needed.
	local vx = -GameState.camPixelX - CULL_MARGIN
	local vy = -GameState.camPixelY - CULL_MARGIN
	local vw = canvas.width + CULL_MARGIN * 2
	local vh = canvas.height + CULL_MARGIN * 2
	local n = 0
	for i = 1, #dynamicObjects do
		local s = dynamicObjects[i].instance
		if s then
			local w = s.frameWidth or (s.image and s.image:getWidth() or 0) or 0
			local h = s.frameHeight or (s.image and s.image:getHeight() or 0) or 0
			if w > 0 and h > 0 then
				local bx = s.x - Pivot.px(s.pivotX, w, 0)
				local by = s.y - Pivot.px(s.pivotY, h, 0)
				if bx + w >= vx and bx <= vx + vw and by + h >= vy and by <= vy + vh then
					n = n + 1
					visible[n] = dynamicObjects[i]
				end
			else
				-- No frame box known: keep it (player, cursor-like, etc.).
				n = n + 1
				visible[n] = dynamicObjects[i]
			end
		end
	end
	for i = n + 1, #visible do
		visible[i] = nil
	end
end

return Camera
